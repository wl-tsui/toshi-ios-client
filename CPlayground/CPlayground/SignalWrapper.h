//
//  SignalWrapper.h
//  CPlayground
//
//  Created by Ellen Shapiro (Work) on 1/26/18.
//  Copyright © 2018 Toshi. All rights reserved.
//

@import Foundation;

/**
 Convenience wrapper around libsignal-protocol-c, because nobody likes trying to do C stuff in Swift.

 Nobody.
 */
@interface SignalWrapper : NSObject

/**
 Attempts to generate and save registration identifier.

 @return YES if both are generated successfully,
 */
+ (BOOL)generateAndSaveRegistrationID;


/**
 Generates a set of pre-keys of the given size from the given offset.

 @param count How many prekeys do you want to generate?
 @param startIndex Where to start in the user's overall index of prekeys
 @return YES if the prekeys were generated and saved. NO if not.
 */
+ (BOOL)generatePreKeys:(NSUInteger)count withStartIndex:(NSUInteger)startIndex;

@end
