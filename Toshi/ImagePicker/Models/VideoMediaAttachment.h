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

#import "VideoInfo.h"
#import "ImageInfo.h"

#define VideoMediaAttachmentType ((int)0x338EAA20)

@interface VideoMediaAttachment : MediaAttachment <NSCoding, MediaAttachmentParser>

@property (nonatomic) int64_t videoId;
@property (nonatomic) int64_t accessHash;

@property (nonatomic) int64_t localVideoId;

@property (nonatomic) int duration;
@property (nonatomic) CGSize dimensions;

@property (nonatomic, strong) VideoInfo *videoInfo;
@property (nonatomic, strong) ImageInfo *thumbnailInfo;

@property (nonatomic) NSString *caption;
@property (nonatomic) bool hasStickers;
@property (nonatomic, strong) NSArray *embeddedStickerDocuments;

@property (nonatomic, readonly) NSArray *textCheckingResults;

@property (nonatomic) bool loopVideo;

@end
