#import "MediaAssetsPickerController.h"

#import "UICollectionView+Utils.h"
#import "ImageUtils.h"
#import "PhotoEditorUtils.h"

#import "MediaPickerLayoutMetrics.h"
#import "MediaAssetsPhotoCell.h"
#import "MediaAssetsVideoCell.h"
#import "MediaAssetsGifCell.h"

#import "MediaAssetsUtils.h"
#import "MediaAssetImageSignals.h"
#import "MediaAssetFetchResultChange.h"

#import "PhotoEditorController.h"
#import "PhotoEditorValues.h"

#import "Common.h"

@interface MediaAssetsPickerController () <UIViewControllerPreviewingDelegate>
{
    MediaAssetsControllerIntent _intent;
    MediaAssetsLibrary *_assetsLibrary;
    
    SMetaDisposable *_assetsDisposable;
    
    MediaAssetFetchResult *_fetchResult;
    
    MediaPickerModernGalleryMixin *_galleryMixin;
    MediaPickerModernGalleryMixin *_previewGalleryMixin;
    NSIndexPath *_previewIndexPath;
    
    bool _checked3dTouch;
}
@end

@implementation MediaAssetsPickerController

- (instancetype)initWithAssetsLibrary:(MediaAssetsLibrary *)assetsLibrary assetGroup:(MediaAssetGroup *)assetGroup intent:(MediaAssetsControllerIntent)intent selectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext
{
    bool hasSelection = false;
    bool hasEditing = false;
    
    switch (intent)
    {
        case MediaAssetsControllerIntentSendMedia:
            hasSelection = true;
            hasEditing = true;
            break;
            
        case MediaAssetsControllerIntentSendFile:
            hasSelection = true;
            hasEditing = true;
            break;
            
        case MediaAssetsControllerIntentSetProfilePhoto:
            hasEditing = true;
            break;
            
        default:
            break;
    }
    
    self = [super initWithSelectionContext:hasSelection ? selectionContext : nil editingContext:hasEditing ? editingContext : nil];
    if (self != nil)
    {
        _assetsLibrary = assetsLibrary;
        _assetGroup = assetGroup;
        _intent = intent;
        
        [self setTitle:_assetGroup.title];
        
        _assetsDisposable = [[SMetaDisposable alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_assetsDisposable dispose];
}

- (void)loadView
{
    [super loadView];
    
    [_collectionView registerClass:[MediaAssetsPhotoCell class] forCellWithReuseIdentifier:MediaAssetsPhotoCellKind];
    [_collectionView registerClass:[MediaAssetsVideoCell class] forCellWithReuseIdentifier:MediaAssetsVideoCellKind];
    [_collectionView registerClass:[MediaAssetsGifCell class] forCellWithReuseIdentifier:MediaAssetsGifCellKind];
    
    __weak MediaAssetsPickerController *weakSelf = self;
    _preheatMixin = [[MediaAssetsPreheatMixin alloc] initWithCollectionView:_collectionView scrollDirection:UICollectionViewScrollDirectionVertical];
    _preheatMixin.imageType = MediaAssetImageTypeThumbnail;
    _preheatMixin.assetCount = ^NSInteger
    {
        __strong MediaAssetsPickerController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return 0;
        
        return [strongSelf _numberOfItems];
    };
    _preheatMixin.assetAtIndexPath = ^MediaAsset *(NSIndexPath *indexPath)
    {
        __strong MediaAssetsPickerController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return nil;
        
        return [strongSelf _itemAtIndexPath:indexPath];
    };
}

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    SSignal *groupSignal = nil;
    if (_assetGroup != nil)
        groupSignal = [SSignal single:_assetGroup];
    else
        groupSignal = [_assetsLibrary cameraRollGroup];
    
    __weak MediaAssetsPickerController *weakSelf = self;
    [_assetsDisposable setDisposable:[[[[groupSignal deliverOn:[SQueue mainQueue]] mapToSignal:^SSignal *(MediaAssetGroup *assetGroup)
    {
        __strong MediaAssetsPickerController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return nil;
        
        if (strongSelf->_assetGroup == nil)
            strongSelf->_assetGroup = assetGroup;
        
        [strongSelf setTitle:assetGroup.title];
        
        return [strongSelf->_assetsLibrary assetsOfAssetGroup:assetGroup reversed:false];
    }] deliverOn:[SQueue mainQueue]] startWithNext:^(id next)
    {
        __strong MediaAssetsPickerController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        if (strongSelf->_layoutMetrics == nil)
        {
            if (strongSelf->_assetGroup.subtype == MediaAssetGroupSubtypePanoramas)
                strongSelf->_layoutMetrics = [MediaPickerLayoutMetrics panoramaLayoutMetrics];
            else
                strongSelf->_layoutMetrics = [MediaPickerLayoutMetrics defaultLayoutMetrics];
            
            strongSelf->_preheatMixin.imageSize = [strongSelf->_layoutMetrics imageSize];
        }
        
        if ([next isKindOfClass:[MediaAssetFetchResult class]])
        {
            MediaAssetFetchResult *fetchResult = (MediaAssetFetchResult *)next;
            
            bool scrollToBottom = (strongSelf->_fetchResult == nil);
            
            strongSelf->_fetchResult = fetchResult;
            [strongSelf->_collectionView reloadData];
            
            if (scrollToBottom)
            {
                [strongSelf->_collectionView layoutSubviews];
                [strongSelf _adjustContentOffsetToBottom];
            }
        }
        else if ([next isKindOfClass:[MediaAssetFetchResultChange class]])
        {
            MediaAssetFetchResultChange *change = (MediaAssetFetchResultChange *)next;
            
            strongSelf->_fetchResult = change.fetchResultAfterChanges;
            [MediaAssetsCollectionViewIncrementalUpdater updateCollectionView:strongSelf->_collectionView withChange:change completion:nil];
        }
        
//        if (strongSelf->_galleryMixin != nil && strongSelf->_fetchResult != nil)
//            [strongSelf->_galleryMixin updateWithFetchResult:strongSelf->_fetchResult];
    }]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setup3DTouch];
}

#pragma mark -

- (NSUInteger)_numberOfItems
{
    return _fetchResult.count;
}

- (id)_itemAtIndexPath:(NSIndexPath *)indexPath
{
    return [_fetchResult assetAtIndex:indexPath.row];
}

- (SSignal *)_signalForItem:(id)item
{
    SSignal *assetSignal = [MediaAssetImageSignals imageForAsset:item imageType:MediaAssetImageTypeThumbnail size:[_layoutMetrics imageSize]];
    if (self.editingContext == nil)
        return assetSignal;
    
    return [[self.editingContext thumbnailImageSignalForItem:item] mapToSignal:^SSignal *(id result)
    {
        if (result != nil)
            return [SSignal single:result];
        else
            return assetSignal;
    }];
}

- (NSString *)_cellKindForItem:(id)item
{
    MediaAsset *asset = (MediaAsset *)item;
    if ([asset isKindOfClass:[MediaAsset class]])
    {
        switch (asset.type)
        {
            case MediaAssetVideoType:
                return MediaAssetsVideoCellKind;
                
            case MediaAssetGifType:
                if (_intent == MediaAssetsControllerIntentSetProfilePhoto)
                    return MediaAssetsPhotoCellKind;
                else
                    return MediaAssetsGifCellKind;
                
            default:
                break;
        }
    }
    return MediaAssetsPhotoCellKind;
}

#pragma mark - Collection View Delegate

- (void)_setupGalleryMixin:(MediaPickerModernGalleryMixin *)mixin
{
//    __weak MediaAssetsPickerController *weakSelf = self;
//    mixin.referenceViewForItem = ^UIView *(MediaPickerGalleryItem *item)
//    {
//        __strong MediaAssetsPickerController *strongSelf = weakSelf;
//        if (strongSelf == nil)
//            return nil;
//        
//        for (MediaPickerCell *cell in [strongSelf->_collectionView visibleCells])
//        {
//            if ([cell.item isEqual:item.asset])
//                return cell;
//        }
//        
//        return nil;
//    };
//    
//    mixin.itemFocused = ^(MediaPickerGalleryItem *item)
//    {
//        __strong MediaAssetsPickerController *strongSelf = weakSelf;
//        if (strongSelf == nil)
//            return;
//        
//        [strongSelf _hideCellForItem:item.asset animated:false];
//    };
//    
//    mixin.didTransitionOut = ^
//    {
//        __strong MediaAssetsPickerController *strongSelf = weakSelf;
//        if (strongSelf == nil)
//            return;
//        
//        [strongSelf _hideCellForItem:nil animated:true];
//        strongSelf->_galleryMixin = nil;
//    };
//    
//    mixin.completeWithItem = ^(MediaPickerGalleryItem *item)
//    {
//        __strong MediaAssetsPickerController *strongSelf = weakSelf;
//        if (strongSelf == nil)
//            return;
//        
//        [(MediaAssetsController *)strongSelf.navigationController completeWithCurrentItem:item.asset];
//    };
}

//- (MediaPickerModernGalleryMixin *)_galleryMixinForItem:(id)item thumbnailImage:(UIImage *)thumbnailImage selectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext suggestionContext:(SuggestionContext *)suggestionContext hasCaptions:(bool)hasCaptions inhibitDocumentCaptions:(bool)inhibitDocumentCaptions asFile:(bool)asFile
//{
//    return [[MediaPickerModernGalleryMixin alloc] initWithItem:item fetchResult:_fetchResult parentController:self thumbnailImage:thumbnailImage selectionContext:selectionContext editingContext:editingContext suggestionContext:suggestionContext hasCaptions:hasCaptions inhibitDocumentCaptions:inhibitDocumentCaptions asFile:asFile itemsLimit:0];
//}

//- (MediaPickerModernGalleryMixin *)galleryMixinForIndexPath:(NSIndexPath *)indexPath previewMode:(bool)previewMode outAsset:(MediaAsset **)outAsset
//{
//    MediaAsset *asset = [self _itemAtIndexPath:indexPath];
//    if (outAsset != NULL)
//        *outAsset = asset;
//    
//    UIImage *thumbnailImage = nil;
//    
//    MediaPickerCell *cell = (MediaPickerCell *)[_collectionView cellForItemAtIndexPath:indexPath];
//    if ([cell isKindOfClass:[MediaPickerCell class]])
//        thumbnailImage = cell.imageView.image;
//    
//    bool hasCaptions = self.captionsEnabled;
//    bool asFile = (_intent == MediaAssetsControllerIntentSendFile);
//    
//    MediaPickerModernGalleryMixin *mixin = [self _galleryMixinForItem:asset thumbnailImage:thumbnailImage selectionContext:self.selectionContext editingContext:self.editingContext suggestionContext:self.suggestionContext hasCaptions:hasCaptions inhibitDocumentCaptions:self.inhibitDocumentCaptions asFile:asFile];
//    
//    __weak MediaAssetsPickerController *weakSelf = self;
//    mixin.thumbnailSignalForItem = ^SSignal *(id item)
//    {
//        __strong MediaAssetsPickerController *strongSelf = weakSelf;
//        if (strongSelf == nil)
//            return nil;
//        
//        return [strongSelf _signalForItem:item];
//    };
//    
//    if (!previewMode)
//        [self _setupGalleryMixin:mixin];
//    
//    return mixin;
//}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MediaAsset *asset = [self _itemAtIndexPath:indexPath];

    __block UIImage *thumbnailImage = nil;
    if ([MediaAssetsLibrary usesPhotoFramework])
    {
        MediaPickerCell *cell = (MediaPickerCell *)[collectionView cellForItemAtIndexPath:indexPath];
        if ([cell isKindOfClass:[MediaPickerCell class]])
            thumbnailImage = cell.imageView.image;
    }
    else
    {
        [[MediaAssetImageSignals imageForAsset:asset imageType:MediaAssetImageTypeAspectRatioThumbnail size:CGSizeZero] startWithNext:^(UIImage *next)
        {
            thumbnailImage = next;
        }];
    }

    __weak MediaAssetsPickerController *weakSelf = self;
    if (_intent == MediaAssetsControllerIntentSetProfilePhoto)
    {
        PhotoEditorController *controller = [[PhotoEditorController alloc] initWithItem:asset intent:PhotoEditorControllerAvatarIntent adjustments:nil caption:nil screenImage:thumbnailImage availableTabs:[PhotoEditorController defaultTabsForAvatarIntent] selectedTab:PhotoEditorCropTab];
        controller.editingContext = self.editingContext;
        controller.didFinishRenderingFullSizeImage = ^(UIImage *resultImage)
        {
            __strong MediaAssetsPickerController *strongSelf = weakSelf;
//            if (strongSelf == nil || !TGAppDelegateInstance.saveEditedPhotos)
//                return;
            
            [[strongSelf->_assetsLibrary saveAssetWithImage:resultImage] startWithNext:nil];
        };
        controller.didFinishEditing = ^(__unused id<MediaEditAdjustments> adjustments, UIImage *resultImage, __unused UIImage *thumbnailImage, bool hasChanges)
        {
            if (!hasChanges)
                return;
            
            __strong MediaAssetsPickerController *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            [(MediaAssetsController *)strongSelf.navigationController completeWithAvatarImage:resultImage];
        };
        
        controller.requestThumbnailImage = ^(id<MediaEditableItem> editableItem)
        {
            return [editableItem thumbnailImageSignal];
        };
        
        controller.requestOriginalScreenSizeImage = ^(id<MediaEditableItem> editableItem, NSTimeInterval position)
        {
            return [editableItem screenImageSignal:position];
        };
        
        controller.requestOriginalFullSizeImage = ^(id<MediaEditableItem> editableItem, NSTimeInterval position)
        {
            return [editableItem originalImageSignal:position];
        };
        
        [self.navigationController pushViewController:controller animated:true];
    }
    else
    {
//        _galleryMixin = [self galleryMixinForIndexPath:indexPath previewMode:false outAsset:NULL];
//        [_galleryMixin present];
    }
}

#pragma mark - 

- (void)setup3DTouch
{
    if (_checked3dTouch)
        return;
    
    _checked3dTouch = true;
    if (iosMajorVersion() >= 9)
    {
        if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)
            [self registerForPreviewingWithDelegate:(id)self sourceView:self.view];
    }
}

//- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
//{
//    CGPoint point = [self.view convertPoint:location toView:_collectionView];
//    NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:point];
//    if (indexPath == nil)
//        return nil;
//    
//    [self _cancelSelectionGestureRecognizer];
//    
//    CGRect cellFrame = [_collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath].frame;
//    previewingContext.sourceRect = [self.view convertRect:cellFrame fromView:_collectionView];
//    
//    MediaAsset *asset = nil;
//    _previewGalleryMixin = [self galleryMixinForIndexPath:indexPath previewMode:true outAsset:&asset];
//    UIViewController *controller = [_previewGalleryMixin galleryController];
//    controller.preferredContentSize = TGFitSize(asset.dimensions, self.view.frame.size);
//    [_previewGalleryMixin setPreviewMode];
//    return controller;
//}

- (void)previewingContext:(id<UIViewControllerPreviewing>)__unused previewingContext commitViewController:(UIViewController *)__unused viewControllerToCommit
{
//    _galleryMixin = _previewGalleryMixin;
//    _previewGalleryMixin = nil;
//    
//    [self _setupGalleryMixin:_galleryMixin];
//    [_galleryMixin present];
}

#pragma mark - Asset Image Preheating

- (void)scrollViewDidScroll:(UIScrollView *)__unused scrollView
{
    bool isViewVisible = (self.isViewLoaded && self.view.window != nil);
    if (!isViewVisible)
        return;
    
    [_preheatMixin update];
}

- (NSArray *)_assetsAtIndexPaths:(NSArray *)indexPaths
{
    if (indexPaths.count == 0)
        return nil;
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths)
    {
        if ((NSUInteger)indexPath.row < [self _numberOfItems])
            [assets addObject:[self _itemAtIndexPath:indexPath]];
    }
    
    return assets;
}

@end
