#import "Yap.h"
#import <YapDatabase/YapDatabase.h>

@interface Yap()
@property (nonnull, nonatomic) YapDatabase *database;
@property (nonnull, nonatomic) YapDatabaseConnection *mainConnection;
@end

@implementation Yap

+ (nonnull instancetype)sharedYap {
    static Yap *_yap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _yap = [[Yap alloc] init];
    });

    return _yap;
}

- (instancetype)init {
    self = [super init];

    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *documentURL = [[[fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject] URLByAppendingPathComponent:@"Token.sqlite"];

    YapDatabaseOptions *options = [[YapDatabaseOptions alloc] init];
    options.corruptAction = YapDatabaseCorruptAction_Fail;
    options.cipherKeyBlock      = ^{
        return [self databasePassword];
    };

    self.database = [[YapDatabase alloc] initWithPath:documentURL.absoluteString options:options];
    self.mainConnection = [self.database newConnection];

    return self;
}

- (NSData *)databasePassword {
    return [@"ThisIsMyDatabasePasswordChangeThisPlease" dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark - Insert

- (void)insertObject:(nullable id)object forKey:(nonnull NSString *)key inCollection:(nullable NSString *)collection {
    [self insertObject:object forKey:key inCollection:collection withMetadata:nil];
}

- (void)insertObject:(nullable id)object forKey:(nonnull NSString *)key {
    [self insertObject:object forKey:key inCollection:nil withMetadata:nil];
}

- (void)insertObject:(nullable id)object forKey:(nonnull NSString *)key inCollection:(nullable NSString *)collection withMetadata:(nullable NSString *)metadata {
    [self.mainConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [transaction setObject:object forKey:key inCollection:collection withMetadata:metadata];
    }];
}

#pragma mark - Contains

- (BOOL)containsObjectForKey:(nonnull NSString *)key {
    return [self containsObjectForKey:key inCollection:nil];
}

- (BOOL)containsObjectForKey:(nonnull NSString *)key inCollection:(nullable NSString *)collection {
    return [self containsObjectForKey:key inCollection:nil];
}

#pragma mark - Retrieve

- (nullable id)retrieveObjectForKey:(nonnull NSString *)key {
    return [self retrieveObjectForKey:key inCollection:nil];
}

- (nullable id)retrieveObjectForKey:(nonnull NSString *)key inCollection:(nullable NSString *)collection {
    __block id object = nil;

    [self.mainConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        object = [transaction objectForKey:key inCollection:collection];
    }];

    return object;
}

@end
