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

#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "MediaAsset.h"

typedef enum
{
    MediaAssetGroupSubtypeNone = 0,
    MediaAssetGroupSubtypeCameraRoll,
    MediaAssetGroupSubtypeMyPhotoStream,
    MediaAssetGroupSubtypeFavorites,
    MediaAssetGroupSubtypeSelfPortraits,
    MediaAssetGroupSubtypePanoramas,
    MediaAssetGroupSubtypeVideos,
    MediaAssetGroupSubtypeSlomo,
    MediaAssetGroupSubtypeTimelapses,
    MediaAssetGroupSubtypeBursts,
    MediaAssetGroupSubtypeScreenshots,
    MediaAssetGroupSubtypeRegular
} MediaAssetGroupSubtype;

@interface MediaAssetGroup : NSObject

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSInteger assetCount;
@property (nonatomic, readonly) MediaAssetGroupSubtype subtype;
@property (nonatomic, readonly) bool isCameraRoll;
@property (nonatomic, readonly) bool isPhotoStream;
@property (nonatomic, readonly) bool isReversed;

@property (nonatomic, readonly) PHFetchResult *backingFetchResult;
@property (nonatomic, readonly) PHAssetCollection *backingAssetCollection;
@property (nonatomic, readonly) ALAssetsGroup *backingAssetsGroup;

- (instancetype)initWithPHFetchResult:(PHFetchResult *)fetchResult;
- (instancetype)initWithPHAssetCollection:(PHAssetCollection *)collection fetchResult:(PHFetchResult *)fetchResult;
- (instancetype)initWithALAssetsGroup:(ALAssetsGroup *)assetsGroup;
- (instancetype)initWithALAssetsGroup:(ALAssetsGroup *)assetsGroup subtype:(MediaAssetGroupSubtype)subtype;

- (NSArray *)latestAssets;

+ (bool)_isSmartAlbumCollectionSubtype:(PHAssetCollectionSubtype)subtype requiredForAssetType:(MediaAssetType)assetType;

@end
