#import <UIKit/UIKit.h>
#import <SignalServiceKit/TSNetworkManager.h>
#import <SignalServiceKit/OWSMessageSender.h>
#import <SignalServiceKit/ContactsUpdater.h>
#import "ContactsManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nullable, strong, nonatomic) UIWindow *window;

@property (nonnull, nonatomic) TSNetworkManager *networkManager;
@property (nonnull, nonatomic) ContactsManager *contactsManager;
@property (nonnull, nonatomic) ContactsUpdater *contactsUpdater;
@property (nonnull, nonatomic) OWSMessageSender *messageSender;

@end

