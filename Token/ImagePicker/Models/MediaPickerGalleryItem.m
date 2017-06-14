#import "MediaPickerGalleryItem.h"
#import "ModernGalleryItemView.h"
#import "Common.h"

@implementation MediaPickerGalleryItem

- (instancetype)initWithAsset:(MediaAsset *)asset
{    
    self = [super init];
    if (self != nil)
    {
        _asset = asset;
    }
    return self;
}

- (Class)viewClass
{
    return [ModernGalleryItemView class];
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[MediaPickerGalleryItem class]] && TGObjectCompare(_asset, ((MediaPickerGalleryItem *)object)->_asset);
}

@end
