//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OWSDispatch : NSObject

/**
 * Attachment downloading
 */
@property (nonatomic, strong, readonly) dispatch_queue_t attachmentsQueue;

/**
 * Signal protocol session state must be coordinated on a serial queue. This is sometimes used synchronously,
 * so never dispatching sync *from* this queue to avoid deadlock.
 */
@property (nonatomic, strong, readonly) dispatch_queue_t sessionStoreQueue;

/**
 * Serial message sending queue
 */
@property (nonatomic, strong, readonly) dispatch_queue_t sendingQueue;

+ (instancetype)shared;

- (void)freeUp;

- (void)setupForNewSession;

@end

void AssertIsOnMainThread();

NS_ASSUME_NONNULL_END

