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

#import "ModernViewModel.h"

@interface ModernButtonViewModel : ModernViewModel

@property (nonatomic, copy) void (^pressed)();

@property (nonatomic, strong) UIImage *supplementaryIcon;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) UIImage *highlightedBackgroundImage;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSArray *possibleTitles;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic) UIEdgeInsets extendedEdgeInsets;

@property (nonatomic) UIEdgeInsets titleInset;

@property (nonatomic) bool modernHighlight;
@property (nonatomic) bool displayProgress;

- (void)setDisplayProgress:(bool)displayProgress animated:(bool)animated;

@end
