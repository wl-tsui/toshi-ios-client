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

@class PaintSwatch;

typedef enum
{
    PhotoPaintSettingsViewIconBrush,
    PhotoPaintSettingsViewIconText,
    PhotoPaintSettingsViewIconMirror
} PhotoPaintSettingsViewIcon;

@interface PhotoPaintSettingsView : UIView

@property (nonatomic, copy) void (^beganColorPicking)(void);
@property (nonatomic, copy) void (^changedColor)(PhotoPaintSettingsView *sender, PaintSwatch *swatch);
@property (nonatomic, copy) void (^finishedColorPicking)(PhotoPaintSettingsView *sender, PaintSwatch *swatch);

@property (nonatomic, copy) void (^settingsPressed)(void);
@property (nonatomic, readonly) UIButton *settingsButton;

@property (nonatomic, strong) PaintSwatch *swatch;
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

- (void)setIcon:(PhotoPaintSettingsViewIcon)icon animated:(bool)animated;
- (void)setHighlighted:(bool)highlighted;

+ (UIImage *)landscapeLeftBackgroundImage;
+ (UIImage *)landscapeRightBackgroundImage;
+ (UIImage *)portraitBackgroundImage;

@end

@protocol PhotoPaintPanelView

@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

- (void)present;
- (void)dismissWithCompletion:(void (^)(void))completion;

@end
