//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import <AFNetworking/AFHTTPSessionManager.h>

#import "OWSCensorshipConfiguration.h"
#import "OWSHTTPSecurityPolicy.h"
#import "OWSSignalService.h"
#import "TSAccountManager.h"
#import "TSConstants.h"
#import "TSStorageManager.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const kTSStorageManager_OWSSignalService = @"kTSStorageManager_OWSSignalService";
NSString *const kTSStorageManager_isCensorshipCircumventionManuallyActivated =
@"kTSStorageManager_isCensorshipCircumventionManuallyActivated";
NSString *const kTSStorageManager_ManualCensorshipCircumventionDomain =
@"kTSStorageManager_ManualCensorshipCircumventionDomain";
static NSString *TextSecureServerURL = @"wss://token-chat-service.herokuapp.com";
NSString *const kTSStorageManager_ManualCensorshipCircumventionCountryCode =
@"kTSStorageManager_ManualCensorshipCircumventionCountryCode";

NSString *const kNSNotificationName_IsCensorshipCircumventionActiveDidChange =
@"kNSNotificationName_IsCensorshipCircumventionActiveDidChange";

@interface OWSSignalService ()

@property (nonatomic, readonly) OWSCensorshipConfiguration *censorshipConfiguration;

@property (nonatomic) BOOL hasCensoredPhoneNumber;

@property (atomic) BOOL isCensorshipCircumventionActive;

@end

#pragma mark -

@implementation OWSSignalService

@synthesize isCensorshipCircumventionActive = _isCensorshipCircumventionActive;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _censorshipConfiguration = [OWSCensorshipConfiguration new];

        [self observeNotifications];

        [self updateHasCensoredPhoneNumber];
        [self updateIsCensorshipCircumventionActive];
    }

    return self;
}

- (void)stopObservingNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)setBaseURLPath:(NSString *)baseURLPath {
    TextSecureServerURL = baseURLPath;
}

+ (NSString *)baseURLPath {
    return TextSecureServerURL;
}

- (void)observeNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationStateDidChange:)
                                                 name:kNSNotificationName_RegistrationStateDidChange
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(localNumberDidChange:)
                                                 name:kNSNotificationName_LocalNumberDidChange
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateHasCensoredPhoneNumber
{
    dispatch_async(dispatch_get_main_queue(), ^{

        NSString *localNumber = [TSAccountManager localNumber];

        if (localNumber) {
            self.hasCensoredPhoneNumber = [self.censorshipConfiguration isCensoredPhoneNumber:localNumber];
        } else {
            DDLogError(@"%@ no known phone number to check for censorship.", self.tag);
            self.hasCensoredPhoneNumber = NO;
        }

        [self updateIsCensorshipCircumventionActive];
    });
}

- (BOOL)isCensorshipCircumventionManuallyActivated
{
    return [[TSStorageManager sharedManager] boolForKey:kTSStorageManager_isCensorshipCircumventionManuallyActivated
                                           inCollection:kTSStorageManager_OWSSignalService];
}

- (void)setIsCensorshipCircumventionManuallyActivated:(BOOL)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[TSStorageManager sharedManager] setObject:@(value)
                                             forKey:kTSStorageManager_isCensorshipCircumventionManuallyActivated
                                       inCollection:kTSStorageManager_OWSSignalService];

        [self updateIsCensorshipCircumventionActive];
    });
}

- (void)updateIsCensorshipCircumventionActive
{
    dispatch_async(dispatch_get_main_queue(), ^{

        self.isCensorshipCircumventionActive
        = (self.isCensorshipCircumventionManuallyActivated || self.hasCensoredPhoneNumber);
    });
}

- (void)setIsCensorshipCircumventionActive:(BOOL)isCensorshipCircumventionActive
{
    dispatch_async(dispatch_get_main_queue(), ^{

        @synchronized(self)
        {
            if (_isCensorshipCircumventionActive == isCensorshipCircumventionActive) {
                return;
            }

            _isCensorshipCircumventionActive = isCensorshipCircumventionActive;
        }

        [[NSNotificationCenter defaultCenter]
         postNotificationName:kNSNotificationName_IsCensorshipCircumventionActiveDidChange
         object:nil
         userInfo:nil];
    });
}

- (BOOL)isCensorshipCircumventionActive
{
    @synchronized(self)
    {
        return _isCensorshipCircumventionActive;
    }
}

- (AFHTTPSessionManager *)HTTPSessionManager
{
    if (self.isCensorshipCircumventionActive) {
        DDLogInfo(@"%@ using reflector HTTPSessionManager", self.tag);
        return self.reflectorHTTPSessionManager;
    } else {
        DDLogDebug(@"%@ using default HTTPSessionManager", self.tag);
        return self.defaultHTTPSessionManager;
    }
}

- (AFHTTPSessionManager *)defaultHTTPSessionManager
{
    NSURL *baseURL = [[NSURL alloc] initWithString:OWSSignalService.baseURLPath];
    NSURLSessionConfiguration *sessionConf = NSURLSessionConfiguration.ephemeralSessionConfiguration;
    AFHTTPSessionManager *sessionManager =
    [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL sessionConfiguration:sessionConf];

    sessionManager.securityPolicy = [OWSHTTPSecurityPolicy sharedPolicy];
    sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];

    return sessionManager;
}

- (AFHTTPSessionManager *)reflectorHTTPSessionManager
{
    NSString *localNumber = [TSAccountManager localNumber];
    OWSAssert(localNumber.length > 0);

    // Target fronting domain
    OWSAssert(self.isCensorshipCircumventionActive);
    NSString *frontingHost = [self.censorshipConfiguration frontingHost:localNumber];
    if (self.isCensorshipCircumventionManuallyActivated && self.manualCensorshipCircumventionDomain.length > 0) {
        frontingHost = self.manualCensorshipCircumventionDomain;
    };
    NSURL *baseURL = [[NSURL alloc] initWithString:[self.censorshipConfiguration frontingHost:localNumber]];
    NSURLSessionConfiguration *sessionConf = NSURLSessionConfiguration.ephemeralSessionConfiguration;
    AFHTTPSessionManager *sessionManager =
    [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL sessionConfiguration:sessionConf];

    sessionManager.securityPolicy = [[self class] googlePinningPolicy];

    sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    [sessionManager.requestSerializer setValue:self.censorshipConfiguration.reflectorHost forHTTPHeaderField:@"Host"];

    sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];

    return sessionManager;
}

#pragma mark - Google Pinning Policy

/**
 * We use the Google Pinning Policy when connecting to our censorship circumventing reflector,
 * which is hosted on Google.
 */
+ (AFSecurityPolicy *)googlePinningPolicy {
    static AFSecurityPolicy *securityPolicy = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        NSString *path = [NSBundle.mainBundle pathForResource:@"GIAG2" ofType:@"crt"];

        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            @throw [NSException
                    exceptionWithName:@"Missing server certificate"
                    reason:[NSString stringWithFormat:@"Missing signing certificate for service googlePinningPolicy"]
                    userInfo:nil];
        }

        NSData *googleCertData = [NSData dataWithContentsOfFile:path options:0 error:&error];
        if (!googleCertData) {
            if (error) {
                @throw [NSException exceptionWithName:@"OWSSignalServiceHTTPSecurityPolicy" reason:@"Couln't read google pinning cert" userInfo:nil];
            } else {
                NSString *reason = [NSString stringWithFormat:@"Reading google pinning cert faile with error: %@", error];
                @throw [NSException exceptionWithName:@"OWSSignalServiceHTTPSecurityPolicy" reason:reason userInfo:nil];
            }
        }

        NSSet<NSData *> *certificates = [NSSet setWithObject:googleCertData];
        securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:certificates];
    });
    return securityPolicy;
}

#pragma mark - Events

- (void)registrationStateDidChange:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateHasCensoredPhoneNumber];
    });
}

- (void)localNumberDidChange:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateHasCensoredPhoneNumber];
    });
}

#pragma mark - Manual Censorship Circumvention

- (NSString *)manualCensorshipCircumventionDomain
{
    return [[TSStorageManager sharedManager] objectForKey:kTSStorageManager_ManualCensorshipCircumventionDomain
                                             inCollection:kTSStorageManager_OWSSignalService];
}

- (void)setManualCensorshipCircumventionDomain:(NSString *)value
{
    dispatch_async(dispatch_get_main_queue(), ^{

        [[TSStorageManager sharedManager] setObject:value
                                             forKey:kTSStorageManager_ManualCensorshipCircumventionDomain
                                       inCollection:kTSStorageManager_OWSSignalService];
    });
}

- (NSString *)manualCensorshipCircumventionCountryCode
{
    OWSAssert([NSThread isMainThread]);

    return [[TSStorageManager sharedManager] objectForKey:kTSStorageManager_ManualCensorshipCircumventionCountryCode
                                             inCollection:kTSStorageManager_OWSSignalService];
}

- (void)setManualCensorshipCircumventionCountryCode:(NSString *)value
{
    dispatch_async(dispatch_get_main_queue(), ^{

        [[TSStorageManager sharedManager] setObject:value
                                             forKey:kTSStorageManager_ManualCensorshipCircumventionCountryCode
                                       inCollection:kTSStorageManager_OWSSignalService];
    });
}

#pragma mark - Logging

+ (NSString *)tag
{
    return [NSString stringWithFormat:@"[%@]", self.class];
}

- (NSString *)tag
{
    return self.class.tag;
}

@end

NS_ASSUME_NONNULL_END

