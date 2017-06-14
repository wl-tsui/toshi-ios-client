// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef __cplusplus
extern "C" {
#endif
    
int32_t murMurHash32(NSString *string);
int32_t murMurHashBytes32(void *bytes, int length);
int32_t phoneMatchHash(NSString *phone);
    
bool TGIsRTL();
bool TGIsArabic();
bool TGIsKorean();
bool TGIsLocaleArabic();
    
#ifdef __cplusplus
}
#endif

@interface StringUtils : NSObject

+ (NSString *)stringByEscapingForURL:(NSString *)string;
+ (NSString *)stringByEscapingForActorURL:(NSString *)string;
+ (NSString *)stringByEncodingInBase64:(NSData *)data;
+ (NSString *)stringByUnescapingFromHTML:(NSString *)srcString;

+ (NSString *)stringWithLocalizedNumber:(NSInteger)number;
+ (NSString *)stringWithLocalizedNumberCharacters:(NSString *)string;

+ (NSString *)md5:(NSString *)string;
+ (NSString *)md5ForData:(NSData *)data;

+ (NSDictionary *)argumentDictionaryInUrlString:(NSString *)string;

+ (bool)stringContainsEmoji:(NSString *)string;
+ (bool)stringContainsEmojiOnly:(NSString *)string length:(NSUInteger *)length;

+ (NSString *)stringForMessageTimerSeconds:(NSUInteger)seconds;
+ (NSString *)stringForShortMessageTimerSeconds:(NSUInteger)seconds;
+ (NSArray *)stringComponentsForMessageTimerSeconds:(NSUInteger)seconds;
+ (NSString *)stringForCallDurationSeconds:(NSUInteger)seconds;
+ (NSString *)stringForShortCallDurationSeconds:(NSUInteger)seconds;
+ (NSString *)stringForUserCount:(NSUInteger)userCount;
+ (NSString *)stringForFileSize:(int64_t)size;
+ (NSString *)stringForFileSize:(int64_t)size precision:(NSInteger)precision;

+ (NSString *)integerValueFormat:(NSString *)prefix value:(NSInteger)value;
+ (NSString *)stringForMuteInterval:(int)value;
+ (NSString *)stringForRemainingMuteInterval:(int)value;

+ (NSString *)stringForDeviceType;

+ (NSString *)stringForCurrency:(NSString *)currency amount:(int64_t)amount;

+ (NSString *)stringForEmojiHashOfData:(NSData *)data count:(NSInteger)count positionExtractor:(int32_t (^)(uint8_t *, int32_t, int32_t))positionExtractor;

@end

@interface NSString (Telegraph)

- (int)lengthByComposedCharacterSequences;
- (int)lengthByComposedCharacterSequencesInRange:(NSRange)range;

- (NSData *)dataByDecodingHexString;
- (NSArray *)getEmojiFromString:(BOOL)checkColor checkString:(__autoreleasing NSString **)checkString;

- (bool)containsSingleEmoji;

- (bool)hasNonWhitespaceCharacters;

- (NSAttributedString *)attributedFormattedStringWithRegularFont:(UIFont *)regularFont boldFont:(UIFont *)boldFont lineSpacing:(CGFloat)lineSpacing paragraphSpacing:(CGFloat)paragraphSpacing alignment:(NSTextAlignment)alignment;

- (NSString *)urlAnchorPart;

@end

@interface NSData (Telegraph)

- (NSString *)stringByEncodingInHex;
- (NSString *)stringByEncodingInHexSeparatedByString:(NSString *)string;

@end
