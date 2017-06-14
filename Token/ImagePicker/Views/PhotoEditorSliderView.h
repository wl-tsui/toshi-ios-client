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

@interface PhotoEditorSliderView : UIControl

@property (nonatomic, copy) void(^interactionBegan)(void);
@property (nonatomic, copy) void(^interactionEnded)(void);

@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

@property (nonatomic, assign) CGFloat minimumValue;
@property (nonatomic, assign) CGFloat maximumValue;

@property (nonatomic, assign) CGFloat startValue;
@property (nonatomic, assign) CGFloat value;

@property (nonatomic, readonly) bool isTracking;

@property (nonatomic, assign) CGFloat knobPadding;
@property (nonatomic, assign) CGFloat lineSize;
@property (nonatomic, strong) UIColor *backColor;
@property (nonatomic, strong) UIColor *trackColor;

@property (nonatomic, strong) UIImage *knobImage;

@property (nonatomic, assign) NSInteger positionsCount;

- (void)setValue:(CGFloat)value animated:(BOOL)animated;

@end

extern const CGFloat PhotoEditorSliderViewMargin;
