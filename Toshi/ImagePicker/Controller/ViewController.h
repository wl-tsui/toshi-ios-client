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
#import <SSignalKit/SSignalKit.h>

typedef enum {
    ViewControllerStyleDefault = 0,
    ViewControllerStyleBlack = 1
} ViewControllerStyle;

@class TGLabel;
@class TGNavigationController;
@class TGPopoverController;

typedef enum {
    ViewControllerNavigationBarAnimationNone = 0,
    ViewControllerNavigationBarAnimationSlide = 1,
    ViewControllerNavigationBarAnimationFade = 2,
    ViewControllerNavigationBarAnimationSlideFar = 3
} ViewControllerNavigationBarAnimation;

#define TGEnableNewAppearance true

@protocol ViewControllerNavigationBarAppearance <NSObject>

- (UIBarStyle)requiredNavigationBarStyle;
- (bool)navigationBarShouldBeHidden;

@optional

- (bool)navigationBarHasAction;
- (void)navigationBarAction;
- (void)navigationBarSwipeDownAction;

@optional

- (bool)statusBarShouldBeHidden;
- (UIStatusBarStyle)preferredStatusBarStyle;

@end

@interface ViewController : UIViewController <ViewControllerNavigationBarAppearance>

+ (UIFont *)titleFontForStyle:(ViewControllerStyle)style landscape:(bool)landscape;
+ (UIFont *)titleTitleFontForStyle:(ViewControllerStyle)style landscape:(bool)landscape;
+ (UIFont *)titleSubtitleFontForStyle:(ViewControllerStyle)style landscape:(bool)landscape;
+ (UIColor *)titleTextColorForStyle:(ViewControllerStyle)style;

+ (CGSize)screenSize:(UIDeviceOrientation)orientation;
+ (CGSize)screenSizeForInterfaceOrientation:(UIInterfaceOrientation)orientation;
+ (bool)isWidescreen;
+ (bool)hasLargeScreen;
+ (bool)hasVeryLargeScreen;

+ (void)disableAutorotation;
+ (void)enableAutorotation;
+ (void)disableAutorotationFor:(NSTimeInterval)timeInterval;
+ (void)disableAutorotationFor:(NSTimeInterval)timeInterval reentrant:(bool)reentrant;
+ (bool)autorotationAllowed;
+ (void)attemptAutorotation;

+ (void)disableUserInteractionFor:(NSTimeInterval)timeInterval;

+ (void)setUseExperimentalRTL:(bool)useExperimentalRTL;
+ (bool)useExperimentalRTL;

@property (nonatomic, strong) NSMutableArray *associatedWindowStack;
@property (nonatomic, strong) TGPopoverController *associatedPopoverController;

@property (nonatomic) ViewControllerStyle style;

@property (nonatomic) bool doNotFlipIfRTL;

@property (nonatomic) bool viewControllerIsChangingInterfaceOrientation;
@property (nonatomic) bool viewControllerHasEverAppeared;
@property (nonatomic) bool viewControllerIsAnimatingAppearanceTransition;
@property (nonatomic) bool adjustControllerInsetWhenStartingRotation;
@property (nonatomic) bool dismissPresentedControllerWhenRemovedFromNavigationStack;
@property (nonatomic) bool viewControllerIsAppearing;
@property (nonatomic) bool viewControllerIsDisappearing;

@property (nonatomic, readonly) CGFloat controllerStatusBarHeight;
@property (nonatomic, readonly) UIEdgeInsets controllerCleanInset;
@property (nonatomic, readonly) UIEdgeInsets controllerInset;
@property (nonatomic, readonly) UIEdgeInsets controllerScrollInset;
@property (nonatomic) UIEdgeInsets parentInsets;
@property (nonatomic) UIEdgeInsets explicitTableInset;
@property (nonatomic) UIEdgeInsets explicitScrollIndicatorInset;
@property (nonatomic) CGFloat additionalNavigationBarHeight;
@property (nonatomic) CGFloat additionalStatusBarHeight;

@property (nonatomic) bool navigationBarShouldBeHidden;

@property (nonatomic) bool autoManageStatusBarBackground;
@property (nonatomic) bool automaticallyManageScrollViewInsets;
@property (nonatomic) bool ignoreKeyboardWhenAdjustingScrollViewInsets;

@property (nonatomic, strong) NSArray *scrollViewsForAutomaticInsetsAdjustment;

@property (nonatomic, weak) UIViewController *customParentViewController;

@property (nonatomic, strong) TGNavigationController *customNavigationController;

@property (nonatomic) bool isFirstInStack;

@property (nonatomic, readonly) UIUserInterfaceSizeClass currentSizeClass;

- (void)setExplicitTableInset:(UIEdgeInsets)explicitTableInset scrollIndicatorInset:(UIEdgeInsets)scrollIndicatorInset;

- (void)adjustToInterfaceOrientation:(UIInterfaceOrientation)orientation;
- (UIEdgeInsets)controllerInsetForInterfaceOrientation:(UIInterfaceOrientation)orientation;

- (bool)_updateControllerInset:(bool)force;
- (bool)_updateControllerInsetForOrientation:(UIInterfaceOrientation)orientation force:(bool)force notify:(bool)notify;
- (bool)shouldAdjustScrollViewInsetsForInversedLayout;
- (bool)shouldIgnoreNavigationBar;

- (void)setNavigationBarHidden:(bool)navigationBarHidden animated:(BOOL)animated;
- (void)setNavigationBarHidden:(bool)navigationBarHidden withAnimation:(ViewControllerNavigationBarAnimation)animation;
- (void)setNavigationBarHidden:(bool)navigationBarHidden withAnimation:(ViewControllerNavigationBarAnimation)animation duration:(NSTimeInterval)duration;
- (CGFloat)statusBarBackgroundAlpha;

- (void)setTargetNavigationItem:(UINavigationItem *)targetNavigationItem titleController:(UIViewController *)titleController;
- (void)setLeftBarButtonItem:(UIBarButtonItem *)leftBarButtonItem;
- (void)setLeftBarButtonItem:(UIBarButtonItem *)leftBarButtonItem animated:(BOOL)animated;
- (void)setRightBarButtonItem:(UIBarButtonItem *)rightBarButtonItem;
- (void)setRightBarButtonItem:(UIBarButtonItem *)rightBarButtonItem animated:(BOOL)animated;
- (void)setTitleText:(NSString *)titleText;
- (void)setTitleView:(UIView *)titleView;

- (UIView *)statusBarBackgroundView;
- (void)setStatusBarBackgroundAlpha:(float)alpha;

- (bool)inPopover;
- (bool)inFormSheet;

- (bool)willCaptureInputShortly;

- (UIPopoverController *)popoverController;

- (void)acquireRotationLock;
- (void)releaseRotationLock;

- (void)localizationUpdated;

+ (int)preferredAnimationCurve;

- (CGSize)referenceViewSizeForOrientation:(UIInterfaceOrientation)orientation;
- (UIInterfaceOrientation)currentInterfaceOrientation;

- (void)layoutControllerForSize:(CGSize)size duration:(NSTimeInterval)duration;

@end

@protocol TGDestructableViewController <NSObject>

- (void)cleanupBeforeDestruction;
- (void)cleanupAfterDestruction;

@optional

- (void)contentControllerWillBeDismissed;

@end

@interface TGAutorotationLock : NSObject

@property (nonatomic) int lockId;

@end

