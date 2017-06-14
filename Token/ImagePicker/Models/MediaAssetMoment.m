#import "MediaAssetMoment.h"
#import "MediaAssetFetchResult.h"

@interface MediaAssetMoment ()
{
    NSUInteger _count;
    PHAssetCollection *_collection;
    MediaAssetFetchResult *_fetchResult;
}
@end

@implementation MediaAssetMoment

- (instancetype)initWithPHAssetCollection:(PHAssetCollection *)collection
{
    self = [super init];
    if (self != nil)
    {
        _collection = collection;
        _count = collection.estimatedAssetCount;
    }
    return self;
}

- (NSString *)title
{
    return _collection.localizedTitle;
}

- (NSDate *)startDate
{
    return _collection.startDate;
}

- (NSDate *)endDate
{
    return _collection.endDate;
}

- (CLLocation *)location
{
    return _collection.approximateLocation;
}

- (NSArray *)locationNames
{
    return _collection.localizedLocationNames;
}

- (NSUInteger)assetCount
{
    if (_fetchResult != nil)
        return _fetchResult.count;
    
    return _count;
}

- (MediaAssetFetchResult *)fetchResult
{
    if (_fetchResult == nil)
    {
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:_collection options:nil];
        _fetchResult = [[MediaAssetFetchResult alloc] initWithPHFetchResult:fetchResult reversed:false];
    }
    
    return _fetchResult;
}

@end
