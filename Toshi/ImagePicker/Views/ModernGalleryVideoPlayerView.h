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

#import <UIKit/UIKit.h>
#import "PIPAblePlayerView.h"
#import "ModernGalleryVideoPlayerState.h"

@interface ModernGalleryVideoPlayerView : UIView <PIPAblePlayerView>

@property (nonatomic, readonly) ModernGalleryVideoPlayerState *state;
@property (nonatomic, readonly, getter=isLoaded) bool loaded;

- (void)loadImageWithUri:(NSString *)uri update:(bool)update synchronously:(bool)synchronously;
- (void)loadImageWithSignal:(SSignal *)signal;
- (void)setVideoPath:(NSString *)videoPath duration:(NSTimeInterval)duration;

- (void)reset;
- (void)stop;

- (void)disposeAudioSession;

@end
