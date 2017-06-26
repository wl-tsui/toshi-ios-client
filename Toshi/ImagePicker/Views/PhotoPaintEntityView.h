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

@class PhotoPaintEntity;
@class PhotoPaintEntitySelectionView;
@class PaintUndoManager;

@interface PhotoPaintEntityView : UIView
{
    NSInteger _entityUUID;
    
    CGFloat _angle;
    CGFloat _scale;
}

@property (nonatomic, readonly) NSInteger entityUUID;

@property (nonatomic, readonly) PhotoPaintEntity *entity;
@property (nonatomic, assign) bool inhibitGestures;

@property (nonatomic, readonly) CGFloat angle;
@property (nonatomic, readonly) CGFloat scale;

@property (nonatomic, copy) bool (^shouldTouchEntity)(PhotoPaintEntityView *);
@property (nonatomic, copy) void (^entityBeganDragging)(PhotoPaintEntityView *);
@property (nonatomic, copy) void (^entityChanged)(PhotoPaintEntityView *);

@property (nonatomic, readonly) bool isTracking;

- (void)pan:(CGPoint)point absolute:(bool)absolute;
- (void)rotate:(CGFloat)angle absolute:(bool)absolute;
- (void)scale:(CGFloat)scale absolute:(bool)absolute;

- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer;

- (bool)precisePointInside:(CGPoint)point;

@property (nonatomic, weak) PhotoPaintEntitySelectionView *selectionView;
- (PhotoPaintEntitySelectionView *)createSelectionView;
- (CGRect)selectionBounds;

@end


@interface PhotoPaintEntitySelectionView : UIView

@property (nonatomic, weak) PhotoPaintEntityView *entityView;

@property (nonatomic, copy) void (^entityRotated)(CGFloat angle);
@property (nonatomic, copy) void (^entityResized)(CGFloat scale);

@property (nonatomic, readonly) bool isTracking;

- (void)update;

- (void)fadeIn;
- (void)fadeOut;

@end
