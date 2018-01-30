//
//  SignalWrapper+Tests.h
//  CPlaygroundTests
//
//  Created by Ellen Shapiro (Work) on 1/30/18.
//  Copyright © 2018 Toshi. All rights reserved.
//

#import "SignalWrapper.h"
#import "Signal.h"

@interface SignalWrapper (Tests)

+ (signal_protocol_address)addressFromString:(nonnull NSString *)string;

+ (nullable ratchet_identity_key_pair *)identityKeyPair;

+ (uint32_t)registrationID;


@end
