#import "MediaAssetImageSignals.h"

#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "MediaAssetModernImageSignals.h"
#import "MediaAssetLegacyImageSignals.h"

#import "ImageUtils.h"
#import "PhotoEditorUtils.h"

#import "MediaAssetsLibrary.h"

const CGSize MediaAssetImageLegacySizeLimit = { 2048, 2048 };

@implementation MediaAssetImageData

@end

@implementation MediaAssetImageFileAttributes

@end


@implementation MediaAssetImageSignals

static Class MediaAssetImageSignalsClass = nil;

+ (void)load
{
    if ([MediaAssetsLibrary usesPhotoFramework])
        MediaAssetImageSignalsClass = [MediaAssetModernImageSignals class];
    else
        MediaAssetImageSignalsClass = [MediaAssetLegacyImageSignals class];
}

+ (SSignal *)imageForAsset:(MediaAsset *)asset imageType:(MediaAssetImageType)imageType size:(CGSize)size
{
    return [self imageForAsset:asset imageType:imageType size:size allowNetworkAccess:true];
}

+ (SSignal *)imageForAsset:(MediaAsset *)asset imageType:(MediaAssetImageType)imageType size:(CGSize)size allowNetworkAccess:(bool)allowNetworkAccess
{
    return [MediaAssetImageSignalsClass imageForAsset:asset imageType:imageType size:size allowNetworkAccess:allowNetworkAccess];
}

+ (SSignal *)imageDataForAsset:(MediaAsset *)asset
{
    return [self imageDataForAsset:asset allowNetworkAccess:true];
}

+ (SSignal *)imageDataForAsset:(MediaAsset *)asset allowNetworkAccess:(bool)allowNetworkAccess
{
    return [MediaAssetImageSignalsClass imageDataForAsset:asset allowNetworkAccess:allowNetworkAccess];
}

+ (SSignal *)imageMetadataForAsset:(MediaAsset *)asset
{
    return [MediaAssetImageSignalsClass imageMetadataForAsset:asset];
}

+ (SSignal *)fileAttributesForAsset:(MediaAsset *)asset
{
    return [MediaAssetImageSignalsClass fileAttributesForAsset:asset];
}

+ (void)startCachingImagesForAssets:(NSArray *)assets imageType:(MediaAssetImageType)imageType size:(CGSize)size
{
    return [MediaAssetImageSignalsClass startCachingImagesForAssets:assets imageType:imageType size:size];
}

+ (void)stopCachingImagesForAssets:(NSArray *)assets imageType:(MediaAssetImageType)imageType size:(CGSize)size
{
    return [MediaAssetImageSignalsClass stopCachingImagesForAssets:assets imageType:imageType size:size];
}

+ (void)stopCachingImagesForAllAssets
{
    [MediaAssetImageSignalsClass stopCachingImagesForAllAssets];
}

+ (SQueue *)_thumbnailQueue
{
    static dispatch_once_t onceToken;
    static SQueue *queue;
    dispatch_once(&onceToken, ^
    {
        queue = [[SQueue alloc] init];
    });
    return queue;
}

+ (SSignal *)videoThumbnailsForAsset:(MediaAsset *)asset size:(CGSize)size timestamps:(NSArray *)timestamps
{
    return [[self avAssetForVideoAsset:asset] mapToSignal:^SSignal *(AVAsset *avAsset)
    {
        return [self videoThumbnailsForAVAsset:avAsset size:size timestamps:timestamps];
    }];
}

+ (SSignal *)videoThumbnailsForAVAsset:(AVAsset *)avAsset size:(CGSize)size timestamps:(NSArray *)timestamps
{
    SSignal *signal = [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        NSMutableArray *images = [[NSMutableArray alloc] init];
        
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:avAsset];
        generator.appliesPreferredTrackTransform = true;
        generator.maximumSize = size;
        
        [generator generateCGImagesAsynchronouslyForTimes:timestamps completionHandler:^(__unused CMTime requestedTime, CGImageRef imageRef, __unused CMTime actualTime, AVAssetImageGeneratorResult result, __unused NSError *error)
        {
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            if (result == AVAssetImageGeneratorSucceeded && image != nil)
                [images addObject:image];
            
            if (images.count == timestamps.count)
            {
                [subscriber putNext:images];
                [subscriber putCompletion];
            }
        }];
        
        return [[SBlockDisposable alloc] initWithBlock:^
        {
            [generator cancelAllCGImageGeneration];
        }];
    }];
    
    return [signal startOn:[self _thumbnailQueue]];
}

+ (SSignal *)videoThumbnailForAsset:(MediaAsset *)asset size:(CGSize)size timestamp:(CMTime)timestamp
{
    return [[self avAssetForVideoAsset:asset] mapToSignal:^SSignal *(AVAsset *avAsset)
    {
        return [self videoThumbnailForAVAsset:avAsset size:size timestamp:timestamp];
    }];
}

+ (SSignal *)videoThumbnailForAVAsset:(AVAsset *)avAsset size:(CGSize)size timestamp:(CMTime)timestamp
{
    SSignal *signal = [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:avAsset];
        generator.appliesPreferredTrackTransform = true;
        generator.maximumSize = size;
        generator.requestedTimeToleranceBefore = kCMTimeZero;
        generator.requestedTimeToleranceAfter = kCMTimeZero;
        
        [generator generateCGImagesAsynchronouslyForTimes:@[ [NSValue valueWithCMTime:timestamp] ] completionHandler:^(__unused CMTime requestedTime, CGImageRef imageRef, __unused CMTime actualTime, AVAssetImageGeneratorResult result, __unused NSError *error)
        {
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            if (result == AVAssetImageGeneratorSucceeded && image != nil)
            {
                [subscriber putNext:image];
                [subscriber putCompletion];
            }
        }];
    
        return [[SBlockDisposable alloc] initWithBlock:^
        {
            [generator cancelAllCGImageGeneration];
        }];
    }];
    
    return [signal startOn:[self _thumbnailQueue]];
}

+ (SSignal *)saveUncompressedVideoForAsset:(MediaAsset *)asset toPath:(NSString *)path
{
    return [self saveUncompressedVideoForAsset:asset toPath:path allowNetworkAccess:false];
}

+ (SSignal *)saveUncompressedVideoForAsset:(MediaAsset *)asset toPath:(NSString *)path allowNetworkAccess:(bool)allowNetworkAccess
{
    if (!asset.isVideo)
        return [SSignal fail:nil];
    
    return [MediaAssetImageSignalsClass saveUncompressedVideoForAsset:asset toPath:path allowNetworkAccess:allowNetworkAccess];
}

+ (SSignal *)playerItemForVideoAsset:(MediaAsset *)asset
{
    if (asset == nil || !asset.isVideo)
        return [SSignal fail:nil];
    
    return [MediaAssetImageSignalsClass playerItemForVideoAsset:asset];
}

+ (SSignal *)avAssetForVideoAsset:(MediaAsset *)asset
{
    return [self avAssetForVideoAsset:asset allowNetworkAccess:false];
}

+ (SSignal *)avAssetForVideoAsset:(MediaAsset *)asset allowNetworkAccess:(bool)allowNetworkAccess
{
    if (asset == nil || !asset.isVideo)
        return [SSignal fail:nil];
    
    return [MediaAssetImageSignalsClass avAssetForVideoAsset:asset allowNetworkAccess:allowNetworkAccess];
}

+ (UIImageOrientation)videoOrientationOfAVAsset:(AVAsset *)avAsset
{
    NSArray *videoTracks = [avAsset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = videoTracks.firstObject;
    if (videoTrack == nil)
        return UIImageOrientationUp;
    
    CGAffineTransform transform = videoTrack.preferredTransform;
    CGFloat angle = TGRadiansToDegrees((CGFloat)atan2(transform.b, transform.a));
    
    UIImageOrientation orientation = 0;
    switch ((NSInteger)angle)
    {
        case 0:
            orientation = UIImageOrientationUp;
            break;
        case 90:
            orientation = UIImageOrientationRight;
            break;
        case 180:
            orientation = UIImageOrientationDown;
            break;
        case -90:
            orientation	= UIImageOrientationLeft;
            break;
        default:
            orientation = UIImageOrientationUp;
            break;
    }
    
    return orientation;
}

+ (bool)usesPhotoFramework
{
    return [MediaAssetImageSignalsClass usesPhotoFramework];
}

@end
