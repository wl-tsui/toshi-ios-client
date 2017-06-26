#import "ModernGalleryVideoItem.h"

#import "ModernGalleryVideoItemView.h"

#import "VideoMediaAttachment.h"
#import "Common.h"

@implementation ModernGalleryVideoItem

- (instancetype)initWithMedia:(id)media previewUri:(NSString *)previewUri
{
    self = [super init];
    if (self != nil)
    {
        _media = media;
        _previewUri = previewUri;
    }
    return self;
}

- (Class)viewClass
{
    return [ModernGalleryVideoItemView class];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[ModernGalleryVideoItem class]])
    {
        return StringCompare(_previewUri, ((ModernGalleryVideoItem *)object).previewUri) && TGObjectCompare(_media, ((ModernGalleryVideoItem *)object).media);
    }
    
    return false;
}

@end
