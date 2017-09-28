#import "YapDatabaseManager.h"
#import <libkern/OSAtomic.h>

/**
 * There should only be one YapDatabase or YapCollectionDatabase per file.
 *
 * The architecture design is to create a single parent database instance,
 * and then spawn connections to the database as needed from the parent.
 *
 * The architecture is built around this restriction, and is dependent upon it for proper operation.
 * This class simply helps maintain this requirement.
**/

@interface YapDatabaseManager()

@property (nonatomic, copy) NSArray <NSString *> *registeredPaths;

@end


@implementation YapDatabaseManager


static OSSpinLock lock;

+ (instancetype)shared
{
    static YapDatabaseManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
   self = [super init];
    if (self) {

        self.registeredPaths = [NSArray array];
    }

    return self;
}

- (BOOL)registerDatabaseForPath:(NSString *)path
{
	if (path == nil) return NO;
	
	// Note: The path has already been standardized by the caller (path = [inPath stringByStandardizingPath]).
	
	BOOL result = NO;

	if (![self.registeredPaths containsObject:path])
	{
        NSMutableArray <NSString *> *copiedPaths = [self.registeredPaths mutableCopy];
		[copiedPaths addObject:path];
        self.registeredPaths = [copiedPaths copy];
		result = YES;
	}
	
	return result;
}

- (void)deregisterDatabaseForPath:(NSString *)inPath
{
	NSString *path = [inPath stringByStandardizingPath];
	if (path == nil) return;

    NSMutableArray <NSString *> *copiedPaths = [self.registeredPaths mutableCopy];
    [copiedPaths removeObject:path];
    self.registeredPaths = [copiedPaths copy];

    NSLog(@"%@", self.registeredPaths);
    //self.registeredPaths = nil;
}

@end
