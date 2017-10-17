//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSStorageManager+SessionStore.h"
#import <AxolotlKit/SessionRecord.h>
#import "TSPreKeyManager.h"

NSString *const TSStorageManagerSessionStoreCollection = @"TSStorageManagerSessionStoreCollection";
NSString *const kSessionStoreDBConnectionKey = @"kSessionStoreDBConnectionKey";

void AssertIsOnSessionStoreQueue()
{
#ifdef DEBUG
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(10, 0)) {
        dispatch_assert_queue([OWSDispatch.shared sessionStoreQueue]);
    } // else, skip assert as it's a development convenience.
#endif
}

@implementation TSStorageManager (SessionStore)

/**
 * Special purpose dbConnection which disables the object cache to better enforce transaction semantics on the store.
 * Note that it's still technically possible to access this collection from a different collection,
 * but that should be considered a bug.
 */

#pragma mark - SessionStore

- (SessionRecord *)loadSession:(NSString *)contactIdentifier deviceId:(int)deviceId
{
    AssertIsOnSessionStoreQueue();

    __block NSDictionary *dictionary;
    //    [self.sessionDBConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
    //        dictionary = [transaction objectForKey:contactIdentifier inCollection:TSStorageManagerSessionStoreCollection];
    //    }];

    SessionRecord *record;

    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:contactIdentifier];
    dictionary = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];;

    NSLog(@" \n\n - Dictionary %@ loaded for %@ \n\n  -", dictionary, contactIdentifier);

    if (dictionary) {
        record = [dictionary objectForKey:@(deviceId)];
    }

    if (!record) {
        NSLog(@"\n\n ---------- \n - Creating new session record for %@ \n\n ---------- \n.", contactIdentifier);
        return [SessionRecord new];
    }

    NSLog(@"\n\n ############################### \n - Session state key: %@ contactID: %@ \n\n#####", record.sessionState.remoteIdentityKey, contactIdentifier);

    return record;
}

- (NSArray *)subDevicesSessions:(NSString *)contactIdentifier
{
    // Deprecated. We aren't currently using this anywhere, but it's "required" by the SessionStore protocol.
    // If we are going to start using it I'd want to re-verify it works as intended.
    OWSAssert(NO);
    AssertIsOnSessionStoreQueue();

    __block NSDictionary *dictionary;
    //    [self.sessionDBConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
    //        dictionary = [transaction objectForKey:contactIdentifier inCollection:TSStorageManagerSessionStoreCollection];
    //    }];

    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:contactIdentifier];
    dictionary =  (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];

    return dictionary ? dictionary.allKeys : @[];
}

- (void)storeSession:(NSString *)contactIdentifier deviceId:(int)deviceId session:(SessionRecord *)session
{
    AssertIsOnSessionStoreQueue();

    // We need to ensure subsequent usage of this SessionRecord does not consider this session as "fresh". Normally this
    // is achieved by marking things as "not fresh" at the point of deserialization - when we fetch a SessionRecord from
    // YapDB (initWithCoder:). However, because YapDB has an object cache, rather than fetching/deserializing, it's
    // possible we'd get back *this* exact instance of the object (which, at this point, is still potentially "fresh"),
    // thus we explicitly mark this instance as "unfresh", any time we save.
    // NOTE: this may no longer be necessary now that we have a non-caching session db connection.
    [session markAsUnFresh];

    __block NSDictionary *immutableDictionary;
    //    [self.sessionDBConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
    //        immutableDictionary =
    //        [transaction objectForKey:contactIdentifier inCollection:TSStorageManagerSessionStoreCollection];
    //    }];

    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:contactIdentifier];
    immutableDictionary =  (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSMutableDictionary *dictionary = [immutableDictionary mutableCopy];

    if (!dictionary) {
        dictionary = [NSMutableDictionary dictionary];
    }

    [dictionary setObject:session forKey:@(deviceId)];

    NSLog(@"\n\n --------- \n Storing session dictionary for \n key %@ \n\n --------", contactIdentifier);

    NSData *myData = [NSKeyedArchiver archivedDataWithRootObject:[dictionary copy]];
    [[NSUserDefaults standardUserDefaults] setObject:myData forKey:contactIdentifier];

    //    [self.sessionDBConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
    //        [transaction setObject:[dictionary copy]
    //                        forKey:contactIdentifier
    //                  inCollection:TSStorageManagerSessionStoreCollection];
    //    }];

    NSLog(@"Test after storing \n\n .");
    SessionRecord *testRecord = [self loadSession:contactIdentifier deviceId:deviceId];
    NSLog(@"Loaded session record: %@", testRecord);
}

- (BOOL)containsSession:(NSString *)contactIdentifier deviceId:(int)deviceId
{
    AssertIsOnSessionStoreQueue();

    return [self loadSession:contactIdentifier deviceId:deviceId].sessionState.hasSenderChain;
}

- (void)deleteSessionForContact:(NSString *)contactIdentifier deviceId:(int)deviceId
{
    AssertIsOnSessionStoreQueue();
    DDLogInfo(
              @"[TSStorageManager (SessionStore)] deleting session for contact: %@ device: %d", contactIdentifier, deviceId);

    __block NSDictionary *immutableDictionary;
    //    [self.sessionDBConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
    //        immutableDictionary =
    //        [transaction objectForKey:contactIdentifier inCollection:TSStorageManagerSessionStoreCollection];
    //    }];

    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:contactIdentifier];
    immutableDictionary =  (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSMutableDictionary *dictionary = [immutableDictionary mutableCopy];

    if (!dictionary) {
        dictionary = [NSMutableDictionary dictionary];
    }

    [dictionary removeObjectForKey:@(deviceId)];

    //    [self.sessionDBConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
    //        [transaction setObject:[dictionary copy]
    //                        forKey:contactIdentifier
    //                  inCollection:TSStorageManagerSessionStoreCollection];
    //    }];

    NSData *myData = [NSKeyedArchiver archivedDataWithRootObject:dictionary];

    [[NSUserDefaults standardUserDefaults] setObject:myData forKey:contactIdentifier];
}

- (void)deleteAllSessionsForContact:(NSString *)contactIdentifier
{
    AssertIsOnSessionStoreQueue();
    DDLogInfo(@"[TSStorageManager (SessionStore)] deleting all sessions for contact:%@", contactIdentifier);

    NSLog(@"\n\n ------------------------ \n\n Deleting all sessions for contact: %@ \n\n -------------------------- \n.", contactIdentifier);
    //    [self.sessionDBConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
    //        [transaction removeObjectForKey:contactIdentifier inCollection:TSStorageManagerSessionStoreCollection];
    //    }];

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:contactIdentifier];
}

- (void)archiveAllSessionsForContact:(NSString *)contactIdentifier
{
    AssertIsOnSessionStoreQueue();

    DDLogInfo(@"[TSStorageManager (SessionStore)] archiving all sessions for contact: %@", contactIdentifier);

    __block NSDictionary<NSNumber *, SessionRecord *> *sessionRecords;
    [self.sessionDBConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        sessionRecords =
        [transaction objectForKey:contactIdentifier inCollection:TSStorageManagerSessionStoreCollection];


        for (id deviceId in sessionRecords) {
            id object = sessionRecords[deviceId];
            if (![object isKindOfClass:[SessionRecord class]]) {
                OWSFail(@"Unexpected object in session dict: %@", object);
                continue;
            }

            SessionRecord *sessionRecord = (SessionRecord *)object;
            [sessionRecord archiveCurrentState];
        }

        [transaction setObject:sessionRecords
                        forKey:contactIdentifier
                  inCollection:TSStorageManagerSessionStoreCollection];
    }];
}

#pragma mark - debug

- (void)printAllSessions
{
    AssertIsOnSessionStoreQueue();

    NSString *tag = @"[TSStorageManager (SessionStore)]";
    [self.sessionDBConnection readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
        DDLogDebug(@"%@ All Sessions:", tag);
        [transaction
         enumerateKeysAndObjectsInCollection:TSStorageManagerSessionStoreCollection
         usingBlock:^(NSString *_Nonnull key,
                      id _Nonnull deviceSessionsObject,
                      BOOL *_Nonnull stop) {
             if (![deviceSessionsObject isKindOfClass:[NSDictionary class]]) {
                 OWSAssert(NO);
                 DDLogError(
                            @"%@ Unexpected type: %@ in collection.", tag, deviceSessionsObject);
                 return;
             }
             NSDictionary *deviceSessions = (NSDictionary *)deviceSessionsObject;

             DDLogDebug(@"%@     Sessions for recipient: %@", tag, key);
             [deviceSessions enumerateKeysAndObjectsUsingBlock:^(
                                                                 id _Nonnull key, id _Nonnull sessionRecordObject, BOOL *_Nonnull stop) {
                 if (![sessionRecordObject isKindOfClass:[SessionRecord class]]) {
                     OWSAssert(NO);
                     DDLogError(@"%@ Unexpected type: %@ in collection.",
                                tag,
                                sessionRecordObject);
                     return;
                 }
                 SessionRecord *sessionRecord = (SessionRecord *)sessionRecordObject;
                 SessionState *activeState = [sessionRecord sessionState];
                 NSArray<SessionState *> *previousStates =
                 [sessionRecord previousSessionStates];
                 DDLogDebug(@"%@         Device: %@ SessionRecord: %@ activeSessionState: "
                            @"%@ previousSessionStates: %@",
                            tag,
                            key,
                            sessionRecord,
                            activeState,
                            previousStates);
             }];
         }];
    }];
}

@end

