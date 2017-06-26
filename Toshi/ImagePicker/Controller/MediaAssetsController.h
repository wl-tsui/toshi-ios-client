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

#import "MediaAssetsLibrary.h"
#import "SuggestionContext.h"

@class MediaAssetsPickerController;

typedef NS_ENUM(NSUInteger, MediaAssetsControllerIntent) {
    MediaAssetsControllerIntentSendMedia,
    MediaAssetsControllerIntentSendFile,
    MediaAssetsControllerIntentSetProfilePhoto,
    MediaAssetsControllerIntentSetCustomWallpaper
}NS_SWIFT_NAME(MediaAssetsControllerIntent);

@interface MediaAssetsController : UINavigationController

@property (nonatomic, strong) SuggestionContext *suggestionContext;
@property (nonatomic, assign) bool localMediaCacheEnabled;
@property (nonatomic, assign) bool captionsEnabled;
@property (nonatomic, assign) bool inhibitDocumentCaptions;
@property (nonatomic, assign) bool shouldStoreAssets;

@property (nonatomic, strong, readonly) NSMutableArray *selectedItems;

@property (nonatomic, assign) bool liveVideoUploadEnabled;
@property (nonatomic, assign) bool shouldShowFileTipIfNeeded;

@property (nonatomic, copy) void (^avatarCompletionBlock)(UIImage *image);
@property (nonatomic, copy) void (^completionBlock)(NSArray *signals);
@property (nonatomic, copy) void (^dismissalBlock)(void);

@property (nonatomic, readonly) MediaAssetsPickerController *pickerController;

- (void)completeWithAvatarImage:(UIImage *)image;
- (void)completeWithCurrentItem:(MediaAsset *)currentItem;

+ (instancetype)controllerWithAssetGroup:(MediaAssetGroup *)assetGroup intent:(MediaAssetsControllerIntent)intent;

- (instancetype)initWithAssetGroup:(MediaAssetGroup *)assetGroup intent:(MediaAssetsControllerIntent)intent
NS_SWIFT_NAME(init(assetGroup:intent:));

+ (MediaAssetType)assetTypeForIntent:(MediaAssetsControllerIntent)intent;

+ (NSArray *)resultSignalsForSelectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext intent:(MediaAssetsControllerIntent)intent currentItem:(MediaAsset *)currentItem storeAssets:(bool)storeAssets useMediaCache:(bool)useMediaCache
NS_SWIFT_NAME(resultSignals(selectionContext:editingContext:intent:currentItem:storeAssets:useMediaCache:));

@end
