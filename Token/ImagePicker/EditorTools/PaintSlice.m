#import "PaintSlice.h"

#import <SSignalKit/SQueue.h>

#import "Painting.h"
#import "PaintUtils.h"

@interface PaintSlice ()
{
    NSData *_data;
    NSString *_fileName;
}
@end

@implementation PaintSlice

- (instancetype)initWithData:(NSData *)data bounds:(CGRect)bounds
{
    self = [super init];
    if (self != nil)
    {
        _bounds = bounds;
        _data = data;
        _fileName = [self _generatefileName];
        
        [[PaintSlice queue] dispatch:^
        {
            [PaintGZipDeflate(_data) writeToFile:_fileName atomically:true];
            [[SQueue mainQueue] dispatch:^
            {
                _data = nil;
            }];
        }];
    }
    return self;
}

- (void)dealloc
{
    if (_fileName != nil)
        [[NSFileManager defaultManager] removeItemAtPath:_fileName error:NULL];
}

- (instancetype)swappedSliceForPainting:(Painting *)painting
{
    NSData *paintingData = nil;
    [painting imageDataForRect:self.bounds resultPaintingData:&paintingData];
    return [[PaintSlice alloc] initWithData:paintingData bounds:self.bounds];
}

- (NSData *)data
{
    if (_data != nil)
        return _data;
    else if (_fileName != nil)
        return PaintGZipInflate([[NSData alloc] initWithContentsOfFile:_fileName]);
    else
        return nil;
}

- (NSString *)_generatefileName
{
    static uint32_t identifier = 0;
    return [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%u.slice", identifier++]];
}

+ (SQueue *)queue
{
    static dispatch_once_t onceToken;
    static SQueue *queue;
    dispatch_once(&onceToken, ^
    {
        queue = [SQueue wrapConcurrentNativeQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)];
    });
    return queue;
}

@end
