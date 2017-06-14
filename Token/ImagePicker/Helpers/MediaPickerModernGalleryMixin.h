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
#import "MediaPickerGalleryModel.h"
#import "ModernGalleryController.h"

@class MediaSelectionContext;
@class MediaEditingContext;
@class SuggestionContext;
@class MediaPickerGalleryItem;
@class MediaAssetFetchResult;
@class MediaAssetMomentList;

@interface MediaPickerModernGalleryMixin : NSObject

@property (nonatomic, weak, readonly) MediaPickerGalleryModel *galleryModel;

@property (nonatomic, copy) void (^itemFocused)(MediaPickerGalleryItem *);

@property (nonatomic, copy) void (^willTransitionIn)();
@property (nonatomic, copy) void (^willTransitionOut)();
@property (nonatomic, copy) void (^didTransitionOut)();
@property (nonatomic, copy) UIView *(^referenceViewForItem)(MediaPickerGalleryItem *);

@property (nonatomic, copy) void (^completeWithItem)(MediaPickerGalleryItem *item);

@property (nonatomic, copy) void (^editorOpened)(void);
@property (nonatomic, copy) void (^editorClosed)(void);

- (instancetype)initWithItem:(id)item fetchResult:(MediaAssetFetchResult *)fetchResult parentController:(ViewController *)parentController thumbnailImage:(UIImage *)thumbnailImage selectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext suggestionContext:(SuggestionContext *)suggestionContext hasCaptions:(bool)hasCaptions inhibitDocumentCaptions:(bool)inhibitDocumentCaptions asFile:(bool)asFile itemsLimit:(NSUInteger)itemsLimit;

- (instancetype)initWithItem:(id)item momentList:(MediaAssetMomentList *)momentList parentController:(ViewController *)parentController thumbnailImage:(UIImage *)thumbnailImage selectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext suggestionContext:(SuggestionContext *)suggestionContext hasCaptions:(bool)hasCaptions inhibitDocumentCaptions:(bool)inhibitDocumentCaptions asFile:(bool)asFile itemsLimit:(NSUInteger)itemsLimit;

- (void)present;
- (void)updateWithFetchResult:(MediaAssetFetchResult *)fetchResult;

- (UIView *)currentReferenceView;

- (void)setThumbnailSignalForItem:(SSignal *(^)(id))thumbnailSignalForItem;

- (ModernGalleryController *)galleryController;
- (void)setPreviewMode;

@end
