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

#import "MediaPickerController.h"
#import "MediaAssetsController.h"

@class MediaAssetsPreheatMixin;
@class MediaPickerModernGalleryMixin;

@interface MediaAssetsPickerController : MediaPickerController
{
    MediaAssetsPreheatMixin *_preheatMixin;
}

@property (nonatomic, assign) bool liveVideoUploadEnabled;
@property (nonatomic, readonly) MediaAssetGroup *assetGroup;

- (instancetype)initWithAssetsLibrary:(MediaAssetsLibrary *)assetsLibrary assetGroup:(MediaAssetGroup *)assetGroup intent:(MediaAssetsControllerIntent)intent selectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext;

@end
