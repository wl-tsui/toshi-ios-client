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
#import <SSignalKit/SSignalKit.h>
#import <AVFoundation/AVFoundation.h>

typedef enum {
    AudioSessionTypePlayVoice,
    AudioSessionTypePlayMusic,
    AudioSessionTypePlayVideo,
    AudioSessionTypePlayAndRecord,
    AudioSessionTypePlayAndRecordHeadphones,
    AudioSessionTypeCall
} AudioSessionType;


typedef enum {
    AudioSessionRouteChangePause,
    AudioSessionRouteChangeResume
} AudioSessionRouteChange;

@class AudioRoute;

@interface AudioSessionManager : NSObject

+ (AudioSessionManager *)instance;

- (id<SDisposable>)requestSessionWithType:(AudioSessionType)type interrupted:(void (^)())interrupted;
- (void)cancelCurrentSession;
+ (SSignal *)routeChange;

- (void)applyRoute:(AudioRoute *)route;

@end


@interface AudioRoute : NSObject

@property (nonatomic, readonly) NSString *uid;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) bool isBuiltIn;
@property (nonatomic, readonly) bool isLoudspeaker;
@property (nonatomic, readonly) bool isBluetooth;
@property (nonatomic, readonly) bool isHeadphones;

@property (nonatomic, readonly) AVAudioSessionPortDescription *device;

+ (instancetype)routeWithDescription:(AVAudioSessionPortDescription *)description;
+ (instancetype)routeForBuiltIn:(bool)headphones;
+ (instancetype)routeForSpeaker;

@end
