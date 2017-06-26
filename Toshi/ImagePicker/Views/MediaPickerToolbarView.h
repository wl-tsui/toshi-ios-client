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

@interface MediaPickerToolbarView : UIView

@property (nonatomic, strong) UIImage *attributionImage;
@property (nonatomic, strong) NSString *leftButtonTitle;
@property (nonatomic, strong) NSString *rightButtonTitle;

@property (nonatomic, copy) void (^leftPressed)(void);
@property (nonatomic, copy) void (^rightPressed)(void);

- (void)setRightButtonHidden:(bool)hidden;
- (void)setRightButtonEnabled:(bool)enabled animated:(bool)animated;
- (void)setSelectedCount:(NSInteger)count animated:(bool)animated;

@end

extern const CGFloat MediaPickerToolbarHeight;
