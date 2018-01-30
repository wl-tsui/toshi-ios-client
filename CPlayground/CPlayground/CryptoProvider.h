//
//  CryptoProvider.h
//  CPlayground
//
//  Created by Ellen Shapiro (Work) on 1/30/18.
//  Copyright © 2018 Toshi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Signal.h"


@interface CryptoProvider : NSObject

+ (void)addDefaultProviderToContext:(signal_context *)context;

@end
