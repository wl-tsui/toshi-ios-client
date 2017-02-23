#import <Foundation/Foundation.h>
#import <SignalServiceKit/TSMessage.h>
#import <SignalServiceKit/TSThread.h>
#import <SignalServiceKit/TSIncomingMessage.h>

@interface TSThread (Additions)

@property (nonatomic, readonly) NSArray<TSIncomingMessage *> *visibleIncomingInteractions;

- (NSArray<TSInteraction *> *)allInteractions;

@end
