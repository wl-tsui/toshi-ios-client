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

#import "MediaPickerCaptionInputPanel.h"

@class SuggestionContext;

@interface PhotoCaptionInputMixin : NSObject

@property (nonatomic, readonly) MediaPickerCaptionInputPanel *inputPanel;
@property (nonatomic, readonly) UIView *dismissView;

@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;
@property (nonatomic, readonly) CGFloat keyboardHeight;
@property (nonatomic, assign) CGFloat contentAreaHeight;

@property (nonatomic, strong) SuggestionContext *suggestionContext;

@property (nonatomic, copy) UIView *(^panelParentView)(void);

@property (nonatomic, copy) void (^panelFocused)(void);
@property (nonatomic, copy) void (^finishedWithCaption)(NSString *caption);
@property (nonatomic, copy) void (^keyboardHeightChanged)(CGFloat keyboardHeight, NSTimeInterval duration, NSInteger animationCurve);

- (void)createInputPanelIfNeeded;
- (void)beginEditing;
- (void)enableDismissal;

- (void)destroy;

@property (nonatomic, strong) NSString *caption;
- (void)setCaption:(NSString *)caption animated:(bool)animated;

- (void)setCaptionPanelHidden:(bool)hidden animated:(bool)animated;

- (void)updateLayoutWithFrame:(CGRect)frame edgeInsets:(UIEdgeInsets)edgeInsets;

@end
