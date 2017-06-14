#import "InlineVideoView.h"

#import "VTPlayer.h"
#import "VTPlayerView.h"

#import "AcceleratedVideoView.h"
#import "VTAcceleratedVideoView.h"

#define USE_VT false

@interface InlineVideoView () {
#if USE_VT
    VTPlayerView *_playerView;
    VTPlayer *_player;
#else
    VTAcceleratedVideoView *_videoView;
#endif
    
    SMetaDisposable *_pathDisposable;
    
}

@property (nonatomic, strong) NSString *viewIdentifier;
@property (nonatomic, strong) NSString *viewStateIdentifier;

@end

@implementation InlineVideoView

+ (SQueue *)playerQueue {
    static SQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[SQueue alloc] init];
    });
    return queue;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        _pathDisposable = [[SMetaDisposable alloc] init];
        
#if USE_VT
        _playerView = [[VTPlayerView alloc] initWithFrame:self.bounds];
        [self addSubview:_playerView];
#else
        _videoView = [[VTAcceleratedVideoView alloc] initWithFrame:self.bounds];
        [self addSubview:_videoView];
#endif
        
        _cornerRadius = 13.0f;
        self.layer.cornerRadius = _cornerRadius;
        self.layer.masksToBounds = true;
        _insets = UIEdgeInsetsMake(-2.0f, -2.0f, -2.0f, -2.0f);
    }
    return self;
}

- (void)setVideoSize:(CGSize)videoSize {
    _videoSize = videoSize;
    _videoView.videoSize = videoSize;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    self.layer.cornerRadius = cornerRadius;
}

- (void)willBecomeRecycled {
#if USE_VT
    [_player stop];
    [_player _setOutput:nil];
#else
    [_videoView setPath:nil];
    [_videoView prepareForRecycle];
#endif
}

- (void)setVideoPathSignal:(SSignal *)signal {
    __weak InlineVideoView *weakSelf = self;
    
    if (signal == nil) {
        [self playVideoFromPath:nil];
    } else {
        [_pathDisposable setDisposable:[[signal deliverOn:[InlineVideoView playerQueue]] startWithNext:^(NSString *path) {
            __strong InlineVideoView *strongSelf = weakSelf;
            if (strongSelf != nil) {
                [strongSelf playVideoFromPath:path];
            }
        }]];
    }
}

- (void)playVideoFromPath:(NSString *)path {
#if USE_VT
    [_player stop];
    [_player _setOutput:nil];
    _player = nil;
    
    if (path != nil) {
        _player = [[VTPlayer alloc] initWithUrl:[NSURL fileURLWithPath:path]];
        [_player _setOutput:_playerView];
        [_player play];
    }
#else
    [_videoView setPath:path];
#endif
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    bounds.origin.x += _insets.left;
    bounds.origin.y += _insets.top;
    bounds.size.width -= _insets.left + _insets.right;
    bounds.size.height -= _insets.top + _insets.bottom;
    
#if USE_VT
    _playerView.frame = bounds;
#else
    _videoView.frame = bounds;
#endif
}

@end
