#import "ModernGalleryModel.h"
#import "Common.h"

@implementation ModernGalleryModel

- (void)_transitionCompleted
{
}

- (void)_replaceItems:(NSArray *)items focusingOnItem:(id<ModernGalleryItem>)item
{
    DispatchOnMainThread(^
    {
        _items = items;
        _focusItem = item;
        
        if (_itemsUpdated)
            _itemsUpdated(item);
    });
}

- (void)_focusOnItem:(id<ModernGalleryItem>)item
{
    DispatchOnMainThread(^
    {
        _focusItem = item;
        
        if (_focusOnItem)
            _focusOnItem(item);
    });
}

- (bool)_shouldAutorotate
{
    return true;
}

- (UIView<ModernGalleryInterfaceView> *)createInterfaceView
{
    return nil;
}

- (UIView<ModernGalleryDefaultHeaderView> *)createDefaultHeaderView
{
    return nil;
}

- (UIView<ModernGalleryDefaultFooterView> *)createDefaultFooterView
{
    return nil;
}

- (UIView<ModernGalleryDefaultFooterAccessoryView> *)createDefaultLeftAccessoryView
{
    return nil;
}

- (UIView<ModernGalleryDefaultFooterAccessoryView> *)createDefaultRightAccessoryView
{
    return nil;
}

@end
