#import "ModernGalleryImageItem.h"

#import "ModernGalleryImageItemView.h"

#import "ImageView.h"
#import "Common.h"

@implementation ModernGalleryImageItem

- (instancetype)initWithUri:(NSString *)uri imageSize:(CGSize)imageSize
{
    self = [super init];
    if (self != nil)
    {
        _uri = uri;
        _imageSize = imageSize;
    }
    return self;
}

- (instancetype)initWithLoader:(dispatch_block_t (^)(ImageView *, bool))loader imageSize:(CGSize)imageSize
{
    self = [super init];
    if (self != nil)
    {
        _loader = [loader copy];
        _imageSize = imageSize;
    }
    return self;
}

- (instancetype)initWithSignal:(SSignal *)signal imageSize:(CGSize)imageSize
{
    self = [super init];
    if (self != nil)
    {
        _loader = [^(ImageView *imageView, bool synchronous)
        {
            [imageView setSignal:(synchronous ? [signal wait:1.0] : signal)];
            return nil;
        } copy];
        _imageSize = imageSize;
    }
    return self;
}

- (Class)viewClass
{
    return [ModernGalleryImageItemView class];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[ModernGalleryImageItem class]])
    {
        if (!StringCompare(_uri, ((ModernGalleryImageItem *)object).uri))
            return false;
        
        if (!CGSizeEqualToSize(_imageSize, ((ModernGalleryImageItem *)object).imageSize))
            return false;
        
        return true;
    }
    
    return false;
}

@end
