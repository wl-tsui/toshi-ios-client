#import "MediaPickerGalleryInterfaceView.h"

#import "pop/POP.h"
#import <SSignalKit/SSignalKit.h>

#import "Common.h"
#import "Hacks.h"
#import "Font.h"
#import "ImageUtils.h"
#import "PhotoEditorUtils.h"
#import "ObserverProxy.h"

#import "ModernButton.h"

#import "MediaSelectionContext.h"
#import "MediaEditingContext.h"
#import "VideoEditAdjustments.h"
#import "MediaVideoConverter.h"
#import "MediaPickerGallerySelectedItemsModel.h"

#import "ModernGallerySelectableItem.h"
#import "ModernGalleryEditableItem.h"
#import "MediaPickerGalleryPhotoItemView.h"
#import "MediaPickerGalleryVideoItemView.h"

#import "MessageImageViewOverlayView.h"

#import "PhotoEditorTabController.h"
#import "PhotoToolbarView.h"
#import "PhotoEditorButton.h"
#import "CheckButtonView.h"
#import "MediaPickerPhotoCounterButton.h"
#import "MediaPickerPhotoStripView.h"

#import "MenuView.h"

#import "PhotoCaptionInputMixin.h"

@interface MediaPickerGalleryInterfaceView ()
{
    id<ModernGalleryItem> _currentItem;
    __weak ModernGalleryItemView *_currentItemView;
    
    MediaSelectionContext *_selectionContext;
    MediaEditingContext *_editingContext;
    
    NSMutableArray *_itemHeaderViews;
    NSMutableArray *_itemFooterViews;
    
    UIView *_wrapperView;
    UIView *_headerWrapperView;
    PhotoToolbarView *_portraitToolbarView;
    PhotoToolbarView *_landscapeToolbarView;
    
    PhotoCaptionInputMixin *_captionMixin;
    
    ModernButton *_muteButton;
    CheckButtonView *_checkButton;
    MediaPickerPhotoCounterButton *_photoCounterButton;
    
    MediaPickerPhotoStripView *_selectedPhotosView;
    
    SMetaDisposable *_adjustmentsDisposable;
    SMetaDisposable *_captionDisposable;
    SMetaDisposable *_itemAvailabilityDisposable;
    SMetaDisposable *_itemSelectedDisposable;
    
    void (^_closePressed)(void);
    void (^_scrollViewOffsetRequested)(CGFloat offset);
}
@end

@implementation MediaPickerGalleryInterfaceView

- (instancetype)initWithFocusItem:(id<ModernGalleryItem>)focusItem selectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext hasSelectionPanel:(bool)hasSelectionPanel
{
    self = [super initWithFrame:CGRectZero];
    if (self != nil)
    {
        _selectionContext = selectionContext;
        _editingContext = editingContext;
        
        _hasSwipeGesture = true;
        
        _itemHeaderViews = [[NSMutableArray alloc] init];
        _itemFooterViews = [[NSMutableArray alloc] init];
        
        _wrapperView = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:_wrapperView];
        
        _headerWrapperView = [[UIView alloc] init];
        [_wrapperView addSubview:_headerWrapperView];
        
        __weak MediaPickerGalleryInterfaceView *weakSelf = self;
        void(^toolbarCancelPressed)(void) = ^
        {
            __strong MediaPickerGalleryInterfaceView *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            strongSelf->_closePressed();
        };
        void(^toolbarDonePressed)(void) = ^
        {
            __strong MediaPickerGalleryInterfaceView *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            strongSelf->_donePressed(strongSelf->_currentItem);
        };
        
        _portraitToolbarView = [[PhotoToolbarView alloc] initWithBackButtonTitle:TGLocalized(@"Back") doneButtonTitle:TGLocalized(@"Send") accentedDone:false solidBackground:false];
        _portraitToolbarView.cancelPressed = toolbarCancelPressed;
        _portraitToolbarView.donePressed = toolbarDonePressed;
        [_wrapperView addSubview:_portraitToolbarView];

        _landscapeToolbarView = [[PhotoToolbarView alloc] initWithBackButtonTitle:TGLocalized(@"Back") doneButtonTitle:TGLocalized(@"Send") accentedDone:false solidBackground:false];
        _landscapeToolbarView.cancelPressed = toolbarCancelPressed;
        _landscapeToolbarView.donePressed = toolbarDonePressed;
        [_wrapperView addSubview:_landscapeToolbarView];
        
        [_landscapeToolbarView calculateLandscapeSizeForPossibleButtonTitles:@[ TGLocalized(@"Back"), TGLocalized(@"Cancel"), TGLocalized(@"Done"), TGLocalized(@"Send") ]];
        
        static dispatch_once_t onceToken;
        static UIImage *muteBackground;
        dispatch_once(&onceToken, ^
        {
            CGRect rect = CGRectMake(0, 0, 44.0f, 44.0f);
            UIGraphicsBeginImageContextWithOptions(rect.size, false, 0);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context, UIColorRGBA(0x000000, 0.6f).CGColor);
            CGContextFillEllipseInRect(context, CGRectInset(rect, 4, 4));
            
            muteBackground = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        });
        
        _muteButton = [[ModernButton alloc] initWithFrame:CGRectMake(0, 0, 44.0f, 44.0f)];
        _muteButton.hidden = true;
        _muteButton.adjustsImageWhenHighlighted = false;
        [_muteButton setBackgroundImage:muteBackground forState:UIControlStateNormal];
        [_muteButton setImage:[PhotoEditorInterfaceAssets gifIcon] forState:UIControlStateNormal];
        [_muteButton setImage:[PhotoEditorInterfaceAssets gifActiveIcon] forState:UIControlStateSelected];
        [_muteButton setImage:[PhotoEditorInterfaceAssets gifActiveIcon]  forState:UIControlStateSelected | UIControlStateHighlighted];
        [_muteButton addTarget:self action:@selector(toggleSendAsGif) forControlEvents:UIControlEventTouchUpInside];
        [_wrapperView addSubview:_muteButton];
        
        if (_selectionContext != nil)
        {
            _checkButton = [[CheckButtonView alloc] initWithStyle:CheckButtonStyleGallery];
            _checkButton.frame = CGRectMake(self.frame.size.width - 53, 11, _checkButton.frame.size.width, _checkButton.frame.size.height);
            [_checkButton addTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            [_wrapperView addSubview:_checkButton];
        
            if (hasSelectionPanel)
            {
                _selectedPhotosView = [[MediaPickerPhotoStripView alloc] initWithFrame:CGRectZero];
                _selectedPhotosView.selectionContext = _selectionContext;
                _selectedPhotosView.editingContext = _editingContext;
                _selectedPhotosView.itemSelected = ^(NSInteger index)
                {
                    __strong MediaPickerGalleryInterfaceView *strongSelf = weakSelf;
                    if (strongSelf == nil)
                        return;
                    
                    if (strongSelf.photoStripItemSelected != nil)
                        strongSelf.photoStripItemSelected(index);
                };
                _selectedPhotosView.hidden = true;
                [_wrapperView addSubview:_selectedPhotosView];
            }
        
            _photoCounterButton = [[MediaPickerPhotoCounterButton alloc] initWithFrame:CGRectMake(0, 0, 64, 38)];
            [_photoCounterButton addTarget:self action:@selector(photoCounterButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            _photoCounterButton.userInteractionEnabled = false;
            [_wrapperView addSubview:_photoCounterButton];
        }
        
        [self updateEditorButtonsForItem:focusItem animated:false];
        
        _adjustmentsDisposable = [[SMetaDisposable alloc] init];
        _captionDisposable = [[SMetaDisposable alloc] init];
        _itemSelectedDisposable = [[SMetaDisposable alloc] init];
        _itemAvailabilityDisposable = [[SMetaDisposable alloc] init];
        
        _captionMixin = [[PhotoCaptionInputMixin alloc] init];
        _captionMixin.panelParentView = ^UIView *
        {
            __strong MediaPickerGalleryInterfaceView *strongSelf = weakSelf;
            return strongSelf->_wrapperView;
        };
        
        _captionMixin.panelFocused = ^
        {
            __strong MediaPickerGalleryInterfaceView *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            ModernGalleryItemView *currentItemView = strongSelf->_currentItemView;
            if ([currentItemView isKindOfClass:[MediaPickerGalleryVideoItemView class]])
            {
                MediaPickerGalleryVideoItemView *videoItemView = (MediaPickerGalleryVideoItemView *)strongSelf->_currentItemView;
                [videoItemView stop];
            }
            
            [strongSelf setSelectionInterfaceHidden:true animated:true];
            [strongSelf setItemHeaderViewHidden:true animated:true];
        };
        
        _captionMixin.finishedWithCaption = ^(NSString *caption)
        {
            __strong MediaPickerGalleryInterfaceView *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            [strongSelf setSelectionInterfaceHidden:false delay:0.25 animated:true];
            [strongSelf setItemHeaderViewHidden:false animated:true];
            
            if (strongSelf.captionSet != nil)
                strongSelf.captionSet(strongSelf->_currentItem, caption);
            
            [strongSelf updateEditorButtonsForItem:strongSelf->_currentItem animated:false];
        };
        
        _captionMixin.keyboardHeightChanged = ^(CGFloat keyboardHeight, NSTimeInterval duration, NSInteger animationCurve)
        {
            __strong MediaPickerGalleryInterfaceView *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            CGFloat offset = 0.0f;
            if (keyboardHeight > 0)
                offset = -keyboardHeight / 2.0f;
            
            [UIView animateWithDuration:duration delay:0.0f options:animationCurve animations:^
            {
                if (strongSelf->_scrollViewOffsetRequested != nil)
                    strongSelf->_scrollViewOffsetRequested(offset);
            } completion:nil];
        };
        
        [_captionMixin createInputPanelIfNeeded];
    }
    return self;
}

- (void)dealloc
{
    [_adjustmentsDisposable dispose];
    [_captionDisposable dispose];
    [_itemSelectedDisposable dispose];
    [_itemAvailabilityDisposable dispose];
}

- (void)setHasCaptions:(bool)hasCaptions
{
    _hasCaptions = hasCaptions;
    if (!hasCaptions)
        [_captionMixin destroy];
}

- (void)setSuggestionContext:(SuggestionContext *)suggestionContext
{
    _captionMixin.suggestionContext = suggestionContext;
}

- (void)setClosePressed:(void (^)(void))closePressed
{
    _closePressed = [closePressed copy];
}

- (void)setScrollViewOffsetRequested:(void (^)(CGFloat))scrollViewOffsetRequested
{
    _scrollViewOffsetRequested = [scrollViewOffsetRequested copy];
}

- (void)setEditorTabPressed:(void (^)(PhotoEditorTab tab))editorTabPressed
{
    __weak MediaPickerGalleryInterfaceView *weakSelf = self;
    void (^tabPressed)(PhotoEditorTab) = ^(PhotoEditorTab tab)
    {
        __strong MediaPickerGalleryInterfaceView *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        if (tab == PhotoEditorGifTab)
            [strongSelf toggleSendAsGif];
        else
            editorTabPressed(tab);
    };
    _portraitToolbarView.tabPressed = tabPressed;
    _landscapeToolbarView.tabPressed = tabPressed;
}

- (void)setSelectedItemsModel:(MediaPickerGallerySelectedItemsModel *)selectedItemsModel
{
    _selectedPhotosView.selectedItemsModel = selectedItemsModel;
    [_selectedPhotosView reloadData];
    
    if (selectedItemsModel != nil)
        _photoCounterButton.userInteractionEnabled = true;
}

- (void)setUsesSimpleLayout:(bool)usesSimpleLayout
{
    _usesSimpleLayout = usesSimpleLayout;
    _landscapeToolbarView.hidden = usesSimpleLayout;
}

- (void)itemFocused:(id<ModernGalleryItem>)item itemView:(ModernGalleryItemView *)itemView
{
    _currentItem = item;
    _currentItemView = itemView;
    
    CGFloat screenSide = MAX(TGScreenSize().width, TGScreenSize().height);
    UIEdgeInsets screenEdges = UIEdgeInsetsMake((screenSide - self.frame.size.height) / 2, (screenSide - self.frame.size.width) / 2, (screenSide + self.frame.size.height) / 2, (screenSide + self.frame.size.width) / 2);
  
    __weak MediaPickerGalleryInterfaceView *weakSelf = self;
    
    if (_selectionContext != nil)
    {
        _checkButton.frame = [self _checkButtonFrameForOrientation:[self interfaceOrientation] screenEdges:screenEdges hasHeaderView:(itemView.headerView != nil)];
        
        SSignal *signal = nil;
        id<MediaSelectableItem>selectableItem = nil;
        if ([_currentItem conformsToProtocol:@protocol(ModernGallerySelectableItem)])
            selectableItem = ((id<ModernGallerySelectableItem>)_currentItem).selectableMediaItem;
        
        [_checkButton setSelected:[_selectionContext isItemSelected:selectableItem] animated:false];
        signal = [_selectionContext itemInformativeSelectedSignal:selectableItem];
        [_itemSelectedDisposable setDisposable:[signal startWithNext:^(MediaSelectionChange *next)
        {
            __strong MediaPickerGalleryInterfaceView *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            if (next.sender != strongSelf->_checkButton)
                [strongSelf->_checkButton setSelected:next.selected animated:next.animated];
        }]];
    }
    
    [self updateEditorButtonsForItem:item animated:true];
    
    __weak ModernGalleryItemView *weakItemView = itemView;
    [_itemAvailabilityDisposable setDisposable:[[[itemView contentAvailabilityStateSignal] deliverOn:[SQueue mainQueue]] startWithNext:^(id next)
    {
        __strong MediaPickerGalleryInterfaceView *strongSelf = weakSelf;
        __strong ModernGalleryItemView *strongItemView = weakItemView;
        if (strongSelf == nil || strongItemView == nil)
            return;

        bool available = [next boolValue];
        
        NSString *itemId = nil;
        if ([strongItemView.item respondsToSelector:@selector(uniqueId)])
            itemId = [itemView.item performSelector:@selector(uniqueId)];
                      
        NSString *currentId = nil;
        if ([strongSelf->_currentItem respondsToSelector:@selector(uniqueId)])
            currentId = [strongSelf->_currentItem performSelector:@selector(uniqueId)];
        
        if (strongItemView.item == strongSelf->_currentItem || [itemId isEqualToString:currentId])
        {
            [strongSelf->_portraitToolbarView setEditButtonsEnabled:available animated:true];
            [strongSelf->_landscapeToolbarView setEditButtonsEnabled:available animated:true];
            
            strongSelf->_muteButton.hidden = ![strongItemView isKindOfClass:[MediaPickerGalleryVideoItemView class]];
        }
    }]];
}

- (PhotoEditorTab)currentTabs
{
    return _portraitToolbarView.currentTabs;
}

- (void)setTabBarUserInteractionEnabled:(bool)enabled
{
    _portraitToolbarView.userInteractionEnabled = enabled;
    _landscapeToolbarView.userInteractionEnabled = enabled;
}

- (void)setThumbnailSignalForItem:(SSignal *(^)(id))thumbnailSignalForItem
{
    [_selectedPhotosView setThumbnailSignalForItem:thumbnailSignalForItem];
}

- (void)checkButtonPressed
{
    if (_currentItem == nil)
        return;
    
    bool animated = false;
    if (!_selectedPhotosView.isAnimating)
    {
        animated = true;
    }

    id<MediaSelectableItem>selectableItem = nil;
    if ([_currentItem conformsToProtocol:@protocol(ModernGallerySelectableItem)])
        selectableItem = ((id<ModernGallerySelectableItem>)_currentItem).selectableMediaItem;
    
    [_checkButton setSelected:!_checkButton.selected animated:true];
    
    if (selectableItem != nil)
        [_selectionContext setItem:selectableItem selected:_checkButton.selected animated:animated sender:_checkButton];
}

- (void)photoCounterButtonPressed
{
    [_photoCounterButton setSelected:!_photoCounterButton.selected animated:true];
    [_selectedPhotosView setHidden:!_photoCounterButton.selected animated:true];
}

- (void)updateEditorButtonsForItem:(id<ModernGalleryItem>)item animated:(bool)animated
{
    if (_editingContext == nil || _editingContext.inhibitEditing)
    {
        [_portraitToolbarView setEditButtonsHidden:true animated:false];
        [_landscapeToolbarView setEditButtonsHidden:true animated:false];
        return;
    }
    
    PhotoEditorTab tabs = PhotoEditorNoneTab;
    if ([item conformsToProtocol:@protocol(ModernGalleryEditableItem)])
        tabs = [(id<ModernGalleryEditableItem>)item toolbarTabs];
    
    if (!self.hasCaptions)
        tabs &= ~PhotoEditorCaptionTab;
    
    [_portraitToolbarView setToolbarTabs:tabs animated:animated];
    [_landscapeToolbarView setToolbarTabs:tabs animated:animated];
    
    bool editButtonsHidden = ![item conformsToProtocol:@protocol(ModernGalleryEditableItem)];
    [_portraitToolbarView setEditButtonsHidden:editButtonsHidden animated:animated];
    [_landscapeToolbarView setEditButtonsHidden:editButtonsHidden animated:animated];
    
    if (editButtonsHidden)
    {
        [_adjustmentsDisposable setDisposable:nil];
        [_captionDisposable setDisposable:nil];
        return;
    }
    
    id<ModernGalleryEditableItem> galleryEditableItem = (id<ModernGalleryEditableItem>)item;
    if ([item conformsToProtocol:@protocol(ModernGalleryEditableItem)])
    {
        id<MediaEditableItem> editableMediaItem = [galleryEditableItem editableMediaItem];
        
        __weak MediaPickerGalleryInterfaceView *weakSelf = self;
        [_adjustmentsDisposable setDisposable:[[[galleryEditableItem.editingContext adjustmentsSignalForItem:editableMediaItem] deliverOn:[SQueue mainQueue]] startWithNext:^(id<MediaEditAdjustments> adjustments)
        {
            __strong MediaPickerGalleryInterfaceView *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            if ([adjustments isKindOfClass:[VideoEditAdjustments class]])
            {
                VideoEditAdjustments *videoAdjustments = (VideoEditAdjustments *)adjustments;
                [strongSelf->_captionMixin setCaptionPanelHidden:(videoAdjustments.sendAsGif && strongSelf->_inhibitDocumentCaptions) animated:true];
            }
            else
            {
                [strongSelf->_captionMixin setCaptionPanelHidden:false animated:true];
            }

            [strongSelf updateEditorButtonsForAdjustments:adjustments dimensions:editableMediaItem.originalSize];
        }]];
        
        [_captionDisposable setDisposable:[[galleryEditableItem.editingContext captionSignalForItem:editableMediaItem] startWithNext:^(NSString *caption)
        {
            __strong MediaPickerGalleryInterfaceView *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            [strongSelf->_captionMixin setCaption:caption animated:animated];
        }]];
    }
    else
    {
        [_adjustmentsDisposable setDisposable:nil];
        [_captionDisposable setDisposable:nil];
        [self updateEditorButtonsForAdjustments:nil dimensions:CGSizeZero];
        [_captionMixin setCaption:nil animated:animated];
    }
}

- (void)updateEditorButtonsForAdjustments:(id<MediaEditAdjustments>)adjustments dimensions:(CGSize)dimensions
{
    PhotoEditorTab highlightedButtons = [PhotoEditorTabController highlightedButtonsForEditorValues:adjustments forAvatar:false];
    [_portraitToolbarView setEditButtonsHighlighted:highlightedButtons];
    [_landscapeToolbarView setEditButtonsHighlighted:highlightedButtons];
    
    if ([adjustments isKindOfClass:[MediaVideoEditAdjustments class]])
        _muteButton.selected = ((MediaVideoEditAdjustments *)adjustments).sendAsGif;
    
    PhotoEditorButton *qualityButton = [_portraitToolbarView buttonForTab:PhotoEditorQualityTab];
    if (qualityButton != nil)
    {
        MediaVideoConversionPreset preset = 0;
        MediaVideoConversionPreset adjustmentsPreset = MediaVideoConversionPresetCompressedDefault;
        if ([adjustments isKindOfClass:[MediaVideoEditAdjustments class]])
            adjustmentsPreset = ((MediaVideoEditAdjustments *)adjustments).preset;
        
        if (adjustmentsPreset != MediaVideoConversionPresetCompressedDefault)
        {
            preset = adjustmentsPreset;
        }
        else
        {
            NSNumber *presetValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"TG_preferredVideoPreset_v0"];
            if (presetValue != nil)
                preset = (MediaVideoConversionPreset)[presetValue integerValue];
            else
                preset = MediaVideoConversionPresetCompressedMedium;
        }
        
        MediaVideoConversionPreset bestPreset = [MediaVideoConverter bestAvailablePresetForDimensions:dimensions];
        if (preset > bestPreset)
            preset = bestPreset;
        
        UIImage *icon = [PhotoEditorInterfaceAssets qualityIconForPreset:preset];
        qualityButton.iconImage = icon;
        
        qualityButton = [_landscapeToolbarView buttonForTab:PhotoEditorQualityTab];
        qualityButton.iconImage = icon;
    }
}

- (void)updateSelectionInterface:(NSUInteger)selectedCount counterVisible:(bool)counterVisible animated:(bool)animated
{
    if (counterVisible)
    {
        bool animateCount = animated && !(counterVisible && _photoCounterButton.internalHidden);
        [_photoCounterButton setSelectedCount:selectedCount animated:animateCount];
        [_photoCounterButton setInternalHidden:false animated:animated completion:nil];
    }
    else
    {
        __weak MediaPickerPhotoCounterButton *weakButton = _photoCounterButton;
        [_photoCounterButton setInternalHidden:true animated:animated completion:^
        {
            __strong MediaPickerPhotoCounterButton *strongButton = weakButton;
            if (strongButton != nil)
            {
                strongButton.selected = false;
                [strongButton setSelectedCount:selectedCount animated:false];
            }
        }];
        [_selectedPhotosView setHidden:true animated:animated];
    }
}

- (void)updateSelectedPhotosView:(bool)reload incremental:(bool)incremental add:(bool)add index:(NSInteger)index
{
    if (_selectedPhotosView == nil)
        return;
    
    if (!reload)
        return;
    
    if (incremental)
    {
        if (add)
            [_selectedPhotosView insertItemAtIndex:index];
        else
            [_selectedPhotosView deleteItemAtIndex:index];
    }
    else
    {
        [_selectedPhotosView reloadData];
    }
}

- (void)setSelectionInterfaceHidden:(bool)hidden animated:(bool)animated
{
    [self setSelectionInterfaceHidden:hidden delay:0 animated:animated];
}

- (void)setSelectionInterfaceHidden:(bool)hidden delay:(NSTimeInterval)__unused delay animated:(bool)animated
{
    CGFloat alpha = (hidden ? 0.0f : 1.0f);
    if (animated)
    {
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState animations:^
        {
            _checkButton.alpha = alpha;
            _muteButton.alpha = alpha;
        } completion:^(BOOL finished)
        {
            if (finished)
            {
                _checkButton.userInteractionEnabled = !hidden;
                _muteButton.userInteractionEnabled = !hidden;
            }
        }];
    }
    else
    {
        _checkButton.alpha = alpha;
        _checkButton.userInteractionEnabled = !hidden;
        
        _muteButton.alpha = alpha;
        _muteButton.userInteractionEnabled = !hidden;
    }
    
    if (hidden)
    {
        [_photoCounterButton setSelected:false animated:animated];
        [_selectedPhotosView setHidden:true animated:animated];
    }
    
    [_photoCounterButton setHidden:hidden delay:delay animated:animated];
}

#pragma mark - 

- (void)setItemHeaderViewHidden:(bool)hidden animated:(bool)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.2f animations:^
        {
            for (UIView *view in _itemHeaderViews)
            {
                if (!view.hidden)
                    view.alpha = hidden ? 0.0f : 1.0f;
            }
        } completion:^(BOOL finished)
        {
            if (finished)
            {
                for (UIView *view in _itemHeaderViews)
                {
                    if (!view.hidden)
                        view.userInteractionEnabled = !hidden;
                }
            }
        }];
    }
    else
    {
        for (UIView *view in _itemHeaderViews)
        {
            if (!view.hidden)
            {
                view.alpha = hidden ? 0.0f : 1.0f;
                view.userInteractionEnabled = !hidden;
            }
        }
    }
}

- (void)toggleSendAsGif
{
    if (![_currentItem conformsToProtocol:@protocol(ModernGalleryEditableItem)])
        return;
    
    ModernGalleryItemView *currentItemView = _currentItemView;
    if ([currentItemView isKindOfClass:[MediaPickerGalleryVideoItemView class]])
        [(MediaPickerGalleryVideoItemView *)currentItemView toggleSendAsGif];
}

- (CGRect)itemFooterViewFrameForSize:(CGSize)size
{
    CGFloat padding = 44.0f;
    
    return CGRectMake(padding, 0.0f, size.width - padding * 2.0f, 44.0f);
}

- (void)addItemHeaderView:(UIView *)itemHeaderView
{
    if (itemHeaderView == nil)
        return;
    
    [_itemHeaderViews addObject:itemHeaderView];
    [_headerWrapperView addSubview:itemHeaderView];
    itemHeaderView.frame = _headerWrapperView.bounds;
}

- (void)removeItemHeaderView:(UIView *)itemHeaderView
{
    if (itemHeaderView == nil)
        return;
    
    [itemHeaderView removeFromSuperview];
    [_itemHeaderViews removeObject:itemHeaderView];
}

- (void)addItemFooterView:(UIView *)itemFooterView
{
    if (itemFooterView == nil)
        return;
    
    [_itemFooterViews addObject:itemFooterView];
    [_portraitToolbarView addSubview:itemFooterView];
    itemFooterView.frame = [self itemFooterViewFrameForSize:self.frame.size];
}

- (void)removeItemFooterView:(UIView *)itemFooterView
{
    if (itemFooterView == nil)
        return;
    
    [itemFooterView removeFromSuperview];
    [_itemFooterViews removeObject:itemFooterView];
}

- (void)addItemLeftAcessoryView:(UIView *)__unused itemLeftAcessoryView
{
    
}

- (void)removeItemLeftAcessoryView:(UIView *)__unused itemLeftAcessoryView
{
    
}

- (void)addItemRightAcessoryView:(UIView *)__unused itemRightAcessoryView
{
    
}

- (void)removeItemRightAcessoryView:(UIView *)__unused itemRightAcessoryView
{
    
}

- (void)animateTransitionInWithDuration:(NSTimeInterval)__unused dutation
{
    
}

- (void)animateTransitionOutWithDuration:(NSTimeInterval)__unused dutation
{
    
}

- (void)setTransitionOutProgress:(CGFloat)transitionOutProgress
{
    if (transitionOutProgress > FLT_EPSILON)
        [self setSelectionInterfaceHidden:true animated:true];
    else
        [self setSelectionInterfaceHidden:false animated:true];
}

- (void)setToolbarsHidden:(bool)hidden animated:(bool)animated
{
    if (hidden)
    {
        [_portraitToolbarView transitionOutAnimated:animated transparent:true hideOnCompletion:false];
        [_landscapeToolbarView transitionOutAnimated:animated transparent:true hideOnCompletion:false];
    }
    else
    {
        [_portraitToolbarView transitionInAnimated:animated transparent:true];
        [_landscapeToolbarView transitionInAnimated:animated transparent:true];
    }
}

- (void)editorTransitionIn
{
    [self setSelectionInterfaceHidden:true animated:true];
    
    [UIView animateWithDuration:0.2 animations:^
    {
        _captionMixin.inputPanel.alpha = 0.0f;
    }];
}

- (void)editorTransitionOut
{
    [self setSelectionInterfaceHidden:false animated:true];
    
    [UIView animateWithDuration:0.3 animations:^
    {
        _captionMixin.inputPanel.alpha = 1.0f;
    }];
}

#pragma mark -

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    
    if (view == _photoCounterButton
        || view == _checkButton
        || view == _muteButton
        || [view isDescendantOfView:_headerWrapperView]
        || [view isDescendantOfView:_portraitToolbarView]
        || [view isDescendantOfView:_landscapeToolbarView]
        || [view isDescendantOfView:_selectedPhotosView]
        || [view isDescendantOfView:_captionMixin.inputPanel]
        || [view isDescendantOfView:_captionMixin.dismissView]
        || [view isKindOfClass:[MenuButtonView class]])
        
    {
        return view;
    }
    
    return nil;
}

- (bool)prefersStatusBarHidden
{
    return true;
}

- (bool)allowsHide
{
    return true;
}

- (bool)showHiddenInterfaceOnScroll
{
    return true;
}

- (bool)allowsDismissalWithSwipeGesture
{
    return self.hasSwipeGesture;
}

- (bool)shouldAutorotate
{
    return true;
}

- (CGRect)_muteButtonFrameForOrientation:(UIInterfaceOrientation)orientation screenEdges:(UIEdgeInsets)screenEdges hasHeaderView:(bool)hasHeaderView
{
    CGRect frame = CGRectZero;
    switch (orientation)
    {
        case UIInterfaceOrientationLandscapeLeft:
            frame = CGRectMake(screenEdges.right - 52, screenEdges.bottom - 54 - 64, _muteButton.frame.size.width, _muteButton.frame.size.height);
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            frame = CGRectMake(screenEdges.left + 10, screenEdges.bottom - 54 - 64, _muteButton.frame.size.width, _muteButton.frame.size.height);
            break;
            
        default:
            frame = CGRectMake(screenEdges.left + 10, screenEdges.top + 10, _muteButton.frame.size.width, _muteButton.frame.size.height);
            break;
    }
    
    if (hasHeaderView)
        frame.origin.y += 64;
    
    return frame;
}

- (CGRect)_checkButtonFrameForOrientation:(UIInterfaceOrientation)orientation screenEdges:(UIEdgeInsets)screenEdges hasHeaderView:(bool)hasHeaderView
{
    CGRect frame = CGRectZero;
    switch (orientation)
    {
        case UIInterfaceOrientationLandscapeLeft:
            frame = CGRectMake(screenEdges.right - 53, screenEdges.top + 11, _checkButton.frame.size.width, _checkButton.frame.size.height);
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            frame = CGRectMake(screenEdges.left + 11, screenEdges.top + 11, _checkButton.frame.size.width, _checkButton.frame.size.height);
            break;
            
        default:
            frame = CGRectMake(screenEdges.right - 53, screenEdges.top + 11, _checkButton.frame.size.width, _checkButton.frame.size.height);
            break;
    }
    
    if (hasHeaderView)
        frame.origin.y += 64;
    
    return frame;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)__unused duration
{
    _landscapeToolbarView.interfaceOrientation = toInterfaceOrientation;
    [self setNeedsLayout];
}

- (UIInterfaceOrientation)interfaceOrientation
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (self.usesSimpleLayout || TGIsPad())
        orientation = UIInterfaceOrientationPortrait;
    
    return orientation;
}

- (CGSize)referenceViewSize
{
    return [UIScreen mainScreen].bounds.size;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [_captionMixin setContentAreaHeight:self.frame.size.height];
    
    UIInterfaceOrientation orientation = [self interfaceOrientation];
    CGSize screenSize = TGScreenSize();
    if (TGIsPad())
        screenSize = [self referenceViewSize];
    
    CGFloat screenSide = MAX(screenSize.width, screenSize.height);
    UIEdgeInsets screenEdges = UIEdgeInsetsZero;
    
    if (TGIsPad())
    {
        _landscapeToolbarView.hidden = true;
        screenEdges = UIEdgeInsetsMake(0, 0, self.frame.size.height, self.frame.size.width);
        _wrapperView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    }
    else
    {
        screenEdges = UIEdgeInsetsMake((screenSide - self.frame.size.height) / 2, (screenSide - self.frame.size.width) / 2, (screenSide + self.frame.size.height) / 2, (screenSide + self.frame.size.width) / 2);
        _wrapperView.frame = CGRectMake((self.frame.size.width - screenSide) / 2, (self.frame.size.height - screenSide) / 2, screenSide, screenSide);
    }
    
    _selectedPhotosView.interfaceOrientation = orientation;
    
    CGFloat photosViewSize = PhotoThumbnailSizeForCurrentScreen().height + 4 * 2;
    
    bool hasHeaderView = (_currentItemView.headerView != nil);
    CGFloat headerInset = hasHeaderView ? 64.0f : 0.0f;
    
    CGFloat portraitToolbarViewBottomEdge = screenSide;
    if (self.usesSimpleLayout || TGIsPad())
        portraitToolbarViewBottomEdge = screenEdges.bottom;
    _portraitToolbarView.frame = CGRectMake(screenEdges.left, portraitToolbarViewBottomEdge - PhotoEditorToolbarSize, self.frame.size.width, PhotoEditorToolbarSize);
    
    UIEdgeInsets captionEdgeInsets = screenEdges;
    captionEdgeInsets.bottom = _portraitToolbarView.frame.size.height;
    [_captionMixin updateLayoutWithFrame:self.bounds edgeInsets:captionEdgeInsets];
    
    switch (orientation)
    {
        case UIInterfaceOrientationLandscapeLeft:
        {
            [UIView performWithoutAnimation:^
            {
                _photoCounterButton.frame = CGRectMake(screenEdges.left + [_landscapeToolbarView landscapeSize] + 1, screenEdges.top + 14 + headerInset, 64, 38);
                
                _selectedPhotosView.frame = CGRectMake(screenEdges.left + [_landscapeToolbarView landscapeSize] + 66, screenEdges.top + 4 + headerInset, photosViewSize, self.frame.size.height - 4 * 2 - headerInset);
                
                _landscapeToolbarView.frame = CGRectMake(screenEdges.left, screenEdges.top, [_landscapeToolbarView landscapeSize], self.frame.size.height);
            }];
            
            _headerWrapperView.frame = CGRectMake([_landscapeToolbarView landscapeSize] + screenEdges.left, screenEdges.top, self.frame.size.width - [_landscapeToolbarView landscapeSize], 64);
        }
            break;
            
        case UIInterfaceOrientationLandscapeRight:
        {
            [UIView performWithoutAnimation:^
            {
                _photoCounterButton.frame = CGRectMake(screenEdges.right - [_landscapeToolbarView landscapeSize] - 64 - 1, screenEdges.top + 14 + headerInset, 64, 38);
                
                _selectedPhotosView.frame = CGRectMake(screenEdges.right - [_landscapeToolbarView landscapeSize] - photosViewSize - 66, screenEdges.top + 4 + headerInset, photosViewSize, self.frame.size.height - 4 * 2 - headerInset);
                
                _landscapeToolbarView.frame = CGRectMake(screenEdges.right - [_landscapeToolbarView landscapeSize], screenEdges.top, [_landscapeToolbarView landscapeSize], self.frame.size.height);
            }];
            
            _headerWrapperView.frame = CGRectMake(screenEdges.left, screenEdges.top, self.frame.size.width - [_landscapeToolbarView landscapeSize], 64);
        }
            break;
            
        default:
        {
//            [UIView performWithoutAnimation:^
//            {
//                _photoCounterButton.frame = CGRectMake(screenEdges.right - 64, screenEdges.bottom - PhotoEditorToolbarSize - [_captionMixin.inputPanel baseHeight] - 38 - 14, 64, 38);
//                
//                _selectedPhotosView.frame = CGRectMake(screenEdges.left + 4, screenEdges.bottom - PhotoEditorToolbarSize - [_captionMixin.inputPanel baseHeight] - photosViewSize - 66, self.frame.size.width - 4 * 2, photosViewSize);
//            }];
            
            _landscapeToolbarView.frame = CGRectMake(_landscapeToolbarView.frame.origin.x, screenEdges.top, [_landscapeToolbarView landscapeSize], self.frame.size.height);
            
            _headerWrapperView.frame = CGRectMake(screenEdges.left, screenEdges.top, self.frame.size.width, 64);
        }
            break;
    }
    
    _muteButton.frame = [self _muteButtonFrameForOrientation:orientation screenEdges:screenEdges hasHeaderView:true];
    _checkButton.frame = [self _checkButtonFrameForOrientation:orientation screenEdges:screenEdges hasHeaderView:hasHeaderView];
    
    for (UIView *itemHeaderView in _itemHeaderViews)
        itemHeaderView.frame = _headerWrapperView.bounds;
    
    CGRect itemFooterViewFrame = [self itemFooterViewFrameForSize:self.frame.size];
    for (UIView *itemFooterView in _itemFooterViews)
        itemFooterView.frame = itemFooterViewFrame;
}

@end
