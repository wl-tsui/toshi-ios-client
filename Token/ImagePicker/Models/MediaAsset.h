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

#import <Foundation/Foundation.h>

#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "MediaSelectionContext.h"
#import "MediaEditingContext.h"

typedef enum
{
    MediaAssetAnyType,
    MediaAssetPhotoType,
    MediaAssetVideoType,
    MediaAssetGifType
} MediaAssetType;

typedef enum
{
    MediaAssetSubtypeNone = 0,
    MediaAssetSubtypePhotoPanorama = (1UL << 0),
    MediaAssetSubtypePhotoHDR = (1UL << 1),
    MediaAssetSubtypePhotoScreenshot = (1UL << 2),
    MediaAssetSubtypeVideoStreamed = (1UL << 16),
    MediaAssetSubtypeVideoHighFrameRate = (1UL << 17),
    MediaAssetSubtypeVideoTimelapse = (1UL << 18)
} MediaAssetSubtype;

@interface MediaAsset : NSObject <MediaSelectableItem>

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) CGSize dimensions;
@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, readonly) bool isVideo;
@property (nonatomic, readonly) NSTimeInterval videoDuration;
@property (nonatomic, readonly) SSignal *actualVideoDuration;
@property (nonatomic, readonly) bool representsBurst;
@property (nonatomic, readonly) NSString *uniformTypeIdentifier;
@property (nonatomic, readonly) NSString *fileName;

@property (nonatomic, readonly) MediaAssetType type;
@property (nonatomic, readonly) MediaAssetSubtype subtypes;

- (instancetype)initWithPHAsset:(PHAsset *)asset;
- (instancetype)initWithALAsset:(ALAsset *)asset;

@property (nonatomic, readonly) PHAsset *backingAsset;
@property (nonatomic, readonly) ALAsset *backingLegacyAsset;

+ (PHAssetMediaType)assetMediaTypeForAssetType:(MediaAssetType)assetType;

@end
