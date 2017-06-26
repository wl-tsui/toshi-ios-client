#import "ModernGalleryItemView.h"

#import "ModernGalleryDefaultFooterView.h"
#import "ModernGalleryDefaultFooterAccessoryView.h"

@implementation ModernGalleryItemView

- (SSignal *)readyForTransitionIn {
    return [SSignal single:@true];
}

- (void)prepareForRecycle
{
}

- (void)prepareForReuse
{
}

- (void)setIsVisible:(bool)__unused isVisible
{
}

- (void)setIsCurrent:(bool)__unused isCurrent
{
}

- (void)setFocused:(bool)isFocused
{
    if (isFocused)
    {
        if ([[self defaultFooterView] respondsToSelector:@selector(setContentHidden:)])
            [[self defaultFooterView] setContentHidden:false];
        else
            [self defaultFooterView].hidden = false;
    }
}

- (UIView *)headerView
{
    return nil;
}

- (UIView *)footerView
{
    return nil;
}

- (UIView *)transitionView
{
    return nil;
}

- (CGRect)transitionViewContentRect
{
    return [self transitionView].bounds;
}

- (bool)dismissControllerNowOrSchedule
{
    return true;
}

- (void)setItem:(id<ModernGalleryItem>)item
{
    [self setItem:item synchronously:false];
}

- (void)setItem:(id<ModernGalleryItem>)item synchronously:(bool)__unused synchronously
{
    _item = item;
    [self.defaultFooterAccessoryLeftView setItem:item];
    [self.defaultFooterAccessoryRightView setItem:item];
}

- (bool)allowsScrollingAtPoint:(CGPoint)__unused point
{
    return true;
}

- (SSignal *)contentAvailabilityStateSignal
{
    return nil;
}

@end
