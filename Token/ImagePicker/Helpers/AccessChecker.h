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

typedef enum {
    PhotoAccessIntentRead,
    PhotoAccessIntentSave,
    PhotoAccessIntentCustomWallpaper
} PhotoAccessIntent;

typedef enum {
    MicrophoneAccessIntentVoice,
    MicrophoneAccessIntentVideo,
    MicrophoneAccessIntentCall,
} MicrophoneAccessIntent;

typedef enum {
    LocationAccessIntentSend,
    LocationAccessIntentTracking,
} LocationAccessIntent;

@interface AccessChecker : NSObject

+ (bool)checkPhotoAuthorizationStatusForIntent:(PhotoAccessIntent)intent alertDismissCompletion:(void (^)(void))alertDismissCompletion
NS_SWIFT_NAME(checkPhotoAuthorizationStatus(intent:alertDismissCompletion:));

+ (bool)checkMicrophoneAuthorizationStatusForIntent:(MicrophoneAccessIntent)intent alertDismissCompletion:(void (^)(void))alertDismissCompletion;

+ (bool)checkCameraAuthorizationStatusWithAlertDismissComlpetion:(void (^)(void))alertDismissCompletion;

+ (bool)checkLocationAuthorizationStatusForIntent:(LocationAccessIntent)intent alertDismissComlpetion:(void (^)(void))alertDismissCompletion;

@end
