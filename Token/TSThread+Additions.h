#import <Foundation/Foundation.h>
#import <SignalServiceKit/TSMessage.h>
#import <SignalServiceKit/TSThread.h>

@interface TSThread (Additions)

@property (nonatomic, readonly) NSArray<TSMessage *> *visibleIncomingInteractions;

- (NSArray<TSInteraction *> *)allInteractions;

@end
