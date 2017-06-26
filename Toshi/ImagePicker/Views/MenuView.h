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

#import "ASWatcher.h"

@interface MenuButtonView : UIButton
@end

@interface MenuView : UIView

@property (nonatomic, assign) bool buttonHighlightDisabled;

@property (nonatomic, strong) NSDictionary *userInfo;
@property (nonatomic, assign) bool multiline;
@property (nonatomic, assign) bool forceArrowOnTop;
@property (nonatomic, assign) CGFloat maxWidth;

- (void)setButtonsAndActions:(NSArray *)buttonsAndActions watcherHandle:(ASHandle *)watcherHandle;

- (void)sizeToFitToWidth:(CGFloat)maxWidth;

@end

@interface MenuContainerView : UIView

@property (nonatomic, strong) MenuView *menuView;

@property (nonatomic, readonly) bool isShowingMenu;
@property (nonatomic) CGRect showingMenuFromRect;

- (void)showMenuFromRect:(CGRect)rect;
- (void)showMenuFromRect:(CGRect)rect animated:(bool)animated;
- (void)hideMenu;

@end
