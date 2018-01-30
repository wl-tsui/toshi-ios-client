//
//  SignalWrappper.m
//  CPlayground
//
//  Created by Ellen Shapiro (Work) on 1/26/18.
//  Copyright © 2018 Toshi. All rights reserved.
//

#import "SignalWrapper.h"

#import "CryptoProvider.h"
#import "NSDate+OWS.h"
#import "Signal.h"

@implementation SignalWrapper

+ (signal_context *)globalContext
{
    static signal_context *_globalContext;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //TODO: Figure out what the hell the userdata is they need here

        signal_context_create(&_globalContext, NULL);
        [CryptoProvider addDefaultProviderToContext:_globalContext];
    });

    return _globalContext;
}

+ (signal_protocol_store_context *)storeContext
{
    static signal_protocol_store_context *_storeContext;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        signal_protocol_session_store *sessionStore;
        signal_protocol_pre_key_store *preKeyStore;
        signal_protocol_signed_pre_key_store *signedPreKeyStore;
        signal_protocol_identity_key_store *identityKeyStore;
        signal_protocol_store_context_create(&_storeContext, [self globalContext]);
        signal_protocol_store_context_set_session_store(_storeContext, sessionStore);
        signal_protocol_store_context_set_pre_key_store(_storeContext, preKeyStore);
        signal_protocol_store_context_set_signed_pre_key_store(_storeContext, signedPreKeyStore);
        signal_protocol_store_context_set_identity_key_store(_storeContext, identityKeyStore);
    });


    return _storeContext;
}

+ (BOOL)generateAndSaveRegistrationID
{
    signal_context *globalContext = [self globalContext];

    ratchet_identity_key_pair *identityKeyPair;
    uint32_t registrationID;
    signal_protocol_key_helper_generate_identity_key_pair(&identityKeyPair,
                                                          globalContext);
    signal_protocol_key_helper_generate_registration_id(&registrationID,
                                                        0,
                                                        globalContext);

    if (identityKeyPair == nil) {
        NSLog(@"Identity key pair was nil!");
        return NO;
    }

    [self storeIdentityKeyPair:identityKeyPair];

    if (registrationID == 0) {
        NSLog(@"Registration identifier was 0!");
        return NO;
    }

    [self storeRegistrationID:registrationID];

    return YES;
}

+ (BOOL)generatePreKeys:(NSUInteger)count withStartIndex:(NSUInteger)startIndex
{
    signal_context *globalContext = [self globalContext];
    ratchet_identity_key_pair *identityKeyPair = [self identityKeyPair];

    signal_protocol_key_helper_pre_key_list_node *preKeysHead;
    session_signed_pre_key *signedPreKey;

    signal_protocol_key_helper_generate_pre_keys(&preKeysHead,
                                                 (unsigned int)startIndex,
                                                 (unsigned int)count,
                                                 globalContext);

    signal_protocol_key_helper_generate_signed_pre_key(&signedPreKey,
                                                       identityKeyPair,
                                                       5,
                                                       [NSDate ows_millisecondTimeStamp],
                                                       globalContext);

    if (preKeysHead == nil) {
        return NO;
    }

    [self storePreKeys:preKeysHead];

    if (signedPreKey == nil) {
        return NO;
    }

    [self storeSignedPreKey:signedPreKey];

    return YES;
}

#pragma mark - Storing things

static ratchet_identity_key_pair *_keyPair;

+ (void)storeIdentityKeyPair:(ratchet_identity_key_pair *)keyPair
{
    // TODO: Replace with actual persistence
    _keyPair = keyPair;
    /* Store identity_key_pair somewhere durable and safe. */

//    uint8_t public = keyPair->publicKey->data;

//    keyPair.publicKey.data
}

+ (ratchet_identity_key_pair *)identityKeyPair
{
    return _keyPair;
}

static uint32_t _registrationID;

+ (void)storeRegistrationID:(uint32_t)registrationID
{
    // TODO: Use actual persistence
    _registrationID = registrationID;
    /* Store registration_id somewhere durable and safe. */
}

+ (uint32_t)registrationID
{
    // TODO: Use actual persistence
    return _registrationID;
}

+ (void)storePreKeys:(signal_protocol_key_helper_pre_key_list_node *)preKeys
{
    /* Store pre keys in the pre key store. */

}

+ (signal_protocol_key_helper_pre_key_list_node *)preKeys
{
    return nil;
}

+ (void)storeSignedPreKey:(session_signed_pre_key *)signedPreKey
{
    /* Store signed pre key in the signed pre key store. */
}

+ (session_signed_pre_key *)signedPreKey
{
    return nil;
}

+ (signal_protocol_address)addressFromString:(NSString *)string
{
    const char * cString = [string cStringUsingEncoding:NSUTF8StringEncoding];


    signal_protocol_address address = {
        cString,
        [string length],
        1
    };

    return address;
}


@end
