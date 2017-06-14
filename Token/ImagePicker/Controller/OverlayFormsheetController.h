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

@class OverlayFormsheetWindow;

@interface OverlayFormsheetController : UIViewController

@property (nonatomic, weak) OverlayFormsheetWindow *formSheetWindow;
@property (nonatomic, readonly) UIViewController *viewController;

- (instancetype)initWithContentController:(UIViewController *)viewController;
- (void)setContentController:(UIViewController *)viewController;

- (void)animateInWithCompletion:(void (^)(void))completion;
- (void)animateOutWithCompletion:(void (^)(void))completion;

@end
