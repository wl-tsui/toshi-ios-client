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

#import "ImageView.h"
#import "CheckButtonView.h"

@class MediaSelectionContext;
@class MediaEditingContext;

@interface MediaPickerCell : UICollectionViewCell
{
    CheckButtonView *_checkButton;
}

@property (nonatomic, readonly) ImageView *imageView;
- (void)setHidden:(bool)hidden animated:(bool)animated;

@property (nonatomic, strong) MediaSelectionContext *selectionContext;
@property (nonatomic, strong) MediaEditingContext *editingContext;

@property (nonatomic, readonly) NSObject *item;
- (void)setItem:(NSObject *)item signal:(SSignal *)signal;

@end
