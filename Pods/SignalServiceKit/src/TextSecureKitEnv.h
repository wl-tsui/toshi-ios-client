//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@protocol ContactsManagerProtocol;
@class OWSMessageSender;
@protocol NotificationsProtocol;
@protocol OWSCallMessageHandler;
@protocol TSPreferences;

@interface TextSecureKitEnv : NSObject

- (instancetype)initWithCallMessageHandler:(id<OWSCallMessageHandler>)callMessageHandler
                           contactsManager:(id<ContactsManagerProtocol>)contactsManager
                             messageSender:(OWSMessageSender *)messageSender
                      notificationsManager:(id<NotificationsProtocol>)notificationsManager
                               preferences:(id<TSPreferences>)preferences
NS_SWIFT_NAME(init(callMessageHandler:contactsManager:messageSender:notificationsManager:preferences:));

- (void)setupWithCallMessageHandler:(id<OWSCallMessageHandler>)callMessageHandler
                    contactsManager:(id<ContactsManagerProtocol>)contactsManager
                      messageSender:(OWSMessageSender *)messageSender
               notificationsManager:(id<NotificationsProtocol>)notificationsManager
                        preferences:(id<TSPreferences>)preferences
NS_SWIFT_NAME(setup(callMessageHandler:contactsManager:messageSender:notificationsManager:preferences:));

+ (instancetype)sharedEnv;
+ (void)setSharedEnv:(nullable TextSecureKitEnv *)env;

@property (nonatomic, readonly) id<OWSCallMessageHandler> callMessageHandler;
@property (nonatomic, readonly) id<ContactsManagerProtocol> contactsManager;
@property (nonatomic, readonly) OWSMessageSender *messageSender;
@property (nonatomic, readonly) id<NotificationsProtocol> notificationsManager;
@property (nonatomic, readonly) id<TSPreferences> preferences;

@end

NS_ASSUME_NONNULL_END
