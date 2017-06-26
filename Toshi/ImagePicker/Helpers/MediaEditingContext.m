#import "MediaEditingContext.h"

#import "UIImage+TG.h"
#import "StringUtils.h"
#import "PhotoEditorUtils.h"
#import "PhotoEditorValues.h"
#import "VideoEditAdjustments.h"

#import "ModernCache.h"
#import "MemoryImageCache.h"
#import "MediaAsset.h"
#import "Common.h"
#import "AppDelegate.h"

@interface MediaImageUpdate : NSObject

@property (nonatomic, readonly, strong) id<MediaEditableItem> item;
@property (nonatomic, readonly, strong) id representation;

+ (instancetype)imageUpdateWithItem:(id<MediaEditableItem>)item representation:(id)representation;

@end


@interface MediaAdjustmentsUpdate : NSObject

@property (nonatomic, readonly, strong) id<MediaEditableItem> item;
@property (nonatomic, readonly, strong) id<MediaEditAdjustments> adjustments;

+ (instancetype)adjustmentsUpdateWithItem:(id<MediaEditableItem>)item adjustments:(id<MediaEditAdjustments>)adjustments;

@end


@interface MediaCaptionUpdate : NSObject

@property (nonatomic, readonly, strong) id<MediaEditableItem> item;
@property (nonatomic, readonly, strong) NSString *caption;

+ (instancetype)captionUpdateWithItem:(id<MediaEditableItem>)item caption:(NSString *)caption;

@end


@interface ModernCache (Private)

- (void)cleanup;

@end

@interface MediaEditingContext ()
{
    NSString *_contextId;
    
    NSMutableDictionary *_captions;
    NSMutableDictionary *_adjustments;
 
    SQueue *_queue;
    
    NSMutableDictionary *_temporaryRepCache;
    
    MemoryImageCache *_imageCache;
    MemoryImageCache *_thumbnailImageCache;
    
    MemoryImageCache *_paintingImageCache;
    
    MemoryImageCache *_originalImageCache;
    MemoryImageCache *_originalThumbnailImageCache;
    
    ModernCache *_diskCache;
    NSURL *_fullSizeResultsUrl;
    NSURL *_paintingDatasUrl;
    NSURL *_paintingImagesUrl;
    NSURL *_videoPaintingImagesUrl;
    
    NSMutableArray *_storeVideoPaintingImages;
    
    NSMutableDictionary *_faces;
    
    SPipe *_representationPipe;
    SPipe *_thumbnailImagePipe;
    SPipe *_adjustmentsPipe;
    SPipe *_captionPipe;
    SPipe *_fullSizePipe;
    SPipe *_cropPipe;
}
@end

@implementation MediaEditingContext

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _contextId = [NSString stringWithFormat:@"%ld", lrand48()];
        _queue = [[SQueue alloc] init];

        _captions = [[NSMutableDictionary alloc] init];
        _adjustments = [[NSMutableDictionary alloc] init];
        
        _imageCache = [[MemoryImageCache alloc] initWithSoftMemoryLimit:[[self class] imageSoftMemoryLimit]
                                                          hardMemoryLimit:[[self class] imageHardMemoryLimit]];
        _thumbnailImageCache = [[MemoryImageCache alloc] initWithSoftMemoryLimit:[[self class] thumbnailImageSoftMemoryLimit]
                                                                   hardMemoryLimit:[[self class] thumbnailImageHardMemoryLimit]];
        
        _paintingImageCache = [[MemoryImageCache alloc] initWithSoftMemoryLimit:[[self class] imageSoftMemoryLimit]
                                                                  hardMemoryLimit:[[self class] imageHardMemoryLimit]];
        
        _originalImageCache = [[MemoryImageCache alloc] initWithSoftMemoryLimit:[[self class] originalImageSoftMemoryLimit]
                                                                  hardMemoryLimit:[[self class] originalImageHardMemoryLimit]];
        _originalThumbnailImageCache = [[MemoryImageCache alloc] initWithSoftMemoryLimit:[[self class] thumbnailImageSoftMemoryLimit]
                                                                           hardMemoryLimit:[[self class] thumbnailImageHardMemoryLimit]];
        
        NSString *diskCachePath = [[AppDelegate documentsPath] stringByAppendingPathComponent:[[self class] diskCachePath]];
        _diskCache = [[ModernCache alloc] initWithPath:diskCachePath size:[[self class] diskMemoryLimit]];
        
        _fullSizeResultsUrl = [NSURL fileURLWithPath:[[AppDelegate documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"photoeditorresults/%@", _contextId]]];
        [[NSFileManager defaultManager] createDirectoryAtPath:_fullSizeResultsUrl.path withIntermediateDirectories:true attributes:nil error:nil];
        
        _paintingImagesUrl = [NSURL fileURLWithPath:[[AppDelegate documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"paintingimages/%@", _contextId]]];
        [[NSFileManager defaultManager] createDirectoryAtPath:_paintingImagesUrl.path withIntermediateDirectories:true attributes:nil error:nil];
       
        _videoPaintingImagesUrl = [NSURL fileURLWithPath:[[AppDelegate documentsPath] stringByAppendingPathComponent:@"videopaintingimages"]];
        [[NSFileManager defaultManager] createDirectoryAtPath:_videoPaintingImagesUrl.path withIntermediateDirectories:true attributes:nil error:nil];
        
        _paintingDatasUrl = [NSURL fileURLWithPath:[[AppDelegate documentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"paintingdatas/%@", _contextId]]];
        [[NSFileManager defaultManager] createDirectoryAtPath:_paintingDatasUrl.path withIntermediateDirectories:true attributes:nil error:nil];
        
        _storeVideoPaintingImages = [[NSMutableArray alloc] init];
        
        _faces = [[NSMutableDictionary alloc] init];
        
        _temporaryRepCache = [[NSMutableDictionary alloc] init];
        
        _representationPipe = [[SPipe alloc] init];
        _thumbnailImagePipe = [[SPipe alloc] init];
        _adjustmentsPipe = [[SPipe alloc] init];
        _captionPipe = [[SPipe alloc] init];
        _fullSizePipe = [[SPipe alloc] init];
        _cropPipe = [[SPipe alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self cleanup];
}

- (void)cleanup
{
    [_diskCache cleanup];
    
    [[NSFileManager defaultManager] removeItemAtPath:_fullSizeResultsUrl.path error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:_paintingImagesUrl.path error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:_paintingDatasUrl.path error:nil];
}

+ (instancetype)contextForCaptionsOnly
{
    MediaEditingContext *context = [[MediaEditingContext alloc] init];
    context->_inhibitEditing = true;
    return context;
}

#pragma mark -

- (SSignal *)imageSignalForItem:(NSObject<MediaEditableItem> *)item
{
    return [self imageSignalForItem:item withUpdates:true];
}

- (SSignal *)imageSignalForItem:(NSObject<MediaEditableItem> *)item withUpdates:(bool)withUpdates
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    if (itemId == nil)
        return [SSignal fail:nil];
    
    SSignal *updateSignal = [[_representationPipe.signalProducer() filter:^bool(MediaImageUpdate *update)
    {
        return [update.item.uniqueIdentifier isEqualToString:item.uniqueIdentifier];
    }] map:^id(MediaImageUpdate *update)
    {
        return update.representation;
    }];
    
    if ([self _adjustmentsForItemId:itemId] == nil)
    {
        SSignal *signal = [SSignal single:nil];
        if (withUpdates)
            signal = [signal then:updateSignal];
        return signal;
    }
    
    NSString *imageUri = [MediaEditingContext _imageUriForItemId:itemId];
    SSignal *signal = [[self _imageSignalForItemId:itemId imageCache:_imageCache imageDiskUri:imageUri synchronous:false] catch:^SSignal *(__unused id error)
    {
        id temporaryRep = [_temporaryRepCache objectForKey:itemId];
        SSignal *signal = [SSignal single:temporaryRep];
        if (withUpdates)
            signal = [signal then:updateSignal];
        return signal;
    }];
    if (withUpdates)
        signal = [signal then:updateSignal];
    return signal;
}

- (SSignal *)thumbnailImageSignalForItem:(id<MediaEditableItem>)item
{
    return [self thumbnailImageSignalForItem:item withUpdates:true synchronous:false];
}

- (SSignal *)thumbnailImageSignalForItem:(id<MediaEditableItem>)item withUpdates:(bool)withUpdates synchronous:(bool)synchronous
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    if (itemId == nil)
        return [SSignal fail:nil];
    
    SSignal *updateSignal = [[_thumbnailImagePipe.signalProducer() filter:^bool(MediaImageUpdate *update)
    {
        return [update.item.uniqueIdentifier isEqualToString:item.uniqueIdentifier];
    }] map:^id(MediaImageUpdate *update)
    {
        return update.representation;
    }];
    
    if ([self _adjustmentsForItemId:itemId] == nil)
    {
        SSignal *signal = [SSignal single:nil];
        if (withUpdates)
            signal = [signal then:updateSignal];
        return signal;
    }
    
    NSString *imageUri = [MediaEditingContext _thumbnailImageUriForItemId:itemId];
    SSignal *signal = [[self _imageSignalForItemId:itemId imageCache:_thumbnailImageCache imageDiskUri:imageUri synchronous:synchronous] catch:^SSignal *(__unused id error)
    {
        SSignal *signal = [SSignal single:nil];
        if (withUpdates)
            signal = [signal then:updateSignal];
        return signal;
    }];
    if (withUpdates)
        signal = [signal then:updateSignal];
    return signal;
}

- (SSignal *)fastImageSignalForItem:(NSObject<MediaEditableItem> *)item withUpdates:(bool)withUpdates
{
    return [[self thumbnailImageSignalForItem:item withUpdates:false synchronous:true] then:[self imageSignalForItem:item withUpdates:withUpdates]];
}

- (SSignal *)_imageSignalForItemId:(NSString *)itemId imageCache:(MemoryImageCache *)imageCache imageDiskUri:(NSString *)imageDiskUri synchronous:(bool)synchronous
{
    if (itemId == nil)
        return [SSignal fail:nil];
    
    SSignal *signal = [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        UIImage *result = [imageCache imageForKey:itemId attributes:NULL];
        if (result == nil)
        {
            NSData *imageData = [_diskCache getValueForKey:[imageDiskUri dataUsingEncoding:NSUTF8StringEncoding]];
            if (imageData.length > 0)
            {
                result = [UIImage imageWithData:imageData];
                [imageCache setImage:result forKey:itemId attributes:NULL];
            }
        }
        
        if (result != nil)
        {
            [subscriber putNext:result];
            [subscriber putCompletion];
        }
        else
        {
            [subscriber putError:nil];
        }
        
        return nil;
    }];
    
    return synchronous ? signal : [signal startOn:_queue];
}

- (void)_clearPreviousImageForItemId:(NSString *)itemId
{    
    [_imageCache setImage:nil forKey:itemId attributes:NULL];
    
    NSString *imageUri = [[self class] _imageUriForItemId:itemId];
    [_diskCache setValue:[NSData data] forKey:[imageUri dataUsingEncoding:NSUTF8StringEncoding]];
}

- (UIImage *)paintingImageForItem:(NSObject<MediaEditableItem> *)item
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    if (itemId == nil)
        return nil;
    
    UIImage *result = [_paintingImageCache imageForKey:itemId attributes:NULL];
    if (result == nil)
    {
        NSURL *imageUrl = [_paintingImagesUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", [StringUtils md5:itemId]]];
        UIImage *diskImage = [UIImage imageWithContentsOfFile:imageUrl.path];
        if (diskImage != nil)
        {
            result = diskImage;
            [_paintingImageCache setImage:result forKey:itemId attributes:NULL];
        }
    }

    return result;
}

#pragma mark - Caption

- (NSString *)captionForItem:(id<MediaEditableItem>)item
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    if (itemId == nil)
        return nil;
    
    return _captions[itemId];
}

- (void)setCaption:(NSString *)caption forItem:(id<MediaEditableItem>)item
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    if (itemId == nil)
        return;
    
    if (caption.length > 0)
        _captions[itemId] = caption;
    else
        [_captions removeObjectForKey:itemId];
    
    _captionPipe.sink([MediaCaptionUpdate captionUpdateWithItem:item caption:caption]);
}

- (SSignal *)captionSignalForItem:(NSObject<MediaEditableItem> *)item
{
    SSignal *updateSignal = [[_captionPipe.signalProducer() filter:^bool(MediaCaptionUpdate *update)
    {
        return [update.item.uniqueIdentifier isEqualToString:item.uniqueIdentifier];
    }] map:^NSString *(MediaCaptionUpdate *update)
    {
        return update.caption;
    }];
    
    return [[SSignal single:[self captionForItem:item]] then:updateSignal];
}

#pragma mark -

- (id<MediaEditAdjustments>)adjustmentsForItem:(id<MediaEditableItem>)item
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    if (itemId == nil)
        return nil;
    
    return [self _adjustmentsForItemId:itemId];
}

- (id<MediaEditAdjustments>)_adjustmentsForItemId:(NSString *)itemId
{
    if (itemId == nil)
        return nil;
    
    return _adjustments[itemId];
}

- (void)setAdjustments:(id<MediaEditAdjustments>)adjustments forItem:(id<MediaEditableItem>)item
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    if (itemId == nil)
        return;
    
    id<MediaEditAdjustments> previousAdjustments = _adjustments[itemId];
    
    if (adjustments != nil)
        _adjustments[itemId] = adjustments;
    else
        [_adjustments removeObjectForKey:itemId];

    bool cropChanged = false;
    if (![previousAdjustments cropAppliedForAvatar:false] && [adjustments cropAppliedForAvatar:false])
        cropChanged = true;
    else if ([previousAdjustments cropAppliedForAvatar:false] && ![adjustments cropAppliedForAvatar:false])
        cropChanged = true;
    else if ([previousAdjustments cropAppliedForAvatar:false] && [adjustments cropAppliedForAvatar:false] && ![previousAdjustments isCropEqualWith:adjustments])
        cropChanged = true;
    
    if (cropChanged)
        _cropPipe.sink(@true);
    
    _adjustmentsPipe.sink([MediaAdjustmentsUpdate adjustmentsUpdateWithItem:item adjustments:adjustments]);
}

- (SSignal *)adjustmentsSignalForItem:(NSObject<MediaEditableItem> *)item
{
    SSignal *updateSignal = [[_adjustmentsPipe.signalProducer() filter:^bool(MediaAdjustmentsUpdate *update)
    {
        return [update.item.uniqueIdentifier isEqualToString:item.uniqueIdentifier];
    }] map:^id<MediaEditAdjustments>(MediaAdjustmentsUpdate *update)
    {
        return update.adjustments;
    }];
    
    return [[SSignal single:[self adjustmentsForItem:item]] then:updateSignal];
}

- (SSignal *)cropAdjustmentsUpdatedSignal
{
    return _cropPipe.signalProducer();
}

#pragma mark -

- (void)setImage:(UIImage *)image thumbnailImage:(UIImage *)thumbnailImage forItem:(id<MediaEditableItem>)item synchronous:(bool)synchronous
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    
    if (itemId == nil)
        return;
    
    void (^block)(void) = ^
    {
        [_temporaryRepCache removeObjectForKey:itemId];
        
        NSString *imageUri = [[self class] _imageUriForItemId:itemId];
        [_imageCache setImage:image forKey:itemId attributes:NULL];
        if (image != nil)
        {
            NSData *imageData = UIImageJPEGRepresentation(image, 0.95f);
            [_diskCache setValue:imageData forKey:[imageUri dataUsingEncoding:NSUTF8StringEncoding]];
        }
        _representationPipe.sink([MediaImageUpdate imageUpdateWithItem:item representation:image]);
    
        NSString *thumbnailImageUri = [[self class] _thumbnailImageUriForItemId:itemId];
        [_thumbnailImageCache setImage:thumbnailImage forKey:itemId attributes:NULL];
        if (thumbnailImage != nil)
        {
            NSData *imageData = UIImageJPEGRepresentation(thumbnailImage, 0.87f);
            [_diskCache setValue:imageData forKey:[thumbnailImageUri dataUsingEncoding:NSUTF8StringEncoding]];
        }
        if ([item isKindOfClass:[MediaAsset class]] && ((MediaAsset *)item).isVideo)
            _thumbnailImagePipe.sink([MediaImageUpdate imageUpdateWithItem:item representation:thumbnailImage]);
    };
    
    if (synchronous)
        [_queue dispatchSync:block];
    else
        [_queue dispatch:block];
}

- (bool)setPaintingData:(NSData *)data image:(UIImage *)image forItem:(NSObject<MediaEditableItem> *)item dataUrl:(NSURL **)dataOutUrl imageUrl:(NSURL **)imageOutUrl forVideo:(bool)video
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    
    if (itemId == nil)
        return false;
    
    NSURL *imagesDirectory = video ? _videoPaintingImagesUrl : _paintingImagesUrl;
    NSURL *imageUrl = [imagesDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", [StringUtils md5:itemId]]];
    NSURL *dataUrl = [_paintingDatasUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat", [StringUtils md5:itemId]]];
    
    [_paintingImageCache setImage:image forKey:itemId attributes:NULL];
    
    if (!imageUrl) {
        return false;
    }
    
    NSData *imageData = UIImagePNGRepresentation(image);
    bool imageSuccess = [imageData writeToURL:imageUrl options:NSDataWritingAtomic error:nil];
    bool dataSuccess = [data writeToURL:dataUrl options:NSDataWritingAtomic error:nil];
    
    if (imageSuccess && imageOutUrl != NULL)
        *imageOutUrl = imageUrl;
    
    if (dataSuccess && dataOutUrl != NULL)
        *dataOutUrl = dataUrl;
    
    if (video)
        [_storeVideoPaintingImages addObject:imageUrl];
    
    return (image == nil || imageSuccess) && (data == nil || dataSuccess);
}

- (void)clearPaintingData
{
    for (NSURL *url in _storeVideoPaintingImages)
    {
        [[NSFileManager defaultManager] removeItemAtURL:url error:NULL];
    }
}

- (SSignal *)facesForItem:(NSObject<MediaEditableItem> *)item
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    if (itemId == nil)
        return [SSignal fail:nil];
    
    NSArray *faces = _faces[itemId];
    
    return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        [subscriber putNext:faces];
        [subscriber putCompletion];
                           
        return nil;
    }];
}

- (void)setFaces:(NSArray *)faces forItem:(NSObject<MediaEditableItem> *)item
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    if (itemId == nil)
        return;
    
    if (faces.count > 0)
        _faces[itemId] = faces;
    else
        [_faces removeObjectForKey:itemId];
}

- (void)setFullSizeImage:(UIImage *)image forItem:(id<MediaEditableItem>)item
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    
    if (itemId == nil)
        return;
    
    NSData *imageData = UIImageJPEGRepresentation(image, 0.7f);
    NSURL *url = [_fullSizeResultsUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", [StringUtils md5:itemId]]];
    
    bool succeed = [imageData writeToURL:url options:NSDataWritingAtomic error:nil];
    if (succeed)
        _fullSizePipe.sink(itemId);
}

- (NSURL *)_fullSizeImageUrlForItem:(id<MediaEditableItem>)item
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    
    if (itemId == nil)
        return nil;
    
    NSURL *url = [_fullSizeResultsUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", [StringUtils md5:itemId]]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:url.path])
        return url;
    
    return nil;
}

- (SSignal *)fullSizeImageUrlForItem:(id<MediaEditableItem>)item
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    id<MediaEditAdjustments> adjustments = [self adjustmentsForItem:item];
    
    if (![adjustments isKindOfClass:[PhotoEditorValues class]])
        return [SSignal complete];
    
    PhotoEditorValues *editorValues = (PhotoEditorValues *)adjustments;
    if (![editorValues toolsApplied] && ![editorValues hasPainting])
        return [SSignal complete];
    
    NSURL *url = [self _fullSizeImageUrlForItem:item];
    if (url != nil)
        return [SSignal single:url];
    
    return [[[_fullSizePipe.signalProducer() filter:^bool(NSString *identifier)
    {
        return [identifier isEqualToString:itemId];
    }] mapToSignal:^SSignal *(__unused id next)
    {
        NSURL *url = [self _fullSizeImageUrlForItem:item];
        if (url != nil)
            return [SSignal single:url];
        else
            return [SSignal complete];
    }] timeout:5.0 onQueue:_queue orSignal:[SSignal complete]];
}

- (void)setTemporaryRep:(id)rep forItem:(id<MediaEditableItem>)item
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    
    if (itemId == nil)
        return;
    
    UIImage *thumbnailImage = nil;
    if ([rep isKindOfClass:[UIImage class]])
    {
        UIImage *image = (UIImage *)rep;
        image.degraded = true;
        image.edited = true;
        
        CGSize fillSize = PhotoThumbnailSizeForCurrentScreen();
        fillSize.width = CGCeil(fillSize.width);
        fillSize.height = CGCeil(fillSize.height);
        
        CGSize size = ScaleToFillSize(image.size, fillSize);
        
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0f);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetInterpolationQuality(context, kCGInterpolationMedium);
        
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        
        thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    [_queue dispatchSync:^
    {
        [self _clearPreviousImageForItemId:itemId];
        
        if (rep != nil)
            [_temporaryRepCache setObject:rep forKey:itemId];
        else
            [_temporaryRepCache removeObjectForKey:itemId];
        
        _representationPipe.sink([MediaImageUpdate imageUpdateWithItem:item representation:rep]);
        
        if (thumbnailImage != nil)
        {
            [_thumbnailImageCache setImage:thumbnailImage forKey:itemId attributes:NULL];
            _thumbnailImagePipe.sink([MediaImageUpdate imageUpdateWithItem:item representation:thumbnailImage]);
        }
    }];
}

#pragma mark - Original Images

- (void)requestOriginalImageForItem:(id<MediaEditableItem>)item completion:(void (^)(UIImage *))completion
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    
    if (itemId == nil)
    {
        if (completion != nil)
            completion(nil);
        return;
    }
    
    __block UIImage *result = [_originalImageCache imageForKey:itemId attributes:NULL];
    if (result != nil)
    {
        if (completion != nil)
            completion(result);
    }
    else
    {
        [_queue dispatch:^
        {
            NSString *originalImageUri = [[self class] _originalImageUriForItemId:itemId];
            NSData *imageData = [_diskCache getValueForKey:[originalImageUri dataUsingEncoding:NSUTF8StringEncoding]];
            if (imageData != nil)
            {
                result = [UIImage imageWithData:imageData];
                
                [_originalImageCache setImage:result forKey:itemId attributes:NULL];
            }
            
            if (completion != nil)
                completion(result);
        }];
    }
}

- (void)requestOriginalThumbnailImageForItem:(id<MediaEditableItem>)item completion:(void (^)(UIImage *))completion
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    
    if (itemId == nil)
    {
        if (completion != nil)
            completion(nil);
        return;
    }
    
    __block UIImage *result = [_originalThumbnailImageCache imageForKey:itemId attributes:NULL];
    if (result != nil)
    {
        if (completion != nil)
            completion(result);
    }
    else
    {
        [_queue dispatch:^
        {
            NSString *originalThumbnailImageUri = [[self class] _originalThumbnailImageUriForItemId:itemId];
            NSData *imageData = [_diskCache getValueForKey:[originalThumbnailImageUri dataUsingEncoding:NSUTF8StringEncoding]];
            if (imageData != nil)
            {
                result = [UIImage imageWithData:imageData];
                
                [_originalThumbnailImageCache setImage:result forKey:itemId attributes:NULL];
            }
            
            if (completion != nil)
                completion(result);
        }];
    }
}

- (void)setOriginalImage:(UIImage *)image forItem:(id<MediaEditableItem>)item synchronous:(bool)synchronous
{
    NSString *itemId = [self _contextualIdForItemId:item.uniqueIdentifier];
    
    if (itemId == nil || image == nil)
        return;
    
    if ([_originalImageCache imageForKey:itemId attributes:NULL] != nil)
        return;
    
    void (^block)(void) = ^
    {
        if (image != nil)
        {
            NSString *originalImageUri = [[self class] _originalImageUriForItemId:itemId];
            NSData *existingImageData = [_diskCache getValueForKey:[originalImageUri dataUsingEncoding:NSUTF8StringEncoding]];
            if (existingImageData.length > 0)
                return;
            
            [_originalImageCache setImage:image forKey:itemId attributes:NULL];
            NSData *imageData = UIImageJPEGRepresentation(image, 0.95f);
            [_diskCache setValue:imageData forKey:[originalImageUri dataUsingEncoding:NSUTF8StringEncoding]];
            
            CGFloat thumbnailImageSide = PhotoThumbnailSizeForCurrentScreen().width;
            CGSize targetSize = ScaleToSize(image.size, CGSizeMake(thumbnailImageSide, thumbnailImageSide));
            
            UIGraphicsBeginImageContextWithOptions(targetSize, true, 0.0f);
            [image drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            [_originalThumbnailImageCache setImage:image forKey:itemId attributes:NULL];
            NSString *originalThumbnailImageUri = [[self class] _originalThumbnailImageUriForItemId:itemId];
            NSData *thumbnailImageData = UIImageJPEGRepresentation(image, 0.87f);
            [_diskCache setValue:thumbnailImageData forKey:[originalThumbnailImageUri dataUsingEncoding:NSUTF8StringEncoding]];
        }
    };
    
    if (synchronous)
        [_queue dispatchSync:block];
    else
        [_queue dispatch:block];
}

+ (NSString *)_originalImageUriForItemId:(NSString *)itemId
{
    return [NSString stringWithFormat:@"photo-editor-original://%@", itemId];
}

+ (NSString *)_originalThumbnailImageUriForItemId:(NSString *)itemId
{
    return [NSString stringWithFormat:@"photo-editor-original-thumb://%@", itemId];
}

#pragma mark - URI

- (NSString *)_contextualIdForItemId:(NSString *)itemId
{
    if (itemId == nil)
        return nil;
    
    return [NSString stringWithFormat:@"%@_%@", _contextId, itemId];
}

+ (NSString *)_imageUriForItemId:(NSString *)itemId
{
    return [NSString stringWithFormat:@"%@://%@", [self imageUriScheme], itemId];
}

+ (NSString *)_thumbnailImageUriForItemId:(NSString *)itemId
{
    return [NSString stringWithFormat:@"%@://%@", [self thumbnailImageUriScheme], itemId];
}

#pragma mark - Constants

+ (NSString *)imageUriScheme
{
    return @"photo-editor";
}

+ (NSString *)thumbnailImageUriScheme
{
    return @"photo-editor-thumb";
}

+ (NSString *)diskCachePath
{
    return @"photoeditorcache_v1";
}

+ (NSUInteger)diskMemoryLimit
{
    return 64 * 1024 * 1024;
}

+ (NSUInteger)imageSoftMemoryLimit
{
    return 13 * 1024 * 1024;
}

+ (NSUInteger)imageHardMemoryLimit
{
    return 15 * 1024 * 1024;
}

+ (NSUInteger)originalImageSoftMemoryLimit
{
    return 12 * 1024 * 1024;
}

+ (NSUInteger)originalImageHardMemoryLimit
{
    return 14 * 1024 * 1024;
}

+ (NSUInteger)thumbnailImageSoftMemoryLimit
{
    return 2 * 1024 * 1024;
}

+ (NSUInteger)thumbnailImageHardMemoryLimit
{
    return 3 * 1024 * 1024;
}

@end


@implementation MediaImageUpdate

+ (instancetype)imageUpdateWithItem:(id<MediaEditableItem>)item representation:(id)representation
{
    MediaImageUpdate *update = [[MediaImageUpdate alloc] init];
    update->_item = item;
    update->_representation = representation;
    return update;
}

@end


@implementation MediaAdjustmentsUpdate

+ (instancetype)adjustmentsUpdateWithItem:(id<MediaEditableItem>)item adjustments:(id<MediaEditAdjustments>)adjustments
{
    MediaAdjustmentsUpdate *update = [[MediaAdjustmentsUpdate alloc] init];
    update->_item = item;
    update->_adjustments = adjustments;
    return update;
}

@end

@implementation MediaCaptionUpdate

+ (instancetype)captionUpdateWithItem:(id<MediaEditableItem>)item caption:(NSString *)caption
{
    MediaCaptionUpdate *update = [[MediaCaptionUpdate alloc] init];
    update->_item = item;
    update->_caption = caption;
    return update;
}

@end
