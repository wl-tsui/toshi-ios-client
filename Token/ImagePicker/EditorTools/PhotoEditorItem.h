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

#import "PhotoEditorToolView.h"
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

@protocol PhotoEditorItem <NSObject>

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *title;

@property (nonatomic, readonly) NSArray *parameters;

@property (nonatomic, readonly) CGFloat defaultValue;
@property (nonatomic, readonly) CGFloat minimumValue;
@property (nonatomic, readonly) CGFloat maximumValue;
@property (nonatomic, readonly) bool segmented;

@property (nonatomic, strong) id value;
@property (nonatomic, strong) id tempValue;
@property (nonatomic, readonly) id displayValue;
@property (nonatomic, readonly) NSString *stringValue;

@property (nonatomic, readonly) bool shouldBeSkipped;
@property (nonatomic, assign) bool beingEdited;
@property (nonatomic, assign) bool disabled;

@property (copy, nonatomic) void(^parametersChanged)(void);

- (UIView <PhotoEditorToolView> *)itemControlViewWithChangeBlock:(void (^)(id newValue, bool animated))changeBlock;
- (UIView <PhotoEditorToolView> *)itemAreaViewWithChangeBlock:(void (^)(id newValue))changeBlock;

- (Class)valueClass;

- (void)updateParameters;

@end
