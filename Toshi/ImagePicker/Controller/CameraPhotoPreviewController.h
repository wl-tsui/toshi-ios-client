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

@class CameraShotMetadata;
@class PhotoEditorValues;
@class SuggestionContext;

@interface CameraPhotoPreviewController : OverlayController

@property (nonatomic, assign) bool allowCaptions;

@property (nonatomic, copy) CGRect(^beginTransitionIn)(void);
@property (nonatomic, copy) CGRect(^beginTransitionOut)(CGRect referenceFrame);

@property (nonatomic, copy) void(^finishedTransitionIn)(void);

@property (nonatomic, copy) void (^photoEditorShown)(void);
@property (nonatomic, copy) void (^photoEditorHidden)(void);

@property (nonatomic, copy) void(^retakePressed)(void);
@property (nonatomic, copy) void(^sendPressed)(UIImage *resultImage, NSString *caption, NSArray *stickers);

@property (nonatomic, strong) SuggestionContext *suggestionContext;
@property (nonatomic, assign) bool shouldStoreAssets;

- (instancetype)initWithImage:(UIImage *)image metadata:(CameraShotMetadata *)metadata;
- (instancetype)initWithImage:(UIImage *)image metadata:(CameraShotMetadata *)metadata backButtonTitle:(NSString *)backButtonTitle;

@end
