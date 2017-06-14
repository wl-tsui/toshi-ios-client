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

@interface ModernButton : UIButton

@property (nonatomic) bool modernHighlight;

@property (nonatomic, strong) UIImage *highlightImage;
@property (nonatomic) bool stretchHighlightImage;
@property (nonatomic, strong) UIColor *highlightBackgroundColor;
@property (nonatomic) UIEdgeInsets backgroundSelectionInsets;
@property (nonatomic) UIEdgeInsets extendedEdgeInsets;

@property (nonatomic, copy) void (^highlitedChanged)(bool highlighted);

- (void)setTitleColor:(UIColor *)color;

- (void)_setHighligtedAnimated:(bool)highlighted animated:(bool)animated;

@end
