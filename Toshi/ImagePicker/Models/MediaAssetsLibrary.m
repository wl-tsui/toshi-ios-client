#import "MediaAssetsLibrary.h"

#import "MediaAssetsModernLibrary.h"
#import "MediaAssetsLegacyLibrary.h"

#import "Common.h"

@implementation MediaAssetsLibrary

static Class MediaAssetsLibraryClass = nil;

+ (void)load
{
    if ([self usesPhotoFramework])
        MediaAssetsLibraryClass = [MediaAssetsModernLibrary class];
    else
        MediaAssetsLibraryClass = [MediaAssetsLegacyLibrary class];

    [MediaAssetsLibraryClass authorizationStatus];
}

- (instancetype)initForAssetType:(MediaAssetType)assetType
{
    self = [super init];
    if (self != nil)
    {
        _assetType = assetType;
        _queue = [[SQueue alloc] init];
    }
    return self;
}

+ (instancetype)libraryForAssetType:(MediaAssetType)assetType
{
    return [[MediaAssetsLibraryClass alloc] initForAssetType:assetType];
}

- (SSignal *)assetWithIdentifier:(NSString *)__unused identifier
{
    return nil;
}

- (SSignal *)assetGroups
{
    return nil;
}

- (SSignal *)cameraRollGroup
{
    return nil;
}

- (SSignal *)updatedAssetsForAssets:(NSArray *)__unused assets
{
    return nil;
}

- (SSignal *)libraryChanged
{
    return nil;
}

NSInteger MediaAssetGroupComparator(MediaAssetGroup *group1, MediaAssetGroup *group2, __unused void *context)
{
    if (group1.subtype < group2.subtype)
        return NSOrderedAscending;
    else if (group1.subtype > group2.subtype)
        return NSOrderedDescending;
    
    return [group1.title compare:group2.title];
}

#pragma mark - Assets

- (SSignal *)assetsOfAssetGroup:(MediaAssetGroup *)__unused assetGroup reversed:(bool)__unused reversed
{
    return nil;
}

- (SSignal *)_legacyAssetsOfAssetGroup:(MediaAssetGroup *)assetGroup reversed:(bool)reversed
{
    NSParameterAssert(assetGroup);
    return [[[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        MediaAssetFetchResult *mediaFetchResult = [[MediaAssetFetchResult alloc] init];
        
        NSEnumerationOptions options = kNilOptions;
        if (reversed)
            options = NSEnumerationReverse;
        
        [assetGroup.backingAssetsGroup enumerateAssetsWithOptions:options usingBlock:^(ALAsset *asset, __unused NSUInteger index, __unused BOOL *stop)
        {
            if (asset != nil)
                [mediaFetchResult _appendALAsset:asset];
        }];
        
        [subscriber putNext:mediaFetchResult];
        [subscriber putCompletion];
        
        return nil;
    }] startOn:_queue];
}

#pragma mark - 

- (SSignal *)saveAssetWithImage:(UIImage *)__unused image
{
    return nil;
}

- (SSignal *)saveAssetWithImageData:(NSData *)__unused imageData
{
    return nil;
}

- (SSignal *)saveAssetWithImageAtUrl:(NSURL *)url
{
    return [self _saveAssetWithUrl:url isVideo:false];
}

- (SSignal *)saveAssetWithVideoAtUrl:(NSURL *)url
{
    return [self _saveAssetWithUrl:url isVideo:true];
}

- (SSignal *)_saveAssetWithUrl:(NSURL *)__unused url isVideo:(bool)__unused isVideo
{
    return nil;
}

#pragma mark -

+ (MediaAssetsLibrary *)sharedLibrary
{
    static dispatch_once_t onceToken;
    static MediaAssetsLibrary *library;
    dispatch_once(&onceToken, ^
    {
        library = [self libraryForAssetType:MediaAssetAnyType];
    });
    return library;
}

#pragma mark - Authorization Status

+ (SSignal *)authorizationStatusSignal
{
    return [MediaAssetsLibraryClass authorizationStatusSignal];
}

+ (void)requestAuthorizationForAssetType:(MediaAssetType)assetType completion:(void (^)(MediaLibraryAuthorizationStatus, MediaAssetGroup *))completion
{
    [MediaAssetsLibraryClass requestAuthorizationForAssetType:assetType completion:completion];
}

+ (MediaLibraryAuthorizationStatus)authorizationStatus
{
    if (MediaLibraryCachedAuthorizationStatus != MediaLibraryAuthorizationStatusNotDetermined)
        return MediaLibraryCachedAuthorizationStatus;
    
    MediaLibraryCachedAuthorizationStatus = [MediaAssetsLibraryClass authorizationStatus];
    
    return MediaLibraryCachedAuthorizationStatus;
}

#pragma mark - 

+ (bool)usesPhotoFramework
{
    static dispatch_once_t onceToken;
    static bool usesPhotosFramework = false;
    dispatch_once(&onceToken, ^
    {
        usesPhotosFramework = (iosMajorVersion() >= 8.0);
    });
    return usesPhotosFramework;
}

@end
