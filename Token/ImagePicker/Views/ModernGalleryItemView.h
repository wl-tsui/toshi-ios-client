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

#import <UIKit/UIKit.h>

#import "ModernGalleryItem.h"

#import "ViewController.h"

#import <SSignalKit/SSignalKit.h>

@class ModernGalleryItemView;
@protocol ModernGalleryDefaultFooterView;
@protocol ModernGalleryDefaultFooterAccessoryView;

@protocol ModernGalleryItemViewDelegate <NSObject>

- (void)itemViewIsReadyForScheduledDismiss:(ModernGalleryItemView *)itemView;
- (void)itemViewDidRequestInterfaceShowHide:(ModernGalleryItemView *)itemView;

- (void)itemViewDidRequestGalleryDismissal:(ModernGalleryItemView *)itemView animated:(bool)animated;

- (UIView *)itemViewDidRequestInterfaceView:(ModernGalleryItemView *)itemView;

- (ViewController *)parentControllerForPresentation;

@end

@interface ModernGalleryItemView : UIView
{
    id<ModernGalleryItem> _item;
}

@property (nonatomic, weak) id<ModernGalleryItemViewDelegate> delegate;

@property (nonatomic) NSUInteger index;
@property (nonatomic, strong) id<ModernGalleryItem> item;
@property (nonatomic, strong) UIView<ModernGalleryDefaultFooterView> *defaultFooterView;
@property (nonatomic, strong) UIView<ModernGalleryDefaultFooterAccessoryView> *defaultFooterAccessoryLeftView;
@property (nonatomic, strong) UIView<ModernGalleryDefaultFooterAccessoryView> *defaultFooterAccessoryRightView;

- (void)setItem:(id<ModernGalleryItem>)item synchronously:(bool)synchronously;

- (SSignal *)readyForTransitionIn;

- (void)prepareForRecycle;
- (void)prepareForReuse;
- (void)setIsVisible:(bool)isVisible;
- (void)setIsCurrent:(bool)isCurrent;
- (void)setFocused:(bool)isFocused;

- (UIView *)headerView;
- (UIView *)footerView;

- (UIView *)transitionView;
- (CGRect)transitionViewContentRect;

- (bool)dismissControllerNowOrSchedule;

- (bool)allowsScrollingAtPoint:(CGPoint)point;

- (SSignal *)contentAvailabilityStateSignal;

@end
