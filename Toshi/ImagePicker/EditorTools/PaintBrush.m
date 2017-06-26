#import "PaintBrush.h"

#import "ImageUtils.h"

const CGSize PaintBrushTextureSize = { 256.0f, 256.0f };
const CGSize PaintBrushPreviewTextureSize = { 64.0f, 64.0f };

@interface PaintBrush ()
{
    NSInteger _uuid;
}
@end

@implementation PaintBrush

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        arc4random_buf(&_uuid, sizeof(NSInteger));
    }
    return self;
}

- (void)dealloc
{
    if (_previewStampRef != NULL)
        CGImageRelease(_previewStampRef);
}

- (BOOL)isEqual:(id)object
{
    if (object == self)
        return true;
    
    if (!object || ![object isKindOfClass:[self class]])
        return false;
    
    PaintBrush *brush = (PaintBrush *)object;
    return (_uuid == brush->_uuid);
}

- (CGFloat)spacing
{
    return 1.0f;
}

- (CGFloat)alpha
{
    return 1.0f;
}

- (CGFloat)angle
{
    return 0.0f;
}

- (CGFloat)scale
{
    return 1.0f;
}

- (bool)lightSaber
{
    return false;
}

- (CGImageRef)stampRef
{
    return NULL;
}

- (CGImageRef)previewStampRef
{
    if (_previewStampRef == NULL)
    {
        UIImage *image = ScaleImageToPixelSize([UIImage imageWithCGImage:self.stampRef], PaintBrushPreviewTextureSize);
        _previewStampRef = image.CGImage;
        CGImageRetain(_previewStampRef);
    }
    
    return _previewStampRef;
}

@end
