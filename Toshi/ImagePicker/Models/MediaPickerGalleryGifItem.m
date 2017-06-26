#import "MediaPickerGalleryGifItem.h"
#import "MediaPickerGalleryGifItemView.h"

#import "MediaAsset+MediaEditableItem.h"

@implementation MediaPickerGalleryGifItem

@synthesize selectionContext;
@synthesize editingContext;

- (NSString *)uniqueId
{
    return self.asset.identifier;
}

- (id<MediaSelectableItem>)selectableMediaItem
{
    return self.asset;
}

- (id<MediaEditableItem>)editableMediaItem
{
    return self.asset;
}

- (PhotoEditorTab)toolbarTabs
{
    return PhotoEditorNoneTab;
}

- (Class)viewClass
{
    return [MediaPickerGalleryGifItemView class];
}

@end
