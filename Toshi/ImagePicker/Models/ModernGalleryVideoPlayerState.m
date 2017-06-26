#import "ModernGalleryVideoPlayerState.h"

@implementation ModernGalleryVideoPlayerState

@synthesize playing = _playing;
@synthesize duration = _duration;
@synthesize position = _position;

- (CGFloat)downloadProgress
{
    return 1.0f;
}

+ (instancetype)stateWithPlaying:(bool)playing duration:(NSTimeInterval)duration position:(NSTimeInterval)position
{
    ModernGalleryVideoPlayerState *state = [[ModernGalleryVideoPlayerState alloc] init];
    state->_playing = playing;
    state->_duration = duration;
    state->_position = position;
    return state;
}

@end
