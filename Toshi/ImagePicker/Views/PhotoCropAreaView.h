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

#import "PhotoCropGridView.h"

@interface PhotoCropAreaView : UIControl

@property (nonatomic, copy) bool(^shouldBeginEditing)(void);
@property (nonatomic, copy) void(^didBeginEditing)(void);
@property (nonatomic, copy) void(^areaChanged)(void);
@property (nonatomic, copy) void(^didEndEditing)(void);

@property (nonatomic, assign) CGFloat aspectRatio;
@property (nonatomic, assign) bool lockAspectRatio;

@property (nonatomic, readonly) bool isTracking;

@property (nonatomic, assign) PhotoCropViewGridMode gridMode;

- (void)setGridMode:(PhotoCropViewGridMode)gridMode animated:(bool)animated;

@end

extern const CGSize PhotoCropCornerControlSize;
