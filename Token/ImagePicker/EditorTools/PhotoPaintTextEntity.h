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

#import "PhotoPaintEntity.h"
#import "PaintSwatch.h"
#import "PhotoPaintFont.h"

@interface PhotoPaintTextEntity : PhotoPaintEntity

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) PhotoPaintFont *font;
@property (nonatomic, strong) PaintSwatch *swatch;
@property (nonatomic, assign) CGFloat baseFontSize;
@property (nonatomic, assign) CGFloat maxWidth;
@property (nonatomic, assign) bool stroke;

- (instancetype)initWithText:(NSString *)text font:(PhotoPaintFont *)font swatch:(PaintSwatch *)swatch baseFontSize:(CGFloat)baseFontSize maxWidth:(CGFloat)maxWidth stroke:(bool)stroke;

@end
