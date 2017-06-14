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

@interface PhotoCropView : UIControl

@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) UIImageOrientation cropOrientation;
@property (nonatomic, assign) CGRect cropRect;
@property (nonatomic, assign) CGFloat rotation;
@property (nonatomic, assign) bool mirrored;
@property (nonatomic, readonly) bool hasArbitraryRotation;
@property (nonatomic, readonly) bool isAspectRatioLocked;
@property (nonatomic, readonly) CGFloat lockedAspectRatio;

@property (nonatomic, readonly) bool isTracking;
@property (nonatomic, readonly) bool isAnimating;
@property (nonatomic, readonly) bool isAnimatingRotation;

@property (nonatomic, copy) void(^croppingChanged)(void);
@property (nonatomic, copy) void(^interactionBegan)(void);
@property (nonatomic, copy) void(^interactionEnded)(void);

- (instancetype)initWithOriginalSize:(CGSize)originalSize hasArbitraryRotation:(bool)hasArbitraryRotation;

- (void)setSnapshotImage:(UIImage *)snapshotImage;
- (void)setSnapshotView:(UIView *)snapshotView;
- (void)setPaintingImage:(UIImage *)paintingImage;

- (void)animateTransitionIn;
- (void)animateTransitionOut;
- (void)transitionInFinishedAnimated:(bool)animated completion:(void (^)(void))completion;

- (void)performConfirmAnimated:(bool)animated;
- (void)performConfirmAnimated:(bool)animated updateInterface:(bool)updateInterface;

- (void)setRotation:(CGFloat)rotation animated:(bool)animated;
- (void)rotate90DegreesCCWAnimated:(bool)animated;

- (void)mirror;

- (void)setLockedAspectRatio:(CGFloat)aspectRatio performResize:(bool)performResize animated:(bool)animated;
- (void)unlockAspectRatio;
- (void)resetAnimated:(bool)animated;

- (UIView *)cropSnapshotView;
- (CGRect)cropRectFrameForView:(UIView *)view;
- (UIImage *)croppedImageWithMaxSize:(CGSize)maxSize;

- (void)_layoutRotationView;

@end
