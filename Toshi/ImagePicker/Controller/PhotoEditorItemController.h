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

#import "ViewController.h"
#import "OverlayController.h"

#import "PhotoEditorItem.h"

@class PhotoEditor;
@class PhotoEditorPreviewView;

@interface PhotoEditorItemController : ViewController

@property (nonatomic, copy) void(^editorItemUpdated)(void);
@property (nonatomic, copy) void(^beginTransitionIn)(void);
@property (nonatomic, copy) void(^beginTransitionOut)(void);
@property (nonatomic, copy) void(^finishedCombinedTransition)(void);

@property (nonatomic, assign) CGFloat toolbarLandscapeSize;
@property (nonatomic, assign) bool initialAppearance;
@property (nonatomic, assign) bool skipProcessingOnCompletion;

- (instancetype)initWithEditorItem:(id<PhotoEditorItem>)editorItem photoEditor:(PhotoEditor *)photoEditor previewView:(PhotoEditorPreviewView *)previewView;

- (void)attachPreviewView:(PhotoEditorPreviewView *)previewView;

- (void)prepareForCombinedAppearance;
- (void)finishedCombinedAppearance;

@end
