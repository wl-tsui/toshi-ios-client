#import "WeakReference.h"

@implementation WeakReference

- (instancetype)initWithObject:(id)object
{
    self = [super init];
    if (self != nil)
    {
        self.object = object;
    }
    return self;
}

@end
