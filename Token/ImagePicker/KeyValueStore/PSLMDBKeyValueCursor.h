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

#import "lmdb.h"

@class PSLMDBTable;

typedef enum {
    PSKeyValueCursorDirectionForward = 0,
    PSKeyValueCursorDirectionBack = 1
} PSKeyValueCursorDirection;

@interface PSLMDBKeyValueCursor : NSObject

- (instancetype)initWithTable:(PSLMDBTable *)table transaction:(MDB_txn *)transaction cursor:(MDB_cursor *)cursor;

- (bool)positionAt:(uint8_t const **)key keyLength:(NSUInteger *)keyLength value:(uint8_t const **)value valueLength:(NSUInteger *)valueLength directionIfNotFound:(PSKeyValueCursorDirection)directionIfNotFound;
- (bool)previous:(uint8_t const **)key keyLength:(NSUInteger *)keyLength value:(uint8_t const **)value valueLength:(NSUInteger *)valueLength;
- (bool)next:(uint8_t const **)key keyLength:(NSUInteger *)keyLength value:(uint8_t const **)value valueLength:(NSUInteger *)valueLength;

@end
