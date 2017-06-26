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

#import <UIKit/UIKit.h>

@class SSignal;
@class MediaSelectionContext;
@class MediaEditingContext;
@protocol MediaSelectableItem;

@interface MediaPickerPhotoStripCell : UICollectionViewCell

@property (nonatomic, strong) MediaSelectionContext *selectionContext;
@property (nonatomic, strong) MediaEditingContext *editingContext;
@property (nonatomic, copy) void (^itemSelected)(id<MediaSelectableItem> item, bool selected, id sender);

- (void)setItem:(NSObject *)item signal:(SSignal *)signal;

@end

extern NSString *const MediaPickerPhotoStripCellKind;
