// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "ModernGalleryInterfaceView.h"
#import "ModernGalleryItem.h"

#import "PhotoToolbarView.h"

@class MediaSelectionContext;
@class MediaEditingContext;
@class SuggestionContext;
@class MediaPickerGallerySelectedItemsModel;

@interface MediaPickerGalleryInterfaceView : UIView <ModernGalleryInterfaceView>

@property (nonatomic, copy) void (^captionSet)(id<ModernGalleryItem>, NSString *);
@property (nonatomic, copy) void (^donePressed)(id<ModernGalleryItem>);

@property (nonatomic, copy) void (^photoStripItemSelected)(NSInteger index);

@property (nonatomic, assign) bool hasCaptions;
@property (nonatomic, assign) bool inhibitDocumentCaptions;
@property (nonatomic, assign) bool usesSimpleLayout;
@property (nonatomic, assign) bool hasSwipeGesture;
@property (nonatomic, assign) bool usesFadeOutForDismissal;

@property (nonatomic, readonly) PhotoEditorTab currentTabs;

- (instancetype)initWithFocusItem:(id<ModernGalleryItem>)focusItem selectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext hasSelectionPanel:(bool)hasSelectionPanel;

- (void)setSelectedItemsModel:(MediaPickerGallerySelectedItemsModel *)selectedItemsModel;
- (void)setEditorTabPressed:(void (^)(PhotoEditorTab tab))editorTabPressed;
- (void)setSuggestionContext:(SuggestionContext *)suggestionContext;

- (void)setThumbnailSignalForItem:(SSignal *(^)(id))thumbnailSignalForItem;

- (void)updateSelectionInterface:(NSUInteger)selectedCount counterVisible:(bool)counterVisible animated:(bool)animated;
- (void)updateSelectedPhotosView:(bool)reload incremental:(bool)incremental add:(bool)add index:(NSInteger)index;
- (void)setSelectionInterfaceHidden:(bool)hidden animated:(bool)animated;

- (void)editorTransitionIn;
- (void)editorTransitionOut;

- (void)setToolbarsHidden:(bool)hidden animated:(bool)animated;

- (void)setTabBarUserInteractionEnabled:(bool)enabled;

@end
