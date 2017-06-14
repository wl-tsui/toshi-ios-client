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

#import <SSignalKit/SSignalKit.h>

@protocol MediaSelectableItem

@property (nonatomic, readonly) NSString *uniqueIdentifier;

@end

@interface MediaSelectionContext : NSObject

@property (nonatomic, copy) SSignal *(^updatedItemsSignal)(NSArray *items);
- (void)setItemSourceUpdatedSignal:(SSignal *)signal;

- (void)setItem:(id<MediaSelectableItem>)item selected:(bool)selected;
- (void)setItem:(id<MediaSelectableItem>)item selected:(bool)selected animated:(bool)animated sender:(id)sender;

- (bool)toggleItemSelection:(id<MediaSelectableItem>)item;
- (bool)toggleItemSelection:(id<MediaSelectableItem>)item animated:(bool)animated sender:(id)sender;

- (void)clear;

- (bool)isItemSelected:(id<MediaSelectableItem>)item;

- (SSignal *)itemSelectedSignal:(id<MediaSelectableItem>)item;
- (SSignal *)itemInformativeSelectedSignal:(id<MediaSelectableItem>)item;
- (SSignal *)selectionChangedSignal;

- (void)enumerateSelectedItems:(void (^)(id<MediaSelectableItem>))enumerationBlock;

- (NSOrderedSet *)selectedItemsIdentifiers;
- (NSArray *)selectedItems;

- (NSUInteger)count;

+ (SSignal *)combinedSelectionChangedSignalForContexts:(NSArray *)contexts;

@end


@interface MediaSelectionChange : NSObject

@property (nonatomic, readonly) id<MediaSelectableItem> item;
@property (nonatomic, readonly) bool selected;
@property (nonatomic, readonly) bool animated;
@property (nonatomic, readonly, strong) id sender;

@end
