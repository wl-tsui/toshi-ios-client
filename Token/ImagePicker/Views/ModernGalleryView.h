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

#import "ModernGalleryInterfaceView.h"

@class ModernGalleryScrollView;

@interface ModernGalleryView : UIView

@property (nonatomic, copy) bool (^transitionOut)(CGFloat velocity);

@property (nonatomic, strong, readonly) UIView<ModernGalleryInterfaceView> *interfaceView;
@property (nonatomic, strong, readonly) ModernGalleryScrollView *scrollView;

@property (nonatomic, copy) void (^closePressed)();

- (instancetype)initWithFrame:(CGRect)frame itemPadding:(CGFloat)itemPadding interfaceView:(UIView<ModernGalleryInterfaceView> *)interfaceView previewMode:(bool)previewMode previewSize:(CGSize)previewSize;

- (bool)shouldAutorotate;

- (void)showHideInterface;
- (void)hideInterfaceAnimated;
- (void)updateInterfaceVisibility;

- (void)addItemHeaderView:(UIView *)itemHeaderView;
- (void)removeItemHeaderView:(UIView *)itemHeaderView;
- (void)addItemFooterView:(UIView *)itemFooterView;
- (void)removeItemFooterView:(UIView *)itemFooterView;

- (void)simpleTransitionOutWithVelocity:(CGFloat)velocity completion:(void (^)())completion;
- (void)transitionInWithDuration:(NSTimeInterval)duration;
- (void)transitionOutWithDuration:(NSTimeInterval)duration;

- (void)fadeOutWithDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

- (void)setScrollViewVerticalOffset:(CGFloat)offset;

- (void)setPreviewMode:(bool)previewMode;

@end
