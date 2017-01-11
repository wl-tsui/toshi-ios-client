#import "CryptoTools.h"

@implementation CryptoTools

+ (NSData *)generateSecureRandomData:(NSUInteger)length {
    NSMutableData *d = [NSMutableData dataWithLength:length];
    OSStatus status  = SecRandomCopyBytes(kSecRandomDefault, length, [d mutableBytes]);
    if (status != noErr) {
        exit(-1);
    }

    return [d copy];
}

+ (uint16_t)generateSecureRandomUInt16 {
    return [[self generateSecureRandomData:sizeof(uint16_t)] bigEndianUInt16At:0];
}

+ (uint32_t)generateSecureRandomUInt32 {
    return [[self generateSecureRandomData:sizeof(uint32_t)] bigEndianUInt32At:0];
}

+ (NSString *)computeOtpWithPassword:(NSString *)password andCounter:(int64_t)counter {
    NSData *d = [[@(counter) stringValue] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *h = [d hmacWithSha1WithKey:[password dataUsingEncoding:NSUTF8StringEncoding]];

    return [h base64EncodedStringWithOptions:0];
}

@end

//@implementation NSData (CryptoTools)
//
//- (NSData *)hmacWithSha1WithKey:(NSData *)key {
//    return [EvpMessageDigest hmacUsingSha1Data:self withKey:key];
//}
//
//- (NSData *)hmacWithSha256WithKey:(NSData *)key {
//    return [EvpMessageDigest hmacUsingSha256Data:self withKey:key];
//}
//
//- (NSData *)encryptWithAesInCipherFeedbackModeWithKey:(NSData *)key andIv:(NSData *)iv {
//    return [EvpSymetricUtil encryptMessage:self usingAes128WithCfbAndKey:key andIv:iv];
//}
//- (NSData *)encryptWithAesInCipherBlockChainingModeWithPkcs7PaddingWithKey:(NSData *)key andIv:(NSData *)iv {
//    return [EvpSymetricUtil encryptMessage:self usingAes128WithCbcAndPaddingAndKey:key andIv:iv];
//}
//- (NSData *)encryptWithAesInCounterModeWithKey:(NSData *)key andIv:(NSData *)iv {
//    return [EvpSymetricUtil encryptMessage:self usingAes128InCounterModeAndKey:key andIv:iv];
//}
//
//- (NSData *)decryptWithAesInCipherFeedbackModeWithKey:(NSData *)key andIv:(NSData *)iv {
//    return [EvpSymetricUtil decryptMessage:self usingAes128WithCfbAndKey:key andIv:iv];
//}
//- (NSData *)decryptWithAesInCipherBlockChainingModeWithPkcs7PaddingWithKey:(NSData *)key andIv:(NSData *)iv {
//    return [EvpSymetricUtil decryptMessage:self usingAes128WithCbcAndPaddingAndKey:key andIv:iv];
//}
//- (NSData *)decryptWithAesInCounterModeWithKey:(NSData *)key andIv:(NSData *)iv {
//    return [EvpSymetricUtil decryptMessage:self usingAes128InCounterModeAndKey:key andIv:iv];
//}
//
//- (NSData *)hashWithSha256 {
//    return [EvpMessageDigest hashWithSha256:self];
//}
//- (bool)isEqualToData_TimingSafe:(NSData *)other {
//    if (other == nil)
//        return false;
//    NSUInteger n = self.length;
//    if (other.length != n)
//        return false;
//    bool equal = true;
//    for (NSUInteger i = 0; i < n; i++)
//        equal &= [self uint8At:i] == [other uint8At:i];
//    return equal;
//}
//@end

@implementation NSData (Conversions)

- (uint8_t)byteAt:(NSUInteger)offset {
    return ((const uint8_t *)[self bytes])[offset];
}

- (uint16_t)bigEndianUInt16At:(NSUInteger)offset {
    return (uint16_t)[self byteAt:1 + offset] | (uint16_t)((uint16_t)[self byteAt:0 + offset] << 8);
}

- (uint32_t)bigEndianUInt32At:(NSUInteger)offset {
    return ((uint32_t)[self byteAt:3 + offset] << 0) | ((uint32_t)[self byteAt:2 + offset] << 8) | ((uint32_t)[self byteAt:1 + offset] << 16) | ((uint32_t)[self byteAt:0 + offset] << 24);
}

+ (NSData *)dataWithBigEndianBytesOfUInt16:(uint16_t)value {
    uint8_t d[sizeof(uint16_t)];
    d[1] = (uint8_t)((value >> 0) & 0xFF);
    d[0] = (uint8_t)((value >> 8) & 0xFF);

    return [NSData dataWithBytes:d length:sizeof(uint16_t)];
}

+ (NSData *)dataWithBigEndianBytesOfUInt32:(uint32_t)value {
    uint8_t d[sizeof(uint32_t)];
    d[3] = (uint8_t)((value >> 0) & 0xFF);
    d[2] = (uint8_t)((value >> 8) & 0xFF);
    d[1] = (uint8_t)((value >> 16) & 0xFF);
    d[0] = (uint8_t)((value >> 24) & 0xFF);

    return [NSData dataWithBytes:d length:sizeof(uint32_t)];
}

+ (NSData *)switchEndiannessOfData:(NSData *)data {
    const void *bytes                 = [data bytes];
    NSMutableData *switchedEndianData = [NSMutableData new];
    for (NSUInteger i = data.length; i > 0; --i) {
        uint8_t byte = *(((uint8_t *)(bytes)) + ((i - 1) * sizeof(uint8_t)));
        [switchedEndianData appendData:[NSData dataWithBytes:&byte length:sizeof(byte)]];
    }

    return switchedEndianData;
}

@end
