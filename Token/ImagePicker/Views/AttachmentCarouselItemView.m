#import "AttachmentCarouselItemView.h"
#import "MenuSheetButtonItemView.h"
#import "MenuSheetView.h"

#import "AppDelegate.h"
#import "UICollectionView+Utils.h"
#import "ImageUtils.h"
#import "StringUtils.h"
#import "PhotoEditorUtils.h"

#import "MediaEditingContext.h"
#import "MediaSelectionContext.h"

#import "TransitionLayout.h"

#import "AttachmentCameraView.h"

#import "AttachmentPhotoCell.h"
#import "AttachmentVideoCell.h"
#import "AttachmentGifCell.h"

#import "MediaAssetsLibrary.h"
#import "MediaAssetFetchResult.h"

#import "MediaAssetImageSignals.h"

#import "MediaPickerModernGalleryMixin.h"
#import "MediaPickerGalleryItem.h"
#import "MediaAssetsUtils.h"

#import "OverlayControllerWindow.h"

#import "TGMediaAvatarEditorTransition.h"
#import "PhotoEditorController.h"
#import "VideoEditAdjustments.h"
#import "MediaAsset+MediaEditableItem.h"

#import "Common.h"

const CGSize AttachmentCellSize = { 84.0f, 84.0f };
const CGFloat AttachmentEdgeInset = 8.0f;

const CGFloat AttachmentZoomedPhotoRemainer = 32.0f;

const CGFloat AttachmentZoomedPhotoHeight = 198.0f;
const CGFloat AttachmentZoomedPhotoMaxWidth = 250.0f;

const CGFloat AttachmentZoomedPhotoCondensedHeight = 141.0f;
const CGFloat AttachmentZoomedPhotoCondensedMaxWidth = 178.0f;

const CGFloat AttachmentZoomedPhotoAspectRatio = 1.2626f;

const NSUInteger AttachmentDisplayedAssetLimit = 500;

@implementation AttachmentCarouselCollectionView

@end

@interface AttachmentCarouselItemView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
{
    MediaAssetsLibrary *_assetsLibrary;
    SMetaDisposable *_assetsDisposable;
    MediaAssetFetchResult *_fetchResult;
    
    bool _forProfilePhoto;
    
    SMetaDisposable *_selectionChangedDisposable;
    SMetaDisposable *_itemsSizeChangedDisposable;
    
    UICollectionViewFlowLayout *_smallLayout;
    UICollectionViewFlowLayout *_largeLayout;
    UICollectionView *_collectionView;
    MediaAssetsPreheatMixin *_preheatMixin;
    
    AttachmentCameraView *_cameraView;
    
    MenuSheetButtonItemView *_sendMediaItemView;
    MenuSheetButtonItemView *_sendFileItemView;
    
    MediaPickerModernGalleryMixin *_galleryMixin;
    MediaPickerModernGalleryMixin *_previewGalleryMixin;
    MediaAsset *_hiddenItem;
    
    bool _zoomedIn;
    bool _zoomingIn;
    CGFloat _zoomingProgress;
    
    NSInteger _pivotInItemIndex;
    NSInteger _pivotOutItemIndex;
    
    CGSize _imageSize;
    
    CGSize _maxPhotoSize;
    
    CGFloat _smallActivationHeight;
    bool _smallActivated;
    CGSize _smallMaxPhotoSize;
    
    CGFloat _carouselCorrection;
}
@end

@implementation AttachmentCarouselItemView

- (instancetype)initWithCamera:(bool)hasCamera selfPortrait:(bool)selfPortrait forProfilePhoto:(bool)forProfilePhoto assetType:(MediaAssetType)assetType
{
    self = [super initWithType:MenuSheetItemTypeDefault];
    if (self != nil)
    {
        __weak AttachmentCarouselItemView *weakSelf = self;
        _forProfilePhoto = forProfilePhoto;
        
        _assetsLibrary = [MediaAssetsLibrary libraryForAssetType:assetType];
        _assetsDisposable = [[SMetaDisposable alloc] init];
        
        if (!forProfilePhoto)
        {
            _selectionContext = [[MediaSelectionContext alloc] init];
            [_selectionContext setItemSourceUpdatedSignal:[_assetsLibrary libraryChanged]];
            _selectionContext.updatedItemsSignal = ^SSignal *(NSArray *items)
            {
                __strong AttachmentCarouselItemView *strongSelf = weakSelf;
                if (strongSelf == nil)
                    return nil;
                
                return [strongSelf->_assetsLibrary updatedAssetsForAssets:items];
            };
            
            _selectionChangedDisposable = [[SMetaDisposable alloc] init];
            [_selectionChangedDisposable setDisposable:[[[_selectionContext selectionChangedSignal] mapToSignal:^SSignal *(id value)
                                                         {
                                                             __strong AttachmentCarouselItemView *strongSelf = weakSelf;
                                                             if (strongSelf == nil)
                                                                 return [SSignal complete];
                                                             
                                                             return [[strongSelf->_collectionView noOngoingTransitionSignal] then:[SSignal single:value]];
                                                         }] startWithNext:^(__unused MediaSelectionChange *change)
                                                        {
                                                            __strong AttachmentCarouselItemView *strongSelf = weakSelf;
                                                            if (strongSelf == nil)
                                                                return;
                                                            
                                                            NSInteger index = [strongSelf->_fetchResult indexOfAsset:(MediaAsset *)change.item];
                                                            [strongSelf updateSendButtonsFromIndex:index];
                                                        }]];
            
            _editingContext = [[MediaEditingContext alloc] init];
            
            _itemsSizeChangedDisposable = [[SMetaDisposable alloc] init];
            [_itemsSizeChangedDisposable setDisposable:[[[_editingContext cropAdjustmentsUpdatedSignal] deliverOn:[SQueue mainQueue]] startWithNext:^(__unused id next)
                                                        {
                                                            __strong AttachmentCarouselItemView *strongSelf = weakSelf;
                                                            if (strongSelf == nil)
                                                                return;
                                                            
                                                            if (strongSelf->_zoomedIn)
                                                            {
                                                                [strongSelf->_largeLayout invalidateLayout];
                                                                [strongSelf->_collectionView layoutSubviews];
                                                                
                                                                UICollectionViewCell *pivotCell = (UICollectionViewCell *)[strongSelf->_galleryMixin currentReferenceView];
                                                                if (pivotCell != nil)
                                                                {
                                                                    NSIndexPath *indexPath = [strongSelf->_collectionView indexPathForCell:pivotCell];
                                                                    if (indexPath != nil)
                                                                        [strongSelf centerOnItemWithIndex:indexPath.row animated:false];
                                                                }
                                                            }
                                                        }]];
        }
        
        _smallLayout = [[UICollectionViewFlowLayout alloc] init];
        _smallLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _smallLayout.minimumLineSpacing = AttachmentEdgeInset;
        
        _largeLayout = [[UICollectionViewFlowLayout alloc] init];
        _largeLayout.scrollDirection = _smallLayout.scrollDirection;
        _largeLayout.minimumLineSpacing = _smallLayout.minimumLineSpacing;
        
        if (hasCamera)
        {
            _cameraView = [[AttachmentCameraView alloc] initForSelfPortrait:selfPortrait];
            _cameraView.frame = CGRectMake(_smallLayout.minimumLineSpacing, 0, AttachmentCellSize.width, AttachmentCellSize.height);
            [_cameraView startPreview];
            
            _cameraView.pressed = ^
            {
                __strong AttachmentCarouselItemView *strongSelf = weakSelf;
                if (strongSelf == nil)
                    return;
                
                [strongSelf.superview bringSubviewToFront:strongSelf];
                
                if (strongSelf.cameraPressed != nil)
                    strongSelf.cameraPressed(strongSelf->_cameraView);
            };
        }
        
        _collectionView = [[AttachmentCarouselCollectionView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, AttachmentZoomedPhotoHeight + AttachmentEdgeInset * 2) collectionViewLayout:_smallLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.showsHorizontalScrollIndicator = false;
        _collectionView.showsVerticalScrollIndicator = false;
        [_collectionView registerClass:[AttachmentPhotoCell class] forCellWithReuseIdentifier:AttachmentPhotoCellIdentifier];
        [_collectionView registerClass:[AttachmentVideoCell class] forCellWithReuseIdentifier:AttachmentVideoCellIdentifier];
        [_collectionView registerClass:[AttachmentGifCell class] forCellWithReuseIdentifier:AttachmentGifCellIdentifier];
        [self addSubview:_collectionView];
        
        if (_cameraView)
            [_collectionView addSubview:_cameraView];
        
        _sendMediaItemView = [[MenuSheetButtonItemView alloc] initWithTitle:nil type:MenuSheetButtonTypeSend action:^
                              {
                                  __strong AttachmentCarouselItemView *strongSelf = weakSelf;
                                  if (strongSelf != nil && strongSelf.sendPressed != nil)
                                      strongSelf.sendPressed(nil, false);
                              }];
        [_sendMediaItemView setHidden:true animated:false];
        [self addSubview:_sendMediaItemView];
        
        _sendFileItemView = [[MenuSheetButtonItemView alloc] initWithTitle:nil type:MenuSheetButtonTypeDefault action:^
                             {
                                 __strong AttachmentCarouselItemView *strongSelf = weakSelf;
                                 if (strongSelf != nil && strongSelf.sendPressed != nil)
                                     strongSelf.sendPressed(nil, true);
                             }];
        _sendFileItemView.requiresDivider = false;
        [_sendFileItemView setHidden:true animated:false];
        [self addSubview:_sendFileItemView];
        
        [self setSignal:[[MediaAssetsLibrary authorizationStatusSignal] mapToSignal:^SSignal *(NSNumber *statusValue)
                         {
                             __strong AttachmentCarouselItemView *strongSelf = weakSelf;
                             if (strongSelf == nil)
                                 return [SSignal complete];
                             
                             MediaLibraryAuthorizationStatus status = statusValue.intValue;
                             if (status == MediaLibraryAuthorizationStatusAuthorized)
                             {
                                 return [[strongSelf->_assetsLibrary cameraRollGroup] mapToSignal:^SSignal *(MediaAssetGroup *cameraRollGroup)
                                         {
                                             return [strongSelf->_assetsLibrary assetsOfAssetGroup:cameraRollGroup reversed:true];
                                         }];
                             }
                             else
                             {
                                 return [SSignal fail:nil];
                             }
                         }]];
        
        _preheatMixin = [[MediaAssetsPreheatMixin alloc] initWithCollectionView:_collectionView scrollDirection:UICollectionViewScrollDirectionHorizontal];
        _preheatMixin.imageType = MediaAssetImageTypeThumbnail;
        _preheatMixin.assetCount = ^NSInteger
        {
            __strong AttachmentCarouselItemView *strongSelf = weakSelf;
            if (strongSelf == nil)
                return 0;
            
            return [strongSelf collectionView:strongSelf->_collectionView numberOfItemsInSection:0];
        };
        _preheatMixin.assetAtIndexPath = ^MediaAsset *(NSIndexPath *indexPath)
        {
            __strong AttachmentCarouselItemView *strongSelf = weakSelf;
            if (strongSelf == nil)
                return nil;
            
            return [strongSelf->_fetchResult assetAtIndex:indexPath.row];
        };
        
        [self _updateImageSize];
        _preheatMixin.imageSize = _imageSize;
        
        [self setCondensed:false];
        
        _pivotInItemIndex = NSNotFound;
        _pivotOutItemIndex = NSNotFound;
    }
    return self;
}

- (void)dealloc
{
    [_assetsDisposable dispose];
    [_selectionChangedDisposable dispose];
    [_itemsSizeChangedDisposable dispose];
}

- (void)setRemainingHeight:(CGFloat)remainingHeight
{
    _remainingHeight = remainingHeight;
    [self setCondensed:_condensed];
}

- (void)setCondensed:(bool)condensed
{
    _condensed = condensed;
    
    if (condensed)
        _maxPhotoSize = CGSizeMake(AttachmentZoomedPhotoCondensedMaxWidth, AttachmentZoomedPhotoCondensedHeight);
    else
        _maxPhotoSize = CGSizeMake(AttachmentZoomedPhotoMaxWidth, AttachmentZoomedPhotoHeight);
    
    if (_remainingHeight > MenuSheetButtonItemViewHeight * (condensed ? 3 : 4))
        _maxPhotoSize.height += AttachmentZoomedPhotoRemainer;
    
    CGSize screenSize = TGScreenSize();
    _smallActivationHeight = screenSize.width;
    
    CGFloat smallHeight = MAX(95, screenSize.width - 225);
    _smallMaxPhotoSize = CGSizeMake(ceil(smallHeight * AttachmentZoomedPhotoAspectRatio), smallHeight);
    
    CGRect frame = _collectionView.frame;
    frame.size.height = _maxPhotoSize.height + AttachmentEdgeInset * 2;
    _collectionView.frame = frame;
}

- (void)setSignal:(SSignal *)signal
{
    __weak AttachmentCarouselItemView *weakSelf = self;
    [_assetsDisposable setDisposable:[[[signal mapToSignal:^SSignal *(id value)
                                        {
                                            __strong AttachmentCarouselItemView *strongSelf = weakSelf;
                                            if (strongSelf == nil)
                                                return [SSignal complete];
                                            
                                            return [[strongSelf->_collectionView noOngoingTransitionSignal] then:[SSignal single:value]];
                                        }] deliverOn:[SQueue mainQueue]] startWithNext:^(id next)
                                      {
                                          __strong AttachmentCarouselItemView *strongSelf = weakSelf;
                                          if (strongSelf == nil)
                                              return;
                                          
                                          if ([next isKindOfClass:[MediaAssetFetchResult class]])
                                          {
                                              MediaAssetFetchResult *fetchResult = (MediaAssetFetchResult *)next;
                                              strongSelf->_fetchResult = fetchResult;
                                              [strongSelf->_collectionView reloadData];
                                          }
                                          else if ([next isKindOfClass:[MediaAssetFetchResultChange class]])
                                          {
                                              MediaAssetFetchResultChange *change = (MediaAssetFetchResultChange *)next;
                                              strongSelf->_fetchResult = change.fetchResultAfterChanges;
                                              [MediaAssetsCollectionViewIncrementalUpdater updateCollectionView:strongSelf->_collectionView withChange:change completion:nil];
                                              
                                              dispatch_async(dispatch_get_main_queue(), ^
                                                             {
                                                                 [strongSelf scrollViewDidScroll:strongSelf->_collectionView];
                                                             });
                                          }
                                          
                                          if (strongSelf->_galleryMixin != nil && strongSelf->_fetchResult != nil)
                                              [strongSelf->_galleryMixin updateWithFetchResult:strongSelf->_fetchResult];
                                      }]];
}

- (SSignal *)_signalForItem:(MediaAsset *)asset
{
    return [self _signalForItem:asset refresh:false onlyThumbnail:false];
}

- (SSignal *)_signalForItem:(MediaAsset *)asset refresh:(bool)refresh onlyThumbnail:(bool)onlyThumbnail
{
    bool thumbnail = onlyThumbnail || !_zoomedIn;
    CGSize imageSize = onlyThumbnail ? [self imageSizeForThumbnail:true] : _imageSize;
    
    MediaAssetImageType screenImageType = refresh ? MediaAssetImageTypeLargeThumbnail : MediaAssetImageTypeFastLargeThumbnail;
    MediaAssetImageType imageType = thumbnail ? MediaAssetImageTypeAspectRatioThumbnail : screenImageType;
    
    SSignal *assetSignal = [MediaAssetImageSignals imageForAsset:asset imageType:imageType size:imageSize];
    if (_editingContext == nil)
        return assetSignal;
    
    SSignal *editedSignal =  thumbnail ? [_editingContext thumbnailImageSignalForItem:asset] : [_editingContext fastImageSignalForItem:asset withUpdates:true];
    return [editedSignal mapToSignal:^SSignal *(id result)
            {
                if (result != nil)
                    return [SSignal single:result];
                else
                    return assetSignal;
            }];
}

#pragma mark -

- (void)setCameraZoomedIn:(bool)zoomedIn progress:(CGFloat)progress
{
    if (_cameraView == nil)
        return;
    
    CGFloat size = AttachmentCellSize.height;
    progress = zoomedIn ? progress : 1.0f - progress;
    _cameraView.frame = CGRectMake(_smallLayout.minimumLineSpacing - (size + _smallLayout.minimumLineSpacing) * progress, 0, AttachmentCellSize.width + (size - AttachmentCellSize.width) * progress, AttachmentCellSize.height + (size - AttachmentCellSize.height) * progress);
    [_cameraView setZoomedProgress:progress];
}

- (void)setZoomedMode:(bool)zoomed animated:(bool)animated index:(NSInteger)index
{
    if (zoomed == _zoomedIn)
    {
        if (_zoomedIn)
            [self centerOnItemWithIndex:index animated:animated];
        
        return;
    }
    
    _zoomedIn = zoomed;
    _zoomingIn = true;
    _collectionView.userInteractionEnabled = false;
    
    if (zoomed)
        _pivotInItemIndex = index;
    else
        _pivotOutItemIndex = index;
    
    UICollectionViewFlowLayout *toLayout = _zoomedIn ? _largeLayout : _smallLayout;
    
    [self _updateImageSize];
    
    __weak AttachmentCarouselItemView *weakSelf = self;
    TransitionLayout *layout = (TransitionLayout *)[_collectionView transitionToCollectionViewLayout:toLayout duration:0.3f completion:^(__unused BOOL completed, __unused BOOL finished)
                                                        {
                                                            __strong AttachmentCarouselItemView *strongSelf = weakSelf;
                                                            if (strongSelf == nil)
                                                                return;
                                                            
                                                            strongSelf->_zoomingIn = false;
                                                            strongSelf->_collectionView.userInteractionEnabled = true;
                                                            [strongSelf centerOnItemWithIndex:index animated:false];
                                                        }];
    layout.progressChanged = ^(CGFloat progress)
    {
        __strong AttachmentCarouselItemView *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        strongSelf->_zoomingProgress = progress;
        [strongSelf requestMenuLayoutUpdate];
        [strongSelf _layoutButtonItemViews];
        [strongSelf setCameraZoomedIn:strongSelf->_zoomedIn progress:progress];
    };
    layout.transitionAlmostFinished = ^
    {
        __strong AttachmentCarouselItemView *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        strongSelf->_pivotInItemIndex = NSNotFound;
        strongSelf->_pivotOutItemIndex = NSNotFound;
    };
    
    CGPoint toOffset = [_collectionView toContentOffsetForLayout:layout indexPath:[NSIndexPath indexPathForRow:index inSection:0] toSize:_collectionView.bounds.size toContentInset:[self collectionView:_collectionView layout:toLayout insetForSectionAtIndex:0]];
    toOffset.y = 0;
    layout.toContentOffset = toOffset;
    
    for (MenuSheetItemView *itemView in self.underlyingViews)
        [itemView setHidden:zoomed animated:animated];
    
    [_sendMediaItemView setHidden:!zoomed animated:animated];
    [_sendFileItemView setHidden:!zoomed animated:animated];
    
    [self _updateVisibleItems];
}

- (void)updateSendButtonsFromIndex:(NSInteger)index
{
    __block NSInteger photosCount = 0;
    __block NSInteger videosCount = 0;
    __block NSInteger gifsCount = 0;
    
    [_selectionContext enumerateSelectedItems:^(id<MediaSelectableItem> item)
     {
         MediaAsset *asset = (MediaAsset *)item;
         if (![asset isKindOfClass:[MediaAsset class]])
             return;
         
         switch (asset.type)
         {
             case MediaAssetVideoType:
                 videosCount++;
                 break;
                 
             case MediaAssetGifType:
                 gifsCount++;
                 break;
                 
             default:
                 photosCount++;
                 break;
         }
     }];
    
    NSInteger totalCount = photosCount + videosCount + gifsCount;
    bool activated = (totalCount > 0);
    if ([self zoomedModeSupported])
        [self setZoomedMode:activated animated:true index:index];
    else
        [self setSelectedMode:activated animated:true];
    
    if (totalCount == 0)
        return;
    
    if (photosCount > 0 && videosCount == 0 && gifsCount == 0)
    {
        NSString *format = TGLocalized([StringUtils integerValueFormat:@"Send Photo " value:photosCount]);
        _sendMediaItemView.title = [NSString stringWithFormat:format, [NSString stringWithFormat:@"%ld", photosCount]];
    }
    else if (videosCount > 0 && photosCount == 0 && gifsCount == 0)
    {
        NSString *format = TGLocalized([StringUtils integerValueFormat:@"Send Video " value:videosCount]);
        _sendMediaItemView.title = [NSString stringWithFormat:format, [NSString stringWithFormat:@"%ld", videosCount]];
    }
    else if (gifsCount > 0 && photosCount == 0 && videosCount == 0)
    {
        NSString *format = TGLocalized([StringUtils integerValueFormat:@"Send Gif " value:gifsCount]);
        _sendMediaItemView.title = [NSString stringWithFormat:format, [NSString stringWithFormat:@"%ld", gifsCount]];
    }
    else
    {
        NSString *format = TGLocalized([StringUtils integerValueFormat:@"Send Item " value:totalCount]);
        _sendMediaItemView.title = [NSString stringWithFormat:format, [NSString stringWithFormat:@"%ld", totalCount]];
    }
    
    if (totalCount == 1)
        _sendFileItemView.title = TGLocalized(@"Send As File");
    else
        _sendFileItemView.title = TGLocalized(@"Send As Files");
}

- (void)setSelectedMode:(bool)selected animated:(bool)animated
{
    [self.underlyingViews.firstObject setHidden:selected animated:animated];
    [_sendMediaItemView setHidden:!selected animated:animated];
}

- (bool)zoomedModeSupported
{
    return [MediaAssetsLibrary usesPhotoFramework];
}

- (CGPoint)contentOffsetForItemAtIndex:(NSInteger)index
{
    CGRect cellFrame = [_collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]].frame;
    
    CGFloat x = cellFrame.origin.x - (_collectionView.frame.size.width - cellFrame.size.width) / 2.0f;
    CGFloat contentOffset = MAX(0.0f, MIN(x, _collectionView.contentSize.width - _collectionView.frame.size.width));
    
    return CGPointMake(contentOffset, 0);
}

- (void)centerOnItemWithIndex:(NSInteger)index animated:(bool)animated
{
    [_collectionView setContentOffset:[self contentOffsetForItemAtIndex:index] animated:animated];
}

#pragma mark -

- (CGFloat)_preferredHeightForZoomedIn:(bool)zoomedIn progress:(CGFloat)progress screenHeight:(CGFloat)__unused screenHeight
{
    progress = zoomedIn ? progress : 1.0f - progress;
    
    CGFloat inset = AttachmentEdgeInset * 2;
    CGFloat cellHeight = AttachmentCellSize.height;
    CGFloat targetCellHeight = _smallActivated ? _smallMaxPhotoSize.height : _maxPhotoSize.height;
    
    cellHeight = cellHeight + (targetCellHeight - cellHeight) * progress;
    
    return cellHeight + inset;
}

- (CGFloat)_heightCorrectionForZoomedIn:(bool)zoomedIn progress:(CGFloat)progress
{
    progress = zoomedIn ? progress : 1.0f - progress;
    
    CGFloat correction = self.remainingHeight - 2 * MenuSheetButtonItemViewHeight;
    return -(correction * progress);
}

- (CGFloat)preferredHeightForWidth:(CGFloat)__unused width screenHeight:(CGFloat)screenHeight
{
    CGFloat progress = _zoomingIn ? _zoomingProgress : 1.0f;
    return [self _preferredHeightForZoomedIn:_zoomedIn progress:progress screenHeight:screenHeight];
}

- (CGFloat)contentHeightCorrection
{
    CGFloat progress = _zoomingIn ? _zoomingProgress : 1.0f;
    return [self _heightCorrectionForZoomedIn:_zoomedIn progress:progress];
}

#pragma mark -

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!_sendMediaItemView.userInteractionEnabled)
        return [super pointInside:point withEvent:event];
    
    return CGRectContainsPoint(self.bounds, point) || CGRectContainsPoint(_sendMediaItemView.frame, point) || CGRectContainsPoint(_sendFileItemView.frame, point);
}

#pragma mark -

- (void)_updateVisibleItems
{
    for (NSIndexPath *indexPath in _collectionView.indexPathsForVisibleItems)
    {
        MediaAsset *asset = [_fetchResult assetAtIndex:indexPath.row];
        AttachmentAssetCell *cell = (AttachmentAssetCell *)[_collectionView cellForItemAtIndexPath:indexPath];
        if (cell.isZoomed != _zoomedIn)
        {
            cell.isZoomed = _zoomedIn;
            [cell setSignal:[self _signalForItem:asset refresh:true onlyThumbnail:false]];
        }
    }
}

- (void)_updateImageSize
{
    _imageSize = [self imageSizeForThumbnail:!_zoomedIn];
}

- (CGSize)imageSizeForThumbnail:(bool)forThumbnail
{
    CGFloat scale = MIN(2.0f, TGScreenScaling());
    if (forThumbnail)
        return CGSizeMake(AttachmentCellSize.width * scale, AttachmentCellSize.height * scale);
    else
        return CGSizeMake(floor(AttachmentZoomedPhotoMaxWidth * scale), floor(AttachmentZoomedPhotoMaxWidth * scale));
}

- (bool)hasCameraInCurrentMode
{
    return (!_zoomedIn && _cameraView != nil);
}

#pragma mark -

- (void)_setupGalleryMixin:(MediaPickerModernGalleryMixin *)mixin
{
    __weak AttachmentCarouselItemView *weakSelf = self;
    mixin.referenceViewForItem = ^UIView *(MediaPickerGalleryItem *item)
    {
        __strong AttachmentCarouselItemView *strongSelf = weakSelf;
        if (strongSelf != nil)
            return [strongSelf referenceViewForAsset:item.asset];
        
        return nil;
    };
    
    mixin.itemFocused = ^(MediaPickerGalleryItem *item)
    {
        __strong AttachmentCarouselItemView *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        strongSelf->_hiddenItem = item.asset;
        [strongSelf updateHiddenCellAnimated:false];
    };
    
    mixin.willTransitionIn = ^
    {
        __strong AttachmentCarouselItemView *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        [strongSelf.superview bringSubviewToFront:strongSelf];
        [strongSelf->_cameraView pausePreview];
    };
    
    mixin.willTransitionOut = ^
    {
        __strong AttachmentCarouselItemView *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        [strongSelf->_cameraView resumePreview];
    };
    
    mixin.didTransitionOut = ^
    {
        __strong AttachmentCarouselItemView *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        strongSelf->_hiddenItem = nil;
        [strongSelf updateHiddenCellAnimated:true];
        
        strongSelf->_galleryMixin = nil;
    };
    
    mixin.completeWithItem = ^(MediaPickerGalleryItem *item)
    {
        __strong AttachmentCarouselItemView *strongSelf = weakSelf;
        if (strongSelf != nil && strongSelf.sendPressed != nil)
            strongSelf.sendPressed(item.asset, false);
    };
    
    mixin.editorOpened = self.editorOpened;
    mixin.editorClosed = self.editorClosed;
}

- (MediaPickerModernGalleryMixin *)galleryMixinForIndexPath:(NSIndexPath *)indexPath previewMode:(bool)previewMode outAsset:(MediaAsset **)outAsset
{
    MediaAsset *asset = [_fetchResult assetAtIndex:indexPath.row];
    if (outAsset != NULL)
        *outAsset = asset;
    
    UIImage *thumbnailImage = nil;
    
    AttachmentAssetCell *cell = (AttachmentAssetCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:[AttachmentAssetCell class]])
        thumbnailImage = cell.imageView.image;
    
    MediaPickerModernGalleryMixin *mixin = [[MediaPickerModernGalleryMixin alloc] initWithItem:asset fetchResult:_fetchResult parentController:self.parentController thumbnailImage:thumbnailImage selectionContext:_selectionContext editingContext:_editingContext suggestionContext:self.suggestionContext hasCaptions:(_allowCaptions && !_forProfilePhoto) inhibitDocumentCaptions:_inhibitDocumentCaptions asFile:false itemsLimit:AttachmentDisplayedAssetLimit];
    
    __weak AttachmentCarouselItemView *weakSelf = self;
    mixin.thumbnailSignalForItem = ^SSignal *(id item)
    {
        __strong AttachmentCarouselItemView *strongSelf = weakSelf;
        if (strongSelf == nil)
            return nil;
        
        return [strongSelf _signalForItem:item refresh:false onlyThumbnail:true];
    };
    
    if (!previewMode)
        [self _setupGalleryMixin:mixin];
    
    return mixin;
}

- (UIView *)referenceViewForAsset:(MediaAsset *)asset
{
    for (AttachmentAssetCell *cell in [_collectionView visibleCells])
    {
        if ([cell.asset isEqual:asset])
            return cell;
    }
    
    return nil;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    MediaAsset *asset = [_fetchResult assetAtIndex:index];
    
    __block UIImage *thumbnailImage = nil;
    if ([MediaAssetsLibrary usesPhotoFramework])
    {
        AttachmentAssetCell *cell = (AttachmentAssetCell *)[collectionView cellForItemAtIndexPath:indexPath];
        if ([cell isKindOfClass:[AttachmentAssetCell class]])
            thumbnailImage = cell.imageView.image;
    }
    else
    {
        [[MediaAssetImageSignals imageForAsset:asset imageType:MediaAssetImageTypeAspectRatioThumbnail size:CGSizeZero] startWithNext:^(UIImage *next)
         {
             thumbnailImage = next;
         }];
    }
    
    __weak AttachmentCarouselItemView *weakSelf = self;
    UIView *(^referenceViewForAsset)(MediaAsset *) = ^UIView *(MediaAsset *asset)
    {
        __strong AttachmentCarouselItemView *strongSelf = weakSelf;
        if (strongSelf != nil)
            return [strongSelf referenceViewForAsset:asset];
        
        return nil;
    };
    
    if (self.openEditor)
    {
        PhotoEditorController *controller = [[PhotoEditorController alloc] initWithItem:asset intent:PhotoEditorControllerAvatarIntent adjustments:nil caption:nil screenImage:thumbnailImage availableTabs:[PhotoEditorController defaultTabsForAvatarIntent] selectedTab:PhotoEditorCropTab];
        controller.editingContext = _editingContext;
        controller.dontHideStatusBar = true;
        
        TGMediaAvatarEditorTransition *transition = [[TGMediaAvatarEditorTransition alloc] initWithController:controller fromView:referenceViewForAsset(asset)];
        
        controller.didFinishRenderingFullSizeImage = ^(UIImage *resultImage)
        {
            __strong AttachmentCarouselItemView *strongSelf = weakSelf;
            
            
            [[strongSelf->_assetsLibrary saveAssetWithImage:resultImage] startWithNext:nil];
        };
        
        __weak PhotoEditorController *weakController = controller;
        controller.didFinishEditing = ^(__unused id<MediaEditAdjustments> adjustments, UIImage *resultImage, __unused UIImage *thumbnailImage, __unused bool hasChanges)
        {
            if (!hasChanges)
                return;
            
            __strong AttachmentCarouselItemView *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            __strong PhotoEditorController *strongController = weakController;
            if (strongController == nil)
                return;
            
            if (strongSelf.avatarCompletionBlock != nil)
                strongSelf.avatarCompletionBlock(resultImage);
            
            [strongController dismissAnimated:true];
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
        
        OverlayControllerWindow *controllerWindow = [[OverlayControllerWindow alloc] initWithParentController:_parentController contentController:controller];
        controllerWindow.hidden = false;
        controller.view.clipsToBounds = true;
        
        transition.referenceFrame = ^CGRect
        {
            UIView *referenceView = referenceViewForAsset(asset);
            return [referenceView.superview convertRect:referenceView.frame toView:nil];
        };
        transition.referenceImageSize = ^CGSize
        {
            return asset.dimensions;
        };
        transition.referenceScreenImageSignal = ^SSignal *
        {
            return [MediaAssetImageSignals imageForAsset:asset imageType:MediaAssetImageTypeFastScreen size:CGSizeMake(640, 640)];
        };
        [transition presentAnimated:true];
        
        controller.beginCustomTransitionOut = ^(CGRect outReferenceFrame, UIView *repView, void (^completion)(void))
        {
            __strong AttachmentCarouselItemView *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            transition.outReferenceFrame = outReferenceFrame;
            transition.repView = repView;
            [transition dismissAnimated:true completion:^
             {
                 strongSelf->_hiddenItem = nil;
                 [strongSelf updateHiddenCellAnimated:false];
                 
                 dispatch_async(dispatch_get_main_queue(), ^
                                {
                                    if (completion != nil)
                                        completion();
                                });
             }];
        };
        
        _hiddenItem = asset;
        [self updateHiddenCellAnimated:false];
    }
    else
    {
        _galleryMixin = [self galleryMixinForIndexPath:indexPath previewMode:false outAsset:NULL];
        [_galleryMixin present];
    }
}

- (NSInteger)collectionView:(UICollectionView *)__unused collectionView numberOfItemsInSection:(NSInteger)__unused section
{
    return MIN(_fetchResult.count, AttachmentDisplayedAssetLimit);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    
    MediaAsset *asset = [_fetchResult assetAtIndex:index];
    NSString *cellIdentifier = nil;
    switch (asset.type)
    {
        case MediaAssetVideoType:
            cellIdentifier = AttachmentVideoCellIdentifier;
            break;
            
        case MediaAssetGifType:
            if (_forProfilePhoto)
                cellIdentifier = AttachmentPhotoCellIdentifier;
            else
                cellIdentifier = AttachmentGifCellIdentifier;
            break;
            
        default:
            cellIdentifier = AttachmentPhotoCellIdentifier;
            break;
    }
    
    AttachmentAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    NSInteger pivotIndex = NSNotFound;
    NSInteger limit = 0;
    if (_pivotInItemIndex != NSNotFound)
    {
        if (self.frame.size.width <= 320)
            limit = 2;
        else
            limit = 3;
        
        pivotIndex = _pivotInItemIndex;
    }
    else if (_pivotOutItemIndex != NSNotFound)
    {
        pivotIndex = _pivotOutItemIndex;
        
        if (self.frame.size.width <= 320)
            limit = 3;
        else
            limit = 5;
    }
    
    if (!(pivotIndex != NSNotFound && (indexPath.row < pivotIndex - limit || indexPath.row > pivotIndex + limit)))
    {
        cell.selectionContext = _selectionContext;
        cell.editingContext = _editingContext;
        
        if (![asset isEqual:cell.asset] || cell.isZoomed != _zoomedIn)
        {
            cell.isZoomed = _zoomedIn;
            [cell setAsset:asset signal:[self _signalForItem:asset refresh:[cell.asset isEqual:asset] onlyThumbnail:false]];
        }
    }
    
    return cell;
}

- (void)updateHiddenCellAnimated:(bool)animated
{
    for (AttachmentAssetCell *cell in [_collectionView visibleCells])
        [cell setHidden:([cell.asset isEqual:_hiddenItem]) animated:animated];
}

#pragma mark -

- (CGSize)collectionView:(UICollectionView *)__unused collectionView layout:(UICollectionViewLayout *)__unused collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_zoomedIn)
    {
        CGSize maxPhotoSize = _maxPhotoSize;
        if (_smallActivated)
            maxPhotoSize = _smallMaxPhotoSize;
        
        if (_pivotInItemIndex != NSNotFound && (indexPath.row < _pivotInItemIndex - 2 || indexPath.row > _pivotInItemIndex + 2))
            return CGSizeMake(maxPhotoSize.height, maxPhotoSize.height);
        
        MediaAsset *asset = [_fetchResult assetAtIndex:indexPath.row];
        if (asset != nil)
        {
            CGSize dimensions = asset.dimensions;
            if (dimensions.width < 1.0f)
                dimensions.width = 1.0f;
            if (dimensions.height < 1.0f)
                dimensions.height = 1.0f;
            
            id<MediaEditAdjustments> adjustments = [_editingContext adjustmentsForItem:asset];
            if ([adjustments cropAppliedForAvatar:false])
            {
                dimensions = adjustments.cropRect.size;
                
                bool sideward = TGOrientationIsSideward(adjustments.cropOrientation, NULL);
                if (sideward)
                    dimensions = CGSizeMake(dimensions.height, dimensions.width);
            }
            
            CGFloat width = MIN(maxPhotoSize.width, ceil(dimensions.width * maxPhotoSize.height / dimensions.height));
            return CGSizeMake(width, maxPhotoSize.height);
        }
        
        return CGSizeMake(maxPhotoSize.height, maxPhotoSize.height);
    }
    
    return AttachmentCellSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)__unused collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)__unused section
{
    CGFloat edgeInset = AttachmentEdgeInset;
    CGFloat leftInset = [self hasCameraInCurrentMode] ? 2 * edgeInset + 84.0f : edgeInset;
    
    CGFloat height = self.frame.size.height;
    
    if (collectionViewLayout == _smallLayout)
        height = [self _preferredHeightForZoomedIn:false progress:1.0f screenHeight:self.screenHeight];
    else if (collectionViewLayout == _largeLayout)
        height = [self _preferredHeightForZoomedIn:true progress:1.0f screenHeight:self.screenHeight];
    
    CGFloat cellHeight = height - 2 * edgeInset;
    CGFloat topInset = _collectionView.frame.size.height - cellHeight - edgeInset;
    CGFloat bottomInset = edgeInset;
    
    return UIEdgeInsetsMake(topInset, leftInset, bottomInset, edgeInset);
}

- (CGFloat)collectionView:(UICollectionView *)__unused collectionView layout:(UICollectionViewLayout *)__unused collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)__unused section
{
    return _smallLayout.minimumLineSpacing;
}

- (UICollectionViewTransitionLayout *)collectionView:(UICollectionView *)__unused collectionView transitionLayoutForOldLayout:(UICollectionViewLayout *)fromLayout newLayout:(UICollectionViewLayout *)toLayout
{
    return [[TransitionLayout alloc] initWithCurrentLayout:fromLayout nextLayout:toLayout];
}

#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)__unused scrollView
{
    if (_zoomingIn)
        return;
    
    if (!_zoomedIn)
        [_preheatMixin update];
    
    for (UICollectionViewCell *cell in _collectionView.visibleCells)
    {
        if ([cell isKindOfClass:[AttachmentAssetCell class]])
            [(AttachmentAssetCell *)cell setNeedsLayout];
    }
}

#pragma mark -

- (void)menuView:(MenuSheetView *)menuView willAppearAnimated:(bool)__unused animated
{
    __weak AttachmentCarouselItemView *weakSelf = self;
    menuView.tapDismissalAllowed = ^bool
    {
        __strong AttachmentCarouselItemView *strongSelf = weakSelf;
        if (strongSelf == nil)
            return true;
        
        return !strongSelf->_collectionView.isDecelerating && !strongSelf->_collectionView.isTracking;
    };
}

- (void)menuView:(MenuSheetView *)menuView willDisappearAnimated:(bool)animated
{
    [super menuView:menuView didDisappearAnimated:animated];
    menuView.tapDismissalAllowed = nil;
    [_cameraView stopPreview];
}

#pragma mark -

- (void)setScreenHeight:(CGFloat)screenHeight
{
    _screenHeight = screenHeight;
    [self _updateSmallActivated];
    
}

- (void)setSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    _sizeClass = sizeClass;
    [self _updateSmallActivated];
}

- (void)_updateSmallActivated
{
    _smallActivated = (fabs(_screenHeight - _smallActivationHeight) < FLT_EPSILON && _sizeClass == UIUserInterfaceSizeClassCompact);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = _collectionView.frame;
    frame.size.width = self.frame.size.width;
    
    frame.size.height = (_smallActivated ? _smallMaxPhotoSize.height : _maxPhotoSize.height) + AttachmentEdgeInset * 2;
    frame.origin.y = self.frame.size.height - frame.size.height;
    
    if (!CGRectEqualToRect(frame, _collectionView.frame))
    {
        bool invalidate = fabs(_collectionView.frame.size.height - frame.size.height) > FLT_EPSILON;
        
        _collectionView.frame = frame;
        
        if (invalidate)
        {
            [_smallLayout invalidateLayout];
            [_largeLayout invalidateLayout];
            [_collectionView layoutSubviews];
        }
    }
    
    CGFloat height = self.frame.size.height;
    CGFloat cellHeight = height - 2 * AttachmentEdgeInset;
    CGFloat topInset = _collectionView.frame.size.height - cellHeight - AttachmentEdgeInset;
    
    frame = _cameraView.frame;
    frame.origin.y = topInset;
    _cameraView.frame = frame;
    
    [self _layoutButtonItemViews];
}

- (void)_layoutButtonItemViews
{
    _sendMediaItemView.frame = CGRectMake(0, [self preferredHeightForWidth:self.frame.size.width screenHeight:self.screenHeight], self.frame.size.width, [_sendMediaItemView preferredHeightForWidth:self.frame.size.width screenHeight:self.screenHeight]);
    _sendFileItemView.frame = CGRectMake(0, CGRectGetMaxY(_sendMediaItemView.frame), self.frame.size.width, [_sendFileItemView preferredHeightForWidth:self.frame.size.width screenHeight:self.screenHeight]);
}

#pragma mark - 

- (UIView *)previewSourceView
{
    return _collectionView;
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
    NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:location];
    if (indexPath == nil)
        return nil;
    
    CGRect cellFrame = [_collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath].frame;
    previewingContext.sourceRect = cellFrame;
    
    MediaAsset *asset = nil;
    _previewGalleryMixin = [self galleryMixinForIndexPath:indexPath previewMode:true outAsset:&asset];
    UIViewController *controller = [_previewGalleryMixin galleryController];
    
    CGSize screenSize = TGScreenSize();
    controller.preferredContentSize = TGFitSize(asset.dimensions, screenSize);
    [_previewGalleryMixin setPreviewMode];
    return controller;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)__unused previewingContext commitViewController:(UIViewController *)__unused viewControllerToCommit
{
    _galleryMixin = _previewGalleryMixin;
    _previewGalleryMixin = nil;
    
    [self _setupGalleryMixin:_galleryMixin];
    [_galleryMixin present];
}

@end
