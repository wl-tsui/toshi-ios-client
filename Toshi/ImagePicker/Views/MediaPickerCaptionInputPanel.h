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
@class ModernConversationAssociatedInputPanel;

@protocol MediaPickerCaptionInputPanelDelegate;

@interface MediaPickerCaptionInputPanel : UIView

//@property (nonatomic, weak) id<MediaPickerCaptionInputPanelDelegate> delegate;
//
//@property (nonatomic, strong) NSString *caption;
//- (void)setCaption:(NSString *)caption animated:(bool)animated;
//
//@property (nonatomic, readonly) HPGrowingTextView *inputField;
//
//@property (nonatomic, assign) CGFloat bottomMargin;
//@property (nonatomic, assign, getter=isCollapsed) bool collapsed;
//- (void)setCollapsed:(bool)collapsed animated:(bool)animated;
//
//- (void)replaceMention:(NSString *)mention;
//- (void)replaceMention:(NSString *)mention username:(bool)username userId:(int32_t)userId;
//- (void)replaceHashtag:(NSString *)hashtag;
//
//- (void)adjustForOrientation:(UIInterfaceOrientation)orientation keyboardHeight:(CGFloat)keyboardHeight duration:(NSTimeInterval)duration animationCurve:(NSInteger)animationCurve;
//
//- (void)dismiss;
//
//- (CGFloat)heightForInputFieldHeight:(CGFloat)inputFieldHeight;
//- (CGFloat)baseHeight;
//
//- (void)setAssociatedPanel:(ModernConversationAssociatedInputPanel *)associatedPanel animated:(bool)animated;
//- (ModernConversationAssociatedInputPanel *)associatedPanel;
//
//- (void)setContentAreaHeight:(CGFloat)contentAreaHeight;
//
//@end
//
//@protocol MediaPickerCaptionInputPanelDelegate <NSObject>
//
//- (bool)inputPanelShouldBecomeFirstResponder:(MediaPickerCaptionInputPanel *)inputPanel;
//- (void)inputPanelFocused:(MediaPickerCaptionInputPanel *)inputPanel;
//- (void)inputPanelRequestedSetCaption:(MediaPickerCaptionInputPanel *)inputPanel text:(NSString *)text;
//- (void)inputPanelMentionEntered:(MediaPickerCaptionInputPanel *)inputTextPanel mention:(NSString *)mention startOfLine:(bool)startOfLine;
//- (void)inputPanelHashtagEntered:(MediaPickerCaptionInputPanel *)inputTextPanel hashtag:(NSString *)hashtag;
//- (void)inputPanelWillChangeHeight:(MediaPickerCaptionInputPanel *)inputPanel height:(CGFloat)height duration:(NSTimeInterval)duration animationCurve:(int)animationCurve;
//
//@optional
//- (void)inputPanelTextChanged:(MediaPickerCaptionInputPanel *)inputTextPanel text:(NSString *)text;

@end
