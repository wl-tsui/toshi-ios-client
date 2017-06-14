#import "MediaPickerGalleryPhotoItem.h"
#import "MediaPickerGalleryPhotoItemView.h"

#import "MediaAsset+MediaEditableItem.h"

@implementation MediaPickerGalleryPhotoItem

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
    return PhotoEditorCaptionTab | PhotoEditorCropTab | PhotoEditorToolsTab;
}

- (Class)viewClass
{
    return [MediaPickerGalleryPhotoItemView class];
}

@end
