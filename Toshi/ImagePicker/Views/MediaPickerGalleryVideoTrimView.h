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

@interface MediaPickerGalleryVideoTrimView : UIControl

@property (nonatomic, copy) void(^didBeginEditing)(bool start);
@property (nonatomic, copy) void(^startHandleMoved)(CGPoint translation);
@property (nonatomic, copy) void(^endHandleMoved)(CGPoint translation);
@property (nonatomic, copy) void(^didEndEditing)(void);

@property (nonatomic, assign) bool trimmingEnabled;

- (void)setTrimming:(bool)trimming animated:(bool)animated;

@end
