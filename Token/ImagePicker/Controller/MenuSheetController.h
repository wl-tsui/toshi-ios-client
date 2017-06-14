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

#import "MenuSheetButtonItemView.h"
#import "MenuSheetTitleItemView.h"
#import "ViewController.h"

@class SDisposableSet;

@interface MenuSheetController : UIViewController

@property (nonatomic, strong, readonly) SDisposableSet *disposables;

@property (nonatomic, assign) bool requiuresDimView;
@property (nonatomic, assign) bool dismissesByOutsideTap;
@property (nonatomic, assign) bool hasSwipeGesture;

@property (nonatomic, assign) bool followsKeyboard;

@property (nonatomic, assign) bool narrowInLandscape;
@property (nonatomic, assign) bool inhibitPopoverPresentation;

@property (nonatomic, readonly) NSArray *itemViews;

@property (nonatomic, copy) void (^willPresent)(CGFloat offset);
@property (nonatomic, copy) void (^didDismiss)(bool manual);

@property (nonatomic, assign) UIPopoverArrowDirection permittedArrowDirections;
@property (nonatomic, copy) CGRect (^sourceRect)(void);
@property (nonatomic, readonly) UIView *sourceView;
@property (nonatomic, strong) UIBarButtonItem *barButtonItem;
@property (nonatomic, readonly) UIUserInterfaceSizeClass sizeClass;

@property (nonatomic, readonly) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, readonly) ViewController *parentController;

@property (nonatomic, assign) CGFloat maxHeight;

@property (nonatomic, readonly) CGFloat statusBarHeight;

@property (nonatomic) bool packIsArchived;
@property (nonatomic) bool packIsMask;

- (instancetype)initWithItemViews:(NSArray *)itemViews;
- (void)setItemViews:(NSArray *)itemViews;
- (void)setItemViews:(NSArray *)itemViews animated:(bool)animated;

- (void)presentInViewController:(UIViewController *)viewController sourceView:(UIView *)sourceView animated:(bool)animated;
- (void)dismissAnimated:(bool)animated;
- (void)dismissAnimated:(bool)animated manual:(bool)manual;
- (void)dismissAnimated:(bool)animated manual:(bool)manual completion:(void (^)(void))completion;

@end
