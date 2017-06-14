#import "MediaPickerModernGalleryMixin.h"

#import "ModernGalleryController.h"
#import "MediaPickerGalleryItem.h"
#import "MediaPickerGalleryPhotoItem.h"
#import "MediaPickerGalleryVideoItem.h"
#import "MediaPickerGalleryVideoItemView.h"
#import "MediaPickerGalleryGifItem.h"

#import "MediaEditingContext.h"
#import "MediaSelectionContext.h"
#import "SuggestionContext.h"

#import "MediaAsset.h"
#import "MediaAssetFetchResult.h"
#import "MediaAssetMomentList.h"
#import "MediaAssetMoment.h"

#import "OverlayControllerWindow.h"

@interface MediaPickerModernGalleryMixin ()
{
    MediaEditingContext *_editingContext;
    bool _asFile;
    
    __weak ViewController *_parentController;
    __weak ModernGalleryController *_galleryController;
    ModernGalleryController *_strongGalleryController;
    
    NSUInteger _itemsLimit;
}
@end

@implementation MediaPickerModernGalleryMixin

- (instancetype)initWithItem:(id)item fetchResult:(MediaAssetFetchResult *)fetchResult parentController:(ViewController *)parentController thumbnailImage:(UIImage *)thumbnailImage selectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext suggestionContext:(SuggestionContext *)suggestionContext hasCaptions:(bool)hasCaptions inhibitDocumentCaptions:(bool)inhibitDocumentCaptions asFile:(bool)asFile itemsLimit:(NSUInteger)itemsLimit
{
    return [self initWithItem:item fetchResult:fetchResult momentList:nil parentController:parentController thumbnailImage:thumbnailImage selectionContext:selectionContext editingContext:editingContext suggestionContext:suggestionContext hasCaptions:hasCaptions inhibitDocumentCaptions:inhibitDocumentCaptions asFile:asFile itemsLimit:itemsLimit];
}

- (instancetype)initWithItem:(id)item momentList:(MediaAssetMomentList *)momentList parentController:(ViewController *)parentController thumbnailImage:(UIImage *)thumbnailImage selectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext suggestionContext:(SuggestionContext *)suggestionContext hasCaptions:(bool)hasCaptions inhibitDocumentCaptions:(bool)inhibitDocumentCaptions asFile:(bool)asFile itemsLimit:(NSUInteger)itemsLimit
{
    return [self initWithItem:item fetchResult:nil momentList:momentList parentController:parentController thumbnailImage:thumbnailImage selectionContext:selectionContext editingContext:editingContext suggestionContext:suggestionContext hasCaptions:hasCaptions inhibitDocumentCaptions:inhibitDocumentCaptions asFile:asFile itemsLimit:itemsLimit];
}

- (instancetype)initWithItem:(id)item fetchResult:(MediaAssetFetchResult *)fetchResult momentList:(MediaAssetMomentList *)momentList parentController:(ViewController *)parentController thumbnailImage:(UIImage *)thumbnailImage selectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext suggestionContext:(SuggestionContext *)suggestionContext hasCaptions:(bool)hasCaptions inhibitDocumentCaptions:(bool)inhibitDocumentCaptions asFile:(bool)asFile itemsLimit:(NSUInteger)itemsLimit
{
    self = [super init];
    if (self != nil)
    {
        _parentController = parentController;
        _editingContext = asFile ? nil : editingContext;
        _asFile = asFile;
        _itemsLimit = itemsLimit;
        
        __weak MediaPickerModernGalleryMixin *weakSelf = self;
        
        ModernGalleryController *modernGallery = [[ModernGalleryController alloc] init];
        _galleryController = modernGallery;
        _strongGalleryController = modernGallery;
        modernGallery.isImportant = true;
        
        __block id<ModernGalleryItem> focusItem = nil;
        void (^enumerationBlock)(MediaPickerGalleryItem *) = ^(MediaPickerGalleryItem *galleryItem)
        {
            if (focusItem == nil && [galleryItem.asset isEqual:item])
            {
                focusItem = galleryItem;
                galleryItem.immediateThumbnailImage = thumbnailImage;
            }
        };
        
        NSArray *galleryItems = fetchResult != nil ? [self prepareGalleryItemsForFetchResult:fetchResult selectionContext:selectionContext editingContext:editingContext asFile:asFile enumerationBlock:enumerationBlock] : [self prepareGalleryItemsForMomentList:momentList selectionContext:selectionContext editingContext:editingContext asFile:asFile enumerationBlock:enumerationBlock];
        
        MediaPickerGalleryModel *model = [[MediaPickerGalleryModel alloc] initWithItems:galleryItems focusItem:focusItem selectionContext:selectionContext editingContext:editingContext hasCaptions:hasCaptions inhibitDocumentCaptions:inhibitDocumentCaptions hasSelectionPanel:true];
        _galleryModel = model;
        model.controller = modernGallery;
        model.suggestionContext = suggestionContext;
        model.willFinishEditingItem = ^(id<MediaEditableItem> editableItem, id<MediaEditAdjustments> adjustments, id representation, bool hasChanges)
        {
            __strong MediaPickerModernGalleryMixin *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            if (hasChanges)
            {
                [editingContext setAdjustments:adjustments forItem:editableItem];
                [editingContext setTemporaryRep:representation forItem:editableItem];
            }
            
            if (selectionContext != nil && adjustments != nil && [editableItem conformsToProtocol:@protocol(MediaSelectableItem)])
                [selectionContext setItem:(id<MediaSelectableItem>)editableItem selected:true];
        };
        
        model.didFinishEditingItem = ^(id<MediaEditableItem> editableItem, __unused id<MediaEditAdjustments> adjustments, UIImage *resultImage, UIImage *thumbnailImage)
        {
            [editingContext setImage:resultImage thumbnailImage:thumbnailImage forItem:editableItem synchronous:false];
        };
        
        model.didFinishRenderingFullSizeImage = ^(id<MediaEditableItem> editableItem, UIImage *resultImage)
        {
            [editingContext setFullSizeImage:resultImage forItem:editableItem];
        };
        
        model.saveItemCaption = ^(id<MediaEditableItem> editableItem, NSString *caption)
        {
            [editingContext setCaption:caption forItem:editableItem];
            
            if (selectionContext != nil && caption.length > 0 && [editableItem conformsToProtocol:@protocol(MediaSelectableItem)])
                [selectionContext setItem:(id<MediaSelectableItem>)editableItem selected:true];
        };
        
        model.requestAdjustments = ^id<MediaEditAdjustments> (id<MediaEditableItem> editableItem)
        {
            return [editingContext adjustmentsForItem:editableItem];
        };
        
        model.interfaceView.usesSimpleLayout = asFile;
        [model.interfaceView updateSelectionInterface:selectionContext.count counterVisible:(selectionContext.count > 0) animated:false];
        model.interfaceView.donePressed = ^(MediaPickerGalleryItem *item)
        {
            __strong MediaPickerModernGalleryMixin *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            strongSelf->_galleryModel.dismiss(true, false);
            
            if (strongSelf.completeWithItem != nil)
                strongSelf.completeWithItem(item);
        };
        
        modernGallery.model = model;
        modernGallery.itemFocused = ^(MediaPickerGalleryItem *item)
        {
            __strong MediaPickerModernGalleryMixin *strongSelf = weakSelf;
            if (strongSelf != nil && strongSelf.itemFocused != nil)
                strongSelf.itemFocused(item);
        };
        
        modernGallery.beginTransitionIn = ^UIView *(MediaPickerGalleryItem *item, ModernGalleryItemView *itemView)
        {
            __strong MediaPickerModernGalleryMixin *strongSelf = weakSelf;
            if (strongSelf == nil)
                return nil;
            
            if (strongSelf.willTransitionIn != nil)
                strongSelf.willTransitionIn();
            
            if ([itemView isKindOfClass:[MediaPickerGalleryVideoItemView class]])
                [itemView setIsCurrent:true];
            
            if (strongSelf.referenceViewForItem != nil)
                return strongSelf.referenceViewForItem(item);
            
            return nil;
        };
        
        modernGallery.finishedTransitionIn = ^(__unused MediaPickerGalleryItem *item, __unused ModernGalleryItemView *itemView)
        {
            __strong MediaPickerModernGalleryMixin *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            [strongSelf->_galleryModel.interfaceView setSelectedItemsModel:strongSelf->_galleryModel.selectedItemsModel];
            
            if ([itemView isKindOfClass:[MediaPickerGalleryVideoItemView class]])
            {
                if (strongSelf->_galleryController.previewMode)
                    [(MediaPickerGalleryVideoItemView *)itemView playIfAvailable];
            }
        };
        
        modernGallery.beginTransitionOut = ^UIView *(MediaPickerGalleryItem *item, ModernGalleryItemView *itemView)
        {
            __strong MediaPickerModernGalleryMixin *strongSelf = weakSelf;
            if (strongSelf != nil)
            {
                if (strongSelf.willTransitionOut != nil)
                    strongSelf.willTransitionOut();
                
                if ([itemView isKindOfClass:[MediaPickerGalleryVideoItemView class]])
                    [(MediaPickerGalleryVideoItemView *)itemView stop];
                
                if (strongSelf.referenceViewForItem != nil)
                    return strongSelf.referenceViewForItem(item);
            }
            return nil;
        };
        
        modernGallery.completedTransitionOut = ^
        {
            __strong MediaPickerModernGalleryMixin *strongSelf = weakSelf;
            if (strongSelf != nil && strongSelf.didTransitionOut != nil)
                strongSelf.didTransitionOut();
        };
    }
    return self;
}

- (void)present
{
    _galleryModel.editorOpened = self.editorOpened;
    _galleryModel.editorClosed = self.editorClosed;
    
    [_galleryController setPreviewMode:false];
    
    OverlayControllerWindow *controllerWindow = [[OverlayControllerWindow alloc] initWithParentController:_parentController contentController:_galleryController];
    controllerWindow.hidden = false;
    _galleryController.view.clipsToBounds = true;
    
    _strongGalleryController = nil;
}

- (UIViewController *)galleryController
{
    return _galleryController;
}

- (void)setPreviewMode
{
    _galleryController.previewMode = true;
    _strongGalleryController = nil;
}

- (void)updateWithFetchResult:(MediaAssetFetchResult *)fetchResult
{
    MediaAsset *currentAsset = ((MediaPickerGalleryItem *)_galleryController.currentItem).asset;
    bool exists = ([fetchResult indexOfAsset:currentAsset] != NSNotFound);
    
    if (!exists)
    {
        _galleryModel.dismiss(true, false);
        return;
    }
    
    __block id<ModernGalleryItem> focusItem = nil;
    NSArray *galleryItems = [self prepareGalleryItemsForFetchResult:fetchResult selectionContext:_galleryModel.selectionContext editingContext:_editingContext asFile:_asFile enumerationBlock:^(MediaPickerGalleryItem *item)
                             {
                                 if (focusItem == nil && [item isEqual:_galleryController.currentItem])
                                     focusItem = item;
                             }];
    
    [_galleryModel _replaceItems:galleryItems focusingOnItem:focusItem];
}

- (NSArray *)prepareGalleryItemsForFetchResult:(MediaAssetFetchResult *)fetchResult selectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext asFile:(bool)asFile enumerationBlock:(void (^)(MediaPickerGalleryItem *))enumerationBlock
{
    NSMutableArray *galleryItems = [[NSMutableArray alloc] init];
    
    NSUInteger count = fetchResult.count;
    if (_itemsLimit > 0)
        count = MIN(count, _itemsLimit);
    
    for (NSUInteger i = 0; i < count; i++)
    {
        MediaAsset *asset = [fetchResult assetAtIndex:i];
        
        MediaPickerGalleryItem *galleryItem = nil;
        switch (asset.type)
        {
            case MediaAssetVideoType:
            {
                MediaPickerGalleryVideoItem *videoItem = [[MediaPickerGalleryVideoItem alloc] initWithAsset:asset];
                videoItem.selectionContext = selectionContext;
                videoItem.editingContext = editingContext;
                
                galleryItem = videoItem;
            }
                break;
                
            case MediaAssetGifType:
            {
                MediaPickerGalleryGifItem *gifItem = [[MediaPickerGalleryGifItem alloc] initWithAsset:asset];
                gifItem.selectionContext = selectionContext;
                gifItem.editingContext = editingContext;
                
                galleryItem = gifItem;
            }
                break;
                
            default:
            {
                MediaPickerGalleryPhotoItem *photoItem = [[MediaPickerGalleryPhotoItem alloc] initWithAsset:asset];
                photoItem.selectionContext = selectionContext;
                photoItem.editingContext = editingContext;
                
                galleryItem = photoItem;
            }
                break;
        }
        
        if (enumerationBlock != nil)
            enumerationBlock(galleryItem);
        
        galleryItem.asFile = asFile;
        
        if (galleryItem != nil)
            [galleryItems addObject:galleryItem];
    }
    
    return galleryItems;
}

- (NSArray *)prepareGalleryItemsForMomentList:(MediaAssetMomentList *)momentList selectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext asFile:(bool)asFile enumerationBlock:(void (^)(MediaPickerGalleryItem *))enumerationBlock
{
    NSMutableArray *galleryItems = [[NSMutableArray alloc] init];
    
    for (NSUInteger i = 0; i < momentList.count; i++)
    {
        MediaAssetMoment *moment = momentList[i];
        
        for (NSUInteger k = 0; k < moment.assetCount; k++)
        {
            MediaAsset *asset = [moment.fetchResult assetAtIndex:k];
            
            MediaPickerGalleryItem *galleryItem = nil;
            switch (asset.type)
            {
                case MediaAssetVideoType:
                {
                    MediaPickerGalleryVideoItem *videoItem = [[MediaPickerGalleryVideoItem alloc] initWithAsset:asset];
                    videoItem.selectionContext = selectionContext;
                    videoItem.editingContext = editingContext;
                    
                    galleryItem = videoItem;
                }
                    break;
                    
                case MediaAssetGifType:
                {
                    MediaPickerGalleryGifItem *gifItem = [[MediaPickerGalleryGifItem alloc] initWithAsset:asset];
                    gifItem.selectionContext = selectionContext;
                    gifItem.editingContext = editingContext;
                    
                    galleryItem = gifItem;
                }
                    break;
                    
                default:
                {
                    MediaPickerGalleryPhotoItem *photoItem = [[MediaPickerGalleryPhotoItem alloc] initWithAsset:asset];
                    photoItem.selectionContext = selectionContext;
                    photoItem.editingContext = editingContext;
                    
                    galleryItem = photoItem;
                }
                    break;
            }
            
            if (enumerationBlock != nil)
                enumerationBlock(galleryItem);
            
            galleryItem.asFile = asFile;
            
            if (galleryItem != nil)
                [galleryItems addObject:galleryItem];
        }
    }
    
    return galleryItems;
}

- (void)setThumbnailSignalForItem:(SSignal *(^)(id))thumbnailSignalForItem
{
    [_galleryModel.interfaceView setThumbnailSignalForItem:thumbnailSignalForItem];
}

- (UIView *)currentReferenceView
{
    if (self.referenceViewForItem != nil)
        return self.referenceViewForItem(_galleryController.currentItem);
    
    return nil;
}

@end
