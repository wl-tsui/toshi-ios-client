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

@interface PhotoCropScrollView : UIView

@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, assign) CGFloat contentRotation;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, assign) CGFloat maximumZoomScale;
@property (nonatomic, readonly) CGFloat minimumZoomScale;

@property (nonatomic, readonly) CGAffineTransform cropTransform;

@property (nonatomic, readonly) CGRect zoomedRect;
@property (nonatomic, readonly) CGRect availableRect;

@property (nonatomic, weak) UIImageView *imageView;

@property (nonatomic, readonly) bool isTracking;
@property (nonatomic, readonly) bool animating;

@property (nonatomic, copy) bool(^shouldBeginChanging)(void);
@property (nonatomic, copy) void(^didBeginChanging)(void);
@property (nonatomic, copy) void(^didEndChanging)(void);

- (void)setContentRotation:(CGFloat)contentRotation maximize:(bool)maximize resetting:(bool)resetting;
- (void)setContentMirrored:(bool)mirrored;
- (void)translateContentViewWithOffset:(CGPoint)offset;

- (UIView *)setSnapshotViewEnabled:(bool)enabled;
- (void)setPaintingImage:(UIImage *)image;

- (void)zoomToRect:(CGRect)rect withFrame:(CGRect)frame animated:(bool)animated completion:(void (^)(void))completion;
- (void)fitContentInsideBoundsAllowScale:(bool)allowScale animated:(bool)animated completion:(void (^)(void))completion;
- (void)fitContentInsideBoundsAllowScale:(bool)allowScale maximize:(bool)maximize animated:(bool)animated completion:(void (^)(void))completion;

- (void)storeRotationStartValues;
- (void)resetRotationStartValues;

- (void)reset;
- (void)resetAnimatedWithFrame:(CGRect)frame completion:(void (^)(void))completion;

@end
