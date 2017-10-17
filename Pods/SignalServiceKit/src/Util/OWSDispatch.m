//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSDispatch.h"

NS_ASSUME_NONNULL_BEGIN

@interface OWSDispatch ()

@property (nonatomic, strong, readwrite) dispatch_queue_t attachmentsQueue;
@property (nonatomic, strong, readwrite) dispatch_queue_t sessionStoreQueue;
@property (nonatomic, strong, readwrite) dispatch_queue_t sendingQueue;

@end

@implementation OWSDispatch

+ (instancetype)shared
{
    static OWSDispatch *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

- (void)freeUp
{
    self.attachmentsQueue = nil;
    self.sessionStoreQueue = nil;
    self.sendingQueue = nil;
}

- (void)setupForNewSession
{
    self.attachmentsQueue = dispatch_queue_create("org.whispersystems.signal.attachments", NULL);
    self.sessionStoreQueue = dispatch_queue_create("org.whispersystems.signal.sessionStoreQueue", NULL);
    self.sendingQueue = dispatch_queue_create("org.whispersystems.signal.sendQueue", NULL);
}

@end

void AssertIsOnMainThread() {
    OWSCAssert([NSThread isMainThread]);
}

NS_ASSUME_NONNULL_END

