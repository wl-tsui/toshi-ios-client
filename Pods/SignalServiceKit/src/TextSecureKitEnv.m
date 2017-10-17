//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TextSecureKitEnv.h"

#import "TSAccountManager.h"
#import "PhoneNumberUtil.h"
#import "OWSIdentityManager.h"
#import "TSMessagesManager.h"
#import "TSNetworkManager.h"
#import "TSSocketManager.h"
#import "TSStorageManager.h"
#import "OWSIncomingMessageReadObserver.h"

NS_ASSUME_NONNULL_BEGIN

@interface TextSecureKitEnv ()

@property (nonatomic, readwrite) id<OWSCallMessageHandler> callMessageHandler;
@property (nonatomic, readwrite) id<ContactsManagerProtocol> contactsManager;
@property (nonatomic, readwrite) OWSMessageSender *messageSender;
@property (nonatomic, readwrite) id<NotificationsProtocol> notificationsManager;
@property (nonatomic, readwrite) id<TSPreferences> preferences;

@property (nonatomic, strong, readwrite) TSAccountManager *accountManager;
@property (nonatomic, strong, readwrite) OWSSignalService *signalService;
@property (nonatomic, strong, readwrite) TSSocketManager *socketManager;
@property (nonatomic, strong, readwrite) TSStorageManager *storageManager;

@property (nonatomic, strong, readwrite) PhoneNumberUtil *phoneNumberUtil;

@property (nonatomic, strong, readwrite) TSMessagesManager *messagesManager;
@property (nonatomic, strong, readwrite) TSNetworkManager *networkManager;

@property (nonatomic, strong, readwrite) OWSIdentityManager *identityManager;
@property (nonatomic, strong, readwrite) OWSIncomingMessageReadObserver *incomingMessageReadObserver;

@end

@implementation TextSecureKitEnv

+ (instancetype)sharedEnv {
    static TextSecureKitEnv *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });

    return shared;
}

- (void)setupForNewSession
{
    self.accountManager = [[TSAccountManager alloc] init];
    self.socketManager = [[TSSocketManager alloc] init];
    self.signalService = [[OWSSignalService alloc] init];
    self.phoneNumberUtil = [[PhoneNumberUtil alloc] init];

    self.messagesManager = [[TSMessagesManager alloc] init];
    self.identityManager = [[OWSIdentityManager alloc] init];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"accountmanager: %@\nsocketmanager: %@\nsignalService: %@\nphoneUtils: %@\n message sender: %@\n contactManager: %@\n storageManager: %@\n", self.accountManager, self.socketManager, self.signalService, self.phoneNumberUtil, self.messageSender, self.contactsManager, self.storageManager];
}

- (void)freeUpWithBackup:(BOOL)withBackup
{
    self.accountManager = nil;
    self.socketManager = nil;
    self.phoneNumberUtil = nil;
    self.callMessageHandler = nil;
    self.contactsManager = nil;
    self.messageSender = nil;
    self.notificationsManager = nil;
    self.preferences = nil;
    self.incomingMessageReadObserver = nil;
    self.identityManager = nil;

    [self.storageManager resetSignalStorageWithBackup:withBackup];
    self.storageManager = nil;

    [self.signalService stopObservingNotifications];
    self.signalService = nil;

    [OWSDispatch.shared freeUp];
}

//@synthesize callMessageHandler = _callMessageHandler,
//    contactsManager = _contactsManager,
//    messageSender = _messageSender,
//    notificationsManager = _notificationsManager,
//    preferences = _preferences;

//- (instancetype)initWithCallMessageHandler:(id<OWSCallMessageHandler>)callMessageHandler
//                           contactsManager:(id<ContactsManagerProtocol>)contactsManager
//                             messageSender:(OWSMessageSender *)messageSender
//                      notificationsManager:(id<NotificationsProtocol>)notificationsManager
//                               preferences:(nonnull id<TSPreferences>)preferences
//{
//    self = [super init];
//    if (!self) {
//        return self;
//    }
//
//    self.callMessageHandler = callMessageHandler;
//    self.contactsManager = contactsManager;
//    self.messageSender = messageSender;
//    self.notificationsManager = notificationsManager;
//    self.preferences = preferences;
//
//    return self;
//}

- (void)setupWithCallMessageHandler:(id<OWSCallMessageHandler>)callMessageHandler
                    contactsManager:(id<ContactsManagerProtocol>)contactsManager
                      messageSender:(OWSMessageSender *)messageSender
               notificationsManager:(id<NotificationsProtocol>)notificationsManager
                        preferences:(id<TSPreferences>)preferences
                     storageManager:(TSStorageManager *)storageManager
                     networkManager:(TSNetworkManager *)networkManager
{
    @synchronized (self) {
        [OWSDispatch.shared setupForNewSession];

        self.callMessageHandler = callMessageHandler;
        self.contactsManager = contactsManager;
        self.messageSender = messageSender;
        self.notificationsManager = notificationsManager;
        self.preferences = preferences;
        self.storageManager = storageManager;
        self.networkManager = networkManager;

        self.incomingMessageReadObserver = [[OWSIncomingMessageReadObserver alloc] initWithStorageManager:self.storageManager
                                                                                            messageSender:self.messageSender];

        [self.storageManager setupDatabase];

        [self setupForNewSession];

        NSLog(@"\n\n *** %@ \n\n ---- \n", self);
    }
}

#pragma mark - getters

- (id<OWSCallMessageHandler>)callMessageHandler
{
    NSAssert(_callMessageHandler, @"Trying to access the callMessageHandler before it's set.");
    return _callMessageHandler;
}

- (id<ContactsManagerProtocol>)contactsManager
{
    NSAssert(_contactsManager, @"Trying to access the contactsManager before it's set.");
    return _contactsManager;
}

- (OWSMessageSender *)messageSender
{
    NSAssert(_messageSender, @"Trying to access the messageSender before it's set.");
    return _messageSender;
}

- (id<NotificationsProtocol>)notificationsManager
{
    NSAssert(_notificationsManager, @"Trying to access the notificationsManager before it's set.");
    return _notificationsManager;
}

- (id<TSPreferences>)preferences
{
    NSAssert(_preferences, @"Trying to access preferences before it's set.");
    return _preferences;
}

@end

NS_ASSUME_NONNULL_END

