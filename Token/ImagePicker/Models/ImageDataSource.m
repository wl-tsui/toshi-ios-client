#import "ImageDataSource.h"

@implementation ImageDataSource

+ (NSMutableArray *)_dataSourceList
{
    static NSMutableArray *array = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        array = [[NSMutableArray alloc] init];
    });
    
    return array;
}

+ (void)registerDataSource:(ImageDataSource *)dataSource
{
    if (dataSource == nil)
        return;
    
    if (![[self _dataSourceList] containsObject:dataSource])
        [[self _dataSourceList] addObject:dataSource];
}

+ (void)enumerateDataSources:(bool (^)(ImageDataSource *dataSource))handler
{
    if (!handler)
        return;
    
    [[self _dataSourceList] enumerateObjectsUsingBlock:^(ImageDataSource *dataSource, __unused NSUInteger idx, BOOL *stop)
    {
        if (handler(dataSource) && stop != NULL)
            *stop = true;
    }];
}

+ (void)enqueueImageProcessingBlock:(void (^)())imageProcessingBlock
{
    static dispatch_queue_t queue = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        queue = dispatch_queue_create("ph.telegra.datasourceimageprocessing", 0);
    });
    
    dispatch_async(queue, imageProcessingBlock);
}

- (bool)canHandleUri:(NSString *)__unused uri
{
    return false;
}

- (bool)canHandleAttributeUri:(NSString *)__unused uri
{
    return false;
}

- (DataResource *)loadDataSyncWithUri:(NSString *)__unused uri canWait:(bool)__unused canWait acceptPartialData:(bool)__unused acceptPartialData asyncTaskId:(__autoreleasing id *)__unused asyncTaskId progress:(void (^)(float))__unused progress partialCompletion:(void (^)(DataResource *))__unused partialCompletion completion:(void (^)(DataResource *))__unused completion
{
    return nil;
}

- (id)loadDataAsyncWithUri:(NSString *)__unused uri progress:(void (^)(float progress))__unused progress partialCompletion:(void (^)(DataResource *resource))__unused partialCompletion completion:(void (^)(DataResource *resource))__unused completion
{
    return nil;
}

- (id)loadAttributeSyncForUri:(NSString *)__unused uri attribute:(NSString *)__unused attribute
{
    return nil;
}

- (void)cancelTaskById:(id)__unused taskId
{
}

@end

