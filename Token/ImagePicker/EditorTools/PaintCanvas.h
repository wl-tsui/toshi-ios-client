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

@class Painting;
@class PaintBrush;
@class PaintState;

@interface PaintCanvas : UIView

@property (nonatomic, strong) Painting *painting;
@property (nonatomic, readonly) PaintState *state;

@property (nonatomic, assign) CGRect cropRect;
@property (nonatomic, assign) UIImageOrientation cropOrientation;
@property (nonatomic, assign) CGSize originalSize;

@property (nonatomic, copy) bool (^shouldDrawOnSingleTap)(void);

@property (nonatomic, copy) bool (^shouldDraw)(void);
@property (nonatomic, copy) void (^strokeBegan)(void);
@property (nonatomic, copy) void (^strokeCommited)(void);
@property (nonatomic, copy) UIView *(^hitTest)(CGPoint point, UIEvent *event);
@property (nonatomic, copy) bool (^pointInsideContainer)(CGPoint point);

@property (nonatomic, readonly) bool isTracking;

- (void)draw;

- (void)setBrush:(PaintBrush *)brush;
- (void)setBrushWeight:(CGFloat)brushWeight;
- (void)setBrushColor:(UIColor *)color;
- (void)setEraser:(bool)eraser;

@end
