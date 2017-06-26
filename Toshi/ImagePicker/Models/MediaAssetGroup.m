#import "MediaAssetGroup.h"
#import "Common.h"

@interface MediaAssetGroup ()
{
    NSString *_identifier;
    NSString *_title;
    NSArray *_latestAssets;
    MediaAssetGroupSubtype _subtype;
    NSNumber *_cachedAssetCount;
}
@end

@implementation MediaAssetGroup

- (instancetype)initWithPHFetchResult:(PHFetchResult *)fetchResult
{
    self = [super init];
    if (self != nil)
    {
        _backingFetchResult = fetchResult;
        _isCameraRoll = true;
        _title = TGLocalized(@"CameraRoll");
    }
    return self;
}

- (instancetype)initWithPHAssetCollection:(PHAssetCollection *)collection fetchResult:(PHFetchResult *)fetchResult
{
    self = [super init];
    if (self != nil)
    {
        _backingAssetCollection = collection;
        _backingFetchResult = fetchResult;
        _isCameraRoll = (collection.assetCollectionType == PHAssetCollectionTypeSmartAlbum && collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary);
        
        if (_backingFetchResult == nil)
        {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            //if (_assetType != MediaPickerAssetAnyType)
            //    options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %i", [MediaAssetsLibrary _assetMediaTypeForAssetType:_assetType]];
            
            _backingFetchResult = [PHAsset fetchAssetsInAssetCollection:_backingAssetCollection options:options];
        }
    }
    return self;
}

- (instancetype)initWithALAssetsGroup:(ALAssetsGroup *)assetsGroup
{
    bool isCameraRoll = ([[assetsGroup valueForProperty:ALAssetsGroupPropertyType] integerValue] == ALAssetsGroupSavedPhotos);
    MediaAssetGroupSubtype subtype = isCameraRoll ? MediaAssetGroupSubtypeCameraRoll : MediaAssetGroupSubtypeNone;
    return [self initWithALAssetsGroup:assetsGroup subtype:subtype];
}

- (instancetype)initWithALAssetsGroup:(ALAssetsGroup *)assetsGroup subtype:(MediaAssetGroupSubtype)subtype
{
    self = [super init];
    if (self != nil)
    {
        _backingAssetsGroup = assetsGroup;
        _subtype = subtype;
        
        if (subtype == MediaAssetGroupSubtypeVideos)
        {
            _title = TGLocalized(@"Videos");
            
            [self.backingAssetsGroup setAssetsFilter:[ALAssetsFilter allVideos]];
            _cachedAssetCount = @(self.backingAssetsGroup.numberOfAssets);
            [self.backingAssetsGroup setAssetsFilter:[ALAssetsFilter allAssets]];
        }
        else
        {
            _isCameraRoll = ([[assetsGroup valueForProperty:ALAssetsGroupPropertyType] integerValue] == ALAssetsGroupSavedPhotos);
            if (_isCameraRoll)
            {
                _subtype = MediaAssetGroupSubtypeCameraRoll;
            }
            else
            {
                _isPhotoStream = ([[assetsGroup valueForProperty:ALAssetsGroupPropertyType] integerValue] == ALAssetsGroupPhotoStream);
                _subtype = _isPhotoStream ? MediaAssetGroupSubtypeMyPhotoStream : MediaAssetGroupSubtypeRegular;
            }
        }
        
        NSMutableArray *latestAssets = [[NSMutableArray alloc] init];
        [assetsGroup enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *asset, __unused NSUInteger index, BOOL *stop)
        {
            if (asset != nil && (_subtype != MediaAssetGroupSubtypeVideos || [[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]))
            {
                [latestAssets addObject:[[MediaAsset alloc] initWithALAsset:asset]];
            }
            if (latestAssets.count == 3 && stop != NULL)
                *stop = true;
        }];
        
        _latestAssets = latestAssets;
    }
    return self;
}

- (NSString *)identifier
{
    if (self.backingAssetCollection != nil)
        return self.backingAssetCollection.localIdentifier;
    else if (_backingAssetsGroup != nil)
        return [self.backingAssetsGroup valueForProperty:ALAssetsGroupPropertyPersistentID];
    
    return _identifier;
}

- (NSString *)title
{
    if (_title != nil)
        return _title;
    if (_backingAssetCollection != nil)
        return _backingAssetCollection.localizedTitle;
    if (_backingAssetsGroup != nil)
        return [_backingAssetsGroup valueForProperty:ALAssetsGroupPropertyName];
    
    return nil;
}

- (NSInteger)assetCount
{
    if (self.backingFetchResult != nil)
    {
        return self.backingFetchResult.count;
    }
    else if (self.backingAssetsGroup != nil)
    {
        if (self.subtype == MediaAssetGroupSubtypeVideos)
        {
            if (_cachedAssetCount != nil)
                return _cachedAssetCount.integerValue;
            
            return -1;
        }
        return self.backingAssetsGroup.numberOfAssets;
    }
    
    return 0;
}

- (MediaAssetGroupSubtype)subtype
{
    if (self.backingAssetCollection != nil)
    {
        return [MediaAssetGroup _assetGroupSubtypeForCollectionSubtype:self.backingAssetCollection.assetCollectionSubtype];
    }
    else if (self.backingFetchResult != nil)
    {
        if (_isCameraRoll)
            return MediaAssetGroupSubtypeCameraRoll;
    }
    else if (self.backingAssetsGroup != nil)
    {
        if (_isCameraRoll)
            return MediaAssetGroupSubtypeCameraRoll;
        else if (_subtype != MediaAssetGroupSubtypeNone)
            return _subtype;
    }
    
    return MediaAssetGroupSubtypeRegular;
}

- (NSArray *)latestAssets
{
    if (_backingFetchResult != nil)
    {
        if (_latestAssets != nil)
            return _latestAssets;
        
        NSMutableArray *latestAssets = [[NSMutableArray alloc] init];
        
        NSInteger totalCount = _backingFetchResult.count;
        
        if (totalCount == 0)
            return nil;
        
        NSInteger requiredCount = MIN(3, totalCount);
        
        for (NSInteger i = 0; i < requiredCount; i++)
        {
            NSInteger index = (self.subtype != MediaAssetGroupSubtypeRegular) ? totalCount - i - 1 : i;
            PHAsset *asset = [_backingFetchResult objectAtIndex:index];
            
            MediaAsset *pickerAsset = [[MediaAsset alloc] initWithPHAsset:asset];
            
            if (pickerAsset != nil)
                [latestAssets addObject:pickerAsset];
        }
        
        _latestAssets = latestAssets;
    }
    
    return _latestAssets;
}

- (BOOL)isEqual:(id)object
{
    if (object == self)
        return YES;
    
    if (!object || ![object isKindOfClass:[self class]])
        return NO;
    
    return [self.identifier isEqual:((MediaAssetGroup *)object).identifier];
}

+ (MediaAssetGroupSubtype)_assetGroupSubtypeForCollectionSubtype:(PHAssetCollectionSubtype)subtype
{
    switch (subtype)
    {
        case PHAssetCollectionSubtypeSmartAlbumPanoramas:
            return MediaAssetGroupSubtypePanoramas;
            
        case PHAssetCollectionSubtypeSmartAlbumVideos:
            return MediaAssetGroupSubtypeVideos;
            
        case PHAssetCollectionSubtypeSmartAlbumFavorites:
            return MediaAssetGroupSubtypeFavorites;
            
        case PHAssetCollectionSubtypeSmartAlbumTimelapses:
            return MediaAssetGroupSubtypeTimelapses;
            
        case PHAssetCollectionSubtypeSmartAlbumBursts:
            return MediaAssetGroupSubtypeBursts;
            
        case PHAssetCollectionSubtypeSmartAlbumSlomoVideos:
            return MediaAssetGroupSubtypeSlomo;
            
        case PHAssetCollectionSubtypeSmartAlbumUserLibrary:
            return MediaAssetGroupSubtypeCameraRoll;
            
        case PHAssetCollectionSubtypeSmartAlbumScreenshots:
            return MediaAssetGroupSubtypeScreenshots;
            
        case PHAssetCollectionSubtypeSmartAlbumSelfPortraits:
            return MediaAssetGroupSubtypeSelfPortraits;
            
        case PHAssetCollectionSubtypeAlbumMyPhotoStream:
            return MediaAssetGroupSubtypeMyPhotoStream;
            
        default:
            return MediaAssetGroupSubtypeRegular;
    }
}

+ (bool)_isSmartAlbumCollectionSubtype:(PHAssetCollectionSubtype)subtype requiredForAssetType:(MediaAssetType)assetType
{
    switch (subtype)
    {
        case PHAssetCollectionSubtypeSmartAlbumPanoramas:
        {
            switch (assetType)
            {
                case MediaAssetVideoType:
                    return false;
                     
                default:
                    return true;
            }
        }
            break;
            
        case PHAssetCollectionSubtypeSmartAlbumFavorites:
        {
            return true;
        }
            break;
            
        case PHAssetCollectionSubtypeSmartAlbumTimelapses:
        {
            switch (assetType)
            {
                case MediaAssetPhotoType:
                    return false;
                    
                default:
                    return true;
            }
        }
            break;
            
        case PHAssetCollectionSubtypeSmartAlbumVideos:
        {
            switch (assetType)
            {
                case MediaAssetAnyType:
                    return true;
                    
                default:
                    return false;
            }
        }
            
        case PHAssetCollectionSubtypeSmartAlbumSlomoVideos:
        {
            switch (assetType)
            {
                case MediaAssetPhotoType:
                    return false;
                    
                default:
                    return true;
            }
        }
            break;
            
        case PHAssetCollectionSubtypeSmartAlbumBursts:
        {
            switch (assetType)
            {
                case MediaAssetVideoType:
                    return false;
                    
                default:
                    return true;
            }
        }
            break;
            
        case PHAssetCollectionSubtypeSmartAlbumScreenshots:
        {
            switch (assetType)
            {
                case MediaAssetVideoType:
                    return false;
                    
                default:
                    return true;
            }
        }
            
        case PHAssetCollectionSubtypeSmartAlbumSelfPortraits:
        {
            switch (assetType)
            {
                case MediaAssetVideoType:
                    return false;
                    
                default:
                    return true;
            }
        }
            
        default:
        {
            return false;
        }
    }
}

@end
