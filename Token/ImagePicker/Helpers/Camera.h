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
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

#import "CameraShotMetadata.h"

typedef enum {
    PGCameraAuthorizationStatusNotDetermined,
    PGCameraAuthorizationStatusRestricted,
    PGCameraAuthorizationStatusDenied,
    PGCameraAuthorizationStatusAuthorized
} PGCameraAuthorizationStatus;

typedef enum {
    PGMicrophoneAuthorizationStatusNotDetermined,
    PGMicrophoneAuthorizationStatusRestricted,
    PGMicrophoneAuthorizationStatusDenied,
    PGMicrophoneAuthorizationStatusAuthorized
} PGMicrophoneAuthorizationStatus;

typedef enum
{
    PGCameraModeUndefined,
    PGCameraModePhoto,
    PGCameraModeVideo,
    PGCameraModeSquare,
    PGCameraModeClip
} PGCameraMode;

typedef enum
{
    PGCameraFlashModeOff,
    PGCameraFlashModeOn,
    PGCameraFlashModeAuto
} PGCameraFlashMode;

typedef enum
{
    PGCameraPositionUndefined,
    PGCameraPositionRear,
    PGCameraPositionFront
} PGCameraPosition;

@class CameraCaptureSession;
@class CameraDeviceAngleSampler;
@class CameraPreviewView;

@interface Camera : NSObject

@property (readonly, nonatomic) CameraCaptureSession *captureSession;
@property (readonly, nonatomic) CameraDeviceAngleSampler *deviceAngleSampler;

@property (nonatomic, copy) void(^captureStarted)(bool resumed);
@property (nonatomic, copy) void(^captureStopped)(bool paused);

@property (nonatomic, copy) void(^beganModeChange)(PGCameraMode mode, void(^commitBlock)(void));
@property (nonatomic, copy) void(^finishedModeChange)(void);

@property (nonatomic, copy) void(^beganPositionChange)(bool targetPositionHasFlash, bool targetPositionHasZoom, void(^commitBlock)(void));
@property (nonatomic, copy) void(^finishedPositionChange)(void);

@property (nonatomic, copy) void(^beganAdjustingFocus)(void);
@property (nonatomic, copy) void(^finishedAdjustingFocus)(void);

@property (nonatomic, copy) void(^flashActivityChanged)(bool flashActive);
@property (nonatomic, copy) void(^flashAvailabilityChanged)(bool flashAvailable);

@property (nonatomic, copy) void(^beganVideoRecording)(bool moment);
@property (nonatomic, copy) void(^finishedVideoRecording)(bool moment);
@property (nonatomic, copy) void(^reallyBeganVideoRecording)(bool moment);

@property (nonatomic, copy) void(^captureInterrupted)(AVCaptureSessionInterruptionReason reason);

@property (nonatomic, copy) void(^onAutoStartVideoRecording)(void);

@property (nonatomic, copy) UIInterfaceOrientation(^requestedCurrentInterfaceOrientation)(bool *mirrored);

@property (nonatomic, assign) PGCameraMode cameraMode;
@property (nonatomic, assign) PGCameraFlashMode flashMode;

@property (nonatomic, readonly) bool isZoomAvailable;
@property (nonatomic, assign) CGFloat zoomLevel;

@property (nonatomic, assign) bool disabled;
@property (nonatomic, readonly) bool isCapturing;
@property (nonatomic, readonly) NSTimeInterval videoRecordingDuration;

@property (nonatomic, assign) bool autoStartVideoRecording;

- (instancetype)initWithMode:(PGCameraMode)mode position:(PGCameraPosition)position;

- (void)attachPreviewView:(CameraPreviewView *)previewView;

- (bool)supportsExposurePOI;
- (bool)supportsFocusPOI;
- (void)setFocusPoint:(CGPoint)focusPoint;

- (bool)supportsExposureTargetBias;
- (void)beginExposureTargetBiasChange;
- (void)setExposureTargetBias:(CGFloat)bias;
- (void)endExposureTargetBiasChange;

- (void)captureNextFrameCompletion:(void (^)(UIImage * image))completion;

- (void)takePhotoWithCompletion:(void (^)(UIImage *result, CameraShotMetadata *metadata))completion;

- (void)startVideoRecordingForMoment:(bool)moment completion:(void (^)(NSURL *, CGAffineTransform transform, CGSize dimensions, NSTimeInterval duration, bool success))completion;
- (void)stopVideoRecording;
- (bool)isRecordingVideo;

- (void)startCaptureForResume:(bool)resume completion:(void (^)(void))completion;
- (void)stopCaptureForPause:(bool)pause completion:(void (^)(void))completion;

- (bool)isResetNeeded;
- (void)resetSynchronous:(bool)synchronous completion:(void (^)(void))completion;
- (void)resetTerminal:(bool)terminal synchronous:(bool)synchronous completion:(void (^)(void))completion;

- (bool)hasFlash;
- (bool)flashActive;
- (bool)flashAvailable;

- (PGCameraPosition)togglePosition;

+ (bool)cameraAvailable;
+ (bool)hasFrontCamera;
+ (bool)hasRearCamera;

+ (PGCameraAuthorizationStatus)cameraAuthorizationStatus;
+ (PGMicrophoneAuthorizationStatus)microphoneAuthorizationStatus;

@end
