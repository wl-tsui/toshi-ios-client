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

#import "ActionStage.h"

#import <AssetsLibrary/AssetsLibrary.h>

#ifdef __cplusplus
extern "C" {
#endif

void dispatchOnAssetsProcessingQueue(dispatch_block_t block);
void sharedAssetsLibraryRetain();
void sharedAssetsLibraryRelease();
    
#ifdef __cplusplus
}
#endif

@protocol TGImagePickerControllerDelegate;

@interface TGImagePickerController : NSObject

+ (id)sharedAssetsLibrary;
+ (id)preloadLibrary;
+ (void)loadAssetWithUrl:(NSURL *)url completion:(void (^)(ALAsset *asset))completion;
+ (void)storeImageAsset:(NSData *)data;

@end

@protocol TGImagePickerControllerDelegate <NSObject>

- (void)imagePickerController:(TGImagePickerController *)imagePicker didFinishPickingWithAssets:(NSArray *)assets;

@end
