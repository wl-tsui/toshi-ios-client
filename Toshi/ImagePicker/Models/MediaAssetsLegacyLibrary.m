#import "MediaAssetsLegacyLibrary.h"

#import <AssetsLibrary/AssetsLibrary.h>

#import "ObserverProxy.h"

@interface MediaAssetsLegacyLibrary ()
{
    ALAssetsLibrary *_assetsLibrary;
    ObserverProxy *_assetsChangeObserver;
    SPipe *_libraryChangePipe;
}
@end

@implementation MediaAssetsLegacyLibrary

- (instancetype)initForAssetType:(MediaAssetType)assetType
{
    self = [super initForAssetType:assetType];
    if (self != nil)
    {
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
        _assetsChangeObserver = [[ObserverProxy alloc] initWithTarget:self targetSelector:@selector(assetsLibraryDidChange:) name:ALAssetsLibraryChangedNotification];
        _libraryChangePipe = [[SPipe alloc] init];
    }
    return self;
}

- (SSignal *)assetWithIdentifier:(NSString *)identifier
{
    if (identifier.length == 0)
        return [SSignal fail:nil];
    
    return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        [_assetsLibrary assetForURL:[NSURL URLWithString:identifier] resultBlock:^(ALAsset *asset)
        {
            if (asset != nil)
            {
                [subscriber putNext:[[MediaAsset alloc] initWithALAsset:asset]];
                [subscriber putCompletion];
            }
            else
            {
                [subscriber putError:nil];
            }
        } failureBlock:^(__unused NSError *error)
        {
            [subscriber putError:nil];
        }];
        
        return nil;
    }];
}

- (SSignal *)assetGroups
{
    SSignal *(^groupsSignal)(void) = ^
    {
        return [[[[[[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
        {
            [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *assetsGroup, __unused BOOL *stop)
            {
                if (assetsGroup != nil)
                {
                    if (self.assetType != MediaAssetAnyType)
                        [assetsGroup setAssetsFilter:[MediaAssetsLegacyLibrary _assetsFilterForAssetType:self.assetType]];
                    
                    MediaAssetGroup *group = [[MediaAssetGroup alloc] initWithALAssetsGroup:assetsGroup];
                    [subscriber putNext:group];
                }
                else
                {
                    [subscriber putCompletion];
                }
            } failureBlock:^(NSError *error)
            {
                [subscriber putError:error];
            }];
            
            return nil;
        }] then:[[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
        {
            [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *assetsGroup, __unused BOOL *stop)
            {
                if (assetsGroup != nil)
                {
                    if ([[assetsGroup valueForProperty:ALAssetsGroupPropertyType] integerValue] == ALAssetsGroupSavedPhotos)
                    {
                        MediaAssetGroup *group = [[MediaAssetGroup alloc] initWithALAssetsGroup:assetsGroup subtype:MediaAssetGroupSubtypeVideos];
                        [subscriber putNext:group];
                        [subscriber putCompletion];
                    }
                }
                else
                {
                    [subscriber putCompletion];
                }
            } failureBlock:^(NSError *error)
            {
                [subscriber putError:error];
            }];
            
            return nil;
        }]] reduceLeft:[[NSMutableArray alloc] init] with:^id(NSMutableArray *groups, id group)
        {
            [groups addObject:group];
            return groups;
        }] map:^NSMutableArray *(NSMutableArray *groups)
        {
            [groups sortUsingFunction:MediaAssetGroupComparator context:nil];
            return groups;
        }] startOn:_queue];
    };
    
    SSignal *updateSignal = [[self libraryChanged] mapToSignal:^SSignal *(__unused id change)
    {
        return groupsSignal();
    }];
    
    return [groupsSignal() then:updateSignal];
}

- (SSignal *)cameraRollGroup
{
    return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop)
        {
            if (group != nil)
            {
                if (self.assetType != MediaAssetAnyType)
                    [group setAssetsFilter:[MediaAssetsLegacyLibrary _assetsFilterForAssetType:self.assetType]];

                [subscriber putNext:[[MediaAssetGroup alloc] initWithALAssetsGroup:group]];
                [subscriber putCompletion];

                if (stop != NULL)
                    *stop = true;
            }
            else
            {
                [subscriber putError:nil];
            }
        } failureBlock:^(NSError *error)
        {
            [subscriber putError:error];
        }];

        return nil;
    }];
}

- (SSignal *)assetsOfAssetGroup:(MediaAssetGroup *)assetGroup reversed:(bool)reversed
{
    NSParameterAssert(assetGroup);
    
    SSignal *(^fetchSignal)(MediaAssetGroup *) = ^SSignal *(MediaAssetGroup *group)
    {
        return [[[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
        {
            MediaAssetFetchResult *mediaFetchResult = [[MediaAssetFetchResult alloc] initForALAssetsReversed:reversed];
            
            NSEnumerationOptions options = kNilOptions;
            if (group.isReversed)
                options = NSEnumerationReverse;
            
            [group.backingAssetsGroup enumerateAssetsWithOptions:options usingBlock:^(ALAsset *asset, __unused NSUInteger index, __unused BOOL *stop)
            {
                if (asset != nil && (assetGroup.subtype != MediaAssetGroupSubtypeVideos || [[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]))
                {
                    [mediaFetchResult _appendALAsset:asset];
                }
            }];
            
            [subscriber putNext:mediaFetchResult];
            [subscriber putCompletion];
            
            return nil;
        }] startOn:_queue];
    };
    
    SSignal *updateSignal = [[self libraryChanged] mapToSignal:^SSignal *(__unused id change)
    {
        return fetchSignal(assetGroup);
    }];
    
    return [fetchSignal(assetGroup) then:updateSignal];
}

- (SSignal *)updatedAssetsForAssets:(NSArray *)assets
{
    SSignal *(^updatedAssetSignal)(MediaAsset *) = ^SSignal *(MediaAsset *asset)
    {
        return [[[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
        {
            [_assetsLibrary assetForURL:asset.url resultBlock:^(ALAsset *asset)
            {
                if (asset != nil)
                {
                    MediaAsset *updatedAsset = [[MediaAsset alloc] initWithALAsset:asset];
                    [subscriber putNext:updatedAsset];
                    [subscriber putCompletion];
                }
                else
                {
                    [subscriber putError:nil];
                }
            } failureBlock:^(__unused NSError *error)
            {
                [subscriber putError:nil];
            }];
            
            return nil;
        }] catch:^SSignal *(__unused id error)
        {
            return [SSignal complete];
        }];
    };
    
    NSMutableArray *signals = [[NSMutableArray alloc] init];
    for (MediaAsset *asset in assets)
        [signals addObject:updatedAssetSignal(asset)];
    
    SSignal *combinedSignal = nil;
    for (SSignal *signal in signals)
    {
        if (combinedSignal == nil)
            combinedSignal = signal;
        else
            combinedSignal = [combinedSignal then:signal];
    }
    
    return [combinedSignal reduceLeft:[[NSMutableArray alloc] init] with:^id(NSMutableArray *array, MediaAsset *updatedAsset)
    {
        [array addObject:updatedAsset];
        return array;
    }];
}

- (SSignal *)filterDeletedAssets:(NSArray *)assets
{
    SSignal *(^assetDeletedSignal)(MediaAsset *) = ^SSignal *(MediaAsset *asset)
    {
        return [[[[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
        {
            [_assetsLibrary assetForURL:asset.url resultBlock:^(ALAsset *asset)
            {
                [subscriber putNext:@(asset != nil)];
                [subscriber putCompletion];
            } failureBlock:^(__unused NSError *error)
            {
                [subscriber putNext:@(false)];
                [subscriber putCompletion];
            }];
            
            return nil;
        }] filter:^bool(NSNumber *exists)
        {
            return !exists.boolValue;
        }] map:^MediaAsset *(__unused id exists)
        {
            return asset;
        }];
    };
    
    NSMutableArray *signals = [[NSMutableArray alloc] init];
    for (MediaAsset *asset in assets)
        [signals addObject:assetDeletedSignal(asset)];
    
    SSignal *combinedSignal = nil;
    for (SSignal *signal in signals)
    {
        if (combinedSignal == nil)
            combinedSignal = signal;
        else
            combinedSignal = [combinedSignal then:signal];
    }
    
    return [combinedSignal reduceLeft:[[NSMutableArray alloc] init] with:^id(NSMutableArray *array, MediaAsset *deletedAsset)
    {
        [array addObject:deletedAsset];
        return array;
    }];
}

#pragma mark -

- (void)assetsLibraryDidChange:(NSNotification *)__unused notification
{
    __strong MediaAssetsLegacyLibrary *strongSelf = self;
    if (strongSelf != nil)
        strongSelf->_libraryChangePipe.sink([SSignal single:@(true)]);
}

- (SSignal *)libraryChanged
{
    return [[_libraryChangePipe.signalProducer() delay:0.5 onQueue:_queue] switchToLatest];
}

#pragma mark -

- (SSignal *)saveAssetWithImage:(UIImage *)image
{
    return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        [_assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error)
        {
            if (assetURL != nil && error == nil)
                [subscriber putCompletion];
            else
                [subscriber putError:error];
        }];
        
        return nil;
    }];
}

- (SSignal *)saveAssetWithImageData:(NSData *)imageData
{
    return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        [_assetsLibrary writeImageDataToSavedPhotosAlbum:imageData metadata:nil completionBlock:^(NSURL *assetURL, NSError *error)
        {
            if (assetURL != nil && error == nil)
                [subscriber putCompletion];
            else
                [subscriber putError:error];
        }];
        
        return nil;
    }];
}

- (SSignal *)_saveAssetWithUrl:(NSURL *)url isVideo:(bool)isVideo
{
    return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        void (^writeCompletionBlock)(NSURL *, NSError *) = ^(NSURL *assetURL, NSError *error)
        {
            if (assetURL != nil && error == nil)
                [subscriber putCompletion];
            else
                [subscriber putError:error];
        };
        
        if (!isVideo)
        {
            NSData *data = [[NSData alloc] initWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:nil];
            [_assetsLibrary writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:writeCompletionBlock];
        }
        else
        {
            [_assetsLibrary writeVideoAtPathToSavedPhotosAlbum:url completionBlock:writeCompletionBlock];
        }
        
        return nil;
    }];
}

+ (ALAssetsFilter *)_assetsFilterForAssetType:(MediaAssetType)assetType
{
    switch (assetType)
    {
        case MediaAssetPhotoType:
            return [ALAssetsFilter allPhotos];
            
        case MediaAssetVideoType:
            return [ALAssetsFilter allVideos];
            
        default:
            return [ALAssetsFilter allAssets];
    }
}

+ (SSignal *)authorizationStatusSignal
{
    if (MediaLibraryCachedAuthorizationStatus != MediaLibraryAuthorizationStatusNotDetermined)
        return [SSignal single:@(MediaLibraryCachedAuthorizationStatus)];
    
    return [SSignal single:@(MediaLibraryAuthorizationStatusAuthorized)];
}

+ (void)requestAuthorizationForAssetType:(MediaAssetType)assetType completion:(void (^)(MediaLibraryAuthorizationStatus, MediaAssetGroup *))completion
{
    MediaLibraryAuthorizationStatus currentStatus = [self authorizationStatus];
    if (currentStatus == MediaLibraryAuthorizationStatusDenied || currentStatus == MediaLibraryAuthorizationStatusRestricted)
    {
        completion(currentStatus, nil);
    }
    else
    {
        MediaAssetsLibrary *library = [self libraryForAssetType:assetType];
        [[library cameraRollGroup] startWithNext:^(MediaAssetGroup *group)
        {
            MediaLibraryCachedAuthorizationStatus = [self authorizationStatus];
            completion([self authorizationStatus], group);
        } error:^(__unused id error)
        {
            MediaLibraryCachedAuthorizationStatus = [self authorizationStatus];
            completion([self authorizationStatus], nil);
        } completed:nil];
    }
}

+ (MediaLibraryAuthorizationStatus)authorizationStatus
{
    return [self _authorizationStatusForALAuthorizationStatus:[ALAssetsLibrary authorizationStatus]];
}

+ (MediaLibraryAuthorizationStatus)_authorizationStatusForALAuthorizationStatus:(ALAuthorizationStatus)status
{
    switch (status)
    {
        case ALAuthorizationStatusRestricted:
            return MediaLibraryAuthorizationStatusRestricted;
            
        case ALAuthorizationStatusDenied:
            return MediaLibraryAuthorizationStatusDenied;
            
        case ALAuthorizationStatusAuthorized:
            return MediaLibraryAuthorizationStatusAuthorized;
            
        default:
            return MediaLibraryAuthorizationStatusNotDetermined;
    }
}

@end
