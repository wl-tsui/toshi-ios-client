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

#import "MenuSheetItemView.h"
#import "MediaAsset.h"
#import "OverlayController.h"

@class MediaSelectionContext;
@class MediaEditingContext;
@class SuggestionContext;
@class ViewController;
@class AttachmentCameraView;

@interface AttachmentCarouselCollectionView : UICollectionView

@end

@interface AttachmentCarouselItemView : MenuSheetItemView

@property (nonatomic, weak) OverlayController *parentController;

@property (nonatomic, readonly) MediaSelectionContext *selectionContext;
@property (nonatomic, readonly) MediaEditingContext *editingContext;
@property (nonatomic, strong) SuggestionContext *suggestionContext;
@property (nonatomic) bool allowCaptions;
@property (nonatomic) bool inhibitDocumentCaptions;

@property (nonatomic, strong) NSArray *underlyingViews;
@property (nonatomic, assign) bool openEditor;

@property (nonatomic, copy) void (^cameraPressed)(AttachmentCameraView *cameraView);
@property (nonatomic, copy) void (^sendPressed)(MediaAsset *currentItem, bool asFiles);
@property (nonatomic, copy) void (^avatarCompletionBlock)(UIImage *image);

@property (nonatomic, copy) void (^editorOpened)(void);
@property (nonatomic, copy) void (^editorClosed)(void);
@property (nonatomic, copy) void (^didSelectImage)(UIImage *, MediaAsset *asset, UIView *fromView);

@property (nonatomic, assign) CGFloat remainingHeight;
@property (nonatomic, assign) bool condensed;

- (instancetype)initWithCamera:(bool)hasCamera selfPortrait:(bool)selfPortrait forProfilePhoto:(bool)forProfilePhoto assetType:(MediaAssetType)assetType
NS_SWIFT_NAME(init(camera:selfPortrait:forProfilePhoto:assetType:));

- (void)updateVisibleItems;
- (void)updateCameraView;

@end
