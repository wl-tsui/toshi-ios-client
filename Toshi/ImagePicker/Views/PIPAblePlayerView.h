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

@class TGEmbedPIPPlaceholderView;
@protocol PIPAblePlayerView;

typedef enum
{
    TGEmbedPIPCornerNone,
    TGEmbedPIPCornerTopLeft,
    TGEmbedPIPCornerTopRight,
    TGEmbedPIPCornerBottomRight,
    TGEmbedPIPCornerBottomLeft
} TGEmbedPIPCorner;

@protocol TGPIPAblePlayerState

@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) NSTimeInterval position;
@property (nonatomic, readonly) CGFloat downloadProgress;

@property (nonatomic, readonly, getter=isPlaying) bool playing;

@end

@protocol TGPIPAblePlayerContainerView

- (TGEmbedPIPPlaceholderView *)pipPlaceholderView;
- (void)reattachPlayerView:(UIView<PIPAblePlayerView> *)playerView;
- (bool)shouldReattachPlayerBeforeTransition;

@end

@protocol PIPAblePlayerView <NSObject>

@property (nonatomic, copy) void (^requestPictureInPicture)(TGEmbedPIPCorner corner);

- (void)playVideo;
- (void)pauseVideo;

- (void)seekToPosition:(NSTimeInterval)position;
- (void)seekToFractPosition:(CGFloat)position;

- (id<TGPIPAblePlayerState>)state;
- (SSignal *)stateSignal;

@property (nonatomic, assign) bool disallowPIP;
- (bool)supportsPIP;
- (void)switchToPictureInPicture;

- (void)_requestSystemPictureInPictureMode;
- (void)_prepareToEnterFullscreen;
- (void)_prepareToLeaveFullscreen;

- (void)resumePIPPlayback;
- (void)pausePIPPlayback;

- (void)beginLeavingFullscreen;
- (void)finishedLeavingFullscreen;

@property (nonatomic, assign) CGRect initialFrame;

@end
