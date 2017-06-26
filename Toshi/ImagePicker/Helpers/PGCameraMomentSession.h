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

#import "PGCameraMomentSegment.h"

@class Camera;

@interface PGCameraMomentSession : NSObject

@property (nonatomic, copy) void (^beganCapture)(void);
@property (nonatomic, copy) void (^finishedCapture)(void);
@property (nonatomic, copy) bool (^captureIsAvailable)(void);
@property (nonatomic, copy) void (^durationChanged)(NSTimeInterval);

@property (nonatomic, readonly) bool isCapturing;
@property (nonatomic, readonly) UIImage *previewImage;
@property (nonatomic, readonly) bool hasSegments;

@property (nonatomic, readonly) PGCameraMomentSegment *lastSegment;

- (instancetype)initWithCamera:(Camera *)camera;

- (void)captureSegment;
- (void)commitSegment;

- (void)addSegment:(PGCameraMomentSegment *)segment;
- (void)removeSegment:(PGCameraMomentSegment *)segment;
- (void)removeLastSegment;
- (void)removeAllSegments;

@end
