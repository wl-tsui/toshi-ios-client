#import "AVURLAsset+MediaItem.h"
#import "MediaAssetImageSignals.h"

#import "PhotoEditorUtils.h"

@implementation AVURLAsset (MediaItem)

- (NSString *)uniqueIdentifier
{
    return self.URL.absoluteString;
}

- (CGSize)originalSize
{
    AVAssetTrack *track = self.tracks.firstObject;
    return CGRectApplyAffineTransform((CGRect){ CGPointZero, track.naturalSize }, track.preferredTransform).size;
}

- (SSignal *)thumbnailImageSignal
{
    CGFloat thumbnailImageSide = PhotoThumbnailSizeForCurrentScreen().width;
    CGSize size = ScaleToSize(self.originalSize, CGSizeMake(thumbnailImageSide, thumbnailImageSide));
    
    return [MediaAssetImageSignals videoThumbnailForAVAsset:self size:size timestamp:kCMTimeZero];
}

- (SSignal *)screenImageSignal:(NSTimeInterval)__unused position
{
    return nil;
}

- (SSignal *)originalImageSignal:(NSTimeInterval)__unused position
{
    return nil;
}

@end
