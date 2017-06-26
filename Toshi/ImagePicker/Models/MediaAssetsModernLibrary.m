#import "MediaAssetsModernLibrary.h"
#import "MediaAssetFetchResultChange.h"
#import "MediaAssetMomentList.h"
#import <MobileCoreServices/MobileCoreServices.h>

#import "Common.h"

@interface MediaAssetsModernLibrary () <PHPhotoLibraryChangeObserver>
{
    PHPhotoLibrary *_photoLibrary;
    SPipe *_libraryChangePipe;
}
@end

@implementation MediaAssetsModernLibrary

- (instancetype)initForAssetType:(MediaAssetType)assetType
{
    self = [super initForAssetType:assetType];
    if (self != nil)
    {
        _libraryChangePipe = [[SPipe alloc] init];
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (SSignal *)assetGroups
{
    MediaAssetType assetType = self.assetType;
    SSignal *(^groupsSignal)(void) = ^
    {
        return [[self cameraRollGroup] map:^NSArray *(MediaAssetGroup *cameraRollGroup)
        {
            NSMutableArray *groups = [[NSMutableArray alloc] init];
            if (cameraRollGroup != nil)
                [groups addObject:cameraRollGroup];
            
            PHFetchResult *albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
            for (PHAssetCollection *album in albums)
                [groups addObject:[[MediaAssetGroup alloc] initWithPHAssetCollection:album fetchResult:nil]];
            
            PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
            for (PHAssetCollection *album in smartAlbums)
            {
                if ([MediaAssetGroup _isSmartAlbumCollectionSubtype:album.assetCollectionSubtype requiredForAssetType:assetType])
                {
                    MediaAssetGroup *group = [[MediaAssetGroup alloc] initWithPHAssetCollection:album fetchResult:nil];
                    if (group.assetCount > 0)
                        [groups addObject:group];
                }
            }
            
            [groups sortUsingFunction:MediaAssetGroupComparator context:nil];
            
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:true]];
            
            //PHFetchResult *moments = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeMoment subtype:PHAssetCollectionSubtypeAny options:options];
            //MediaAssetMomentList *momentList = [[MediaAssetMomentList alloc] initWithPHFetchResult:moments];
            //[groups insertObject:momentList atIndex:0];
            
            return groups;
        }];
    };
    
    SSignal *initialSignal = [[MediaAssetsModernLibrary _requestAuthorization] mapToSignal:^SSignal *(NSNumber *statusValue)
    {
        MediaLibraryAuthorizationStatus status = (MediaLibraryAuthorizationStatus)[statusValue integerValue];
        if (status != MediaLibraryAuthorizationStatusAuthorized)
            return [SSignal fail:nil];
        
        return groupsSignal();
    }];
    
    SSignal *updateSignal = [[self libraryChanged] mapToSignal:^SSignal *(__unused id change)
    {
        return groupsSignal();
    }];
    
    return [initialSignal then:updateSignal];
}

- (SSignal *)cameraRollGroup
{
    MediaAssetType assetType = self.assetType;
    return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        PHFetchOptions *options = [PHFetchOptions new];
        
        if (iosMajorVersion() == 8 && iosMinorVersion() < 1)
        {
            PHFetchResult *fetchResult = nil;
            
            if (assetType == MediaAssetAnyType)
                fetchResult = [PHAsset fetchAssetsWithOptions:options];
            else
                fetchResult = [PHAsset fetchAssetsWithMediaType:[MediaAsset assetMediaTypeForAssetType:assetType] options:options];
            
            [subscriber putNext:[[MediaAssetGroup alloc] initWithPHFetchResult:fetchResult]];
            [subscriber putCompletion];
        }
        else
        {
            PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
            PHAssetCollection *assetCollection = fetchResult.firstObject;
            
            if (assetCollection != nil)
            {
                if (assetType != MediaAssetAnyType)
                    options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %i", [MediaAsset assetMediaTypeForAssetType:assetType]];
                
                PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
                
                [subscriber putNext:[[MediaAssetGroup alloc] initWithPHAssetCollection:assetCollection fetchResult:assetsFetchResult]];
                [subscriber putCompletion];
            }
            else
            {
                [subscriber putError:nil];
            }
        }
        
        return nil;
    }];
}

- (SSignal *)assetsOfAssetGroup:(MediaAssetGroup *)assetGroup reversed:(bool)reversed
{
    if (assetGroup == nil)
        return [SSignal fail:nil];
    
    SAtomic *fetchResult = [[SAtomic alloc] initWithValue:assetGroup.backingFetchResult];
    SSignal *initialSignal = [[MediaAssetsModernLibrary _requestAuthorization] mapToSignal:^SSignal *(NSNumber *statusValue)
    {
        MediaLibraryAuthorizationStatus status = (MediaLibraryAuthorizationStatus)[statusValue integerValue];
        if (status == MediaLibraryAuthorizationStatusNotDetermined)
            return [SSignal fail:nil];
        
        return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
        {
            [subscriber putNext:[[MediaAssetFetchResult alloc] initWithPHFetchResult:fetchResult.value reversed:reversed]];
            [subscriber putCompletion];
            
            return nil;
        }];
    }];
    
    SSignal *updateSignal = [[[[self libraryChanged] map:^PHFetchResultChangeDetails *(PHChange *change)
    {
        return [change changeDetailsForFetchResult:fetchResult.value];
    }] filter:^bool(PHFetchResultChangeDetails *details)
    {
        return (details != nil);
    }] map:^id(PHFetchResultChangeDetails *details)
    {
        [fetchResult modify:^id(__unused id value)
        {
            return details.fetchResultAfterChanges;
        }];
        return [MediaAssetFetchResultChange changeWithPHFetchResultChangeDetails:details reversed:reversed];
    }];
    
    return [initialSignal then:updateSignal];
}

+ (NSLock *)sharedRequestLock
{
    static dispatch_once_t onceToken;
    static NSLock *lock;
    dispatch_once(&onceToken, ^
    {
        lock = [[NSLock alloc] init];
    });
    return lock;
}

- (SSignal *)updatedAssetsForAssets:(NSArray *)assets
{
    return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        NSMutableArray *identifiers = [[NSMutableArray alloc] init];
        for (MediaAsset *asset in assets)
            [identifiers addObject:asset.identifier];
        
        NSMutableArray *updatedAssets = [[NSMutableArray alloc] init];
        
        [[MediaAssetsModernLibrary sharedRequestLock] lock];
        @autoreleasepool
        {
            PHFetchResult *fetchResult =  [PHAsset fetchAssetsWithLocalIdentifiers:identifiers options:nil];
            for (PHAsset *asset in fetchResult)
            {
                MediaAsset *updatedAsset = [[MediaAsset alloc] initWithPHAsset:asset];
                if (updatedAsset != nil)
                    [updatedAssets addObject:updatedAsset];
            }
        }
        [[MediaAssetsModernLibrary sharedRequestLock] unlock];
        
        [subscriber putNext:updatedAssets];
        [subscriber putCompletion];
        
        return nil;
    }];
}

- (SSignal *)assetWithIdentifier:(NSString *)identifier
{
    if (identifier.length == 0)
        return [SSignal fail:nil];
    
    return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        PHAsset *asset = nil;
        
        [[MediaAssetsModernLibrary sharedRequestLock] lock];
        @autoreleasepool
        {
            asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[ identifier ] options:nil].firstObject;
        }
        [[MediaAssetsModernLibrary sharedRequestLock] unlock];
        
        if (asset != nil)
        {
            [subscriber putNext:[[MediaAsset alloc] initWithPHAsset:asset]];
            [subscriber putCompletion];
        }
        else
        {
            [subscriber putError:nil];
        }
        
        return nil;
    }];
}

#pragma mark - 

- (void)photoLibraryDidChange:(PHChange *)change
{
    __strong MediaAssetsModernLibrary *strongSelf = self;
    if (strongSelf != nil)
        strongSelf->_libraryChangePipe.sink(change);
}

- (SSignal *)libraryChanged
{
    return [_libraryChangePipe.signalProducer() filter:^bool(PHChange *change)
    {
        return (change != nil);
    }];
}

#pragma mark -

- (UIImage *)reorientedMirroredImage:(UIImage *)image
{
    UIImageOrientation newOrientation = image.imageOrientation;
    switch (image.imageOrientation)
    {
        case UIImageOrientationLeftMirrored:
            newOrientation = UIImageOrientationRightMirrored;
            break;
            
        case UIImageOrientationRightMirrored:
            newOrientation = UIImageOrientationLeftMirrored;
            break;
            
        default:
            break;
    }
    
    if (newOrientation != image.imageOrientation)
        return [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:newOrientation];
    
    return image;
}

- (SSignal *)saveAssetWithImage:(UIImage *)image
{
    return [[MediaAssetsModernLibrary _requestAuthorization] mapToSignal:^SSignal *(NSNumber *statusValue)
    {
        MediaLibraryAuthorizationStatus status = (MediaLibraryAuthorizationStatus)[statusValue integerValue];
        if (status != MediaLibraryAuthorizationStatusAuthorized)
            return [SSignal fail:nil];
       
        return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
        {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
            {
                [PHAssetChangeRequest creationRequestForAssetFromImage:[self reorientedMirroredImage:image]];
            } completionHandler:^(BOOL success, NSError *error)
            {
                if (error == nil && success)
                    [subscriber putCompletion];
                else
                    [subscriber putError:error];
            }];
            
            return nil;
        }];
    }];
}

- (SSignal *)saveAssetWithImageData:(NSData *)imageData
{
    if (imageData == nil || imageData.length == 0)
        return [SSignal fail:nil];
    
    return [self saveAssetWithImage:[UIImage imageWithData:imageData]];
}

- (SSignal *)_saveAssetWithUrl:(NSURL *)url isVideo:(bool)isVideo
{
    return [[MediaAssetsModernLibrary _requestAuthorization] mapToSignal:^SSignal *(NSNumber *statusValue)
    {
        MediaLibraryAuthorizationStatus status = (MediaLibraryAuthorizationStatus)[statusValue integerValue];
        if (status != MediaLibraryAuthorizationStatusAuthorized)
            return [SSignal fail:nil];
       
        return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
        {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
            {
                if (!isVideo)
                    [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:url];
                else
                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
            } completionHandler:^(BOOL success, NSError *error)
            {
                if (error == nil && success)
                    [subscriber putCompletion];
                else
                    [subscriber putError:error];
            }];
            
            return nil;
        }];
    }];
}

#pragma mark -

+ (SSignal *)_requestAuthorization
{
    if (MediaLibraryCachedAuthorizationStatus != MediaLibraryAuthorizationStatusNotDetermined)
        return [SSignal single:@(MediaLibraryCachedAuthorizationStatus)];
    
    return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
        {
            MediaLibraryAuthorizationStatus authorizationStatus = [self _authorizationStatusForPHAuthorizationStatus:status];
            MediaLibraryCachedAuthorizationStatus = authorizationStatus;
            [subscriber putNext:@(authorizationStatus)];
            [subscriber putCompletion];
        }];
        
        return nil;
    }];
}

+ (SSignal *)authorizationStatusSignal
{
    return [self _requestAuthorization];
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
        [[[self _requestAuthorization] mapToSignal:^SSignal *(NSNumber *statusValue)
        {
            MediaLibraryAuthorizationStatus status = (MediaLibraryAuthorizationStatus)statusValue.integerValue;
            if (status == MediaLibraryAuthorizationStatusAuthorized)
            {
                MediaAssetsLibrary *library = [self libraryForAssetType:assetType];
                return [library cameraRollGroup];
            }
            else
            {
                completion(status, nil);
                return [SSignal complete];
            }
        }] startWithNext:^(MediaAssetGroup *group)
        {
            completion(MediaLibraryAuthorizationStatusAuthorized, group);
        } error:^(__unused id error)
        {
            completion([self authorizationStatus], nil);
        } completed:nil];
    }
}

+ (MediaLibraryAuthorizationStatus)authorizationStatus
{
    return [self _authorizationStatusForPHAuthorizationStatus:[PHPhotoLibrary authorizationStatus]];
}

+ (MediaLibraryAuthorizationStatus)_authorizationStatusForPHAuthorizationStatus:(PHAuthorizationStatus)status
{
    switch (status)
    {
        case PHAuthorizationStatusRestricted:
            return MediaLibraryAuthorizationStatusRestricted;
            
        case PHAuthorizationStatusDenied:
            return MediaLibraryAuthorizationStatusDenied;
            
        case PHAuthorizationStatusAuthorized:
            return MediaLibraryAuthorizationStatusAuthorized;
            
        default:
            return MediaLibraryAuthorizationStatusNotDetermined;
    }
}

@end
