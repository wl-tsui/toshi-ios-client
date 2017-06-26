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

#import "ViewController.h"
#import "SuggestionContext.h"

@class MediaPickerLayoutMetrics;
@class MediaSelectionContext;
@class MediaEditingContext;
@class MediaPickerSelectionGestureRecognizer;

@interface MediaPickerController : ViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
{
    MediaPickerLayoutMetrics *_layoutMetrics;
    CGFloat _collectionViewWidth;
    UICollectionView *_collectionView;
    UIView *_wrapperView;
    MediaPickerSelectionGestureRecognizer *_selectionGestureRecognizer;
}

@property (nonatomic, strong) SuggestionContext *suggestionContext;
@property (nonatomic, assign) bool localMediaCacheEnabled;
@property (nonatomic, assign) bool captionsEnabled;
@property (nonatomic, assign) bool inhibitDocumentCaptions;
@property (nonatomic, assign) bool shouldStoreAssets;

@property (nonatomic, readonly) MediaSelectionContext *selectionContext;
@property (nonatomic, readonly) MediaEditingContext *editingContext;

@property (nonatomic, copy) void (^catchToolbarView)(bool enabled);

- (instancetype)initWithSelectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext;

- (NSUInteger)_numberOfItems;
- (id)_itemAtIndexPath:(NSIndexPath *)indexPath;
- (SSignal *)_signalForItem:(id)item;
- (NSString *)_cellKindForItem:(id)item;
- (Class)_collectionViewClass;
- (UICollectionViewLayout *)_collectionLayout;

- (void)_hideCellForItem:(id)item animated:(bool)animated;
- (void)_adjustContentOffsetToBottom;

- (void)_setupSelectionGesture;
- (void)_cancelSelectionGestureRecognizer;

@end
