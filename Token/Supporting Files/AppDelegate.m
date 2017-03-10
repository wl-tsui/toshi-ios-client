#import "AppDelegate.h"

#import "Token-Swift.h"

#import "NSData+ows_StripToken.h"

#import <EtherealCereal/EtherealCereal.h>

#import <SignalServiceKit/OWSSignalService.h>
#import <SignalServiceKit/TSOutgoingMessage.h>
#import <SignalServiceKit/TSStorageManager.h>
#import <SignalServiceKit/TSStorageManager+keyingMaterial.h>
#import <SignalServiceKit/OWSSyncContactsMessage.h>
#import <SignalServiceKit/NSDate+millisecondTimeStamp.h>
#import <SignalServiceKit/TextSecureKitEnv.h>
#import <SignalServiceKit/OWSIncomingMessageReadObserver.h>
#import <SignalServiceKit/TSSocketManager.h>

NSString * const DevelopmentTextSecureWebSocketAPI = @"wss://token-chat-service-development.herokuapp.com/v1/websocket/";
NSString * const DevelopmentTextSecureServerURL = @"https://token-chat-service-development.herokuapp.com";

NSString * const DistributionTextSecureWebSocketAPI = @"wss://token-chat-service.herokuapp.com/v1/websocket/";
NSString * const DistributionTextSecureServerURL = @"https://token-chat-service.herokuapp.com";

@interface AppDelegate ()
@property (nonnull, nonatomic) Cereal *cereal;
@property (nonnull, nonatomic) ChatAPIClient *chatAPIClient;
@property (nonnull, nonatomic) IDAPIClient *idAPIClient;

@property (nonatomic) OWSIncomingMessageReadObserver *incomingMessageReadObserver;

@property (nonatomic) OWSMessageFetcherJob *messageFetcherJob;

@property (nonatomic) NSString *token;
@property (nonatomic) NSString *voipToken;

@end

@implementation AppDelegate
@synthesize token = _token;
@synthesize voipToken = _voipToken;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [TSSocketManager setBaseURL:DistributionTextSecureWebSocketAPI];
    [OWSSignalService setBaseURL:DistributionTextSecureServerURL];

    self.cereal = [[Cereal alloc] init];
    [[TSStorageManager sharedManager] storePhoneNumber:self.cereal.address];

    self.chatAPIClient = [[ChatAPIClient alloc] initWithCereal:self.cereal];
    self.idAPIClient = [[IDAPIClient alloc] initWithCereal:self.cereal];

    [self setupBasicAppearance];
    [self setupTSKitEnv];

    UIApplicationState launchState = application.applicationState;
    [[TSAccountManager sharedInstance] ifRegistered:YES runAsync:^{
        if (launchState == UIApplicationStateInactive) {
            NSLog(@"The app was launched from inactive");
            [TSSocketManager becomeActiveFromForeground];
        } else if (launchState == UIApplicationStateBackground) {
            NSLog(@"The app was launched from being backgrounded");
            [TSSocketManager becomeActiveFromBackgroundExpectMessage:NO];
        } else {
            NSLog(@"The app was launched in an unknown way");
        }

        [TSPreKeyManager refreshPreKeys];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self registerForRemoteNotifications];
        });
    }];

    self.window = [[UIWindow alloc] init];
    self.window.backgroundColor = [Theme viewBackgroundColor];
    self.window.rootViewController = [[TabBarController alloc] initWithChatAPIClient:self.chatAPIClient idAPIClient:self.idAPIClient];

    [self.window makeKeyAndVisible];

    if (User.current == nil) {
        [self.idAPIClient registerUserIfNeeded:^{
            [self.chatAPIClient registerUserIfNeeded];
        }];
    } else {
        [self.idAPIClient retrieveUserWithUsername:[User.current username] completion:^(User * _Nullable user) {
            NSLog(@"%@", user);
            if (user == nil) {
                [self.idAPIClient registerUserIfNeeded:^{
                    [self.chatAPIClient registerUserIfNeeded];
                }];
            }
        }];
    }

    return YES;
}

- (void)setupBasicAppearance {
    NSDictionary *attributtes = @{NSForegroundColorAttributeName: [Theme navigationTitleTextColor], NSFontAttributeName: [Theme boldWithSize:17]};

    UINavigationBar *navBarAppearance = [UINavigationBar appearance];
    [navBarAppearance setTitleTextAttributes:attributtes];
    [navBarAppearance setTintColor:[Theme navigationTitleTextColor]];

    attributtes = @{NSForegroundColorAttributeName: [Theme navigationTitleTextColor], NSFontAttributeName: [Theme regularWithSize:17]};
    UIBarButtonItem *barButtonAppearance = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]];
    [barButtonAppearance setTitleTextAttributes:attributtes forState:UIControlStateNormal];
}

- (void)setupTSKitEnv {
    [TextSecureKitEnv sharedEnv].contactsManager = [[ContactsManager alloc] init];
    [TextSecureKitEnv sharedEnv].notificationsManager = [[SignalNotificationManager alloc] init];
    TSStorageManager *storageManager = [TSStorageManager sharedManager];
    [storageManager setupDatabase];

    self.networkManager = [TSNetworkManager sharedManager];
    self.contactsManager = [[ContactsManager alloc] init];
    self.contactsUpdater = [[ContactsUpdater alloc] init];

    self.messageSender = [[OWSMessageSender alloc] initWithNetworkManager:self.networkManager storageManager:storageManager contactsManager:self.contactsManager contactsUpdater:self.contactsUpdater];

    self.incomingMessageReadObserver = [[OWSIncomingMessageReadObserver alloc] initWithStorageManager:storageManager messageSender:self.messageSender];
    [self.incomingMessageReadObserver startObserving];

//    self.staleNotificationObserver = [OWSStaleNotificationObserver new];
//    [self.staleNotificationObserver startObserving];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [SignalNotificationManager updateApplicationBadgeNumber];

    UIBackgroundTaskIdentifier __block bgTask = UIBackgroundTaskInvalid;
    bgTask = [application beginBackgroundTaskWithExpirationHandler:^{ }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([TSAccountManager isRegistered]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [TSSocketManager resignActivity];
            });
        }

        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    });
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [SignalNotificationManager updateApplicationBadgeNumber];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [SignalNotificationManager updateApplicationBadgeNumber];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[TSAccountManager sharedInstance] ifRegistered:YES runAsync:^{
        // We're double checking that the app is active, to be sure since we
        // can't verify in production env due to code
        // signing.
        [TSSocketManager becomeActiveFromForeground];
    }];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Accessors 

- (NSString *)token {
    if (!_token) {
        _token = @"";
    }

    return _token;
}

- (NSString *)voipToken {
    if (!_voipToken) {
        _voipToken = @"";
    }

    return _voipToken;
}

- (void)setToken:(NSString *)token {
    _token = token;

    [self updateRemoteNotificationCredentials];
}

- (void)setVoipToken:(NSString *)voipToken {
    _voipToken = voipToken;

    [self updateRemoteNotificationCredentials];
}

#pragma mark - Push notifications

- (void)registerForRemoteNotifications {
    UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;

    [center requestAuthorizationWithOptions:authOptions completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (error){
            @throw error.localizedDescription;
        } else if (granted) {
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
    }];

    OWSSignalService *signalService = [OWSSignalService new];
    self.messageFetcherJob = [[OWSMessageFetcherJob alloc] initWithMessagesManager:[TSMessagesManager sharedManager] messageSender:self.messageSender networkManager:self.networkManager signalService:signalService];

    PKPushRegistry *voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    voipRegistry.delegate = self;
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)updateRemoteNotificationCredentials {
    [[TSAccountManager sharedInstance] registerForPushNotificationsWithPushToken:self.token voipToken:self.voipToken success:^{
        NSLog(@"TOKEN: chat PN register - SUCCESS: token: %@, voip: %@", self.token, self.voipToken);

        [[EthereumAPIClient shared] registerForNotifications: ^(BOOL success){
            if (success) {
                [[EthereumAPIClient shared] registerForPushNotificationsWithDeviceToken:self.token];
            }
        }];

    } failure:^(NSError * _Nonnull error) {
        NSLog(@"TOKEN: chat PN register - FAILURE: %@", error.localizedDescription);
    }];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type {
    [self.messageFetcherJob runAsync];
}

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(PKPushType)type {

}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(PKPushType)type {
    self.voipToken = [credentials.token ows_tripToken];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    [BackgroundNotificationHandler handle:notification :^(UNNotificationPresentationOptions options) {
        completionHandler(options);
    }];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {

    NSLog(@"Handle action for %@.", response);

    completionHandler();
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {

    [SignalNotificationHandler handleMessage:userInfo completion:^(UIBackgroundFetchResult result) {
        if (result == UIBackgroundFetchResultNewData) {
            [self.messageFetcherJob runAsync];
        }

        completionHandler(result);
    }];

    [EthereumNotificationHandler handlePayment:userInfo completion:^(UIBackgroundFetchResult result) {
        completionHandler(result);
    }];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    self.token = [deviceToken hexadecimalString];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"!");
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler {

    NSLog(@"!");
}

@end
