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
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import "ModernViewStorage.h"

@protocol ModernView;

@interface ModernViewModel : NSObject
{
    @private
    struct {
        int hasNoView : 1;
        int skipDrawInContext : 1;
        int disableSubmodelAutomaticBinding : 1;
        int viewUserInteractionDisabled : 1;
    } _modelFlags;
}

@property (nonatomic, strong) id modelId;

@property (nonatomic, strong) NSString *viewStateIdentifier;

@property (nonatomic) CGRect frame;
@property (nonatomic) CGPoint parentOffset;
@property (nonatomic) float alpha;
@property (nonatomic) bool hidden;

@property (nonatomic, strong, readonly) NSArray *submodels;

@property (nonatomic, copy) void (^unbindAction)();

- (bool)hasNoView;
- (void)setHasNoView:(bool)hasNoView;

- (bool)skipDrawInContext;
- (void)setSkipDrawInContext:(bool)skipDrawInContext;

- (bool)disableSubmodelAutomaticBinding;
- (void)setDisableSubmodelAutomaticBinding:(bool)disableSubmodelAutomaticBinding;

- (bool)viewUserInteractionDisabled;
- (void)setViewUserInteractionDisabled:(bool)viewUserInteractionDisabled;

- (Class)viewClass;
- (UIView<ModernView> *)_dequeueView:(ModernViewStorage *)viewStorage;

- (UIView<ModernView> *)boundView;
- (void)bindViewToContainer:(UIView *)container viewStorage:(ModernViewStorage *)viewStorage;
- (void)unbindView:(ModernViewStorage *)viewStorage;
- (void)moveViewToContainer:(UIView *)container;

- (void)_offsetBoundViews:(CGSize)offset;

- (void)drawInContext:(CGContextRef)context;
- (void)drawSubmodelsInContext:(CGContextRef)context;

- (void)sizeToFit;
- (CGRect)bounds;

- (bool)containsSubmodel:(ModernViewModel *)model;
- (void)addSubmodel:(ModernViewModel *)model;
- (void)insertSubmodel:(ModernViewModel *)model belowSubmodel:(ModernViewModel *)belowSubmodel;
- (void)insertSubmodel:(ModernViewModel *)model aboveSubmodel:(ModernViewModel *)aboveSubmodel;
- (void)removeSubmodel:(ModernViewModel *)model viewStorage:(ModernViewStorage *)viewStorage;
- (void)layoutForContainerSize:(CGSize)containerSize;

- (void)collectBoundModelViewFramesRecursively:(NSMutableDictionary *)dict;
- (void)collectBoundModelViewFramesRecursively:(NSMutableDictionary *)dict ifPresentInDict:(NSMutableDictionary *)anotherDict;
- (void)restoreBoundModelViewFramesRecursively:(NSMutableDictionary *)dict;

@end
