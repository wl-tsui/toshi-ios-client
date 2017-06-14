#import "MediaAsset.h"
#import "MediaAssetImageSignals.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import "ImageUtils.h"
#import "Common.h"

@interface MediaAsset ()
{
    NSNumber *_cachedType;
    
    NSString *_cachedUniqueId;
    NSURL *_cachedLegacyAssetUrl;
    NSNumber *_cachedLegacyVideoRotated;
    
    NSNumber *_cachedDuration;
}
@end

@implementation MediaAsset

- (instancetype)initWithPHAsset:(PHAsset *)asset
{
    self = [super init];
    if (self != nil)
    {
        _backingAsset = asset;
    }
    return self;
}

- (instancetype)initWithALAsset:(ALAsset *)asset
{
    self = [super init];
    if (self != nil)
    {
        _backingLegacyAsset = asset;
    }
    return self;
}

- (NSString *)identifier
{
    if (_cachedUniqueId == nil)
    {
        if (self.backingAsset != nil)
            _cachedUniqueId = self.backingAsset.localIdentifier;
        else
            _cachedUniqueId = self.url.absoluteString;
    }
    
    return _cachedUniqueId;
}

- (NSURL *)url
{
    if (self.backingLegacyAsset != nil)
    {
        if (!_cachedLegacyAssetUrl)
            _cachedLegacyAssetUrl = [self.backingLegacyAsset defaultRepresentation].url;
        
        return _cachedLegacyAssetUrl;
    }
    
    return nil;
}

- (CGSize)dimensions
{
    if (self.backingAsset != nil)
    {
        return CGSizeMake(self.backingAsset.pixelWidth, self.backingAsset.pixelHeight);
    }
    else if (self.backingLegacyAsset != nil)
    {
        CGSize dimensions = self.backingLegacyAsset.defaultRepresentation.dimensions;
        
        if (self.isVideo)
        {
            bool videoRotated = false;
            if (_cachedLegacyVideoRotated == nil)
            {
                CGImageRef thumbnailImage = self.backingLegacyAsset.aspectRatioThumbnail;
                CGSize thumbnailSize = CGSizeMake(CGImageGetWidth(thumbnailImage), CGImageGetHeight(thumbnailImage));
                bool thumbnailIsWide = (thumbnailSize.width > thumbnailSize.height);
                bool videoIsWide = (dimensions.width > dimensions.height);
                
                videoRotated = (thumbnailIsWide != videoIsWide);
                _cachedLegacyVideoRotated = @(videoRotated);
            }
            else
            {
                videoRotated = _cachedLegacyVideoRotated.boolValue;
            }
            
            if (videoRotated)
                dimensions = CGSizeMake(dimensions.height, dimensions.width);
        }
        
        return dimensions;
    }
    
    return CGSizeZero;
}

- (NSDate *)date
{
    if (self.backingAsset != nil)
        return self.backingAsset.creationDate;
    else if (self.backingLegacyAsset != nil)
        return [self.backingLegacyAsset valueForProperty:ALAssetPropertyDate];
    
    return nil;
}

- (bool)isVideo
{
    return self.type == MediaAssetVideoType;
}

- (bool)representsBurst
{
    return self.backingAsset.representsBurst;
}

- (NSString *)uniformTypeIdentifier
{
    if (self.backingAsset != nil)
        return [self.backingAsset valueForKey:@"uniformTypeIdentifier"];
    else if (self.backingLegacyAsset != nil)
        return self.backingLegacyAsset.defaultRepresentation.UTI;
    
    return nil;
}

- (NSString *)fileName
{
    if (self.backingAsset != nil)
        return [self.backingAsset valueForKey:@"filename"];
    else if (self.backingLegacyAsset != nil)
        return self.backingLegacyAsset.defaultRepresentation.filename;
    
    return nil;
}

- (bool)_isGif
{
    return [self.uniformTypeIdentifier isEqualToString:(NSString *)kUTTypeGIF];
}

- (MediaAssetType)type
{
    if (_cachedType == nil)
    {
        if (self.backingAsset != nil)
        {
            if ([self _isGif])
                _cachedType = @(MediaAssetGifType);
            else
                _cachedType = @([MediaAsset assetTypeForPHAssetMediaType:self.backingAsset.mediaType]);
        }
        else if (self.backingLegacyAsset != nil)
        {
            if ([[self.backingLegacyAsset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo])
                _cachedType = @(MediaAssetVideoType);
            else if ([self _isGif])
                _cachedType = @(MediaAssetGifType);
            else
                _cachedType = @(MediaAssetPhotoType);
        }
    }
    
    return _cachedType.intValue;
}

- (MediaAssetSubtype)subtypes
{
    MediaAssetSubtype subtypes = MediaAssetSubtypeNone;
    
    if (self.backingAsset != nil)
        subtypes = [MediaAsset assetSubtypesForPHAssetMediaSubtypes:self.backingAsset.mediaSubtypes];
    
    return subtypes;
}

- (NSTimeInterval)videoDuration
{
    if (self.backingAsset != nil)
        return self.backingAsset.duration;
    else if (self.backingLegacyAsset != nil)
        return [[self.backingLegacyAsset valueForProperty:ALAssetPropertyDuration] doubleValue];
    
    return 0;
}

- (SSignal *)actualVideoDuration
{
    if (!self.isVideo)
        return [SSignal fail:nil];
    
    if (!_cachedDuration)
    {
        return [[MediaAssetImageSignals avAssetForVideoAsset:self] map:^id(AVAsset *asset)
        {
            NSTimeInterval duration = CMTimeGetSeconds(asset.duration);
            _cachedDuration = @(duration);
            return _cachedDuration;
        }];
    }
    
    return [SSignal single:_cachedDuration];
}

+ (PHAssetMediaType)assetMediaTypeForAssetType:(MediaAssetType)assetType
{
    switch (assetType)
    {
        case MediaAssetPhotoType:
            return PHAssetMediaTypeImage;
            
        case MediaAssetVideoType:
            return PHAssetMediaTypeVideo;
            
        default:
            return PHAssetMediaTypeUnknown;
    }
}

- (BOOL)isEqual:(id)object
{
    if (object == self)
        return YES;
    
    if (!object || ![object isKindOfClass:[self class]])
        return NO;
    
    return [self.identifier isEqual:((MediaAsset *)object).identifier];
}

+ (MediaAssetType)assetTypeForPHAssetMediaType:(PHAssetMediaType)type
{
    switch (type)
    {
        case PHAssetMediaTypeImage:
            return MediaAssetPhotoType;
            
        case PHAssetMediaTypeVideo:
            return MediaAssetVideoType;
            
        default:
            return MediaAssetAnyType;
    }
}

+ (MediaAssetSubtype)assetSubtypesForPHAssetMediaSubtypes:(PHAssetMediaSubtype) subtypes
{
    MediaAssetSubtype result = MediaAssetSubtypeNone;
    
    if (subtypes & PHAssetMediaSubtypePhotoPanorama)
        result |= MediaAssetSubtypePhotoPanorama;
    
    if (subtypes & PHAssetMediaSubtypePhotoHDR)
        result |= MediaAssetSubtypePhotoHDR;
    
    if (iosMajorVersion() >= 9 && subtypes & PHAssetMediaSubtypePhotoScreenshot)
        result |= MediaAssetSubtypePhotoScreenshot;
    
    if (subtypes & PHAssetMediaSubtypeVideoStreamed)
        result |= MediaAssetSubtypeVideoStreamed;
    
    if (subtypes & PHAssetMediaSubtypeVideoHighFrameRate)
        result |= MediaAssetSubtypeVideoHighFrameRate;
    
    if (subtypes & PHAssetMediaSubtypeVideoTimelapse)
        result |= MediaAssetSubtypeVideoTimelapse;
    
    return result;
}

- (NSString *)uniqueIdentifier
{
    return self.identifier;
}

@end
