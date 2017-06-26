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

@class MenuSheetView;
@class MenuSheetController;

typedef enum
{
    MenuSheetItemTypeDefault,
    MenuSheetItemTypeHeader,
    MenuSheetItemTypeFooter
} MenuSheetItemType;

@interface MenuSheetItemView : UIView <UIViewControllerPreviewingDelegate>
{
    CGFloat _screenHeight;
    UIUserInterfaceSizeClass _sizeClass;
}

@property (nonatomic, weak) MenuSheetController *menuController;
@property (nonatomic, readonly) MenuSheetItemType type;

- (instancetype)initWithType:(MenuSheetItemType)type;

- (void)setHidden:(bool)hidden animated:(bool)animated;

@property (nonatomic, readonly) CGFloat contentHeightCorrection;
- (CGFloat)preferredHeightForWidth:(CGFloat)width screenHeight:(CGFloat)screenHeight;

@property (nonatomic, assign) bool requiresDivider;
@property (nonatomic, assign) bool requiresClearBackground;

@property (nonatomic, assign) bool handlesPan;
- (bool)passPanOffset:(CGFloat)offset;
@property (nonatomic, readonly) bool inhibitPan;

@property (nonatomic, readonly) UIView *previewSourceView;

@property (nonatomic, assign) bool condensable;
@property (nonatomic, assign) bool distractable;
@property (nonatomic, assign) bool overflow;

@property (nonatomic, assign) CGFloat screenHeight;
@property (nonatomic, assign) UIUserInterfaceSizeClass sizeClass;

@property (nonatomic, copy) void (^layoutUpdateBlock)(void);
- (void)requestMenuLayoutUpdate;

@property (nonatomic, copy) void (^highlightUpdateBlock)(bool highlighted);

@property (nonatomic, copy) void (^handleInternalPan)(UIPanGestureRecognizer *);

- (void)_updateHeightAnimated:(bool)animated;
- (void)_didLayoutSubviews;

- (void)_willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration;
- (void)_didRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation;

- (void)didChangeAbsoluteFrame;

- (void)menuView:(MenuSheetView *)menuView willAppearAnimated:(bool)animated;
- (void)menuView:(MenuSheetView *)menuView didAppearAnimated:(bool)animated;
- (void)menuView:(MenuSheetView *)menuView willDisappearAnimated:(bool)animated;
- (void)menuView:(MenuSheetView *)menuView didDisappearAnimated:(bool)animated;

@end
