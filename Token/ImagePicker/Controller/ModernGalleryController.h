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

#import "OverlayController.h"

@class ModernGalleryModel;
@protocol ModernGalleryItem;
@class ModernGalleryItemView;

typedef enum {
    ModernGalleryScrollAnimationDirectionDefault,
    ModernGalleryScrollAnimationDirectionLeft,
    ModernGalleryScrollAnimationDirectionRight
} ModernGalleryScrollAnimationDirection;

@interface ModernGalleryController : OverlayController

@property (nonatomic) UIStatusBarStyle defaultStatusBarStyle;
@property (nonatomic) bool shouldAnimateStatusBarStyleTransition;

@property (nonatomic, strong) ModernGalleryModel *model;
@property (nonatomic, assign) bool animateTransition;
@property (nonatomic, assign) bool asyncTransitionIn;
@property (nonatomic, assign) bool showInterface;
@property (nonatomic, assign) bool adjustsStatusBarVisibility;
@property (nonatomic, assign) bool hasFadeOutTransition;
@property (nonatomic, assign) bool previewMode;
 
@property (nonatomic, copy) void (^itemFocused)(id<ModernGalleryItem>);
@property (nonatomic, copy) UIView *(^beginTransitionIn)(id<ModernGalleryItem>, ModernGalleryItemView *);
@property (nonatomic, copy) void (^startedTransitionIn)();
@property (nonatomic, copy) void (^finishedTransitionIn)(id<ModernGalleryItem>, ModernGalleryItemView *);
@property (nonatomic, copy) UIView *(^beginTransitionOut)(id<ModernGalleryItem>, ModernGalleryItemView *);
@property (nonatomic, copy) void (^completedTransitionOut)();

- (NSArray *)visibleItemViews;
- (ModernGalleryItemView *)itemViewForItem:(id<ModernGalleryItem>)item;
- (id<ModernGalleryItem>)currentItem;

- (void)setCurrentItemIndex:(NSUInteger)index animated:(bool)animated;
- (void)setCurrentItemIndex:(NSUInteger)index direction:(ModernGalleryScrollAnimationDirection)direction animated:(bool)animated;

- (void)dismissWhenReady;

- (bool)isFullyOpaque;

@end
