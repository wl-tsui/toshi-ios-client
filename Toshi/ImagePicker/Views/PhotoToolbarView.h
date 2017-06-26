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

#import "PhotoEditorButton.h"

typedef enum
{
    PhotoEditorNoneTab    = 0,
    PhotoEditorCropTab    = 1 << 0,
    PhotoEditorToolsTab   = 1 << 1,
    PhotoEditorCaptionTab = 1 << 2,
    PhotoEditorRotateTab  = 1 << 3,
    PhotoEditorPaintTab   = 1 << 4,
    PhotoEditorStickerTab = 1 << 5,
    PhotoEditorTextTab    = 1 << 6,
    PhotoEditorGifTab     = 1 << 7,
    PhotoEditorQualityTab = 1 << 8
} PhotoEditorTab;

@interface PhotoToolbarView : UIView

@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

@property (nonatomic, copy) void(^cancelPressed)(void);
@property (nonatomic, copy) void(^donePressed)(void);

@property (nonatomic, copy) void(^doneLongPressed)(id sender);

@property (nonatomic, copy) void(^tabPressed)(PhotoEditorTab tab);

@property (nonatomic, readonly) CGRect cancelButtonFrame;

- (instancetype)initWithBackButtonTitle:(NSString *)backButtonTitle doneButtonTitle:(NSString *)doneButtonTitle accentedDone:(bool)accentedDone solidBackground:(bool)solidBackground;

- (void)transitionInAnimated:(bool)animated;
- (void)transitionInAnimated:(bool)animated transparent:(bool)transparent;
- (void)transitionOutAnimated:(bool)animated;
- (void)transitionOutAnimated:(bool)animated transparent:(bool)transparent hideOnCompletion:(bool)hideOnCompletion;

- (void)setDoneButtonEnabled:(bool)enabled animated:(bool)animated;
- (void)setEditButtonsEnabled:(bool)enabled animated:(bool)animated;
- (void)setEditButtonsHidden:(bool)hidden animated:(bool)animated;
- (void)setEditButtonsHighlighted:(PhotoEditorTab)buttons;

@property (nonatomic, readonly) PhotoEditorTab currentTabs;
- (void)setToolbarTabs:(PhotoEditorTab)tabs animated:(bool)animated;

- (void)setActiveTab:(PhotoEditorTab)tab;

- (PhotoEditorButton *)buttonForTab:(PhotoEditorTab)tab;

- (void)calculateLandscapeSizeForPossibleButtonTitles:(NSArray *)possibleButtonTitles;
- (CGFloat)landscapeSize;

@end
