#import "AudioSessionManager.h"

#import <pthread.h>

#import "Common.h"

@interface AudioSessionManager ()
{
    pthread_mutex_t _mutex;
    int32_t _clientId;
    
    AudioSessionType _currentType;
    bool _currentActive;
    NSMutableArray *_currentClientIds;
    NSMutableArray *_currentInterruptedArray;
    
    bool _isInterrupting;
}

@end

@implementation AudioSessionManager

+ (AudioSessionManager *)instance
{
    static AudioSessionManager *singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        singleton = [[AudioSessionManager alloc] init];
    });
    
    return singleton;
}

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        pthread_mutex_init(&_mutex, NULL);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionInterruption:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
}

- (NSString *)nativeCategoryForType:(AudioSessionType)type
{
    switch (type)
    {
        case AudioSessionTypePlayVoice:
        case AudioSessionTypePlayMusic:
        case AudioSessionTypePlayVideo:
            return AVAudioSessionCategoryPlayback;
        case AudioSessionTypePlayAndRecord:
        case AudioSessionTypePlayAndRecordHeadphones:
        case AudioSessionTypeCall:
            return AVAudioSessionCategoryPlayAndRecord;
    }
}

- (id<SDisposable>)requestSessionWithType:(AudioSessionType)type interrupted:(void (^)())interrupted
{
    NSArray *interruptedToInvoke = nil;
    id<SDisposable> result = nil;
    
//    if (type == AudioSessionTypePlayVideo) {
//        [TGTelegraphInstance.musicPlayer controlPause];
//    }
    
    pthread_mutex_lock(&_mutex);
    {
        if (_currentType != AudioSessionTypeCall)
        {
            if (_isInterrupting)
            {
                if (interrupted)
                    interruptedToInvoke = @[[interrupted copy]];
            }
            else
            {
                if (_currentInterruptedArray == nil)
                    _currentInterruptedArray = [[NSMutableArray alloc] init];
                if (_currentClientIds == nil)
                    _currentClientIds = [[NSMutableArray alloc] init];
                
                int32_t clientId = _clientId++;
                
                if (!_currentActive || _currentType != type)
                {
                    _currentActive = true;
                    _currentType = type;
                    
                    interruptedToInvoke = [[NSArray alloc] initWithArray:_currentInterruptedArray];
                    [_currentInterruptedArray removeAllObjects];
                    [_currentClientIds removeAllObjects];
                    
                    NSError *error = nil;
                    
                    TGLog(@"(AudioSessionManager setting category %d active overriding port: %d)", (int)type, ((type == AudioSessionTypePlayAndRecordHeadphones || type == AudioSessionTypePlayMusic || type == AudioSessionTypePlayVideo)) ? 1 : 0);
                    [[AVAudioSession sharedInstance] setCategory:[self nativeCategoryForType:type] withOptions:(type == AudioSessionTypePlayAndRecord || type == AudioSessionTypePlayAndRecordHeadphones || type == AudioSessionTypeCall) ? AVAudioSessionCategoryOptionAllowBluetooth : 0 error:&error];
                    if (error != nil)
                        TGLog(@"(AudioSessionManager setting category %d error %@)", (int)type, error);
                    [[AVAudioSession sharedInstance] setMode:(type == AudioSessionTypeCall) ? AVAudioSessionModeVoiceChat : AVAudioSessionModeDefault error:&error];
                    if (error != nil)
                        TGLog(@"(AudioSessionManager setting mode error %@)", error);
                    [[AVAudioSession sharedInstance] setActive:true error:&error];
                    if (error != nil)
                        TGLog(@"(AudioSessionManager setting active error %@)", error);
                    //if ((type == AudioSessionTypePlayAndRecordHeadphones || type == AudioSessionTypePlayMusic || type == AudioSessionTypePlayVideo)) {
                    [[AVAudioSession sharedInstance] overrideOutputAudioPort:(type == AudioSessionTypePlayAndRecordHeadphones || type == AudioSessionTypePlayMusic || type == AudioSessionTypePlayVideo || type == AudioSessionTypeCall) ? AVAudioSessionPortOverrideNone : AVAudioSessionPortOverrideSpeaker error:&error];
                    //}
                    if (error != nil)
                        TGLog(@"(AudioSessionManager override port error %@)", error);
                }
                
                if (interrupted)
                    [_currentInterruptedArray addObject:[interrupted copy]];
                else
                    [_currentInterruptedArray addObject:[^{} copy]];
                [_currentClientIds addObject:@(clientId)];
                
                __weak AudioSessionManager *weakSelf = self;
                result = [[SBlockDisposable alloc] initWithBlock:^
                {
                    __strong AudioSessionManager *strongSelf = weakSelf;
                    if (strongSelf != nil)
                        [strongSelf endSessionForClientId:clientId];
                }];
            }
        }
    }
    pthread_mutex_unlock(&_mutex);
    
    for (void (^f)() in interruptedToInvoke)
    {
        f();
    }
    
    return result;
}

- (void)cancelCurrentSession
{
    [self cancelCurrentSession:false];
}

- (void)cancelCurrentSession:(bool)interrupted
{
    if (interrupted)
    {
        bool ignore = false;
        pthread_mutex_lock(&_mutex);
        {
            if (_currentType == AudioSessionTypeCall)
                ignore = true;
        }
        pthread_mutex_unlock(&_mutex);
        if (ignore)
            return;
    }
    
    NSArray *interruptedToInvoke = nil;

    pthread_mutex_lock(&_mutex);
    {
        _isInterrupting = true;
        interruptedToInvoke = [[NSArray alloc] initWithArray:_currentInterruptedArray];
    }
    pthread_mutex_unlock(&_mutex);
    
    for (void (^f)() in interruptedToInvoke)
    {
        f();
    }
    
    pthread_mutex_lock(&_mutex);
    {
        _isInterrupting = false;
        
        [_currentClientIds removeAllObjects];
        [_currentInterruptedArray removeAllObjects];
        
        _currentActive = false;
        _currentType = AudioSessionTypePlayMusic;
        
        TGLog(@"(AudioSessionManager setting inactive)");
        NSError *error = nil;
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
        if (error != nil)
            TGLog(@"(AudioSessionManager override port error %@)", error);
        [[AVAudioSession sharedInstance] setCategory:[self nativeCategoryForType:_currentType] error:&error];
        if (error != nil)
            TGLog(@"(AudioSessionManager setting category error %@)", error);
        [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeDefault error:&error];
        if (error != nil)
            TGLog(@"(AudioSessionManager setting mode error %@)", error);
        [[AVAudioSession sharedInstance] setActive:false withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
        if (error != nil)
            TGLog(@"(AudioSessionManager setting inactive error %@)", error);
    }
    pthread_mutex_unlock(&_mutex);
}

- (void)endSessionForClientId:(int32_t)clientId
{
    pthread_mutex_lock(&_mutex);
    {
        for (NSUInteger i = 0; i < _currentClientIds.count; i++)
        {
            if ([_currentClientIds[i] intValue] == clientId)
            {
                [_currentInterruptedArray removeObjectAtIndex:i];
                [_currentClientIds removeObjectAtIndex:i];
                
                break;
            }
        }
        
        if (_currentActive && _currentClientIds.count == 0)
        {
            _currentActive = false;
            _currentType = AudioSessionTypePlayMusic;
            
            TGLog(@"(AudioSessionManager setting inactive)");
            NSError *error = nil;
            [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
            if (error != nil)
                TGLog(@"(AudioSessionManager override port error %@)", error);
            [[AVAudioSession sharedInstance] setCategory:[self nativeCategoryForType:_currentType] error:&error];
            if (error != nil)
                TGLog(@"(AudioSessionManager setting category error %@)", error);
            [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeDefault error:&error];
            if (error != nil)
                TGLog(@"(AudioSessionManager setting mode error %@)", error);
            [[AVAudioSession sharedInstance] setActive:false withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
            if (error != nil)
                TGLog(@"(AudioSessionManager setting inactive error %@)", error);
        }
    }
    pthread_mutex_unlock(&_mutex);
}

+ (SSignal *)routeChange
{
    return [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        id observer = [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionRouteChangeNotification object:nil queue:nil usingBlock:^(NSNotification *notification)
        {
            if ([notification.userInfo[AVAudioSessionRouteChangeReasonKey] intValue] == AVAudioSessionRouteChangeReasonOldDeviceUnavailable)
            {
                [subscriber putNext:@(AudioSessionRouteChangePause)];
            }
            else if ([notification.userInfo[AVAudioSessionRouteChangeReasonKey] intValue] == AVAudioSessionRouteChangeReasonNewDeviceAvailable)
            {
                [subscriber putNext:@(AudioSessionRouteChangeResume)];
            }
        }];
        
        return [[SBlockDisposable alloc] initWithBlock:^
        {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }];
    }];
}

- (void)audioSessionInterruption:(NSNotification *)notification
{
    NSNumber *interruptionType = (NSNumber *)notification.userInfo[AVAudioSessionInterruptionTypeKey];
    if ([interruptionType intValue] == AVAudioSessionInterruptionTypeBegan)
        [self cancelCurrentSession:true];
}

- (void)applyRoute:(AudioRoute *)route
{
    NSError *error;
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if ([route.uid isEqualToString:@"builtin"])
    {
        [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:NULL];
        NSArray *inputs = [[AVAudioSession sharedInstance] availableInputs];
        for (AVAudioSessionPortDescription *input in inputs)
        {
            if ([input.portType isEqualToString:AVAudioSessionPortBuiltInMic])
            {
                [session setPreferredInput:input error:&error];
                return;
            }
        }
    }
    else if ([route.uid isEqualToString:@"speaker"])
    {
        [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:NULL];
    }
    else
    {
        [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:NULL];
        NSArray *inputs = [[AVAudioSession sharedInstance] availableInputs];
        for (AVAudioSessionPortDescription *input in inputs)
        {
            if ([input.UID isEqualToString:route.uid])
            {
                [session setPreferredInput:input error:&error];
                return;
            }
        }
    }
}

@end


@interface AudioRoute ()
{
    bool _isBluetooth;
}
@end

@implementation AudioRoute

+ (instancetype)routeForBuiltIn:(bool)headphones
{
    NSString *deviceModel = [UIDevice currentDevice].model;
    AudioRoute *route = [[AudioRoute alloc] init];
    route->_name = headphones ? TGLocalized(@"Call.AudioRouteHeadphones") : deviceModel;
    route->_uid = @"builtin";
    route->_isBuiltIn = true;
    route->_isHeadphones = headphones;
    return route;
}

+ (instancetype)routeForSpeaker
{
    NSString *deviceModel = [UIDevice currentDevice].model;
    if (![deviceModel isEqualToString:@"iPhone"])
        return nil;
    
    AudioRoute *route = [[AudioRoute alloc] init];
    route->_name = TGLocalized(@"Call.AudioRouteSpeaker");
    route->_uid = @"speaker";
    route->_isLoudspeaker = true;
    return route;
}

+ (instancetype)routeWithDescription:(AVAudioSessionPortDescription *)description
{
    AudioRoute *route = [[AudioRoute alloc] init];
    route->_name = description.portName;
    route->_uid = description.UID;
    route->_isBluetooth = [[self bluetoothTypes] containsObject:description.portType];
    return route;
}

+ (NSArray *)bluetoothTypes
{
    static dispatch_once_t onceToken;
    static NSArray *bluetoothTypes;
    dispatch_once(&onceToken, ^
    {
        bluetoothTypes = @[AVAudioSessionPortBluetoothA2DP, AVAudioSessionPortBluetoothLE, AVAudioSessionPortBluetoothHFP];
    });
    return bluetoothTypes;
}

@end
