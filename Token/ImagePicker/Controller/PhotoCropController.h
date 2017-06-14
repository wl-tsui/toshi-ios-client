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

@class CameraShotMetadata;
@class PhotoEditor;
@class PhotoEditorPreviewView;

@interface PhotoCropController : PhotoEditorTabController

@property (nonatomic, readonly) bool switching;
@property (nonatomic, readonly) UIImageOrientation cropOrientation;

@property (nonatomic, copy) void (^finishedPhotoProcessing)(void);
@property (nonatomic, copy) void (^cropReset)(void);

- (instancetype)initWithPhotoEditor:(PhotoEditor *)photoEditor previewView:(PhotoEditorPreviewView *)previewView metadata:(CameraShotMetadata *)metadata forVideo:(bool)forVideo;

- (void)setAutorotationAngle:(CGFloat)autorotationAngle;

- (void)rotate;

- (void)setImage:(UIImage *)image;
- (void)setSnapshotImage:(UIImage *)snapshotImage;
- (void)setSnapshotView:(UIView *)snapshotView;

@end
