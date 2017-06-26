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

@interface CameraZoomView : UIView

@property (copy, nonatomic) void(^activityChanged)(bool active);

@property (nonatomic, assign) CGFloat zoomLevel;
- (void)setZoomLevel:(CGFloat)zoomLevel displayNeeded:(bool)displayNeeded;

- (void)interactionEnded;

- (bool)isActive;

- (void)hideAnimated:(bool)animated;

@end
