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

#import "OverlayController.h"
#import "OverlayControllerWindow.h"

@class Camera;
@class CameraPreviewView;
@class SuggestionContext;
@class VideoEditAdjustments;

typedef enum {
    CameraControllerGenericIntent,
    CameraControllerAvatarIntent,
} CameraControllerIntent;

@interface CameraControllerWindow : OverlayControllerWindow

@end

@interface CameraController : OverlayController

@property (nonatomic, assign) bool liveUploadEnabled;
@property (nonatomic, assign) bool shouldStoreCapturedAssets;

@property (nonatomic, assign) bool allowCaptions;
@property (nonatomic, assign) bool inhibitDocumentCaptions;

@property (nonatomic, copy) void(^finishedWithPhoto)(UIImage *resultImage, NSString *caption, NSArray *stickers);
@property (nonatomic, copy) void(^finishedWithVideo)(NSURL *videoURL, UIImage *previewImage, NSTimeInterval duration, CGSize dimensions, VideoEditAdjustments *adjustments, NSString *caption, NSArray *stickers);

@property (nonatomic, copy) CGRect(^beginTransitionOut)(void);
@property (nonatomic, copy) void(^finishedTransitionOut)(void);

@property (nonatomic, strong) SuggestionContext *suggestionContext;

- (instancetype)initWithIntent:(CameraControllerIntent)intent;
- (instancetype)initWithCamera:(Camera *)camera previewView:(CameraPreviewView *)previewView intent:(CameraControllerIntent)intent;

- (void)beginTransitionInFromRect:(CGRect)rect;

+ (UIInterfaceOrientation)_interfaceOrientationForDeviceOrientation:(UIDeviceOrientation)orientation;

@end
