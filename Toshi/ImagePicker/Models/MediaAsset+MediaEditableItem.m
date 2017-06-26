#import "MediaAsset+MediaEditableItem.h"
#import "MediaAssetImageSignals.h"

#import "ImageUtils.h"
#import "PhotoEditorUtils.h"

@implementation MediaAsset (MediaEditableItem)

- (NSString *)uniqueIdentifier
{
    return self.identifier;
}

- (CGSize)originalSize
{
    if (![MediaAssetImageSignals usesPhotoFramework])
        return TGFitSize(self.dimensions, MediaAssetImageLegacySizeLimit);
    
    return self.dimensions;
}

- (SSignal *)thumbnailImageSignal
{
    CGFloat scale = MIN(2.0f, TGScreenScaling());
    CGFloat thumbnailImageSide = PhotoThumbnailSizeForCurrentScreen().width * scale;
    
    return [MediaAssetImageSignals imageForAsset:self imageType:MediaAssetImageTypeAspectRatioThumbnail size:CGSizeMake(thumbnailImageSide, thumbnailImageSide)];
}

- (SSignal *)screenImageSignal:(NSTimeInterval)__unused position
{
    return [MediaAssetImageSignals imageForAsset:self imageType:MediaAssetImageTypeScreen size:PhotoEditorScreenImageMaxSize()];
}

- (SSignal *)originalImageSignal:(NSTimeInterval)position
{
    if (self.isVideo)
        return [MediaAssetImageSignals videoThumbnailForAsset:self size:self.dimensions timestamp:CMTimeMakeWithSeconds(position, NSEC_PER_SEC)];
    
    return [MediaAssetImageSignals imageForAsset:self imageType:MediaAssetImageTypeFullSize size:CGSizeZero];
}

@end
