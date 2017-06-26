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

@protocol ASWatcher;

@interface ASHandle : NSObject

@property (nonatomic, weak) id<ASWatcher> delegate;
@property (nonatomic) bool releaseOnMainThread;

- (id)initWithDelegate:(id<ASWatcher>)delegate;
- (id)initWithDelegate:(id<ASWatcher>)delegate releaseOnMainThread:(bool)releaseOnMainThread;
- (void)reset;

- (bool)hasDelegate;

- (void)requestAction:(NSString *)action options:(id)options;
- (void)receiveActorMessage:(NSString *)path messageType:(NSString *)messageType message:(id)message;
- (void)notifyResourceDispatched:(NSString *)path resource:(id)resource;
- (void)notifyResourceDispatched:(NSString *)path resource:(id)resource arguments:(id)arguments;

@end
