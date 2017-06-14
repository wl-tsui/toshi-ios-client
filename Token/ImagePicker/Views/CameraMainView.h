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
#import "Camera.h"

@class ModernButton;
@class CameraShutterButton;
@class CameraModeControl;
@class CameraFlipButton;
@class CameraTimeCodeView;
@class CameraZoomView;
@class CameraSegmentsView;

@interface CameraMainView : UIView
{
    UIInterfaceOrientation _interfaceOrientation;
    
    ModernButton *_cancelButton;
    ModernButton *_doneButton;
    CameraShutterButton *_shutterButton;
    CameraModeControl *_modeControl;
    
    CameraFlipButton *_flipButton;
    CameraTimeCodeView *_timecodeView;
    
    CameraSegmentsView *_segmentsView;
    
    CameraZoomView *_zoomView;
}

@property (nonatomic, copy) void(^cameraFlipped)(void);
@property (nonatomic, copy) bool(^cameraShouldLeaveMode)(PGCameraMode mode);
@property (nonatomic, copy) void(^cameraModeChanged)(PGCameraMode mode);
@property (nonatomic, copy) void(^flashModeChanged)(PGCameraFlashMode mode);

@property (nonatomic, copy) void(^focusPointChanged)(CGPoint point);
@property (nonatomic, copy) void(^expositionChanged)(CGFloat value);

@property (nonatomic, copy) void(^shutterPressed)(bool fromHardwareButton);
@property (nonatomic, copy) void(^shutterReleased)(bool fromHardwareButton);
@property (nonatomic, copy) void(^cancelPressed)(void);
@property (nonatomic, copy) void(^donePressed)(void);

@property (nonatomic, copy) void (^deleteSegmentButtonPressed)(void);

@property (nonatomic, copy) NSTimeInterval(^requestedVideoRecordingDuration)(void);

@property (nonatomic, assign) CGRect previewViewFrame;

- (void)setCameraMode:(PGCameraMode)mode;
- (void)updateForCameraModeChangeWithPreviousMode:(PGCameraMode)previousMode;
- (void)updateForCameraModeChangeAfterResize;

- (void)setFlashMode:(PGCameraFlashMode)mode;
- (void)setFlashActive:(bool)active;
- (void)setFlashUnavailable:(bool)unavailable;
- (void)setHasFlash:(bool)hasFlash;

- (void)setHasZoom:(bool)hasZoom;
- (void)setZoomLevel:(CGFloat)zoomLevel displayNeeded:(bool)displayNeeded;
- (void)zoomChangingEnded;

- (void)setHasModeControl:(bool)hasModeControl;

- (void)setShutterButtonHighlighted:(bool)highlighted;
- (void)setShutterButtonEnabled:(bool)enabled;

- (void)setDoneButtonHidden:(bool)hidden animated:(bool)animated;

- (void)shutterButtonPressed;
- (void)shutterButtonReleased;
- (void)flipButtonPressed;
- (void)cancelButtonPressed;
- (void)doneButtonPressed;

- (void)setRecordingVideo:(bool)recordingVideo animated:(bool)animated;
- (void)setInterfaceHiddenForVideoRecording:(bool)hidden animated:(bool)animated;

- (void)setStartedSegmentCapture;
- (void)setCurrentSegmentLength:(CGFloat)length;
- (void)setCommitSegmentCapture;
- (void)previewLastSegment;
- (void)removeLastSegment;

- (void)showMomentCaptureDismissWarningWithCompletion:(void (^)(bool dismiss))completion;

- (UIInterfaceOrientation)interfaceOrientation;
- (void)setInterfaceOrientation:(UIInterfaceOrientation)orientation animated:(bool)animated;

- (void)layoutPreviewRelativeViews;

@end
