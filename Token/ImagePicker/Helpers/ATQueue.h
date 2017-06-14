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

typedef enum {
    ATQueuePriorityLow,
    ATQueuePriorityDefault,
    ATQueuePriorityHigh
} ATQueuePriority;

@interface ATQueue : NSObject

+ (ATQueue *)mainQueue;
+ (ATQueue *)concurrentDefaultQueue;
+ (ATQueue *)concurrentBackgroundQueue;

- (instancetype)init;
- (instancetype)initWithName:(NSString *)name;
- (instancetype)initWithPriority:(ATQueuePriority)priority;

- (void)dispatch:(dispatch_block_t)block;
- (void)dispatch:(dispatch_block_t)block synchronous:(bool)synchronous;
- (void)dispatchAfter:(NSTimeInterval)seconds block:(dispatch_block_t)block;

- (dispatch_queue_t)nativeQueue;

@end
