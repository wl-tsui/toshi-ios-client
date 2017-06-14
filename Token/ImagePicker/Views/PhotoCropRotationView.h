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

@interface PhotoCropRotationView : UIControl

@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;
@property (nonatomic, assign) CGFloat angle;

@property (nonatomic, readonly) bool isTracking;

@property (nonatomic, copy) bool(^shouldBeginChanging)(void);
@property (nonatomic, copy) void(^didBeginChanging)(void);
@property (nonatomic, copy) void(^angleChanged)(CGFloat angle, bool resetting);
@property (nonatomic, copy) void(^didEndChanging)(void);

- (void)setAngle:(CGFloat)angle animated:(bool)animated;
- (void)resetAnimated:(bool)animated;

@end
