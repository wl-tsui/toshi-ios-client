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

@interface PhotoAvatarCropView : UIView

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, assign) CGRect cropRect;
@property (nonatomic, assign) UIImageOrientation cropOrientation;
@property (nonatomic, assign) bool cropMirrored;

@property (nonatomic, copy) void(^croppingChanged)(void);
@property (nonatomic, copy) void(^interactionEnded)(void);

@property (nonatomic, readonly) bool isTracking;
@property (nonatomic, readonly) bool isAnimating;

- (instancetype)initWithOriginalSize:(CGSize)originalSize screenSize:(CGSize)screenSize;

- (void)setSnapshotImage:(UIImage *)image;
- (void)setSnapshotView:(UIView *)snapshotView;

- (void)_replaceSnapshotImage:(UIImage *)image;

- (void)rotate90DegreesCCWAnimated:(bool)animated;
- (void)mirror;
- (void)resetAnimated:(bool)animated;

- (void)animateTransitionIn;
- (void)animateTransitionOutSwitching:(bool)switching;
- (void)transitionInFinishedFromCamera:(bool)fromCamera;

- (void)invalidateCropRect;

- (void)hideImageForCustomTransition;

- (CGRect)contentFrameForView:(UIView *)view;
- (CGRect)cropRectFrameForView:(UIView *)view;
- (UIImage *)croppedImageWithMaxSize:(CGSize)maxSize;
- (UIView *)cropSnapshotView;

- (void)updateCircleImageWithReferenceSize:(CGSize)referenceSize;

+ (CGSize)areaInsetSize;

@end
