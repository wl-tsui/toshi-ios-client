#import "MemoryImageCache.h"

#import <SSignalKit/SSignalKit.h>

@interface MemoryImageCacheItem : NSObject

@property (nonatomic) id object;
@property (nonatomic, strong) NSDictionary *attributes;
@property (nonatomic) NSUInteger size;
@property (nonatomic) CFAbsoluteTime timestamp;

@end

@implementation MemoryImageCacheItem

- (instancetype)initWithObject:(id)object attributes:(NSDictionary *)attributes size:(NSUInteger)size timestamp:(CFAbsoluteTime)timestamp
{
    self = [super init];
    if (self != nil)
    {
        _object = object;
        _attributes = attributes;
        _size = size;
        _timestamp = timestamp;
    }
    return self;
}

@end

@interface MemoryImageCache ()
{
    SQueue *_queue;
    
    NSUInteger _softMemoryLimit;
    NSUInteger _hardMemoryLimit;
    
    NSMutableDictionary *_cache;
    NSUInteger _cacheSize;
    
    NSMutableDictionary *_averageColors;
}

@end

@implementation MemoryImageCache

- (instancetype)initWithSoftMemoryLimit:(NSUInteger)softMemoryLimit hardMemoryLimit:(NSUInteger)hardMemoryLimit
{
    self = [super init];
    if (self != nil)
    {
        _queue = [SQueue mainQueue];
        _softMemoryLimit = softMemoryLimit;
        _hardMemoryLimit = MAX(hardMemoryLimit, softMemoryLimit);
        _cache = [[NSMutableDictionary alloc] init];
        _averageColors = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)_addSize:(NSUInteger)size
{
    if (_cacheSize + size > _hardMemoryLimit)
    {
        __block NSInteger requiredMemory = _cacheSize + size - _softMemoryLimit;
        
        [[_cache keysSortedByValueUsingComparator:^NSComparisonResult(MemoryImageCacheItem *item1, MemoryImageCacheItem *item2)
        {
            return item1.timestamp < item2.timestamp ? NSOrderedAscending : NSOrderedDescending;
        }] enumerateObjectsUsingBlock:^(id key, __unused NSUInteger idx, BOOL *stop)
        {
            MemoryImageCacheItem *item = _cache[key];
            requiredMemory -= item.size;
            [_cache removeObjectForKey:key];
            
            if (requiredMemory <= 0 && stop != NULL)
                *stop = true;
        }];
        
        __block NSUInteger currentCacheSize = 0;
        [_cache enumerateKeysAndObjectsUsingBlock:^(__unused id key, MemoryImageCacheItem *item, __unused BOOL *stop)
        {
            currentCacheSize += item.size;
        }];
        
        _cacheSize = currentCacheSize;
    }
    
    _cacheSize += size;
}

- (UIImage *)imageForKey:(NSString *)key attributes:(__autoreleasing NSDictionary **)attributes
{
    if (key == nil)
        return nil;
    
    __block id result = nil;
    [_queue dispatchSync:^
    {
        MemoryImageCacheItem *item = _cache[key];
        if (item != nil)
        {
            result = item.object;
            item.timestamp = CFAbsoluteTimeGetCurrent();
            
            if (attributes != NULL)
                *attributes = item.attributes;
        }
    }];
    
    return result;
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key attributes:(NSDictionary *)attributes
{
    if (key != nil)
    {
        [_queue dispatch:^
        {
            MemoryImageCacheItem *item = _cache[key];
            if (item != nil)
            {
                if (item.size > _cacheSize)
                    _cacheSize = 0;
                else
                    _cacheSize -= item.size;
            }
            
            if (image != nil && [image isKindOfClass:[UIImage class]])
            {
                CGSize dimensions = image.size;
                CGFloat scale = image.scale;
                NSUInteger size = (NSUInteger)((dimensions.width * scale * dimensions.height * scale) * 4);
                _cache[key] = [[MemoryImageCacheItem alloc] initWithObject:image attributes:attributes size:size timestamp:CFAbsoluteTimeGetCurrent()];
                [self _addSize:size];
            }
            else
                [_cache removeObjectForKey:key];
        }];
    }
}

- (void)setAverageColor:(uint32_t)color forKey:(NSString *)key
{
    if (key == nil)
        return;
    
    [_queue dispatch:^
    {
        _averageColors[key] = @(color);
    }];
}

- (bool)averageColorForKey:(NSString *)key color:(uint32_t *)color
{
    if (key == nil)
        return nil;
    
    __block bool result = false;
    __block uint32_t resultColor = 0;
    [_queue dispatchSync:^
    {
        NSNumber *nColor = _averageColors[key];
        if (nColor != nil)
        {
            result = true;
            resultColor = (uint32_t)[nColor unsignedIntValue];
        }
    }];
    
    if (color)
        *color = resultColor;
    
    return result;
}

@end
