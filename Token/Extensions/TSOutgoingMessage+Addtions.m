//
//  TSOutgoingMessage.m
//  Token
//
//  Created by Igor Ranieri on 28.04.17.
//  Copyright © 2017 Bakken&Bæck. All rights reserved.
//

#import "TSOutgoingMessage.h"

@interface TSOutgoingMessage ()
@property (atomic, readwrite) TSOutgoingMessageState messageState;
@end

@implementation TSOutgoingMessage (Additions)

- (void)setState:(TSOutgoingMessageState)state {
    self.messageState = state;
}

@end
