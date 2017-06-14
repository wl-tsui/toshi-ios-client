#import "PhotoCaptionInputMixin.h"

#import "ImageUtils.h"
#import "ObserverProxy.h"
#import "ViewController.h"
#import "SuggestionContext.h"

@interface PhotoCaptionInputMixin ()
{
    ObserverProxy *_keyboardWillChangeFrameProxy;
    bool _editing;
    
    UIGestureRecognizer *_dismissTapRecognizer;
}
@end

@implementation PhotoCaptionInputMixin

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _keyboardWillChangeFrameProxy = [[ObserverProxy alloc] initWithTarget:self targetSelector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification];
    }
    return self;
}

- (void)dealloc
{
    [_dismissView removeFromSuperview];
    [_inputPanel removeFromSuperview];
}

- (void)createInputPanelIfNeeded
{
    if (_inputPanel != nil)
        return;
}

- (void)destroy
{
    [self.inputPanel removeFromSuperview];
}

- (void)createDismissViewIfNeeded
{
}

- (void)setCaption:(NSString *)caption
{
    [self setCaption:caption animated:false];
}

- (void)setCaption:(NSString *)caption animated:(bool)animated
{
    _caption = caption;
}

- (void)setCaptionPanelHidden:(bool)hidden animated:(bool)__unused animated
{
    self.inputPanel.hidden = hidden;
}

- (void)beginEditing
{
    _editing = true;
    
    [self createDismissViewIfNeeded];
    [self createInputPanelIfNeeded];
}

- (void)enableDismissal
{
    _dismissTapRecognizer.enabled = true;
}

#pragma mark - 

- (void)handleDismissTap:(UITapGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateRecognized)
        return;
    
    [_dismissView removeFromSuperview];
}

#pragma mark - Input Panel Delegate


- (void)inputPanelMentionEntered:(MediaPickerCaptionInputPanel *)__unused inputTextPanel mention:(NSString *)mention startOfLine:(bool)__unused startOfLine
{
    if (mention == nil)
    {
//        if ([[inputTextPanel associatedPanel] isKindOfClass:[ModernConversationMentionsAssociatedPanel class]])
//            [inputTextPanel setAssociatedPanel:nil animated:true];
    }
    else
    {
//        ModernConversationMentionsAssociatedPanel *panel = nil;
//        if ([[inputTextPanel associatedPanel] isKindOfClass:[ModernConversationMentionsAssociatedPanel class]])
//            panel = (ModernConversationMentionsAssociatedPanel *)[inputTextPanel associatedPanel];
//        else
//        {
//            panel = [[ModernConversationMentionsAssociatedPanel alloc] initWithStyle:ModernConversationAssociatedInputPanelDarkStyle];
//            
//            __weak PhotoCaptionInputMixin *weakSelf = self;
//            panel.userSelected = ^(TGUser *user)
//            {
//                __strong PhotoCaptionInputMixin *strongSelf = weakSelf;
//                if (strongSelf != nil)
//                {
//                    if ([[strongSelf->_inputPanel associatedPanel] isKindOfClass:[ModernConversationMentionsAssociatedPanel class]])
//                        [strongSelf->_inputPanel setAssociatedPanel:nil animated:false];
//                    
//                    if (user.userName.length == 0) {
//                        [strongSelf->_inputPanel replaceMention:[[NSString alloc] initWithFormat:@"%@", user.displayFirstName] username:false userId:user.uid];
//                    } else {
//                        [strongSelf->_inputPanel replaceMention:[[NSString alloc] initWithFormat:@"%@", user.userName] username:true userId:user.uid];
//                    }
//                }
//            };
//        }
        
        SSignal *userListSignal = nil;
        if (self.suggestionContext.userListSignal != nil)
            userListSignal = self.suggestionContext.userListSignal(mention);
        
       // [panel setUserListSignal:userListSignal];
        
        //[inputTextPanel setAssociatedPanel:panel animated:true];
    }
}

- (void)inputPanelHashtagEntered:(MediaPickerCaptionInputPanel *)inputTextPanel hashtag:(NSString *)hashtag
{
    if (hashtag == nil)
    {
//        if ([[inputTextPanel associatedPanel] isKindOfClass:[ModernConversationHashtagsAssociatedPanel class]])
//            [inputTextPanel setAssociatedPanel:nil animated:true];
    }
    else
    {
//        ModernConversationHashtagsAssociatedPanel *panel = nil;
//        if ([[inputTextPanel associatedPanel] isKindOfClass:[ModernConversationHashtagsAssociatedPanel class]])
//            panel = (ModernConversationHashtagsAssociatedPanel *)[inputTextPanel associatedPanel];
//        else
//        {
//            panel = [[ModernConversationHashtagsAssociatedPanel alloc] initWithStyle:ModernConversationAssociatedInputPanelDarkStyle];
//          
//            __weak PhotoCaptionInputMixin *weakSelf = self;
//            panel.hashtagSelected = ^(NSString *hashtag)
//            {
//                __strong PhotoCaptionInputMixin *strongSelf = weakSelf;
//                if (strongSelf != nil)
//                {
//                    if ([[strongSelf->_inputPanel associatedPanel] isKindOfClass:[ModernConversationHashtagsAssociatedPanel class]])
//                        [strongSelf->_inputPanel setAssociatedPanel:nil animated:false];
//                    
//                    [strongSelf->_inputPanel replaceHashtag:hashtag];
//                }
//            };
//            [inputTextPanel setAssociatedPanel:panel animated:true];
//        }
        
        SSignal *hashtagListSignal = nil;
        if (self.suggestionContext.hashtagListSignal != nil)
            hashtagListSignal = self.suggestionContext.hashtagListSignal(hashtag);
        
     //   [panel setHashtagListSignal:hashtagListSignal];
    }
}

//- (void)inputPanelWillChangeHeight:(MediaPickerCaptionInputPanel *)inputPanel height:(CGFloat)__unused height duration:(NSTimeInterval)duration animationCurve:(int)animationCurve
//{
//    [inputPanel adjustForOrientation:UIInterfaceOrientationPortrait keyboardHeight:_keyboardHeight duration:duration animationCurve:animationCurve];
//}

//- (void)setContentAreaHeight:(CGFloat)contentAreaHeight
//{
//    _contentAreaHeight = contentAreaHeight;
//    
//    CGFloat finalHeight = _contentAreaHeight - _keyboardHeight;
//    [_inputPanel setContentAreaHeight:finalHeight];
//}

//- (UIView *)_parentView
//{
//    UIView *parentView = nil;
//    if (self.panelParentView != nil)
//        parentView = self.panelParentView();
//    
//    return parentView;
//}

#pragma mark - Keyboard

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
//    UIView *parentView = [self _parentView];
//    
//    NSTimeInterval duration = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] == nil ? 0.3 : [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
//    int curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
//    CGRect screenKeyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
//    CGRect keyboardFrame = [parentView convertRect:screenKeyboardFrame fromView:nil];
//    
//    CGFloat keyboardHeight = (keyboardFrame.size.height <= FLT_EPSILON || keyboardFrame.size.width <= FLT_EPSILON) ? 0.0f : (parentView.frame.size.height - keyboardFrame.origin.y);
//    keyboardHeight = MAX(keyboardHeight, 0.0f);
//    
//    _keyboardHeight = keyboardHeight;
//    
//    if (!UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) && !TGIsPad())
//        return;
//    
//    [_inputPanel adjustForOrientation:UIInterfaceOrientationPortrait keyboardHeight:keyboardHeight duration:duration animationCurve:curve];
//    
//    if (self.keyboardHeightChanged != nil)
//        self.keyboardHeightChanged(keyboardHeight, duration, curve);
//    
//    CGFloat finalHeight = _contentAreaHeight - _keyboardHeight;
//    [_inputPanel setContentAreaHeight:finalHeight];
}

- (void)updateLayoutWithFrame:(CGRect)frame edgeInsets:(UIEdgeInsets)edgeInsets
{
    _inputPanel.frame = CGRectMake(edgeInsets.left, _inputPanel.frame.origin.y, frame.size.width, _inputPanel.frame.size.height);
//    _inputPanel.bottomMargin = edgeInsets.bottom;
//    [_inputPanel adjustForOrientation:UIInterfaceOrientationPortrait keyboardHeight:_keyboardHeight duration:0.0 animationCurve:0];
}

@end
