#import "MediaPickerLayoutMetrics.h"

#import "ImageUtils.h"
#import "PhotoEditorUtils.h"

@interface MediaPickerLayoutMetrics ()
{
    NSValue *_imageSizeValue;
    bool _isPanorama;
}
@end

@implementation MediaPickerLayoutMetrics

- (CGSize)imageSize
{
    if (_imageSizeValue == nil)
    {
        CGFloat scale = MIN(2.0f, TGScreenScaling());
        CGSize imageSize = CGSizeMake(ceil(self.normalItemSize.width) * scale, ceil(self.normalItemSize.height) * scale);
        CGFloat maxSide = MAX(imageSize.width, imageSize.height);
        _imageSizeValue = [NSValue valueWithCGSize:CGSizeMake(maxSide, maxSide)];
    }
    
    return _imageSizeValue.CGSizeValue;
}

- (CGSize)itemSizeForCollectionViewWidth:(CGFloat)collectionViewWidth
{
    bool isWidescreen = (collectionViewWidth >= self.widescreenWidth - FLT_EPSILON);
    CGSize size = isWidescreen ? self.wideItemSize : self.normalItemSize;
    
    if (_isPanorama)
    {
        size.width = collectionViewWidth - (isWidescreen ? self.wideEdgeInsets.left + self.wideEdgeInsets.right : self.normalEdgeInsets.left + self.normalEdgeInsets.right);
    }
    
    return size;
}

+ (MediaPickerLayoutMetrics *)defaultLayoutMetrics
{
    MediaPickerLayoutMetrics *metrics = [[MediaPickerLayoutMetrics alloc] init];
    
    CGSize screenSize = TGScreenSize();
    CGFloat widescreenWidth = MAX(screenSize.width, screenSize.height);

    metrics->_widescreenWidth = widescreenWidth;
    
    CGSize itemSize = PhotoThumbnailSizeForCurrentScreen();
    if ([UIScreen mainScreen].scale >= 2.0f - FLT_EPSILON)
    {
        if (widescreenWidth >= 736.0f - FLT_EPSILON)
        {
            metrics->_normalItemSize = itemSize;
            metrics->_wideItemSize = itemSize;
            metrics->_normalEdgeInsets = UIEdgeInsetsMake(4.0f, 0.0f, 2.0f, 0.0f);
            metrics->_wideEdgeInsets = UIEdgeInsetsMake(4.0f, 2.0f, 1.0f, 2.0f);
            metrics->_normalLineSpacing = 1.0f;
            metrics->_wideLineSpacing = 2.0f;
        }
        else if (widescreenWidth >= 667.0f - FLT_EPSILON)
        {
            metrics->_normalItemSize = itemSize;
            metrics->_wideItemSize = CGSizeMake(floor(itemSize.width), floor(itemSize.height));
            metrics->_normalEdgeInsets = UIEdgeInsetsMake(4.0f, 0.0f, 2.0f, 0.0f);
            metrics->_wideEdgeInsets = UIEdgeInsetsMake(4.0f, 2.0f, 1.0f, 2.0f);
            metrics->_normalLineSpacing = 1.0f;
            metrics->_wideLineSpacing = 2.0f;
        }
        else
        {
            metrics->_normalItemSize = itemSize;
            metrics->_wideItemSize = CGSizeMake(floor(itemSize.width), floor(itemSize.height));
            metrics->_normalEdgeInsets = UIEdgeInsetsMake(4.0f, 0.0f, 2.0f, 0.0f);
            metrics->_wideEdgeInsets = UIEdgeInsetsMake(4.0f, 1.0f, 1.0f, 1.0f);
            metrics->_normalLineSpacing = 2.0f;
            metrics->_wideLineSpacing = 3.0f;
        }
    }
    else
    {
        metrics->_normalItemSize = itemSize;
        metrics->_wideItemSize = CGSizeMake(floor(itemSize.width), floor(itemSize.height));
        metrics->_normalEdgeInsets = UIEdgeInsetsMake(4.0f, 0.0f, 2.0f, 0.0f);
        metrics->_wideEdgeInsets = UIEdgeInsetsMake(4.0f, 1.0f, 1.0f, 1.0f);
        metrics->_normalLineSpacing = 2.0f;
        metrics->_wideLineSpacing = 2.0f;
    }

    return metrics;
}

+ (MediaPickerLayoutMetrics *)panoramaLayoutMetrics
{
    MediaPickerLayoutMetrics *metrics = [self defaultLayoutMetrics];
    metrics->_isPanorama = true;
    
    metrics->_normalLineSpacing = 10.0f;
    metrics->_wideLineSpacing = 10.0f;
    metrics->_normalEdgeInsets = UIEdgeInsetsMake(metrics->_normalEdgeInsets.top, 0, metrics->_normalEdgeInsets.bottom, 0);
    metrics->_wideEdgeInsets = UIEdgeInsetsMake(metrics->_wideEdgeInsets.top, 0, metrics->_wideEdgeInsets.bottom, 0);
    
    return metrics;
}

@end
