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

#import "MediaEditingContext.h"

#import "PhotoEditorController.h"
#import "PhotoToolbarView.h"
#import "ViewController.h"

@class SSignal;
@class CameraShotMetadata;
@class SuggestionContext;
@class PhotoEditorController;

typedef enum {
    PhotoEditorControllerGenericIntent = 0,
    PhotoEditorControllerAvatarIntent = 1,
    PhotoEditorControllerFromCameraIntent = (1 << 1),
    PhotoEditorControllerWebIntent = (1 << 2),
    PhotoEditorControllerVideoIntent = (1 << 3)
} PhotoEditorControllerIntent;

@interface PhotoEditorController : OverlayController

@property (nonatomic, strong) SuggestionContext *suggestionContext;
@property (nonatomic, strong) MediaEditingContext *editingContext;

@property (nonatomic, copy) UIView *(^beginTransitionIn)(CGRect *referenceFrame, UIView **parentView);
@property (nonatomic, copy) void (^finishedTransitionIn)(void);
@property (nonatomic, copy) UIView *(^beginTransitionOut)(CGRect *referenceFrame, UIView **parentView);
@property (nonatomic, copy) void (^finishedTransitionOut)(bool saved);

@property (nonatomic, copy) void (^beginCustomTransitionOut)(CGRect, UIView *, void(^)(void));

@property (nonatomic, copy) SSignal *(^requestThumbnailImage)(id<MediaEditableItem> item);
@property (nonatomic, copy) SSignal *(^requestOriginalScreenSizeImage)(id<MediaEditableItem> item, NSTimeInterval position);
@property (nonatomic, copy) SSignal *(^requestOriginalFullSizeImage)(id<MediaEditableItem> item, NSTimeInterval position);
@property (nonatomic, copy) SSignal *(^requestMetadata)(id<MediaEditableItem> item);
@property (nonatomic, copy) id<MediaEditAdjustments> (^requestAdjustments)(id<MediaEditableItem> item);

@property (nonatomic, copy) UIImage *(^requestImage)(void);
@property (nonatomic, copy) void (^requestToolbarsHidden)(bool hidden, bool animated);

@property (nonatomic, copy) void (^captionSet)(NSString *caption);

@property (nonatomic, copy) void (^willFinishEditing)(id<MediaEditAdjustments> adjustments, id temporaryRep, bool hasChanges);
@property (nonatomic, copy) void (^didFinishRenderingFullSizeImage)(UIImage *fullSizeImage);
@property (nonatomic, copy) void (^didFinishEditing)(id<MediaEditAdjustments> adjustments, UIImage *resultImage, UIImage *thumbnailImage, bool hasChanges);

@property (nonatomic, assign) bool skipInitialTransition;
@property (nonatomic, assign) bool dontHideStatusBar;
@property (nonatomic, strong) CameraShotMetadata *metadata;

- (instancetype)initWithItem:(id<MediaEditableItem>)item intent:(PhotoEditorControllerIntent)intent adjustments:(id<MediaEditAdjustments>)adjustments caption:(NSString *)caption screenImage:(UIImage *)screenImage availableTabs:(PhotoEditorTab)availableTabs selectedTab:(PhotoEditorTab)selectedTab
NS_SWIFT_NAME(init(item:intent:adjustments:caption:screenImage:availbaleTabs:selectedTab:));

- (void)dismissEditor;
- (void)applyEditor;

- (void)dismissAnimated:(bool)animated;

- (void)updateStatusBarAppearanceForDismiss;
- (CGSize)referenceViewSize;

- (void)_setScreenImage:(UIImage *)screenImage;
- (void)_finishedTransitionIn;
- (UIView *)transitionWrapperView;
- (CGFloat)toolbarLandscapeSize;

- (void)setToolbarHidden:(bool)hidden animated:(bool)animated;

+ (PhotoEditorTab)defaultTabsForAvatarIntent;

@end
