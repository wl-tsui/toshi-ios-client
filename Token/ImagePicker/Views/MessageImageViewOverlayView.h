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

typedef enum {
    MessageImageViewOverlayStyleDefault = 0,
    MessageImageViewOverlayStyleAccent = 1,
    MessageImageViewOverlayStyleList = 2,
    MessageImageViewOverlayStyleIncoming = 3,
    MessageImageViewOverlayStyleOutgoing = 4
} MessageImageViewOverlayStyle;

@interface MessageImageViewOverlayView : UIView

@property (nonatomic, readonly) CGFloat progress;

- (void)setRadius:(CGFloat)radius;
- (void)setOverlayBackgroundColorHint:(UIColor *)overlayBackgroundColorHint;
- (void)setOverlayStyle:(MessageImageViewOverlayStyle)overlayStyle;
- (void)setBlurredBackgroundImage:(UIImage *)blurredBackgroundImage;
- (void)setDownload;
- (void)setProgress:(CGFloat)progress animated:(bool)animated;
- (void)setSecretProgress:(CGFloat)progress completeDuration:(NSTimeInterval)completeDuration animated:(bool)animated;
- (void)setProgress:(CGFloat)progress cancelEnabled:(bool)cancelEnabled animated:(bool)animated;
- (void)setProgressAnimated:(CGFloat)progress duration:(NSTimeInterval)duration cancelEnabled:(bool)cancelEnabled;
- (void)setPlay;
- (void)setPlayMedia;
- (void)setPauseMedia;
- (void)setSecret:(bool)isViewed;
- (void)setNone;

@end
