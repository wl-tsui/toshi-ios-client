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
#import "ModernButton.h"

@interface MediaPickerPhotoCounterButton : UIButton

@property (nonatomic, assign) bool internalHidden;

- (void)setSelectedCount:(NSInteger)count animated:(bool)animated;
- (void)setActiveNumber:(NSInteger)number animated:(bool)animated;
- (void)cancelledProcessingAnimated:(bool)animated completion:(void (^)(void))completion;

- (void)setInternalHidden:(bool)internalHidden animated:(bool)animated completion:(void (^)(void))completion;
- (void)setHidden:(bool)hidden animated:(bool)animated;
- (void)setHidden:(bool)hidden delay:(NSTimeInterval)delay animated:(bool)animated;
- (void)setSelected:(bool)selected animated:(bool)animated;

@end
