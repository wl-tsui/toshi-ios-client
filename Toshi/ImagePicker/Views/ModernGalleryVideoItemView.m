#import "ModernGalleryVideoItemView.h"

#import <AVFoundation/AVFoundation.h>

#import "ImageUtils.h"
#import "ImageView.h"

#import "ModernGalleryVideoItem.h"
#import "VideoMediaAttachment.h"
#import "Common.h"
#import "DocumentMediaAttachment.h"

#import "ModernGalleryRotationGestureRecognizer.h"
#import "ModernGalleryVideoFooterView.h"
#import "ModernGalleryVideoView.h"
#import "ModernGalleryVideoContentView.h"
#import "ModernGalleryDefaultFooterView.h"

#import "DoubleTapGestureRecognizer.h"

#import "TimerTarget.h"
#import "ObserverProxy.h"
#import "ASHandle.h"
#import "ModernButton.h"
#import "MessageImageViewOverlayView.h"

#import "ActionStage.h"

#import "AudioSessionManager.h"

@interface ModernGalleryVideoItemView () <DoubleTapGestureRecognizerDelegate, ASWatcher>
{
    UIView *_containerView;
    ModernGalleryVideoContentView *_contentView;
    UIView *_playerView;
    ModernGalleryVideoView *_videoView;
    
    CGFloat _playerLayerRotation;
    NSUInteger _currentLoopCount;
    
    ModernButton *_actionButton;
    MessageImageViewOverlayView *_progressView;
    
    bool _mediaAvailable;
    int32_t _transactionId;
    
    ModernGalleryVideoFooterView *_footerView;
    
    NSTimer *_positionTimer;
    NSTimer *_videoFlickerTimer;
    
    ObserverProxy *_didPlayToEndObserver;
    
    NSTimeInterval _duration;
    
    SMetaDisposable *_currentAudioSession;
}

@property (nonatomic, strong) ASHandle *actionHandle;

@property (nonatomic) bool isPlaying;
@property (nonatomic) bool isScrubbing;

@end

@implementation ModernGalleryVideoItemView

- (UIImage *)playButtonImage
{
    static UIImage *image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        const CGFloat diameter = 50.0f;
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(diameter, diameter), false, 0.0f);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        const CGFloat width = 20.0f;
        const CGFloat height = width + 4.0f;
        const CGFloat offset = 3.0f;
        
        CGContextSetBlendMode(context, kCGBlendModeCopy);
        
        CGContextSetFillColorWithColor(context, UIColorRGBA(0xffffffff, 1.0f).CGColor);
        CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, diameter, diameter));
        
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, offset + floor((diameter - width) / 2.0f), floor((diameter - height) / 2.0f));
        CGContextAddLineToPoint(context, offset + floor((diameter - width) / 2.0f) + width, floor(diameter / 2.0f));
        CGContextAddLineToPoint(context, offset + floor((diameter - width) / 2.0f), floor((diameter + height) / 2.0f));
        CGContextClosePath(context);
        CGContextSetFillColorWithColor(context, UIColorRGBA(0x727272, 1.0f).CGColor);
        CGContextFillPath(context);
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    return image;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        _currentAudioSession = [[SMetaDisposable alloc] init];
        
        _containerView = [[ModernGalleryVideoContentView alloc] initWithFrame:(CGRect){CGPointZero, frame.size}];
        [self addSubview:_containerView];
        
        DoubleTapGestureRecognizer *recognizer = [[DoubleTapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGesture:)];
        recognizer.consumeSingleTap = true;
        recognizer.avoidControls = true;
        [self addGestureRecognizer:recognizer];
        
        _contentView = [[ModernGalleryVideoContentView alloc] init];
        [_containerView addSubview:_contentView];
        
        _imageView = [[ImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleToFill;
        [_contentView addSubview:_imageView];
        
        _playerView = [[UIView alloc] init];
        [_contentView addSubview:_playerView];
        
        _actionButton = [[ModernButton alloc] initWithFrame:(CGRect){CGPointZero, {50.0f, 50.0f}}];
        _actionButton.modernHighlight = true; 
        
        CGFloat circleDiameter = 50.0f;
        static UIImage *highlightImage = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
        {
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(circleDiameter, circleDiameter), false, 0.0f);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context, UIColorRGBA(0x000000, 0.4f).CGColor);
            CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, circleDiameter, circleDiameter));
            highlightImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        });
        
        _actionButton.highlightImage = highlightImage;
        
        _progressView = [[MessageImageViewOverlayView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 50.0f)];
        _progressView.userInteractionEnabled = false;
        [_actionButton addSubview:_progressView];
        
        [_actionButton addTarget:self action:@selector(playPressed) forControlEvents:UIControlEventTouchUpInside];
        
        _contentView.button = _actionButton;
        [_contentView addSubview:_actionButton];
        
        __weak ModernGalleryVideoItemView *weakSelf = self;
        
        _footerView = [[ModernGalleryVideoFooterView alloc] init];
        _footerView.playPressed = ^
        {
            __strong ModernGalleryVideoItemView *strongSelf = weakSelf;
            [strongSelf playPressed];
        };
        _footerView.pausePressed = ^
        {
            __strong ModernGalleryVideoItemView *strongSelf = weakSelf;
            [strongSelf pausePressed];
        };
        
        ModernGalleryRotationGestureRecognizer *rotationRecognizer = [[ModernGalleryRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationGesture:)];
        rotationRecognizer.cancelsTouchesInView = false;
        [self addGestureRecognizer:rotationRecognizer];
    }
    return self;
}

- (void)dealloc
{
    [self stop];
    
    [_actionHandle reset];
    [ActionStageInstance() removeWatcher:self];
    
    [_currentAudioSession dispose];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    CGAffineTransform transform = _containerView.transform;
    _containerView.transform = CGAffineTransformIdentity;
    _containerView.frame = (CGRect){CGPointZero, frame.size};
    _containerView.transform = transform;
    
    _contentView.frame = (CGRect){CGPointZero, frame.size};
}

- (void)prepareForRecycle
{
    [super prepareForRecycle];
    
    [ActionStageInstance() removeWatcher:self];
    
    [self cleanupCurrentPlayer];
    
    _currentLoopCount = 0;
    
    [_imageView reset];
    
    [_videoFlickerTimer invalidate];
    _videoFlickerTimer = nil;
    
    _videoView.alpha = 1.0f;
    
    [_positionTimer invalidate];
    _positionTimer = nil;
    
    _playerLayerRotation = 0.0f;
    _containerView.transform = CGAffineTransformIdentity;
    _actionButton.transform = CGAffineTransformIdentity;
    
    self.isPlaying = false;
    
    [self footerView].hidden = true;
}

- (void)cleanupCurrentPlayer
{
    [self stop];
    
    _videoDimensions = CGSizeZero;
    
    [_imageView reset];
}

- (void)stop
{
    if (_player != nil)
    {
        _didPlayToEndObserver = nil;
        
        [_player pause];
        [_player replaceCurrentItemWithPlayerItem:nil];
        _player = nil;
    }
    
    if (_videoView != nil)
    {
        SMetaDisposable *currentAudioSession = _currentAudioSession;
        if (currentAudioSession)
        {
            _videoView.deallocBlock = ^
            {
                [[SQueue concurrentDefaultQueue] dispatch:^
                {
                    [currentAudioSession setDisposable:nil];
                }];
            };
        }
        [_videoView cleanupPlayer];
        [_videoView removeFromSuperview];
        _videoView = nil;
    }
    
    [_positionTimer invalidate];
    _positionTimer = nil;
    
    self.isPlaying = false;
    [self updatePosition:false forceZero:true];
}

- (void)stopForOutTransition
{
    if (_player != nil && _videoView != nil && iosMajorVersion() >= 8)
    {
        [_player pause];
        
        UIView *snapshotView = [_videoView snapshotViewAfterScreenUpdates:false];
        [_videoView.superview insertSubview:snapshotView aboveSubview:_videoView];
    }
    
    [_actionButton removeFromSuperview];
    [self stop];
}



- (void)setItem:(ModernGalleryVideoItem *)item synchronously:(bool)synchronously
{
    _transactionId++;
    
    [super setItem:item synchronously:synchronously];
    
    [self cleanupCurrentPlayer];
    
    [self footerView].hidden = true;
}

- (void)setMediaAvailable:(bool)mediaAvailable
{
    _mediaAvailable = mediaAvailable;
    
    if (_mediaAvailable)
        [_progressView setPlay];
    else
        [_progressView setDownload];
}

- (void)play
{
    [self playPressed];
}

- (void)loadAndPlay
{
    [self playPressed];
}

- (void)_willPlay
{
}

- (void)hidePlayButton
{
    _actionButton.hidden = true;
}

- (void)playPressed
{
    if (_mediaAvailable)
    {
        [self _willPlay];
        
        CGSize dimensions = CGSizeZero;
        NSString *videoPath = nil;
        
        if (_player == nil)
        {
            if (videoPath != nil)
            {
                _videoDimensions = dimensions;
                
                __weak ModernGalleryVideoItemView *weakSelf = self;
                [[SQueue concurrentDefaultQueue] dispatch:^
                {
                    [_currentAudioSession setDisposable:[[AudioSessionManager instance] requestSessionWithType:AudioSessionTypePlayVideo interrupted:^
                    {
                        DispatchOnMainThread(^
                        {
                            __strong ModernGalleryVideoItemView *strongSelf = weakSelf;
                            if (strongSelf != nil)
                                [strongSelf pausePressed];
                        });
                    }]];
                }];
                
                _player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:videoPath]];
                _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
                
                _didPlayToEndObserver = [[ObserverProxy alloc] initWithTarget:self targetSelector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:[_player currentItem]];
                
                if (_videoView != nil)
                    [_videoView removeFromSuperview];
                
                _videoView = [[ModernGalleryVideoView alloc] initWithFrame:_playerView.bounds player:_player];
                _videoView.frame = _playerView.bounds;
                _videoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                if (_videoDimensions.width > FLT_EPSILON && _videoDimensions.height > FLT_EPSILON) {
                    _videoView.playerLayer.videoGravity = AVLayerVideoGravityResize;
                } else {
                    _videoView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                }
                
                _videoView.playerLayer.opaque = false;
                _videoView.playerLayer.backgroundColor = nil;
                [_playerView addSubview:_videoView];
                
                _videoView.alpha = 0.0f;
                _videoFlickerTimer = [TimerTarget scheduledMainThreadTimerWithTarget:self action:@selector(videoFlickerTimerEvent) interval:0.1 repeat:false];
                
                self.isPlaying = true;
                [_player play];
                
                _positionTimer = [TimerTarget scheduledMainThreadTimerWithTarget:self action:@selector(positionTimerEvent) interval:0.25 repeat:true];
                [self positionTimerEvent];
                
                [self layoutSubviews];
                
                [self footerView].hidden = false;
                [self setDefaultFooterHidden:true];
            }
        }
        else
        {
            self.isPlaying = true;
            [_player play];
            
            _positionTimer = [TimerTarget scheduledMainThreadTimerWithTarget:self action:@selector(positionTimerEvent) interval:0.25 repeat:true];
            [self positionTimerEvent];
        }
    }
}

- (void)setDefaultFooterHidden:(bool)hidden
{
    if ([[self defaultFooterView] respondsToSelector:@selector(setContentHidden:)])
        [[self defaultFooterView] setContentHidden:hidden];
    else
        [self defaultFooterView].hidden = hidden;
}

- (void)pausePressed
{
    self.isPlaying = false;
    [_player pause];
    
    [_positionTimer invalidate];
    _positionTimer = nil;
    
    [self updatePosition:false forceZero:false];
    
    _actionButton.hidden = true;
}

- (void)playerItemDidPlayToEndTime:(NSNotification *)notification
{
    _currentLoopCount++;
    
    if ([self shouldLoopVideo:_currentLoopCount])
    {
        AVPlayerItem *p = [notification object];
        [p seekToTime:kCMTimeZero];
    }
    else
    {
        [_player pause];
        
        AVPlayerItem *p = [notification object];
        [p seekToTime:kCMTimeZero];
        
        [_positionTimer invalidate];
        _positionTimer = nil;
        
        self.isPlaying = false;
        [self updatePosition:false forceZero:true];
    }
}

- (bool)shouldLoopVideo:(NSUInteger)__unused currentLoopCount
{
    return false;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_videoDimensions.width > FLT_EPSILON && _videoDimensions.height > FLT_EPSILON)
    {
        CGSize fittedSize = TGFitSize(TGFillSize(_videoDimensions, self.bounds.size), self.bounds.size);
        
        CGFloat normalizedRotation = floor(_playerLayerRotation / (CGFloat)M_PI) * (CGFloat)M_PI;
        
        if (ABS(_playerLayerRotation - normalizedRotation) > FLT_EPSILON)
        {
            fittedSize = TGFitSize(TGFillSize(_videoDimensions, CGSizeMake(self.bounds.size.height, self.bounds.size.width)), CGSizeMake(self.bounds.size.height, self.bounds.size.width));
        }
        
        CGRect playerFrame = CGRectMake(floor((self.bounds.size.width - fittedSize.width) / 2.0f), floor((self.bounds.size.height - fittedSize.height) / 2.0f), fittedSize.width, fittedSize.height);
        CGRect playerBounds = playerFrame;
        
        if (!CGRectEqualToRect(_imageView.frame, playerBounds))
        {
            _playerView.frame = playerBounds;
            _videoView.frame = (CGRect){CGPointZero, playerBounds.size};
            _imageView.frame = playerBounds;
        }
    }
    else
    {
        CGSize fittedSize = self.bounds.size;
        
        CGRect playerFrame = CGRectMake(floor((self.bounds.size.width - fittedSize.width) / 2.0f), floor((self.bounds.size.height - fittedSize.height) / 2.0f), fittedSize.width, fittedSize.height);
        CGRect playerBounds = playerFrame;
        
        if (!CGRectEqualToRect(_imageView.frame, playerBounds))
        {
            _playerView.frame = playerBounds;
            _videoView.frame = (CGRect){CGPointZero, playerBounds.size};
            _imageView.frame = playerBounds;
        }
    }
}

- (UIView *)headerView
{
    return nil;// _scrubbingInterfaceView;
}

- (UIView *)footerView
{
    return _footerView;
}

- (CGFloat)normalizeAngle:(CGFloat)angle
{
    CGFloat n = (int)(angle / (CGFloat)M_2_PI);
    if (angle < 0)
        angle += n * M_2_PI;
    else
        angle -= n * M_2_PI;
    return angle;
}

- (void)rotationGesture:(UIRotationGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        _containerView.transform = CGAffineTransformMakeRotation([self normalizeAngle:_playerLayerRotation + [recognizer rotation]]);
        _actionButton.transform = CGAffineTransformMakeRotation(-[self normalizeAngle:_playerLayerRotation + [recognizer rotation]]);
    }
    else if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        CGFloat tempAngle = [self normalizeAngle:_playerLayerRotation + [recognizer rotation]];
        CGFloat angle = floor(tempAngle / (CGFloat)M_2_PI) * (CGFloat)M_2_PI;
        
        _playerLayerRotation = floor((angle + (CGFloat)M_PI_4) / (CGFloat)M_PI_2) * (CGFloat)M_PI_2;
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^
        {
            _containerView.transform = CGAffineTransformMakeRotation(_playerLayerRotation);
            _actionButton.transform = CGAffineTransformMakeRotation(-_playerLayerRotation);
            [self layoutSubviews];
        } completion:nil];
    }
    else if (recognizer.state == UIGestureRecognizerStateFailed)
    {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^
        {
            _containerView.transform = CGAffineTransformMakeRotation(_playerLayerRotation);
            _actionButton.transform = CGAffineTransformMakeRotation(-_playerLayerRotation);
            [self layoutSubviews];
        } completion:nil];
    }
}

- (void)setIsPlaying:(bool)isPlaying
{
    _isPlaying = isPlaying;
    
    _actionButton.hidden = _isPlaying || _isScrubbing;
    _footerView.isPlaying = _isPlaying;
}

- (void)videoFlickerTimerEvent
{
    [_videoFlickerTimer invalidate];
    _videoFlickerTimer = nil;
    
    _videoView.alpha = 1.0f;
}

- (void)positionTimerEvent
{
    [self updatePosition:true forceZero:false];
}

- (void)updatePosition:(bool)animated forceZero:(bool)forceZero
{
    NSTimeInterval duration = _duration;
    NSTimeInterval actualDuration = CMTimeGetSeconds(_player.currentItem.duration);
    if (actualDuration > 0.1f)
        duration = actualDuration;
}

- (void)doubleTapGesture:(DoubleTapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        if (recognizer.doubleTapped)
        {
        }
        else
        {
            id<ModernGalleryItemViewDelegate> delegate = self.delegate;
            if ([delegate respondsToSelector:@selector(itemViewDidRequestInterfaceShowHide:)])
                [delegate itemViewDidRequestInterfaceShowHide:self];
        }
    }
}

- (UIView *)transitionView
{
    return _contentView;
}

- (CGRect)transitionViewContentRect
{
    return [_contentView convertRect:_playerView.bounds fromView:_playerView];
}

- (void)setFocused:(bool)isFocused
{
    if (!isFocused)
    {
        [self footerView].hidden = true;
        [self setDefaultFooterHidden:false];
    }
}

- (void)setIsVisible:(bool)isVisible
{
    [super setIsVisible:isVisible];
    
    if (!isVisible && _player != nil)
        [self stop];
}

- (void)setProgressVisible:(bool)progressVisible value:(float)value animated:(bool)animated
{
    if (progressVisible)
        [_progressView setProgress:value cancelEnabled:true animated:animated];
    else if (_mediaAvailable)
        [_progressView setPlay];
    else
        [_progressView setDownload];
}

- (void)actorMessageReceived:(NSString *)path messageType:(NSString *)messageType message:(id)message
{
    if ([path hasPrefix:@"/as/media/video/"])
    {
        if ([messageType isEqualToString:@"progress"])
        {
            float progress = [message floatValue];
            DispatchOnMainThread(^
            {
                [self setProgressVisible:true value:progress animated:true];
            });
        }
    }
}

- (void)actorCompleted:(int)status path:(NSString *)path result:(id)__unused result
{
    if ([path hasPrefix:@"/as/media/video/"])
    {
    }
}

@end
