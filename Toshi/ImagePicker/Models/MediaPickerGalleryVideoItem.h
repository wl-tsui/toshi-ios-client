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

#import "MediaPickerGalleryItem.h"
#import "ModernGallerySelectableItem.h"
#import "ModernGalleryEditableItem.h"
#import <AVFoundation/AVFoundation.h>

@protocol MediaEditAdjustments;

@interface MediaPickerGalleryVideoItem : MediaPickerGalleryItem <ModernGallerySelectableItem, ModernGalleryEditableItem>

@property (nonatomic, readonly) AVURLAsset *avAsset;
@property (nonatomic, readonly) CGSize dimensions;

- (instancetype)initWithFileURL:(NSURL *)fileURL dimensions:(CGSize)dimensions duration:(NSTimeInterval)duration;

- (SSignal *)durationSignal;

@end
