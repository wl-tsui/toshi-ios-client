#import "TSThread+Additions.h"

@implementation TSThread (Additions)

- (NSArray<TSMessage *> *)visibleInteractions {
    NSMutableArray *visible = [NSMutableArray array];

    for (TSInteraction *interaction in self.allInteractions) {
        if ([interaction isKindOfClass:[TSMessage class]]) {
            NSString *body = ((TSMessage *)interaction).body;
            // We use hard-coded strings here since the constants for them are declared inside a swift enum
            // hence inaccessible through Objective C. Since we only use it here, I left them as literals.g
            if ([body hasPrefix:@"SOFA::Message:"] || [body hasPrefix:@"SOFA::PaymentRequest:"]) {
                [visible addObject:interaction];
            }
        }
    }

    return visible;
}

@end
