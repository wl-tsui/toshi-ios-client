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

#import "ModernGalleryItem.h"
#import <UIKit/UIKit.h>
#import <SSignalKit/SSignalKit.h>

@class ImageInfo;
@class ImageView;

@interface ModernGalleryImageItem : NSObject <ModernGalleryItem>

@property (nonatomic, readonly) NSString *uri;
@property (nonatomic, copy, readonly) dispatch_block_t (^loader)(ImageView *, bool);

@property (nonatomic, readonly) CGSize imageSize;
@property (nonatomic, strong) NSArray *embeddedStickerDocuments;
@property (nonatomic) bool hasStickers;
@property (nonatomic) int64_t imageId;
@property (nonatomic) int64_t accessHash;

- (instancetype)initWithUri:(NSString *)uri imageSize:(CGSize)imageSize;
- (instancetype)initWithLoader:(dispatch_block_t (^)(ImageView *, bool))loader imageSize:(CGSize)imageSize;
- (instancetype)initWithSignal:(SSignal *)signal imageSize:(CGSize)imageSize;

@end
