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

@class PhotoEditorView;
@class PaintingData;

@interface PhotoEditorPreviewView : UIView

@property (nonatomic, readonly) PhotoEditorView *imageView;
@property (nonatomic, readonly) UIImageView *paintingView;

@property (nonatomic, copy) void(^touchedDown)(void);
@property (nonatomic, copy) void(^touchedUp)(void);
@property (nonatomic, copy) void(^interactionEnded)(void);

@property (nonatomic, readonly) bool isTracking;

- (void)setSnapshotImage:(UIImage *)image;
- (void)setSnapshotView:(UIView *)view;
- (void)setPaintingImageWithData:(PaintingData *)values;
- (void)setPaintingHidden:(bool)hidden;

- (void)setSnapshotImageOnTransition:(UIImage *)image;

- (void)setCropRect:(CGRect)cropRect cropOrientation:(UIImageOrientation)cropOrientation cropRotation:(CGFloat)cropRotation cropMirrored:(bool)cropMirrored originalSize:(CGSize)originalSize;

- (UIView *)originalSnapshotView;

- (void)performTransitionInWithCompletion:(void (^)(void))completion;
- (void)setNeedsTransitionIn;
- (void)performTransitionInIfNeeded;

- (void)prepareTransitionFadeView;
- (void)performTransitionFade;

- (void)prepareForTransitionOut;

- (void)performTransitionToCropAnimated:(bool)animated;

@end
