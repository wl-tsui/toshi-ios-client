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

#import "ModernGalleryInterfaceView.h"
#import "ModernGalleryDefaultHeaderView.h"
#import "ModernGalleryDefaultFooterView.h"
#import "ModernGalleryDefaultFooterAccessoryView.h"

@class ModernGalleryController;
@protocol ModernGalleryItem;

@interface ModernGalleryModel : NSObject

@property (nonatomic, strong) NSArray *items;

@property (nonatomic, strong, readonly) id<ModernGalleryItem> focusItem;

@property (nonatomic, copy) void (^itemsUpdated)(id<ModernGalleryItem>);
@property (nonatomic, copy) void (^focusOnItem)(id<ModernGalleryItem>);
@property (nonatomic, copy) UIView *(^actionSheetView)();
@property (nonatomic, copy) UIViewController *(^viewControllerForModalPresentation)();
@property (nonatomic, copy) void (^dismiss)(bool, bool);
@property (nonatomic, copy) void (^dismissWhenReady)();
@property (nonatomic, copy) NSArray *(^visibleItems)();

- (void)_transitionCompleted;
- (void)_replaceItems:(NSArray *)items focusingOnItem:(id<ModernGalleryItem>)item;
- (void)_focusOnItem:(id<ModernGalleryItem>)item;

- (bool)_shouldAutorotate;

- (UIView<ModernGalleryInterfaceView> *)createInterfaceView;
- (UIView<ModernGalleryDefaultHeaderView> *)createDefaultHeaderView;
- (UIView<ModernGalleryDefaultFooterView> *)createDefaultFooterView;
- (UIView<ModernGalleryDefaultFooterAccessoryView> *)createDefaultLeftAccessoryView;
- (UIView<ModernGalleryDefaultFooterAccessoryView> *)createDefaultRightAccessoryView;

@end
