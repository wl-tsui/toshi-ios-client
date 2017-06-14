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

#import <SSignalKit/SSignalKit.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

@class MediaAsset;
@class AVPlayerItem;
@class AVAsset;

typedef enum
{
    MediaAssetImageTypeUndefined = 0,
    MediaAssetImageTypeThumbnail,
    MediaAssetImageTypeAspectRatioThumbnail,
    MediaAssetImageTypeScreen,
    MediaAssetImageTypeFastScreen,
    MediaAssetImageTypeLargeThumbnail,    
    MediaAssetImageTypeFastLargeThumbnail,
    MediaAssetImageTypeFullSize
} MediaAssetImageType;

@interface MediaAssetImageData : NSObject

@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *fileUTI;
@property (nonatomic, strong) NSData *imageData;

@end


@interface MediaAssetImageFileAttributes : NSObject

@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *fileUTI;
@property (nonatomic, assign) CGSize dimensions;
@property (nonatomic, assign) NSUInteger fileSize;

@end


@interface MediaAssetImageSignals : NSObject

+ (SSignal *)imageForAsset:(MediaAsset *)asset imageType:(MediaAssetImageType)imageType size:(CGSize)size;
+ (SSignal *)imageForAsset:(MediaAsset *)asset imageType:(MediaAssetImageType)imageType size:(CGSize)size allowNetworkAccess:(bool)allowNetworkAccess;

+ (SSignal *)imageDataForAsset:(MediaAsset *)asset;
+ (SSignal *)imageDataForAsset:(MediaAsset *)asset allowNetworkAccess:(bool)allowNetworkAccess;

+ (SSignal *)imageMetadataForAsset:(MediaAsset *)asset;
+ (SSignal *)fileAttributesForAsset:(MediaAsset *)asset;

+ (void)startCachingImagesForAssets:(NSArray *)assets imageType:(MediaAssetImageType)imageType size:(CGSize)size;
+ (void)stopCachingImagesForAssets:(NSArray *)assets imageType:(MediaAssetImageType)imageType size:(CGSize)size;
+ (void)stopCachingImagesForAllAssets;

+ (SSignal *)videoThumbnailsForAsset:(MediaAsset *)asset size:(CGSize)size timestamps:(NSArray *)timestamps;
+ (SSignal *)videoThumbnailsForAVAsset:(AVAsset *)avAsset size:(CGSize)size timestamps:(NSArray *)timestamps;
+ (SSignal *)videoThumbnailForAsset:(MediaAsset *)asset size:(CGSize)size timestamp:(CMTime)timestamp;
+ (SSignal *)videoThumbnailForAVAsset:(AVAsset *)avAsset size:(CGSize)size timestamp:(CMTime)timestamp;

+ (SSignal *)saveUncompressedVideoForAsset:(MediaAsset *)asset toPath:(NSString *)path;
+ (SSignal *)saveUncompressedVideoForAsset:(MediaAsset *)asset toPath:(NSString *)path allowNetworkAccess:(bool)allowNetworkAccess;

+ (SSignal *)playerItemForVideoAsset:(MediaAsset *)asset;
+ (SSignal *)avAssetForVideoAsset:(MediaAsset *)asset;
+ (SSignal *)avAssetForVideoAsset:(MediaAsset *)asset allowNetworkAccess:(bool)allowNetworkAccess;
+ (UIImageOrientation)videoOrientationOfAVAsset:(AVAsset *)avAsset;

+ (bool)usesPhotoFramework;

@end

extern const CGSize MediaAssetImageLegacySizeLimit;
