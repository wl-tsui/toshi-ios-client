#import "UIImage+MediaEditableItem.h"

#import <objc/runtime.h>
#import "ImageUtils.h"
#import "PhotoEditorUtils.h"

@implementation UIImage (MediaEditableItem)

- (NSString *)uniqueIdentifier
{
    NSString *cachedIdentifier = objc_getAssociatedObject(self, @selector(uniqueIdentifier));
    if (cachedIdentifier == nil)
    {
        cachedIdentifier = [NSString stringWithFormat:@"%ld", lrand48()];
        objc_setAssociatedObject(self, @selector(uniqueIdentifier), cachedIdentifier, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cachedIdentifier;
}

- (CGSize)originalSize
{
    return self.size;
}

- (SSignal *)thumbnailImageSignal
{
    CGFloat thumbnailImageSide = PhotoThumbnailSizeForCurrentScreen().width;
    CGSize size = ScaleToSize(self.size, CGSizeMake(thumbnailImageSide, thumbnailImageSide));
    
    return [[[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0f);
        [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [subscriber putNext:image];
        [subscriber putCompletion];
        
        return nil;
    }] startOn:[SQueue concurrentDefaultQueue]];
}

- (SSignal *)screenImageSignal:(NSTimeInterval)__unused position
{
    CGSize size = TGFitSize(self.size, PhotoEditorScreenImageMaxSize());
    
    return [[[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0f);
        [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [subscriber putNext:image];
        [subscriber putCompletion];
        
        return nil;
    }] startOn:[SQueue concurrentDefaultQueue]];
}

- (SSignal *)originalImageSignal:(NSTimeInterval)__unused position
{
    return [SSignal single:self];
}

@end
