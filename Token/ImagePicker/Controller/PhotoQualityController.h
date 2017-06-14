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

#import "PhotoEditorTabController.h"

#import "VideoEditAdjustments.h"

@class PhotoEditor;
@class PhotoEditorPreviewView;
@class PhotoEditorController;

@interface PhotoQualityController : ViewController

@property (nonatomic, weak) id item;

@property (nonatomic, weak) PhotoEditorController *mainController;

@property (nonatomic, copy) void(^beginTransitionOut)(void);
@property (nonatomic, copy) void(^finishedCombinedTransition)(void);

@property (nonatomic, assign) CGFloat toolbarLandscapeSize;

@property (nonatomic, readonly) MediaVideoConversionPreset preset;


- (instancetype)initWithPhotoEditor:(PhotoEditor *)photoEditor;

- (void)attachPreviewView:(PhotoEditorPreviewView *)previewView;

- (void)_animatePreviewViewTransitionOutToFrame:(CGRect)targetFrame saving:(bool)saving parentView:(UIView *)parentView completion:(void (^)(void))completion;

- (void)prepareForCombinedAppearance;
- (void)finishedCombinedAppearance;

@end
