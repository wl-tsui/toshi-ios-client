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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

@class SSignal;
@class PhotoHistogram;

@protocol PhotoEditorToolView <NSObject>

@property (nonatomic, assign) CGSize actualAreaSize;

@property (nonatomic, copy) void(^valueChanged)(id newValue, bool animated);
@property (nonatomic, strong) id value;

@property (nonatomic, readonly) bool isTracking;
@property (nonatomic, copy) void(^interactionEnded)(void);

@property (nonatomic, assign) bool isLandscape;
@property (nonatomic, assign) CGFloat toolbarLandscapeSize;

- (bool)buttonPressed:(bool)cancelButton;

@optional
- (void)setHistogramSignal:(SSignal *)signal;

@end
