#import "MediaAssetsPickerController.h"
#import "MediaAssetsMomentsController.h"
#import "MediaGroupsController.h"

#import "MediaAssetMomentList.h"

#import "AppDelegate.h"
#import "FileUtils.h"
#import "ImageUtils.h"
#import "PhotoEditorUtils.h"
#import "PaintUtils.h"
#import "UIImage+TG.h"
#import "GifConverter.h"
#import <CommonCrypto/CommonDigest.h>

#import "MediaPickerToolbarView.h"
#import "MediaAssetsTipView.h"

#import "MediaAsset+MediaEditableItem.h"
#import "MediaAssetImageSignals.h"

#import "PhotoEditorController.h"

#import "VideoEditAdjustments.h"
#import "PaintingData.h"
#import "Common.h"
#import "DocumentAttributeFilename.h"
#import "DocumentAttributeAnimated.h"
#import "DocumentAttributeVideo.h"
#import "ItemDescriptor.h"

@interface MediaAssetsController () <UINavigationControllerDelegate>
{
    MediaAssetsControllerIntent _intent;
    
    MediaPickerToolbarView *_toolbarView;
    MediaSelectionContext *_selectionContext;
    MediaEditingContext *_editingContext;
    
    SMetaDisposable *_selectionChangedDisposable;
}

@property (nonatomic, readonly) MediaAssetsLibrary *assetsLibrary;

@end

@implementation  MediaAssetsController

+ (instancetype)controllerWithAssetGroup:( MediaAssetGroup *)assetGroup intent:( MediaAssetsControllerIntent)intent
{
    return [MediaAssetsController __commonInitWith:assetGroup intent:intent];
}

- (instancetype)initWithAssetGroup:(MediaAssetGroup *)assetGroup intent:(MediaAssetsControllerIntent)intent
{
    return [MediaAssetsController __commonInitWith:assetGroup intent:intent];
}

+ (MediaAssetsController *)__commonInitWith:(MediaAssetGroup *)assetGroup intent:(MediaAssetsControllerIntent)intent
{
    MediaAssetsController *assetsController = [[MediaAssetsController alloc] initWithIntent:intent];
    
    __weak MediaAssetsController *weakController = assetsController;
    void (^catchToolbarView)(bool) = ^(bool enabled)
    {
        __strong MediaAssetsController *strongController = weakController;
        if (strongController == nil)
            return;
        
        UIView *toolbarView = strongController->_toolbarView;
        if (enabled)
        {
            if (toolbarView.superview != strongController.view)
                return;
            
            [strongController.pickerController.view addSubview:toolbarView];
        }
        else
        {
            if (toolbarView.superview == strongController.view)
                return;
            
            [strongController.view addSubview:toolbarView];
        }
    };
    
    MediaGroupsController *groupsController = [[MediaGroupsController alloc] initWithAssetsLibrary:assetsController.assetsLibrary intent:intent];
    groupsController.openAssetGroup = ^(id group)
    {
        __strong MediaAssetsController *strongController = weakController;
        if (strongController == nil)
            return;
        
        MediaAssetsPickerController *pickerController = nil;
        
        if ([group isKindOfClass:[MediaAssetGroup class]])
        {
            pickerController = [[MediaAssetsPickerController alloc] initWithAssetsLibrary:strongController.assetsLibrary assetGroup:group intent:intent selectionContext:strongController->_selectionContext editingContext:strongController->_editingContext];
        }
        else if ([group isKindOfClass:[MediaAssetMomentList class]])
        {
            pickerController = [[MediaAssetsMomentsController alloc] initWithAssetsLibrary:strongController.assetsLibrary momentList:group intent:intent selectionContext:strongController->_selectionContext editingContext:strongController->_editingContext];
        }
        pickerController.suggestionContext = strongController.suggestionContext;
        pickerController.localMediaCacheEnabled = strongController.localMediaCacheEnabled;
        pickerController.captionsEnabled = strongController.captionsEnabled;
        pickerController.inhibitDocumentCaptions = strongController.inhibitDocumentCaptions;
        pickerController.liveVideoUploadEnabled = strongController.liveVideoUploadEnabled;
        pickerController.catchToolbarView = catchToolbarView;
        [strongController pushViewController:pickerController animated:true];
    };
    [groupsController loadViewIfNeeded];
    
    MediaAssetsPickerController *pickerController = [[MediaAssetsPickerController alloc] initWithAssetsLibrary:assetsController.assetsLibrary assetGroup:assetGroup intent:intent selectionContext:assetsController->_selectionContext editingContext:assetsController->_editingContext];
    pickerController.catchToolbarView = catchToolbarView;
    
    [groupsController setIsFirstInStack:true];
    [pickerController setIsFirstInStack:false];
    
    [assetsController setViewControllers:@[ groupsController, pickerController ]];
    
    return assetsController;
}

- (void)setSuggestionContext:(SuggestionContext *)suggestionContext
{
    _suggestionContext = suggestionContext;
    self.pickerController.suggestionContext = suggestionContext;
}

- (void)setCaptionsEnabled:(bool)captionsEnabled
{
    _captionsEnabled = captionsEnabled;
    self.pickerController.captionsEnabled = captionsEnabled;
}

- (void)setInhibitDocumentCaptions:(bool)inhibitDocumentCaptions
{
    _inhibitDocumentCaptions = inhibitDocumentCaptions;
    self.pickerController.inhibitDocumentCaptions = inhibitDocumentCaptions;
}

- (void)setLiveVideoUploadEnabled:(bool)liveVideoUploadEnabled
{
    _liveVideoUploadEnabled = liveVideoUploadEnabled;
    self.pickerController.liveVideoUploadEnabled = liveVideoUploadEnabled;
}

- (void)setLocalMediaCacheEnabled:(bool)localMediaCacheEnabled
{
    _localMediaCacheEnabled = localMediaCacheEnabled;
    self.pickerController.localMediaCacheEnabled = localMediaCacheEnabled;
}

- (void)setShouldStoreAssets:(bool)shouldStoreAssets
{
    _shouldStoreAssets = shouldStoreAssets;
    self.pickerController.shouldStoreAssets = shouldStoreAssets;
}

- (MediaAssetsPickerController *)pickerController
{
    MediaAssetsPickerController *pickerController = nil;
    for (UIViewController *viewController in self.viewControllers)
    {
        if ([viewController isKindOfClass:[MediaAssetsPickerController class]])
        {
            pickerController = (MediaAssetsPickerController *)viewController;
            break;
        }
    }
    return pickerController;
}

- (instancetype)initWithIntent:(MediaAssetsControllerIntent)intent
{
    self = [super initWithNavigationBarClass:[UINavigationBar class] toolbarClass:[UIToolbar class]];
    if (self != nil)
    {
        self.delegate = self;
        _intent = intent;
        _assetsLibrary = [MediaAssetsLibrary libraryForAssetType:[MediaAssetsController assetTypeForIntent:intent]];
        
        __weak MediaAssetsController *weakSelf = self;
        _selectionContext = [[MediaSelectionContext alloc] init];
        [_selectionContext setItemSourceUpdatedSignal:[_assetsLibrary libraryChanged]];
        _selectionContext.updatedItemsSignal = ^SSignal *(NSArray *items)
        {
            __strong MediaAssetsController *strongSelf = weakSelf;
            if (strongSelf == nil)
                return nil;
            
            return [strongSelf->_assetsLibrary updatedAssetsForAssets:items];
        };
        
        _selectionChangedDisposable = [[SMetaDisposable alloc] init];
        [_selectionChangedDisposable setDisposable:[[_selectionContext selectionChangedSignal] startWithNext:^(__unused id next)
                                                    {
                                                        __strong MediaAssetsController *strongSelf = weakSelf;
                                                        if (strongSelf == nil)
                                                            return;
                                                        
                                                        [strongSelf->_toolbarView setSelectedCount:strongSelf->_selectionContext.count animated:true];
                                                        [strongSelf->_toolbarView setRightButtonEnabled:strongSelf->_selectionContext.count > 0 animated:false];
                                                    }]];
        
        if (intent == MediaAssetsControllerIntentSendMedia || intent == MediaAssetsControllerIntentSetProfilePhoto)
            _editingContext = [[MediaEditingContext alloc] init];
        else if (intent == MediaAssetsControllerIntentSendFile)
            _editingContext = [MediaEditingContext contextForCaptionsOnly];
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
    [_selectionChangedDisposable dispose];
}

- (void)loadView
{
    [super loadView];
    
    _toolbarView = [[MediaPickerToolbarView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - MediaPickerToolbarHeight, self.view.frame.size.width, MediaPickerToolbarHeight)];
    _toolbarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    if (_intent != MediaAssetsControllerIntentSendFile && _intent != MediaAssetsControllerIntentSendMedia)
        [_toolbarView setRightButtonHidden:true];
    [self.view addSubview:_toolbarView];
}

- (void)viewDidLoad
{
    __weak MediaAssetsController *weakSelf = self;
    _toolbarView.leftPressed = ^
    {
        __strong MediaAssetsController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        [strongSelf dismiss];
    };
    
    _toolbarView.rightPressed = ^
    {
        __strong MediaAssetsController *strongSelf = weakSelf;
        if (strongSelf != nil)
            [strongSelf completeWithCurrentItem:nil];
    };
}

- (void)dismiss
{
    if (self.dismissalBlock != nil)
        self.dismissalBlock();
    
    [_editingContext clearPaintingData];
}

#pragma mark -

- (void)completeWithAvatarImage:(UIImage *)image
{
    if (self.avatarCompletionBlock != nil)
        self.avatarCompletionBlock(image);
}

- (void)completeWithCurrentItem:(MediaAsset *)currentItem
{
   NSArray *signals = [self resultSignalsWithCurrentItem:currentItem];
    if (self.completionBlock != nil)
        self.completionBlock(signals);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_intent == MediaAssetsControllerIntentSendFile && self.shouldShowFileTipIfNeeded && iosMajorVersion() >= 7)
    {
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"didShowDocumentPickerTip_v2"] boolValue])
        {
            [[NSUserDefaults standardUserDefaults] setObject:@true forKey:@"didShowDocumentPickerTip_v2"];
            
            MediaAssetsTipView *tipView = [[MediaAssetsTipView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, self.view.bounds.size.height)];
            tipView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.navigationController.view addSubview:tipView];
        }
    }
}

- (NSArray *)resultSignalsWithCurrentItem:( MediaAsset *)currentItem
{
    bool storeAssets = (_editingContext != nil) && self.shouldStoreAssets;
    return [ MediaAssetsController resultSignalsForSelectionContext:_selectionContext editingContext:_editingContext intent:_intent currentItem:currentItem storeAssets:storeAssets useMediaCache:self.localMediaCacheEnabled];
}

- (NSArray *)resultSignalsWithCurrentItem:(MediaAsset *)currentItem descriptionGenerator:(id (^)(id, NSString *, NSString *))descriptionGenerator
{
    bool storeAssets = (_editingContext != nil) && self.shouldStoreAssets;
    return [MediaAssetsController resultSignalsForSelectionContext:_selectionContext editingContext:_editingContext intent:_intent currentItem:currentItem storeAssets:storeAssets useMediaCache:self.localMediaCacheEnabled descriptionGenerator:descriptionGenerator];
}

+ (NSArray *)resultSignalsForSelectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext intent:(MediaAssetsControllerIntent)intent currentItem:(MediaAsset *)currentItem storeAssets:(bool)storeAssets useMediaCache:(bool)__unused useMediaCache descriptionGenerator:(id (^)(id, NSString *, NSString *))descriptionGenerator
{
    NSMutableArray *signals = [[NSMutableArray alloc] init];
    NSMutableArray *selectedItems = [selectionContext.selectedItems mutableCopy];
    if (selectedItems.count == 0 && currentItem != nil)
        [selectedItems addObject:currentItem];
    
        NSMutableArray *fullSizeSignals = [[NSMutableArray alloc] init];
        for (MediaAsset *asset in selectedItems)
            [fullSizeSignals addObject:[editingContext fullSizeImageUrlForItem:asset]];
        
        SSignal *combinedSignal = nil;
        SQueue *queue = [SQueue concurrentDefaultQueue];
        
        for (SSignal *signal in fullSizeSignals)
        {
            if (combinedSignal == nil)
                combinedSignal = [signal startOn:queue];
            else
                combinedSignal = [[combinedSignal then:signal] startOn:queue];
        }
        
        [[[[combinedSignal deliverOn:[SQueue mainQueue]] filter:^bool(id result)
           {
               return [result isKindOfClass:[NSURL class]];
           }] mapToSignal:^SSignal *(NSURL *url)
          {
              return [[MediaAssetsLibrary sharedLibrary] saveAssetWithImageAtUrl:url];
          }] startWithNext:nil];
    
    static dispatch_once_t onceToken;
    static UIImage *blankImage;
    dispatch_once(&onceToken, ^
                  {
                      UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), true, 0.0f);
                      
                      CGContextRef context = UIGraphicsGetCurrentContext();
                      CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
                      CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
                      
                      blankImage = UIGraphicsGetImageFromCurrentImageContext();
                      UIGraphicsEndImageContext();
                  });
    
    CGSize fallbackThumbnailImageSize = CGSizeMake(256, 256);
    SSignal *(^inlineThumbnailSignal)(MediaAsset *) = ^SSignal *(MediaAsset *asset)
    {
        return [[MediaAssetImageSignals imageForAsset:asset imageType:MediaAssetImageTypeAspectRatioThumbnail size:fallbackThumbnailImageSize allowNetworkAccess:false] catch:^SSignal *(id error)
                {
                    if ([error respondsToSelector:@selector(boolValue)] && [error boolValue]) {
                        return [MediaAssetImageSignals imageForAsset:asset imageType:MediaAssetImageTypeAspectRatioThumbnail size:fallbackThumbnailImageSize allowNetworkAccess:true];
                    } else {
                        return [SSignal single:blankImage];
                    }
                }];
    };
    
    for (MediaAsset *asset in selectedItems)
    {
        switch (asset.type)
        {
            case MediaAssetPhotoType:
            {
                if (intent == MediaAssetsControllerIntentSendFile)
                {
                    NSString *caption = [editingContext captionForItem:asset];
                    
                    [signals addObject:[[[MediaAssetImageSignals imageDataForAsset:asset allowNetworkAccess:false] map:^NSDictionary *(MediaAssetImageData *assetData)
                                         {
                                             NSString *tempFileName = TGTemporaryFileName(nil);
                                             [assetData.imageData writeToURL:[NSURL fileURLWithPath:tempFileName] atomically:true];
                                             
                                             NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                             dict[@"type"] = @"file";
                                             dict[@"tempFileUrl"] = [NSURL fileURLWithPath:tempFileName];
                                             dict[@"fileName"] = assetData.fileName;
                                             dict[@"mimeType"] = MimeTypeForFileUTI(assetData.fileUTI);
                                             
                                             id generatedItem = descriptionGenerator(dict, caption, nil);
                                             return generatedItem;
                                         }] catch:^SSignal *(id error)
                                        {
                                            if (![error isKindOfClass:[NSNumber class]])
                                                return [SSignal complete];
                                            
                                            return [inlineThumbnailSignal(asset) map:^id(UIImage *image)
                                                    {
                                                        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                                        dict[@"type"] = @"cloudPhoto";
                                                        dict[@"document"] = @true;
                                                        dict[@"asset"] = asset;
                                                        dict[@"previewImage"] = image;
                                                        dict[@"mimeType"] = MimeTypeForFileUTI(asset.uniformTypeIdentifier);
                                                        dict[@"fileName"] = asset.fileName;
                                                        
                                                        id generatedItem = descriptionGenerator(dict, nil, nil);
                                                        return generatedItem;
                                                    }];
                                        }]];
                }
                else
                {
                    NSString *caption = [editingContext captionForItem:asset];
                    id<MediaEditAdjustments> adjustments = [editingContext adjustmentsForItem:asset];
                    
                    SSignal *inlineSignal = [inlineThumbnailSignal(asset) map:^id(UIImage *image)
                                             {
                                                 NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                                 dict[@"type"] = @"cloudPhoto";
                                                 dict[@"document"] = @false;
                                                 dict[@"asset"] = asset;
                                                 dict[@"previewImage"] = image;
                                                 
                                                 id generatedItem = descriptionGenerator(dict, caption, nil);
                                                 return generatedItem;
                                             }];
                    
                    SSignal *assetSignal = inlineSignal;
                    SSignal *imageSignal = assetSignal;
                    if (editingContext != nil)
                    {
                        imageSignal = [[[[[editingContext imageSignalForItem:asset withUpdates:true] filter:^bool(id result)
                                          {
                                              return result == nil || ([result isKindOfClass:[UIImage class]] && !((UIImage *)result).degraded);
                                          }] take:1] mapToSignal:^SSignal *(id result)
                                        {
                                            if (result == nil)
                                            {
                                                return [SSignal fail:nil];
                                            }
                                            else if ([result isKindOfClass:[UIImage class]])
                                            {
                                                UIImage *image = (UIImage *)result;
                                                image.edited = true;
                                                return [SSignal single:image];
                                            }
                                            
                                            return [SSignal complete];
                                        }] onCompletion:^
                                       {
                                           __strong MediaEditingContext *strongEditingContext = editingContext;
                                           [strongEditingContext description];
                                       }];
                    }
                    
                    [signals addObject:[[imageSignal map:^NSDictionary *(UIImage *image)
                                         {
                                             NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                             dict[@"type"] = @"editedPhoto";
                                             dict[@"image"] = image;
                                             
                                             if (adjustments.paintingData.stickers.count > 0)
                                                 dict[@"stickers"] = adjustments.paintingData.stickers;
                                             
                                             id generatedItem = descriptionGenerator(dict, caption, nil);
                                             return generatedItem;
                                         }] catch:^SSignal *(__unused id error)
                                        {
                                            return inlineSignal;
                                        }]];
                }
            }
                break;
                
            case MediaAssetVideoType:
            {
                if (intent == MediaAssetsControllerIntentSendFile)
                {
                    NSString *caption = [editingContext captionForItem:asset];
                    id<MediaEditAdjustments> adjustments = [editingContext adjustmentsForItem:asset];
                    
                    [signals addObject:[inlineThumbnailSignal(asset) map:^id(UIImage *image)
                                        {
                                            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                            dict[@"type"] = @"video";
                                            dict[@"document"] = @true;
                                            dict[@"asset"] = asset;
                                            dict[@"previewImage"] = image;
                                            dict[@"fileName"] = asset.fileName;
                                            
                                            if (adjustments.paintingData.stickers.count > 0)
                                                dict[@"stickers"] = adjustments.paintingData.stickers;
                                            
                                            id generatedItem = descriptionGenerator(dict, caption, nil);
                                            return generatedItem;
                                        }]];
                }
                else
                {
                    VideoEditAdjustments *adjustments = nil;
                    NSString *caption = nil;
                    
                    if (editingContext != nil)
                    {
                        caption = [editingContext captionForItem:asset];
                        adjustments = (VideoEditAdjustments *)[editingContext adjustmentsForItem:asset];
                    }
                    
                    UIImage *(^cropVideoThumbnail)(UIImage *, CGSize, CGSize, bool) = ^UIImage *(UIImage *image, CGSize targetSize, CGSize sourceSize, bool resize)
                    {
                        if ([adjustments cropAppliedForAvatar:false] || adjustments.hasPainting)
                        {
                            CGRect scaledCropRect = CGRectMake(adjustments.cropRect.origin.x * image.size.width / adjustments.originalSize.width, adjustments.cropRect.origin.y * image.size.height / adjustments.originalSize.height, adjustments.cropRect.size.width * image.size.width / adjustments.originalSize.width, adjustments.cropRect.size.height * image.size.height / adjustments.originalSize.height);
                            return PhotoEditorCrop(image, adjustments.paintingData.image, adjustments.cropOrientation, 0, scaledCropRect, adjustments.cropMirrored, targetSize, sourceSize, resize);
                        }
                        
                        return image;
                    };
                    
                    SSignal *trimmedVideoThumbnailSignal = [[MediaAssetImageSignals avAssetForVideoAsset:asset allowNetworkAccess:false] mapToSignal:^SSignal *(AVAsset *avAsset)
                                                            {
                                                                CGSize imageSize = TGFillSize(asset.dimensions, CGSizeMake(384, 384));
                                                                return [[MediaAssetImageSignals videoThumbnailForAVAsset:avAsset size:imageSize timestamp:CMTimeMakeWithSeconds(adjustments.trimStartValue, NSEC_PER_SEC)] map:^UIImage *(UIImage *image)
                                                                        {
                                                                            return cropVideoThumbnail(image, ScaleToFill(asset.dimensions, CGSizeMake(256, 256)), asset.dimensions, true);
                                                                        }];
                                                            }];
                    
                    SSignal *videoThumbnailSignal = [inlineThumbnailSignal(asset) map:^UIImage *(UIImage *image)
                                                     {
                                                         return cropVideoThumbnail(image, image.size, image.size, false);
                                                     }];
                    
                    SSignal *thumbnailSignal = adjustments.trimStartValue > FLT_EPSILON ? trimmedVideoThumbnailSignal : videoThumbnailSignal;
                    
                    [signals addObject:[thumbnailSignal map:^id(UIImage *image)
                                        {
                                            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                            dict[@"type"] = @"video";
                                            dict[@"document"] = @false;
                                            dict[@"asset"] = asset;
                                            dict[@"previewImage"] = image;
                                            dict[@"adjustments"] = adjustments;
                                            
                                            if (adjustments.paintingData.stickers.count > 0)
                                                dict[@"stickers"] = adjustments.paintingData.stickers;
                                            
                                            id generatedItem = descriptionGenerator(dict, caption, nil);
                                            return generatedItem;
                                        }]];
                }
            }
                break;
                
            case MediaAssetGifType:
            {
                NSString *caption = editingContext ? [editingContext captionForItem:asset] : nil;
                
                [signals addObject:[[[MediaAssetImageSignals imageDataForAsset:asset allowNetworkAccess:false] mapToSignal:^SSignal *(MediaAssetImageData *assetData)
                                     {
                                         NSString *tempFileName = TGTemporaryFileName(nil);
                                         NSData *data = assetData.imageData;
                                         
                                         const char *gif87Header = "GIF87";
                                         const char *gif89Header = "GIF89";
                                         if (data.length >= 5 && (!memcmp(data.bytes, gif87Header, 5) || !memcmp(data.bytes, gif89Header, 5)))
                                         {
                                             return [[GifConverter convertGifToMp4:data] map:^id(NSString *filePath)
                                                     {
                                                         NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                                         dict[@"type"] = @"file";
                                                         dict[@"tempFileUrl"] = [NSURL fileURLWithPath:filePath];
                                                         dict[@"fileName"] = @"animation.mp4";
                                                         dict[@"mimeType"] = @"video/mp4";
                                                         dict[@"isAnimation"] = @true;
                                                         
                                                         id generatedItem = descriptionGenerator(dict, caption, nil);
                                                         return generatedItem;
                                                     }];
                                         }
                                         else
                                         {
                                             [data writeToURL:[NSURL fileURLWithPath:tempFileName] atomically:true];
                                             
                                             NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                             dict[@"type"] = @"file";
                                             dict[@"tempFileUrl"] = [NSURL fileURLWithPath:tempFileName];
                                             dict[@"fileName"] = assetData.fileName;
                                             dict[@"mimeType"] = MimeTypeForFileUTI(assetData.fileUTI);
                                             
                                             id generatedItem = descriptionGenerator(dict, caption, nil);
                                             return [SSignal single:generatedItem];
                                         }
                                     }] catch:^SSignal *(id error)
                                    {
                                        if (![error isKindOfClass:[NSNumber class]])
                                            return [SSignal complete];
                                        
                                        return [inlineThumbnailSignal(asset) map:^id(UIImage *image)
                                                {
                                                    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                                    dict[@"type"] = @"cloudPhoto";
                                                    dict[@"document"] = @true;
                                                    dict[@"asset"] = asset;
                                                    dict[@"previewImage"] = image;
                                                    
                                                    id generatedItem = descriptionGenerator(dict, caption, nil);
                                                    return generatedItem;
                                                }];
                                    }]];
            }
                break;
                
            default:
                break;
        }
    }
    return signals;
}

#pragma mark -

- (void)navigationController:(UINavigationController *)__unused navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)__unused animated
{
    UIView *backArrow = [self _findBackArrow:self.navigationBar];
    UIView *backButton = [self _findBackButton:self.navigationBar parentView:self.navigationBar];
    
    if ([viewController isKindOfClass:[PhotoEditorController class]])
    {
        backArrow.alpha = 0.0f;
        backButton.alpha = 0.0f;
    }
    else if ([viewController isKindOfClass:[MediaAssetsPickerController class]])
    {
        backArrow.alpha = 0.0f;
        backButton.alpha = 0.0f;
    }
}

- (void)navigationController:(UINavigationController *)__unused navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)__unused animated
{
    if ([viewController isKindOfClass:[MediaAssetsPickerController class]])
    {
        
        UIView *backArrow = [self _findBackArrow:self.navigationBar];
        UIView *backButton = [self _findBackButton:self.navigationBar parentView:self.navigationBar];
        backArrow.alpha = 1.0f;
        backButton.alpha = 1.0f;
    }
}

+ (NSArray *)resultSignalsForSelectionContext:( MediaSelectionContext *)selectionContext editingContext:( MediaEditingContext *)editingContext intent:( MediaAssetsControllerIntent)intent currentItem:( MediaAsset *)currentItem storeAssets:(bool)storeAssets useMediaCache:(bool)__unused useMediaCache
{
    NSMutableArray *signals = [[NSMutableArray alloc] init];
    NSMutableArray *selectedItems = [selectionContext.selectedItems mutableCopy];
    if (selectedItems.count == 0 && currentItem != nil)
        [selectedItems addObject:currentItem];
    
    NSMutableArray *fullSizeSignals = [[NSMutableArray alloc] init];
    for ( MediaAsset *asset in selectedItems)
        [fullSizeSignals addObject:[editingContext fullSizeImageUrlForItem:asset]];
    
    SSignal *combinedSignal = nil;
    SQueue *queue = [SQueue concurrentDefaultQueue];
    
    for (SSignal *signal in fullSizeSignals)
    {
        if (combinedSignal == nil)
            combinedSignal = [signal startOn:queue];
        else
            combinedSignal = [[combinedSignal then:signal] startOn:queue];
    }
    
    [[[[combinedSignal deliverOn:[SQueue mainQueue]] filter:^bool(id result)
       {
           return [result isKindOfClass:[NSURL class]];
       }] mapToSignal:^SSignal *(NSURL *url)
      {
          return [[MediaAssetsLibrary sharedLibrary] saveAssetWithImageAtUrl:url];
      }] startWithNext:nil];
    
    
    static dispatch_once_t onceToken;
    static UIImage *blankImage;
    dispatch_once(&onceToken, ^
                  {
                      UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), true, 0.0f);
                      
                      CGContextRef context = UIGraphicsGetCurrentContext();
                      CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
                      CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
                      
                      blankImage = UIGraphicsGetImageFromCurrentImageContext();
                      UIGraphicsEndImageContext();
                  });
    
    CGSize fallbackThumbnailImageSize = CGSizeMake(256, 256);
    SSignal *(^inlineThumbnailSignal)(MediaAsset *) = ^SSignal *(MediaAsset *asset)
    {
        return [[MediaAssetImageSignals imageForAsset:asset imageType:MediaAssetImageTypeAspectRatioThumbnail size:fallbackThumbnailImageSize allowNetworkAccess:false] catch:^SSignal *(id error)
                {
                    if ([error respondsToSelector:@selector(boolValue)] && [error boolValue]) {
                        return [MediaAssetImageSignals imageForAsset:asset imageType:MediaAssetImageTypeAspectRatioThumbnail size:fallbackThumbnailImageSize allowNetworkAccess:true];
                    } else {
                        return [SSignal single:blankImage];
                    }
                }];
    };
    
    NSArray *items = selectedItems.copy;
    for (MediaAsset *asset in items)
    {
        switch (asset.type)
        {
            case MediaAssetPhotoType:
            {
                if (intent == MediaAssetsControllerIntentSendFile)
                {
                    NSString *caption = [editingContext captionForItem:asset];
                    
                    [signals addObject:[[[MediaAssetImageSignals imageDataForAsset:asset allowNetworkAccess:false] map:^NSDictionary *(MediaAssetImageData *assetData)
                                         {
                                             NSString *tempFileName = TGTemporaryFileName(nil);
                                             [assetData.imageData writeToURL:[NSURL fileURLWithPath:tempFileName] atomically:true];
                                             
                                             NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                             dict[@"type"] = @"file";
                                             dict[@"tempFileUrl"] = [NSURL fileURLWithPath:tempFileName];
                                             dict[@"fileName"] = assetData.fileName;
                                             dict[@"mimeType"] = MimeTypeForFileUTI(assetData.fileUTI);
                                             
                                             return [ItemDescriptor descriptionForItem:dict caption:caption hash:nil];
                                         }] catch:^SSignal *(id error)
                                        {
                                            if (![error isKindOfClass:[NSNumber class]])
                                                return [SSignal complete];
                                            
                                            return [inlineThumbnailSignal(asset) map:^id(UIImage *image)
                                                    {
                                                        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                                        dict[@"type"] = @"cloudPhoto";
                                                        dict[@"document"] = @true;
                                                        dict[@"asset"] = asset;
                                                        dict[@"previewImage"] = image;
                                                        dict[@"mimeType"] = MimeTypeForFileUTI(asset.uniformTypeIdentifier);
                                                        dict[@"fileName"] = asset.fileName;
                                                        
                                                        return [ItemDescriptor descriptionForItem:dict caption:nil hash:nil];;
                                                    }];
                                        }]];
                }
                else
                {
                    NSString *caption = [editingContext captionForItem:asset];
                    id<MediaEditAdjustments> adjustments = [editingContext adjustmentsForItem:asset];
                    
                    SSignal *inlineSignal = [inlineThumbnailSignal(asset) map:^id(UIImage *image)
                                             {
                                                 NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                                 dict[@"type"] = @"cloudPhoto";
                                                 dict[@"document"] = @false;
                                                 dict[@"asset"] = asset;
                                                 dict[@"previewImage"] = image;
                                                 
                                                 return [ItemDescriptor descriptionForItem:dict caption:caption hash:nil];
                                             }];
                    
                    SSignal *assetSignal = inlineSignal;
                    SSignal *imageSignal = assetSignal;
                    if (editingContext != nil)
                    {
                        imageSignal = [[[[[editingContext imageSignalForItem:asset withUpdates:true] filter:^bool(id result)
                                          {
                                              return result == nil || ([result isKindOfClass:[UIImage class]] && !((UIImage *)result).degraded);
                                          }] take:1] mapToSignal:^SSignal *(id result)
                                        {
                                            if (result == nil)
                                            {
                                                return [SSignal fail:nil];
                                            }
                                            else if ([result isKindOfClass:[UIImage class]])
                                            {
                                                UIImage *image = (UIImage *)result;
                                                image.edited = true;
                                                return [SSignal single:image];
                                            }
                                            
                                            return [SSignal complete];
                                        }] onCompletion:^
                                       {
                                           __strong MediaEditingContext *strongEditingContext = editingContext;
                                           [strongEditingContext description];
                                       }];
                    }
                    
                    [signals addObject:[[imageSignal map:^NSDictionary *(UIImage *image)
                                         {
                                             NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                             dict[@"type"] = @"editedPhoto";
                                             dict[@"image"] = image;
                                             
                                             if (adjustments.paintingData.stickers.count > 0)
                                                 dict[@"stickers"] = adjustments.paintingData.stickers;
                                             return  [ItemDescriptor descriptionForItem:dict caption:caption hash:nil];
                                         }] catch:^SSignal *(__unused id error)
                                        {
                                            return inlineSignal;
                                        }]];
                }
            }
                break;
                
            case MediaAssetVideoType:
            {
                if (intent == MediaAssetsControllerIntentSendFile)
                {
                    NSString *caption = [editingContext captionForItem:asset];
                    id<MediaEditAdjustments> adjustments = [editingContext adjustmentsForItem:asset];
                    
                    [signals addObject:[inlineThumbnailSignal(asset) map:^id(UIImage *image)
                                        {
                                            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                            dict[@"type"] = @"video";
                                            dict[@"document"] = @true;
                                            dict[@"asset"] = asset;
                                            dict[@"previewImage"] = image;
                                            dict[@"fileName"] = asset.fileName;
                                            
                                            if (adjustments.paintingData.stickers.count > 0)
                                                dict[@"stickers"] = adjustments.paintingData.stickers;
                                            
                                            return  [ItemDescriptor descriptionForItem:dict caption:caption hash:nil];
                                        }]];
                }
                else
                {
                    VideoEditAdjustments *adjustments = nil;
                    NSString *caption = nil;
                    
                    if (editingContext != nil)
                    {
                        caption = [editingContext captionForItem:asset];
                        adjustments = (VideoEditAdjustments *)[editingContext adjustmentsForItem:asset];
                    }
                    
                    UIImage *(^cropVideoThumbnail)(UIImage *, CGSize, CGSize, bool) = ^UIImage *(UIImage *image, CGSize targetSize, CGSize sourceSize, bool resize)
                    {
                        if ([adjustments cropAppliedForAvatar:false] || adjustments.hasPainting)
                        {
                            CGRect scaledCropRect = CGRectMake(adjustments.cropRect.origin.x * image.size.width / adjustments.originalSize.width, adjustments.cropRect.origin.y * image.size.height / adjustments.originalSize.height, adjustments.cropRect.size.width * image.size.width / adjustments.originalSize.width, adjustments.cropRect.size.height * image.size.height / adjustments.originalSize.height);
                            return PhotoEditorCrop(image, adjustments.paintingData.image, adjustments.cropOrientation, 0, scaledCropRect, adjustments.cropMirrored, targetSize, sourceSize, resize);
                        }
                        
                        return image;
                    };
                    
                    SSignal *trimmedVideoThumbnailSignal = [[MediaAssetImageSignals avAssetForVideoAsset:asset allowNetworkAccess:false] mapToSignal:^SSignal *(AVAsset *avAsset)
                                                            {
                                                                CGSize imageSize = TGFillSize(asset.dimensions, CGSizeMake(384, 384));
                                                                return [[MediaAssetImageSignals videoThumbnailForAVAsset:avAsset size:imageSize timestamp:CMTimeMakeWithSeconds(adjustments.trimStartValue, NSEC_PER_SEC)] map:^UIImage *(UIImage *image)
                                                                        {
                                                                            return cropVideoThumbnail(image, ScaleToFill(asset.dimensions, CGSizeMake(256, 256)), asset.dimensions, true);
                                                                        }];
                                                            }];
                    
                    SSignal *videoThumbnailSignal = [inlineThumbnailSignal(asset) map:^UIImage *(UIImage *image)
                                                     {
                                                         return cropVideoThumbnail(image, image.size, image.size, false);
                                                     }];
                    
                    SSignal *thumbnailSignal = adjustments.trimStartValue > FLT_EPSILON ? trimmedVideoThumbnailSignal : videoThumbnailSignal;
                    
                    [signals addObject:[thumbnailSignal map:^id(UIImage *image)
                                        {
                                            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                            dict[@"type"] = @"video";
                                            dict[@"document"] = @false;
                                            dict[@"asset"] = asset;
                                            dict[@"previewImage"] = image;
                                            dict[@"adjustments"] = adjustments;
                                            
                                            if (adjustments.paintingData.stickers.count > 0)
                                                dict[@"stickers"] = adjustments.paintingData.stickers;
                                            
                                            return [ItemDescriptor descriptionForItem:dict caption:caption hash:nil];
                                        }]];
                }
            }
                break;
                
            case MediaAssetGifType:
            {
                NSString *caption = editingContext ? [editingContext captionForItem:asset] : nil;
                
                [signals addObject:[[[MediaAssetImageSignals imageDataForAsset:asset allowNetworkAccess:false] mapToSignal:^SSignal *(MediaAssetImageData *assetData)
                                     {
                                         NSString *tempFileName = TGTemporaryFileName(nil);
                                         NSData *data = assetData.imageData;
                                         
                                         const char *gif87Header = "GIF87";
                                         const char *gif89Header = "GIF89";
                                         if (data.length >= 5 && (!memcmp(data.bytes, gif87Header, 5) || !memcmp(data.bytes, gif89Header, 5)))
                                         {
                                             return [[GifConverter convertGifToMp4:data] map:^id(NSString *filePath)
                                                     {
                                                         NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                                         dict[@"type"] = @"file";
                                                         dict[@"tempFileUrl"] = [NSURL fileURLWithPath:filePath];
                                                         dict[@"fileName"] = @"animation.mp4";
                                                         dict[@"mimeType"] = @"video/mp4";
                                                         dict[@"isAnimation"] = @true;
                                                         
                                                         return  [ItemDescriptor descriptionForItem:dict caption:nil hash:nil];
                                                     }];
                                         }
                                         else
                                         {
                                             [data writeToURL:[NSURL fileURLWithPath:tempFileName] atomically:true];
                                             
                                             NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                             dict[@"type"] = @"file";
                                             dict[@"tempFileUrl"] = [NSURL fileURLWithPath:tempFileName];
                                             dict[@"fileName"] = assetData.fileName;
                                             dict[@"mimeType"] = MimeTypeForFileUTI(assetData.fileUTI);
                                             
                                             id generatedItem = [ItemDescriptor descriptionForItem:dict caption:caption hash:nil];
                                             return [SSignal single:generatedItem];
                                         }
                                     }] catch:^SSignal *(id error)
                                    {
                                        if (![error isKindOfClass:[NSNumber class]])
                                            return [SSignal complete];
                                        
                                        return [inlineThumbnailSignal(asset) map:^id(UIImage *image)
                                                {
                                                    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                                                    dict[@"type"] = @"cloudPhoto";
                                                    dict[@"document"] = @true;
                                                    dict[@"asset"] = asset;
                                                    dict[@"previewImage"] = image;
                                                    
                                                    return [ItemDescriptor descriptionForItem:dict caption:caption hash:nil];
                                                }];
                                    }]];
            }
                break;
                
            default:
                break;
        }
    }
    return signals;
}

- (UIView *)_findBackArrow:(UIView *)view
{
    Class backArrowClass = NSClassFromString(TGEncodeText(@"`VJObwjhbujpoCbsCbdlJoejdbupsWjfx", -1));
    
    if ([view isKindOfClass:backArrowClass])
        return view;
    
    for (UIView *subview in view.subviews)
    {
        UIView *result = [self _findBackArrow:subview];
        if (result != nil)
            return result;
    }
    
    return nil;
}

- (UIView *)_findBackButton:(UIView *)view parentView:(UIView *)parentView
{
    Class backButtonClass = NSClassFromString(TGEncodeText(@"VJObwjhbujpoJufnCvuupoWjfx", -1));
    
    if ([view isKindOfClass:backButtonClass])
    {
        if (view.center.x < parentView.frame.size.width / 2.0f)
            return view;
    }
    
    for (UIView *subview in view.subviews)
    {
        UIView *result = [self _findBackButton:subview parentView:parentView];
        if (result != nil)
            return result;
    }
    
    return nil;
}

#pragma mark -

+ (MediaAssetType)assetTypeForIntent:(MediaAssetsControllerIntent)intent
{
    MediaAssetType assetType = MediaAssetAnyType;
    
    switch (intent)
    {
        case MediaAssetsControllerIntentSetProfilePhoto:
        case MediaAssetsControllerIntentSetCustomWallpaper:
            assetType = MediaAssetPhotoType;
            break;
            
        case MediaAssetsControllerIntentSendMedia:
            assetType = MediaAssetAnyType;
            break;
            
        default:
            break;
    }
    
    return assetType;
}

@end
