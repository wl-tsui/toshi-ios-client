#import "StaticBackdropImageData.h"

NSString *StaticBackdropMessageActionCircle = @"StaticBackdropMessageActionCircle";
NSString *StaticBackdropMessageTimestamp = @"StaticBackdropMessageTimestamp";
NSString *StaticBackdropMessageAdditionalData = @"StaticBackdropMessageAdditionalData";

@interface StaticBackdropImageData ()
{
    NSMutableDictionary *_areas;
}

@end

@implementation StaticBackdropImageData

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _areas = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (StaticBackdropAreaData *)backdropAreaForKey:(NSString *)key
{
    if (key == nil)
        return nil;
    
    return _areas[key];
}

- (void)setBackdropArea:(StaticBackdropAreaData *)backdropArea forKey:(NSString *)key
{
    if (key != nil)
    {
        if (backdropArea == nil)
            [_areas removeObjectForKey:key];
        else
            _areas[key] = backdropArea;
    }
}

@end
