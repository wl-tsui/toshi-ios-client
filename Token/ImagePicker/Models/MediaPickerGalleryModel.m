#import "MediaPickerGalleryModel.h"

#import "MediaPickerGallerySelectedItemsModel.h"

#import "ModernGalleryController.h"
#import "ModernGalleryItem.h"
#import "ModernGallerySelectableItem.h"
#import "ModernGalleryEditableItem.h"
#import "ModernGalleryEditableItemView.h"
#import "ModernGalleryZoomableItemView.h"
#import "MediaPickerGalleryVideoItemView.h"

#import "ModernMediaListItem.h"
#import "ModernMediaListSelectableItem.h"

#import "PhotoEditorValues.h"
#import "Common.h"

@interface MediaPickerGalleryModel ()
{
    id<ModernGalleryEditableItem> _itemBeingEdited;
    MediaEditingContext *_editingContext;
}

@property (nonatomic, weak) PhotoEditorController *editorController;

@end

@implementation MediaPickerGalleryModel

- (instancetype)initWithItems:(NSArray *)items focusItem:(id<ModernGalleryItem>)focusItem selectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext hasCaptions:(bool)hasCaptions inhibitDocumentCaptions:(bool)inhibitDocumentCaptions hasSelectionPanel:(bool)hasSelectionPanel
{
    self = [super init];
    if (self != nil)
    {
        [self _replaceItems:items focusingOnItem:focusItem];
        
        _editingContext = editingContext;
        _selectionContext = selectionContext;
        
        __weak MediaPickerGalleryModel *weakSelf = self;
        if (selectionContext != nil)
        {
            _selectedItemsModel = [[MediaPickerGallerySelectedItemsModel alloc] initWithSelectionContext:selectionContext];
            _selectedItemsModel.selectionUpdated = ^(bool reload, bool incremental, bool add, NSInteger index)
            {
                __strong MediaPickerGalleryModel *strongSelf = weakSelf;
                if (strongSelf == nil)
                    return;

                [strongSelf.interfaceView updateSelectionInterface:[strongSelf selectionCount] counterVisible:([strongSelf selectionCount] > 0) animated:incremental];
                [strongSelf.interfaceView updateSelectedPhotosView:reload incremental:incremental add:add index:index];
            };
        }
        
        _interfaceView = [[MediaPickerGalleryInterfaceView alloc] initWithFocusItem:focusItem selectionContext:selectionContext editingContext:editingContext hasSelectionPanel:hasSelectionPanel];
        _interfaceView.hasCaptions = hasCaptions;
        _interfaceView.inhibitDocumentCaptions = inhibitDocumentCaptions;
        [_interfaceView setEditorTabPressed:^(PhotoEditorTab tab)
        {
            __strong MediaPickerGalleryModel *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            __strong ModernGalleryController *controller = strongSelf.controller;
            if ([controller.currentItem conformsToProtocol:@protocol(ModernGalleryEditableItem)])
                [strongSelf presentPhotoEditorForItem:(id<ModernGalleryEditableItem>)controller.currentItem tab:tab];
        }];
        _interfaceView.photoStripItemSelected = ^(NSInteger index)
        {
            __strong MediaPickerGalleryModel *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            [strongSelf setCurrentItemWithIndex:index];
        };
        _interfaceView.captionSet = ^(id<ModernGalleryEditableItem> item, NSString *caption)
        {
            __strong MediaPickerGalleryModel *strongSelf = weakSelf;
            if (strongSelf == nil || strongSelf.saveItemCaption == nil)
                return;
            
            __strong ModernGalleryController *controller = strongSelf.controller;
            if ([controller.currentItem conformsToProtocol:@protocol(ModernGalleryEditableItem)])
                strongSelf.saveItemCaption(((id<ModernGalleryEditableItem>)item).editableMediaItem, caption);
        };
    }
    return self;
}

- (void)setSuggestionContext:(SuggestionContext *)suggestionContext
{
    _suggestionContext = suggestionContext;
    [_interfaceView setSuggestionContext:suggestionContext];
}

- (NSInteger)selectionCount
{
    if (self.externalSelectionCount != nil)
        return self.externalSelectionCount();
    
    return _selectedItemsModel.selectedCount;
}

- (void)setCurrentItem:(id<MediaSelectableItem>)item direction:(ModernGalleryScrollAnimationDirection)direction
{
    if (![(id)item conformsToProtocol:@protocol(MediaSelectableItem)])
        return;
    
    id<MediaSelectableItem> targetSelectableItem = (id<MediaSelectableItem>)item;
    
    __block NSUInteger newIndex = NSNotFound;
    [self.items enumerateObjectsUsingBlock:^(id<ModernGalleryItem> galleryItem, NSUInteger idx, BOOL *stop)
    {
         if ([galleryItem conformsToProtocol:@protocol(ModernGallerySelectableItem)])
         {
             id<MediaSelectableItem> selectableItem = ((id<ModernGallerySelectableItem>)galleryItem).selectableMediaItem;
             
             if ([selectableItem.uniqueIdentifier isEqual:targetSelectableItem.uniqueIdentifier])
             {
                 newIndex = idx;
                 *stop = true;
             }
         }
    }];
    
    ModernGalleryController *galleryController = self.controller;
    [galleryController setCurrentItemIndex:newIndex direction:direction animated:true];
}

- (void)setCurrentItemWithIndex:(NSUInteger)index
{
    if (_selectedItemsModel == nil)
        return;
    
    ModernGalleryController *galleryController = self.controller;
    
    if (![galleryController.currentItem conformsToProtocol:@protocol(ModernGallerySelectableItem)])
        return;
    
    id<ModernGallerySelectableItem> currentGalleryItem = (id<ModernGallerySelectableItem>)galleryController.currentItem;

    __block NSUInteger currentSelectedItemIndex = NSNotFound;
    [_selectedItemsModel.items enumerateObjectsUsingBlock:^(id<MediaSelectableItem> item, NSUInteger index, BOOL *stop)
    {
        if ([item.uniqueIdentifier isEqualToString:currentGalleryItem.selectableMediaItem.uniqueIdentifier])
        {
            currentSelectedItemIndex = index;
            *stop = true;
        }
    }];

    id<MediaSelectableItem> item = _selectedItemsModel.items[index];
    
    ModernGalleryScrollAnimationDirection direction = ModernGalleryScrollAnimationDirectionLeft;
    if (currentSelectedItemIndex < index)
        direction = ModernGalleryScrollAnimationDirectionRight;
    
    [self setCurrentItem:item direction:direction];
}

- (UIView <ModernGalleryInterfaceView> *)createInterfaceView
{
    return _interfaceView;
}

- (UIView *)referenceViewForItem:(id<ModernGalleryItem>)item frame:(CGRect *)frame
{
    ModernGalleryController *galleryController = self.controller;
    ModernGalleryItemView *galleryItemView = [galleryController itemViewForItem:item];
    
    if ([galleryItemView isKindOfClass:[ModernGalleryZoomableItemView class]])
    {
        ModernGalleryZoomableItemView *zoomableItemView = (ModernGalleryZoomableItemView *)galleryItemView;
        
        if (zoomableItemView.contentView != nil)
        {
            if (frame != NULL)
                *frame = [zoomableItemView transitionViewContentRect];
            
            return (UIImageView *)zoomableItemView.transitionContentView;
        }
    }
    else if ([galleryItemView isKindOfClass:[MediaPickerGalleryVideoItemView class]])
    {
        MediaPickerGalleryVideoItemView *videoItemView = (MediaPickerGalleryVideoItemView *)galleryItemView;
        
        if (frame != NULL)
            *frame = [videoItemView transitionViewContentRect];
        
        return (UIView *)videoItemView;
    }
    
    return nil;
}

- (void)updateHiddenItem
{
    ModernGalleryController *galleryController = self.controller;
    
    for (ModernGalleryItemView *itemView in galleryController.visibleItemViews)
    {
        if ([itemView conformsToProtocol:@protocol(ModernGalleryEditableItemView)])
            [(ModernGalleryItemView <ModernGalleryEditableItemView> *)itemView setHiddenAsBeingEdited:[itemView.item isEqual:_itemBeingEdited]];
    }
}

- (void)updateEditedItemView
{
    ModernGalleryController *galleryController = self.controller;
    
    for (ModernGalleryItemView *itemView in galleryController.visibleItemViews)
    {
        if ([itemView conformsToProtocol:@protocol(ModernGalleryEditableItemView)])
        {
            if ([itemView.item isEqual:_itemBeingEdited])
            {
                [(ModernGalleryItemView <ModernGalleryEditableItemView> *)itemView setItem:_itemBeingEdited synchronously:true];
                if (self.itemsUpdated != nil)
                    self.itemsUpdated(_itemBeingEdited);
            }
        }
    }
}

- (void)presentPhotoEditorForItem:(id<ModernGalleryEditableItem>)item tab:(PhotoEditorTab)tab
{
    __weak MediaPickerGalleryModel *weakSelf = self;
    
    if (_itemBeingEdited != nil)
        return;
    
    _itemBeingEdited = item;

    PhotoEditorValues *editorValues = (PhotoEditorValues *)[item.editingContext adjustmentsForItem:item.editableMediaItem];
    
    NSString *caption = [item.editingContext captionForItem:item.editableMediaItem];

    CGRect refFrame = CGRectZero;
    UIView *editorReferenceView = [self referenceViewForItem:item frame:&refFrame];
    UIView *referenceView = nil;
    UIImage *screenImage = nil;
    UIView *referenceParentView = nil;
    UIImage *image = nil;
    
    bool isVideo = false;
    if ([editorReferenceView isKindOfClass:[UIImageView class]])
    {
        screenImage = [(UIImageView *)editorReferenceView image];
        referenceView = editorReferenceView;
    }
    else if ([editorReferenceView isKindOfClass:[MediaPickerGalleryVideoItemView class]])
    {
        MediaPickerGalleryVideoItemView *videoItemView = (MediaPickerGalleryVideoItemView *)editorReferenceView;
        [videoItemView prepareForEditing];
        
        refFrame = [videoItemView editorTransitionViewRect];
        screenImage = [videoItemView transitionImage];
        image = [videoItemView screenImage];
        referenceView = [[UIImageView alloc] initWithImage:screenImage];
        referenceParentView = editorReferenceView;
        
        isVideo = true;
    }
    
    if (self.useGalleryImageAsEditableItemImage && self.storeOriginalImageForItem != nil)
        self.storeOriginalImageForItem(item.editableMediaItem, screenImage);
    
    PhotoEditorControllerIntent intent = isVideo ? PhotoEditorControllerVideoIntent : PhotoEditorControllerGenericIntent;
    PhotoEditorController *controller = [[PhotoEditorController alloc] initWithItem:item.editableMediaItem intent:intent adjustments:editorValues caption:caption screenImage:screenImage availableTabs:_interfaceView.currentTabs selectedTab:tab];
    controller.editingContext = _editingContext;
    self.editorController = controller;
    controller.suggestionContext = self.suggestionContext;
    controller.willFinishEditing = ^(id<MediaEditAdjustments> adjustments, id temporaryRep, bool hasChanges)
    {
        __strong MediaPickerGalleryModel *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        strongSelf->_itemBeingEdited = nil;
        
        if (strongSelf.willFinishEditingItem != nil)
            strongSelf.willFinishEditingItem(item.editableMediaItem, adjustments, temporaryRep, hasChanges);
    };
    
    void (^didFinishEditingItem)(id<MediaEditableItem>item, id<MediaEditAdjustments> adjustments, UIImage *resultImage, UIImage *thumbnailImage) = self.didFinishEditingItem;
    controller.didFinishEditing = ^(id<MediaEditAdjustments> adjustments, UIImage *resultImage, UIImage *thumbnailImage, bool hasChanges)
    {
        __strong MediaPickerGalleryModel *strongSelf = weakSelf;
        if (strongSelf == nil) {
            TGLog(@"controller.didFinishEditing strongSelf == nil");
        }
        
#ifdef DEBUG
        if (adjustments != nil && hasChanges && !isVideo)
            NSAssert(resultImage != nil, @"resultImage should not be nil");
#endif
        
        if (hasChanges)
        {
            if (didFinishEditingItem != nil) {
                didFinishEditingItem(item.editableMediaItem, adjustments, resultImage, thumbnailImage);
            }
        }
        
        if ([editorReferenceView isKindOfClass:[MediaPickerGalleryVideoItemView class]])
        {
            MediaPickerGalleryVideoItemView *videoItemView = (MediaPickerGalleryVideoItemView *)editorReferenceView;
            [videoItemView setScrubbingPanelApperanceLocked:false];
            [videoItemView presentScrubbingPanelAfterReload:hasChanges];
        }
    };
    
    controller.didFinishRenderingFullSizeImage = ^(UIImage *image)
    {
        __strong MediaPickerGalleryModel *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        if (strongSelf.didFinishRenderingFullSizeImage != nil)
            strongSelf.didFinishRenderingFullSizeImage(item.editableMediaItem, image);
    };
    
    controller.captionSet = ^(NSString *caption)
    {
        __strong MediaPickerGalleryModel *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        if (strongSelf.saveItemCaption != nil)
            strongSelf.saveItemCaption(item.editableMediaItem, caption);
    };
    
    controller.requestToolbarsHidden = ^(bool hidden, bool animated)
    {
        __strong MediaPickerGalleryModel *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        [strongSelf.interfaceView setToolbarsHidden:hidden animated:animated];
    };

    controller.beginTransitionIn = ^UIView *(CGRect *referenceFrame, __unused UIView **parentView)
    {
        __strong MediaPickerGalleryModel *strongSelf = weakSelf;
        if (strongSelf == nil)
            return nil;
        
        if (strongSelf.editorOpened != nil)
            strongSelf.editorOpened();
        
        [strongSelf updateHiddenItem];
        [strongSelf.interfaceView editorTransitionIn];
        
        *referenceFrame = refFrame;
        
        if (referenceView.superview == nil)
            *parentView = referenceParentView;
        
        if (iosMajorVersion() >= 7)
            [strongSelf.controller setNeedsStatusBarAppearanceUpdate];
        else
            [[UIApplication sharedApplication] setStatusBarHidden:true];
        
        return referenceView;
    };
    
    controller.finishedTransitionIn = ^
    {
        __strong MediaPickerGalleryModel *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        ModernGalleryController *galleryController = strongSelf.controller;
        ModernGalleryItemView *galleryItemView = [galleryController itemViewForItem:strongSelf->_itemBeingEdited];
        if (![galleryItemView isKindOfClass:[ModernGalleryZoomableItemView class]])
            return;
        
        ModernGalleryZoomableItemView *zoomableItemView = (ModernGalleryZoomableItemView *)galleryItemView;
        [zoomableItemView reset];
    };
    
    controller.beginTransitionOut = ^UIView *(CGRect *referenceFrame, __unused UIView **parentView)
    {
        __strong MediaPickerGalleryModel *strongSelf = weakSelf;
        if (strongSelf == nil)
            return nil;
        
        [strongSelf.interfaceView editorTransitionOut];
        
        CGRect refFrame;
        UIView *referenceView = [strongSelf referenceViewForItem:item frame:&refFrame];
        if ([referenceView isKindOfClass:[MediaPickerGalleryVideoItemView class]])
        {
            MediaPickerGalleryVideoItemView *videoItemView = (MediaPickerGalleryVideoItemView *)referenceView;
            refFrame = [videoItemView editorTransitionViewRect];
            UIImage *screenImage = [videoItemView transitionImage];
            *parentView = referenceView;
            referenceView = [[UIImageView alloc] initWithImage:screenImage];
        }
        
        *referenceFrame = refFrame;
        
        return referenceView;
    };
    
    controller.finishedTransitionOut = ^(__unused bool saved)
    {
        __strong MediaPickerGalleryModel *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        if (strongSelf.editorClosed != nil)
            strongSelf.editorClosed();
        
        [strongSelf updateHiddenItem];
        
        UIView *referenceView = [strongSelf referenceViewForItem:item frame:NULL];
        if ([referenceView isKindOfClass:[MediaPickerGalleryVideoItemView class]])
            [(MediaPickerGalleryVideoItemView *)referenceView setPlayButtonHidden:false animated:true];
        
        if (iosMajorVersion() >= 7)
            [strongSelf.controller setNeedsStatusBarAppearanceUpdate];
        else
            [[UIApplication sharedApplication] setStatusBarHidden:false];
    };
    
    controller.requestThumbnailImage = ^SSignal *(id<MediaEditableItem> editableItem)
    {
        return [editableItem thumbnailImageSignal];
    };
    
    controller.requestOriginalScreenSizeImage = ^SSignal *(id<MediaEditableItem> editableItem, NSTimeInterval position)
    {
        return [editableItem screenImageSignal:position];
    };
    
    controller.requestOriginalFullSizeImage = ^SSignal *(id<MediaEditableItem> editableItem, NSTimeInterval position)
    {
        return [editableItem originalImageSignal:position];
    };
    
    controller.requestAdjustments = ^id<MediaEditAdjustments> (id<MediaEditableItem> editableItem)
    {
        __strong MediaPickerGalleryModel *strongSelf = weakSelf;
        if (strongSelf != nil && strongSelf.requestAdjustments != nil)
            return strongSelf.requestAdjustments(editableItem);
    
        return nil;
    };
    
    controller.requestImage = ^
    {
        return image;
    };
    
    [self.controller addChildViewController:controller];
    [self.controller.view addSubview:controller.view];
}

- (void)_replaceItems:(NSArray *)items focusingOnItem:(id<ModernGalleryItem>)item
{
    [super _replaceItems:items focusingOnItem:item];
 
    ModernGalleryController *controller = self.controller;
    
    NSArray *itemViews = [controller.visibleItemViews copy];
    for (ModernGalleryItemView *itemView in itemViews)
        [itemView setItem:itemView.item synchronously:false];
}

- (bool)_shouldAutorotate
{
    PhotoEditorController *editorController = self.editorController;
    return (!editorController || [editorController shouldAutorotate]);
}

@end
