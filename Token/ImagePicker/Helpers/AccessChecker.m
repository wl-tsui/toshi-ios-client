#import "AccessChecker.h"

#import <CoreLocation/CoreLocation.h>
#import "MediaAssetsLibrary.h"
#import "Camera.h"
#import "Common.h"

@implementation AccessChecker

+ (bool)checkPhotoAuthorizationStatusForIntent:(PhotoAccessIntent)intent alertDismissCompletion:(void (^)(void))alertDismissCompletion
{
    switch ([MediaAssetsLibrary authorizationStatus])
    {
        case MediaLibraryAuthorizationStatusDenied:
        {
            NSString *message = @"";
            switch (intent)
            {
                case PhotoAccessIntentRead:
                    message = TGLocalized(@"AccessDenied.PhotosAndVideos");
                    break;
                    
                case PhotoAccessIntentSave:
                    message = TGLocalized(@"AccessDenied.SaveMedia");
                    break;
                    
                case PhotoAccessIntentCustomWallpaper:
                    message = TGLocalized(@"AccessDenied.CustomWallpaper");
                    break;
                    
                default:
                    break;
            }
        }
            return false;
            
        default:
            return true;
    }
}

+ (bool)checkMicrophoneAuthorizationStatusForIntent:(MicrophoneAccessIntent)intent alertDismissCompletion:(void (^)(void))alertDismissCompletion
{
    switch ([Camera microphoneAuthorizationStatus])
    {
        case PGMicrophoneAuthorizationStatusDenied:
        {
            NSString *message = nil;
            switch (intent)
            {
                case MicrophoneAccessIntentVoice:
                    message = TGLocalized(@"AccessDenied.VoiceMicrophone");
                    break;
                    
                case MicrophoneAccessIntentVideo:
                    message = TGLocalized(@"AccessDenied.VideoMicrophone");
                    break;
                    
                case MicrophoneAccessIntentCall:
                    message = TGLocalized(@"AccessDenied.CallMicrophone");
                    break;
            }
            
//            [[[TGAccessRequiredAlertView alloc] initWithMessage:message
//                                             showSettingsButton:true
//                                                completionBlock:alertDismissCompletion] show];
        }
            return false;
            
        case PGMicrophoneAuthorizationStatusRestricted:
        {
//            [[[TGAccessRequiredAlertView alloc] initWithMessage:TGLocalized(@"AccessDenied.MicrophoneRestricted")
//                                             showSettingsButton:false
//                                                completionBlock:alertDismissCompletion] show];
        }
            return false;
            
        default:
            return true;
    }
}

+ (bool)checkCameraAuthorizationStatusWithAlertDismissComlpetion:(void (^)(void))alertDismissCompletion
{
#if TARGET_IPHONE_SIMULATOR
    if (true) {
        return true;
    }
#endif
    
    if (![Camera cameraAvailable])
    {
//        [[[TGAccessRequiredAlertView alloc] initWithMessage:TGLocalized(@"AccessDenied.CameraDisabled")
//                                         showSettingsButton:true
//                                            completionBlock:alertDismissCompletion] show];
//        
        return false;
    }
    
    switch ([Camera cameraAuthorizationStatus])
    {
        case PGCameraAuthorizationStatusDenied:
        {
//            [[[TGAccessRequiredAlertView alloc] initWithMessage:TGLocalized(@"AccessDenied.Camera")
//                                             showSettingsButton:true
//                                                completionBlock:alertDismissCompletion] show];
        }
            return false;
            
        case PGCameraAuthorizationStatusRestricted:
        {
//            [[[TGAccessRequiredAlertView alloc] initWithMessage:TGLocalized(@"AccessDenied.CameraRestricted")
//                                             showSettingsButton:false
//                                                completionBlock:alertDismissCompletion] show];
        }
            return false;
            
        default:
            return true;
    }
}

+ (bool)checkLocationAuthorizationStatusForIntent:(LocationAccessIntent)intent alertDismissComlpetion:(void (^)(void))alertDismissCompletion
{
    switch ([CLLocationManager authorizationStatus])
    {
        case kCLAuthorizationStatusDenied:
        {
//            [[[TGAccessRequiredAlertView alloc] initWithMessage:intent == LocationAccessIntentSend ? TGLocalized(@"AccessDenied.LocationDenied") : TGLocalized(@"AccessDenied.LocationTracking")
//                                             showSettingsButton:true
//                                                completionBlock:alertDismissCompletion] show];
        }
            return false;
            
        case kCLAuthorizationStatusRestricted:
        {
//            [[[TGAccessRequiredAlertView alloc] initWithMessage:TGLocalized(@"AccessDenied.LocationDisabled")
//                                             showSettingsButton:false
//                                                completionBlock:alertDismissCompletion] show];
        }
            return false;

        default:
            return true;
    }
}

@end
