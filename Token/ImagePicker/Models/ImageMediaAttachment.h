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

#import "MediaAttachment.h"

#import "ImageInfo.h"

#define ImageMediaAttachmentType 0x269BD8A8

@interface ImageMediaAttachment : MediaAttachment <MediaAttachmentParser, NSCopying, NSCoding>

@property (nonatomic) int64_t imageId;
@property (nonatomic, readonly) int64_t localImageId;
@property (nonatomic) int64_t accessHash;
@property (nonatomic) int date;
@property (nonatomic) bool hasLocation;
@property (nonatomic) double locationLatitude;
@property (nonatomic) double locationLongitude;
@property (nonatomic, strong) ImageInfo *imageInfo;
@property (nonatomic) NSString *caption;
@property (nonatomic) bool hasStickers;
@property (nonatomic, strong) NSArray *embeddedStickerDocuments;

@property (nonatomic, readonly) NSArray *textCheckingResults;

+ (int64_t)localImageIdForImageInfo:(ImageInfo *)imageInfo;

- (CGSize)dimensions;

@end
