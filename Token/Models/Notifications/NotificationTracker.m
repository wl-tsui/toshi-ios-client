#import "CryptoTools.h"
//#import "FunctionalUtil.h"
#import <SignalServiceKit/Constraints.h>
#import "NotificationTracker.h"

#define MAX_NOTIFICATIONS_TO_TRACK 100
#define NOTIFICATION_PAYLOAD_KEY @"m"

@interface NSArray (FunctionalUtil)

/// Returns true when any of the items in this array match the given predicate.
- (bool)any:(int (^)(id item))predicate;

/// Returns true when all of the items in this array match the given predicate.
- (bool)all:(int (^)(id item))predicate;

/// Returns the first item in this array that matches the given predicate, or else returns nil if none match it.
- (id)firstMatchingElseNil:(int (^)(id item))predicate;

/// Returns an array of all the results of passing items from this array through the given projection function.
- (NSArray *)map:(id (^)(id item))projection;

/// Returns an array of all the results of passing items from this array through the given projection function.
- (NSArray *)filter:(int (^)(id item))predicate;

/// Returns the sum of the doubles in this array of doubles.
- (double)sumDouble;

/// Returns the sum of the unsigned integers in this array of unsigned integers.
- (NSUInteger)sumNSUInteger;

/// Returns the sum of the integers in this array of integers.
- (NSInteger)sumNSInteger;

- (NSDictionary *)keyedBy:(id (^)(id))keySelector;
- (NSDictionary *)groupBy:(id (^)(id value))keySelector;

@end


@implementation NotificationTracker {
    NSMutableArray *_witnessedNotifications;
}

+ (NotificationTracker *)notificationTracker {
    NotificationTracker *notificationTracker     = [NotificationTracker new];
    notificationTracker->_witnessedNotifications = [NSMutableArray new];
    return notificationTracker;
}

- (BOOL)shouldProcessNotification:(NSDictionary *)notification {
    BOOL should = ![self wasNotificationProcessed:notification];
    if (should) {
        [self markNotificationAsProcessed:notification];
    }
    return should;
}

- (void)markNotificationAsProcessed:(NSDictionary *)notification {
    NSData *data = [self getIdForNotification:notification];
    [_witnessedNotifications insertObject:data atIndex:0];

    while (MAX_NOTIFICATIONS_TO_TRACK < _witnessedNotifications.count) {
        [_witnessedNotifications removeLastObject];
    }
}

- (BOOL)wasNotificationProcessed:(NSDictionary *)notification {
    NSData *data = [self getIdForNotification:notification];

    return [_witnessedNotifications any:^int(NSData *previousData) {
      return [data isEqualToData:previousData];
    }];
}

// Uniquely Identify a notification by the hash of the message payload.
- (NSData *)getIdForNotification:(NSDictionary *)notification {
    NSData *data             = [notification[NOTIFICATION_PAYLOAD_KEY] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *notificationHash = [data hashWithSha256];
    return notificationHash;
}

@end

