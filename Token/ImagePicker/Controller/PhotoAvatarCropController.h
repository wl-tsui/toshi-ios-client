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

@class PhotoEditor;
@class PhotoEditorPreviewView;

@interface PhotoAvatarCropController : PhotoEditorTabController

@property (nonatomic, readonly) UIView *transitionParentView;

@property (nonatomic, assign) bool switching;
@property (nonatomic, assign) bool skipTransitionIn;
@property (nonatomic, assign) bool fromCamera;

@property (nonatomic, copy) void (^finishedPhotoProcessing)(void);

- (instancetype)initWithPhotoEditor:(PhotoEditor *)photoEditor previewView:(PhotoEditorPreviewView *)previewView;

- (void)setImage:(UIImage *)image;
- (void)setSnapshotImage:(UIImage *)snapshotImage;
- (void)setSnapshotView:(UIView *)snapshotView;

- (void)_finishedTransitionIn;

@end
