#import "MediaPickerGallerySelectedItemsModel.h"

@interface MediaPickerGallerySelectedItemsModel ()
{
    MediaSelectionContext *_selectionContext;
    SMetaDisposable *_selectionChangedDisposable;
    
    NSMutableArray *_items;
}
@end

@implementation MediaPickerGallerySelectedItemsModel

- (instancetype)initWithSelectionContext:(MediaSelectionContext *)selectionContext
{
    self = [super init];
    if (self != nil)
    {
        _items = [selectionContext.selectedItems mutableCopy];
        
        _selectionContext = selectionContext;
        
        __weak MediaPickerGallerySelectedItemsModel *weakSelf = self;
        _selectionChangedDisposable = [[SMetaDisposable alloc] init];
        [_selectionChangedDisposable setDisposable:[[selectionContext selectionChangedSignal] startWithNext:^(MediaSelectionChange *next)
        {
            __strong MediaPickerGallerySelectedItemsModel *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            
            if (next.sender == strongSelf)
                return;
            
            if (next.selected)
                [strongSelf addSelectedItem:next.item];
            else
                [strongSelf removeSelectedItem:next.item];
        }]];
    }
    return self;
}

- (void)dealloc
{
    [_selectionChangedDisposable dispose];
}

- (void)addSelectedItem:(id<MediaSelectableItem>)selectedItem
{
    for (id<MediaSelectableItem> item in _items)
    {
        if ([item.uniqueIdentifier isEqualToString:selectedItem.uniqueIdentifier])
        {
            if (self.selectionUpdated != nil)
                self.selectionUpdated(false, false, false, 0);
            
            return;
        }
    }
    
    [_items addObject:selectedItem];
    
    if (self.selectionUpdated != nil)
        self.selectionUpdated(true, true, true, _items.count - 1);
}

- (void)removeSelectedItem:(id<MediaSelectableItem>)selectedItem
{
    NSInteger index = [_items indexOfObject:selectedItem];
    if (index != NSNotFound)
    {
        [_items removeObject:selectedItem];
        
        if (self.selectionUpdated != nil)
            self.selectionUpdated(true, true, false, index);
    }
}

- (NSInteger)selectedCount
{
    NSInteger count = 0;
    for (id<MediaSelectableItem> item in _items)
    {
        if ([_selectionContext isItemSelected:item])
            count++;
    }
    return count;
}

- (NSInteger)totalCount
{
    return _items.count;
}

- (NSArray *)items
{
    return _items;
}

- (NSArray *)selectedItems
{
    NSMutableArray *items = [[NSMutableArray alloc] init];
    for (id<MediaSelectableItem> item in _items)
    {
        if ([_selectionContext isItemSelected:item])
            [items addObject:item];
    }
    return items;
}

@end
