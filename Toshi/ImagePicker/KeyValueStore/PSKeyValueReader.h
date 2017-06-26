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

#import "PSData.h"

typedef enum {
    PSKeyValueReaderSelectLowerKey = 0,
    PSKeyValueReaderSelectHigherKey = 1
} PSKeyValueReaderSelectKey;

typedef enum {
    PSKeyValueReaderEnumerationReverse = 1,
    PSKeyValueReaderEnumerationLowerBoundExclusive = 2,
    PSKeyValueReaderEnumerationUpperBoundExclusive = 4
} PSKeyValueReaderEnumerationOptions;

@protocol PSKeyValueReader <NSObject>

- (bool)readValueForRawKey:(PSConstData *)key value:(PSConstData *)value;

- (bool)readValueBetweenLowerBoundKey:(PSConstData *)lowerBoundKey upperBoundKey:(PSConstData *)upperBoundKey selectKey:(PSKeyValueReaderSelectKey)selectKey selectedKey:(PSConstData *)selectedKey selectedValue:(PSConstData *)selectedValue;

- (void)enumerateKeysAndValuesBetweenLowerBoundKey:(PSConstData *)lowerBoundKey upperBoundKey:(PSConstData *)upperBoundKey options:(NSInteger)options withBlock:(void (^)(PSConstData *key, PSConstData *value, bool *stop))block;

@end
