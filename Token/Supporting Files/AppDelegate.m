#import "AppDelegate.h"

#import "Token-Swift.h"

#import "NotificationsManager.h"
#import "PushManager.h"

#import <SignalServiceKit/TSOutgoingMessage.h>
#import <SignalServiceKit/TSStorageManager.h>
#import <SignalServiceKit/TSStorageManager+keyingMaterial.h>
#import <SignalServiceKit/OWSSyncContactsMessage.h>
#import <SignalServiceKit/NSDate+millisecondTimeStamp.h>
#import <SignalServiceKit/TextSecureKitEnv.h>
#import <SignalServiceKit/OWSIncomingMessageReadObserver.h>
#import <SignalServiceKit/TSSocketManager.h>

@interface AppDelegate ()
@property (nonnull, nonatomic) Cereal *cereal;
@property (nonnull, nonatomic) ChatAPIClient *chatAPIClient;
@property (nonnull, nonatomic) IDAPIClient *idAPIClient;

@property (nonatomic) OWSIncomingMessageReadObserver *incomingMessageReadObserver;
//@property (nonatomic) OWSStaleNotificationObserver *staleNotificationObserver;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
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

        //        [OWSSyncPushTokensJob runWithPushManager:[PushManager sharedManager]
        //                                  accountManager:self.accountManager
        //                                     preferences:[[PropertyListPreferences alloc] init]].then(^{
        //            NSLog(@"Successfully ran syncPushTokensJob.");
        //        }).catch(^(NSError *_Nonnull error) {
        //            NSLog(@"Failed to run syncPushTokensJob with error: %@", error);
        //        });

        [TSPreKeyManager refreshPreKeys];
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
    TSStorageManager *storageManager = [TSStorageManager sharedManager];
    [storageManager setupDatabase];
    [TextSecureKitEnv sharedEnv].notificationsManager = [[NotificationsManager alloc] init];

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

}


- (void)applicationDidEnterBackground:(UIApplication *)application {
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


- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[TSAccountManager sharedInstance] ifRegistered:YES runAsync:^{
        [TSSocketManager becomeActiveFromForeground];
    }];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {

}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"!");
}

@end
