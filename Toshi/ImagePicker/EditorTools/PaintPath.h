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
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface PaintPoint : NSObject

@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) CGFloat z;

@property (nonatomic, assign) bool edge;

- (PaintPoint *)add:(PaintPoint *)point;
- (PaintPoint *)subtract:(PaintPoint *)point;
- (PaintPoint *)multiplyByScalar:(CGFloat)scalar;

- (CGFloat)distanceTo:(PaintPoint *)point;
- (PaintPoint *)normalize;

- (CGPoint)CGPoint;

+ (instancetype)pointWithX:(CGFloat)x y:(CGFloat)y z:(CGFloat)z;
+ (instancetype)pointWithCGPoint:(CGPoint)point z:(CGFloat)z;

@end


typedef enum
{
    PaintActionDraw,
    PaintActionErase
} PaintAction;

@class PaintBrush;

@interface PaintPath : NSObject

@property (nonatomic, strong) NSArray *points;

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) PaintAction action;
@property (nonatomic, assign) CGFloat baseWeight;
@property (nonatomic, strong) PaintBrush *brush;

@property (nonatomic, assign) CGFloat remainder;

- (instancetype)initWithPoint:(PaintPoint *)point;
- (instancetype)initWithPoints:(NSArray *)points;
- (void)addPoint:(PaintPoint *)point;

- (NSArray *)flattenedPoints;

@end

