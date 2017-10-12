//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@protocol ContactsManagerProtocol;
@class OWSMessageSender;
@protocol NotificationsProtocol;
@protocol OWSCallMessageHandler;
@protocol TSPreferences;

@class TSAccountManager, TSSocketManager, TSStorageManager, OWSSignalService, OWSIdentityManager, OWSIncomingMessageReadObserver, PhoneNumberUtil, TSMessagesManager, TSNetworkManager;

@interface TextSecureKitEnv : NSObject

- (void)setupWithCallMessageHandler:(id<OWSCallMessageHandler>)callMessageHandler
                    contactsManager:(id<ContactsManagerProtocol>)contactsManager
                      messageSender:(OWSMessageSender *)messageSender
               notificationsManager:(id<NotificationsProtocol>)notificationsManager
                        preferences:(id<TSPreferences>)preferences
                     storageManager:(TSStorageManager *)storageManager
                     networkManager:(TSNetworkManager *)networkManager
NS_SWIFT_NAME(setup(callMessageHandler:contactsManager:messageSender:notificationsManager:preferences:storageManager:networkManager:));


+ (instancetype)sharedEnv
NS_SWIFT_NAME(shared);

- (void)setupForNewSession;

- (void)freeUpWithBackup:(BOOL)withBackup;

@property (nonatomic, readonly) id<OWSCallMessageHandler> callMessageHandler;
@property (nonatomic, readonly) id<ContactsManagerProtocol> contactsManager;
@property (nonatomic, readonly) OWSMessageSender *messageSender;
@property (nonatomic, readonly) id<NotificationsProtocol> notificationsManager;
@property (nonatomic, readonly) id<TSPreferences> preferences;

@property (nonatomic, strong, readonly) TSAccountManager *accountManager;
@property (nonatomic, strong, readonly) OWSSignalService *signalService;
@property (nonatomic, strong, readonly) TSSocketManager *socketManager;
@property (nonatomic, strong, readonly) TSStorageManager *storageManager;

@property (nonatomic, strong, readonly) PhoneNumberUtil *phoneNumberUtil;

@property (nonatomic, strong, readonly) TSMessagesManager *messagesManager;
@property (nonatomic, strong, readonly) TSNetworkManager *networkManager;

@property (nonatomic, strong, readonly) OWSIdentityManager *identityManager;
@property (nonatomic, strong, readonly) OWSIncomingMessageReadObserver *incomingMessageReadObserver;

@end

NS_ASSUME_NONNULL_END
