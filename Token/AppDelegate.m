#import "AppDelegate.h"
#import "ViewController.h"
#import "Token-Swift.h"
#import "ContactsManager.h"
#import <SignalServiceKit/TSNetworkManager.h>
#import <SignalServiceKit/OWSMessageSender.h>
#import <SignalServiceKit/TSOutgoingMessage.h>
#import <SignalServiceKit/TSStorageManager.h>
#import <SignalServiceKit/TSStorageManager+keyingMaterial.h>
#import <SignalServiceKit/TSContactThread.h>
#import <SignalServiceKit/ContactsUpdater.h>
#import <SignalServiceKit/OWSSyncContactsMessage.h>
#import <SignalServiceKit/NSDate+millisecondTimeStamp.h>

@interface AppDelegate ()
@property (nonnull, nonatomic) Cereal *cereal;
@property (nonnull, nonatomic) ChatAPIClient *chatAPIClient;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.cereal = [[Cereal alloc] init];
    self.chatAPIClient = [[ChatAPIClient alloc] initWithCereal:self.cereal];

    self.window = [[UIWindow alloc] init];
    self.window.rootViewController = [[ViewController alloc] init];
    [self.window makeKeyAndVisible];

    TSStorageManager *storageManager = [TSStorageManager sharedManager];
    [storageManager setupDatabase];

    [storageManager storePhoneNumber:self.cereal.address];

    [self.chatAPIClient registerUserIfNeeded];

//    return YES;

//    NSString *simulator = @"0x29b96e7e01dee80c192092657a575006dba902ef";
//    NSString *device = @"0xb47449f74efb5bfa98e0744b901c54468b93172c";
    NSString *colin = @"0x26dd4687ce139f929d538a2f18818f8368cfad86";

    //    [self retrieveMessagesFrom:colin];
    [self sendMessageTo:colin];

    return YES;
}

- (void)retrieveMessagesFrom:(NSString *)address {
    __block TSThread *thread;

    [[TSStorageManager sharedManager].dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
        thread = [TSContactThread getOrCreateThreadWithContactId:address transaction:transaction];

        [transaction objectForKey:thread.uniqueId inCollection:nil];
    }];

    NSLog(@"%@", thread);
}

- (void)sendMessageTo:(NSString *)recipientAddress {

    [[TSStorageManager sharedManager].dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        SignalRecipient *recipient = [SignalRecipient recipientWithTextSecureIdentifier:recipientAddress withTransaction:transaction];
        if (!recipient) {
            recipient = [[SignalRecipient alloc] initWithTextSecureIdentifier:recipientAddress relay:nil supportsVoice:NO];
        }

        [recipient saveWithTransaction:transaction];
    }];


    __block TSThread *thread;

    [[TSStorageManager sharedManager].dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
        thread = [TSContactThread getOrCreateThreadWithContactId:recipientAddress transaction:transaction];
    }];

    TSNetworkManager *networkManager = [TSNetworkManager sharedManager];
    ContactsManager *contactsManager = [[ContactsManager alloc] init];
    ContactsUpdater *contactsUpdater = [[ContactsUpdater alloc] init];
    OWSMessageSender *messageSender = [[OWSMessageSender alloc] initWithNetworkManager:networkManager storageManager:[TSStorageManager sharedManager] contactsManager:contactsManager contactsUpdater:contactsUpdater];
    TSOutgoingMessage *message = [[TSOutgoingMessage alloc] initWithTimestamp:[NSDate ows_millisecondTimeStamp] inThread:thread messageBody:@"This is a test message"];

    [messageSender sendMessage:message success:^{
        NSLog(@"Success! Message sent!");
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"Failed: %@", error);
    }];

}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
