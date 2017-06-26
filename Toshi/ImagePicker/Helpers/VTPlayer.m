#import "VTPlayer.h"

#import <SSignalKit/SSignalKit.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <libkern/OSAtomic.h>

#import "VTPlayerView.h"

#import "WeakReference.h"
#import "Common.h"

static const NSUInteger highWaterLimit = 6;
static const NSUInteger lowWaterLimit = 2;

static void VTPlayerDecompressionOutputCallback(void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef imageBuffer, CMTime presentationTimestamp, CMTime presentationDuration);

static NSMutableDictionary *sessions() {
    static NSMutableDictionary *dict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = [[NSMutableDictionary alloc] init];
    });
    return dict;
}

static OSSpinLock sessionsLock = 0;
static int32_t nextSessionId = 0;

@interface VTPlayerFrame : NSObject {
    @public
    CVPixelBufferRef _pixelBuffer;
    CFAbsoluteTime _presentationTime;
    CFAbsoluteTime _presentationDuration;
}

@end

@implementation VTPlayerFrame

- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer presentationTime:(CFAbsoluteTime)presentationTime presentationDuration:(CFAbsoluteTime)presentationDuration {
    self = [super init];
    if (self != nil) {
        if (pixelBuffer) {
            CFRetain(pixelBuffer);
            _pixelBuffer = pixelBuffer;
        }
        _presentationTime = presentationTime;
        _presentationDuration = presentationDuration;
    }
    return self;
}

- (void)dealloc {
    if (_pixelBuffer) {
        CFRelease(_pixelBuffer);
    }
}

@end

@interface VTPlayerSession : NSObject {
    int32_t _sessionId;
    SQueue *_queue;
    NSURL *_url;
    CFAbsoluteTime _referencePresentationTime;
    void (^_nextFrame)(VTPlayerFrame *, bool);
    
    bool _initialized;
    
    NSInteger _requestedFrames;
    
    AVAssetReader *_assetReader;
    AVAssetReaderTrackOutput *_videoTrackOutput;
    VTDecompressionSessionRef _decompressionSession;
}

@end

@implementation VTPlayerSession

- (instancetype)initWithQueue:(SQueue *)queue url:(NSURL *)url referencePresentationTime:(CFAbsoluteTime)referencePresentationTime nextFrame:(void (^)(VTPlayerFrame *, bool))nextFrame {
    self = [super init];
    if (self != nil) {
        _sessionId = nextSessionId++;
        _queue = queue;
        _url = url;
        _referencePresentationTime = referencePresentationTime;
        _nextFrame = [nextFrame copy];
        
        OSSpinLockLock(&sessionsLock);
        sessions()[@(_sessionId)] = [[WeakReference alloc] initWithObject:self];
        OSSpinLockUnlock(&sessionsLock);
    }
    return self;
}

- (void)dealloc {
    OSSpinLockLock(&sessionsLock);
    [sessions() removeObjectForKey:@(_sessionId)];
    OSSpinLockUnlock(&sessionsLock);
    
    VTDecompressionSessionRef decompressionSession = _decompressionSession;
    [_queue dispatch:^{
        if (decompressionSession != NULL) {
            VTDecompressionSessionFinishDelayedFrames(decompressionSession);
            VTDecompressionSessionWaitForAsynchronousFrames(decompressionSession);
            VTDecompressionSessionInvalidate(decompressionSession);
            CFRelease(decompressionSession);
        }
    }];
}

- (void)pollFrames:(NSUInteger)count {
    [_queue dispatch:^{
        //TGLog(@"poll %x %d", self, (int)count);
        
        if (!_initialized) {
            _initialized = true;
            
            NSError *error = nil;
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:_url options:@{}];
            _assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
            if (_assetReader == nil || error != nil) {
                return;
            }
            
            AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
            if (videoTrack == nil) {
                return;
            }
            
            NSArray *formatDescriptions = videoTrack.formatDescriptions;
            CMVideoFormatDescriptionRef formatDescription = (__bridge CMVideoFormatDescriptionRef)formatDescriptions.firstObject;
            VTDecompressionOutputCallbackRecord callbackRecord = {&VTPlayerDecompressionOutputCallback, (void *)(intptr_t)_sessionId};
            NSDictionary *imageOutputDescription = @{(NSString *)kCVPixelBufferOpenGLESTextureCacheCompatibilityKey: @true};
            imageOutputDescription = nil;
            VTDecompressionSessionCreate(kCFAllocatorDefault, formatDescription, NULL, (__bridge CFDictionaryRef)imageOutputDescription, &callbackRecord, &_decompressionSession);
            if (_decompressionSession == NULL) {
                return;
            }
            
            _videoTrackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:nil];
            if (![_assetReader canAddOutput:_videoTrackOutput]) {
                VTDecompressionSessionInvalidate(_decompressionSession);
                _decompressionSession = nil;
                
                return;
            }
            
            [_assetReader addOutput:_videoTrackOutput];
            
            if (![_assetReader startReading]) {
                VTDecompressionSessionInvalidate(_decompressionSession);
                _decompressionSession = nil;
                
                return;
            }
        }
        
        if (_decompressionSession != NULL) {
            NSInteger remainingCount = (NSInteger)count;
            NSInteger decodedFrames = 0;
            CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
            while (_assetReader.status == AVAssetReaderStatusReading && remainingCount-- > 0/* && _requestedFrames <= (NSInteger)highWaterLimit*/) {
                CMSampleBufferRef sampleBuffer = [_videoTrackOutput copyNextSampleBuffer];
                if (sampleBuffer != NULL) {
                    _requestedFrames++;
                    VTDecodeFrameFlags decodeFlags = 0;
                    VTDecodeInfoFlags outFlags = 0;
                    VTDecompressionSessionDecodeFrame(_decompressionSession, sampleBuffer, decodeFlags, &sampleBuffer, &outFlags);
                    decodedFrames++;
                    
                    CFRelease(sampleBuffer);
                } else {
                    break;
                }
            }
            TGLog(@"Decoded %d in %f ms", (int)decodedFrames, (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0);
            
            if (_assetReader.status == AVAssetReaderStatusFailed) {
                TGLog(@"(VTPlayer copyNextSampleBuffer error: %@)", _assetReader.error);
            } else if (_assetReader.status == AVAssetReaderStatusCompleted) {
                [_assetReader cancelReading];
                
                //VTDecompressionSessionWaitForAsynchronousFrames(_decompressionSession);
                VTDecompressionSessionInvalidate(_decompressionSession);
                CFRelease(_decompressionSession);
                _decompressionSession = nil;
                if (_nextFrame) {
                    _nextFrame(nil, true);
                }
            }
        }
    }];
}

- (void)addFrame:(VTPlayerFrame *)frame {
    [_queue dispatch:^{
        if (_requestedFrames != 0) {
            _requestedFrames--;
        }
        
        if (_nextFrame) {
            if (frame != nil) {
                frame->_presentationTime += _referencePresentationTime;
            }
            //TGLog(@"frame %x", self);
            _nextFrame(frame, false);
        }
    }];
}

@end

static void VTPlayerDecompressionOutputCallback(void *decompressionOutputRefCon, __unused void *sourceFrameRefCon, OSStatus status, __unused VTDecodeInfoFlags infoFlags, CVImageBufferRef imageBuffer, CMTime presentationTimestamp, CMTime presentationDuration) {
    if (status != noErr) {
        //Console.WriteLine ("Error decompresssing frame at time: {0:#.###} error: {1} infoFlags: {2}", (float)presentationTimeStamp.Value / presentationTimeStamp.TimeScale, (int)status, flags);
        return;
    }
    
    if (imageBuffer == nil) {
        return;
    }
    
    if (CMTIME_IS_INVALID(presentationTimestamp)) {
        return;
    }
    
    CFAbsoluteTime presentationSeconds = CMTimeGetSeconds(presentationTimestamp);
    CFAbsoluteTime durationSeconds = CMTimeGetSeconds(presentationDuration);
    
    OSSpinLockLock(&sessionsLock);
    WeakReference *sessionReference = sessions()[@((int32_t)((intptr_t)decompressionOutputRefCon))];
    OSSpinLockUnlock(&sessionsLock);
    
    VTPlayerSession *playerSession = sessionReference.object;
    if (playerSession != nil) {
        [playerSession addFrame:[[VTPlayerFrame alloc] initWithPixelBuffer:imageBuffer presentationTime:presentationSeconds presentationDuration:durationSeconds]];
    }
}

@interface VTPlayer () {
    SQueue *_queue;
    NSURL *_url;
    
    NSMutableArray *_frames;
    VTPlayerSession *_session;
    
    __weak VTPlayerView *_playerView;
    STimer *_frameTimer;
    
    NSInteger _requestedFrameCount;
    CFAbsoluteTime _previousPresentationTime;
}

@end

@implementation VTPlayer

- (instancetype)initWithUrl:(NSURL *)url {
    self = [super init];
    if (self != nil) {
        _queue = [[SQueue alloc] init];
        _url = url;
        _frames = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    __strong VTPlayerView *playerView = _playerView;
    DispatchOnMainThread(^{
        [playerView description];
    });
}

- (void)play {
    [_queue dispatch:^{
        [_frameTimer invalidate];
        _frameTimer = nil;
        [self _startSessionWithReferencePresentationTime:0.0];
    }];
}

- (void)_setOutput:(VTPlayerView *)playerView {
    [_queue dispatch:^{
        _playerView = playerView;
    }];
}

- (void)_startSessionWithReferencePresentationTime:(CFAbsoluteTime)referencePresentationTime {
    if (_session == nil) {
        __weak VTPlayer *weakSelf = self;
        _session = [[VTPlayerSession alloc] initWithQueue:_queue url:_url referencePresentationTime:referencePresentationTime nextFrame:^(VTPlayerFrame *frame, bool final) {
            __strong VTPlayer *strongSelf = weakSelf;
            if (strongSelf != nil) {
                strongSelf->_requestedFrameCount = MAX(0, strongSelf->_requestedFrameCount - 1);
                if (frame != nil) {
                    [strongSelf->_frames addObject:frame];
                }
                if (final) {
                    VTPlayerFrame *lastFrame = strongSelf->_frames.lastObject;
                    CFAbsoluteTime nextReferencePresentationTime = 0.0;
                    if (lastFrame != nil) {
                        nextReferencePresentationTime = lastFrame->_presentationTime + lastFrame->_presentationDuration;
                    }
                    strongSelf->_session = nil;
                    strongSelf->_requestedFrameCount = 0;
                    [strongSelf _startSessionWithReferencePresentationTime:nextReferencePresentationTime];
                } else if (frame != nil) {
                    [strongSelf _updateTimer];
                }
            }
        }];
        TGLog(@"session %x", _session);
        [self _displayFrame];
    }
}

- (void)_updateTimer {
    if (_frameTimer == nil) {
        [self _displayFrame];
    }
}

- (void)_displayFrame {
    if (_frames.count != 0) {
        VTPlayerFrame *frame = _frames[0];
        [_frames removeObjectAtIndex:0];
        _previousPresentationTime = frame->_presentationTime;
        
        if (_frames.count != 0 && _frameTimer == nil) {
            VTPlayerFrame *nextFrame = _frames[0];
        
            CFAbsoluteTime delay = MAX(0.04, nextFrame->_presentationTime - _previousPresentationTime);
            __weak VTPlayer *weakSelf = self;
            _frameTimer = [[STimer alloc] initWithTimeout:delay repeat:false completion:^{
                __strong VTPlayer *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    strongSelf->_frameTimer = nil;
                    [strongSelf _displayFrame];
                }
            } queue:_queue];
            [_frameTimer start];
        }
    }
    
    if (_frames.count <= lowWaterLimit) {
        [self _requestFrames:highWaterLimit - _frames.count];
    }
}

- (void)_requestFrames:(NSUInteger)count {
    //if (_requestedFrameCount < (NSInteger)highWaterLimit) {
    //    _requestedFrameCount += count;
        [_session pollFrames:count];
    //}
}

- (void)stop {
    [_queue dispatch:^{
        [_frameTimer invalidate];
        _session = nil;
    }];
}

@end
