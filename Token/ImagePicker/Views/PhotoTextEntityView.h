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

#import "PhotoPaintEntityView.h"
#import "PhotoPaintTextEntity.h"

@class PaintSwatch;

@interface PhotoTextSelectionView : PhotoPaintEntitySelectionView

@end


@interface PhotoTextEntityView : PhotoPaintEntityView

@property (nonatomic, readonly) PhotoPaintTextEntity *entity;

@property (nonatomic, readonly) bool isEmpty;

@property (nonatomic, copy) void (^beganEditing)(PhotoTextEntityView *);
@property (nonatomic, copy) void (^finishedEditing)(PhotoTextEntityView *);

- (instancetype)initWithEntity:(PhotoPaintTextEntity *)entity;
- (void)setFont:(PhotoPaintFont *)font;
- (void)setSwatch:(PaintSwatch *)swatch;
- (void)setStroke:(bool)stroke;

@property (nonatomic, readonly) bool isEditing;
- (void)beginEditing;
- (void)endEditing;

@end


@interface PhotoTextView : UITextView

@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, assign) CGFloat strokeWidth;
@property (nonatomic, assign) CGPoint strokeOffset;

@end
