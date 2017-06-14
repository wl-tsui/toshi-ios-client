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

#import "ASHandle.h"

@interface ASActor : NSObject

+ (void)registerActorClass:(Class)requestBuilderClass;

+ (ASActor *)requestBuilderForGenericPath:(NSString *)genericPath path:(NSString *)path;

+ (NSString *)genericPath;

@property (nonatomic, strong) NSString *path;

@property (nonatomic, strong) NSString *requestQueueName;
@property (nonatomic, strong) NSDictionary *storedOptions;

@property (nonatomic) bool requiresAuthorization;

@property (nonatomic) NSTimeInterval cancelTimeout;
@property (nonatomic, strong) id cancelToken;
@property (nonatomic, strong) NSMutableArray *multipleCancelTokens;
@property (nonatomic) bool cancelled;

- (id)initWithPath:(NSString *)path;
- (void)prepare:(NSDictionary *)options;
- (void)execute:(NSDictionary *)options;
- (void)cancel;

- (void)addCancelToken:(id)token;

- (void)watcherJoined:(ASHandle *)watcherHandle options:(NSDictionary *)options waitingInActorQueue:(bool)waitingInActorQueue;

- (void)handleRequestProblem;

@end
