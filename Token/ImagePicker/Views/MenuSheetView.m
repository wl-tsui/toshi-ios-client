
#import "MenuSheetView.h"
#import "MenuSheetItemView.h"
#import "Common.h"
#import "ImageUtils.h"

NSString *const MenuDividerTop = @"top";
NSString *const MenuDividerBottom = @"bottom";

const bool MenuSheetUseEffectView = false;

const CGFloat MenuSheetCornerRadius = 14.5f;
const UIEdgeInsets MenuSheetPhoneEdgeInsets = { 10.0f, 10.0f, 10.0f, 10.0f };
const CGFloat MenuSheetInterSectionSpacing = 8.0f;

@implementation MenuSheetScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        self.scrollsToTop = false;
        self.showsHorizontalScrollIndicator = false;
        self.showsVerticalScrollIndicator = false;
    }
    return self;
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)__unused view
{
    return true;
}

@end

@interface MenuSheetBackgroundView : UIView
{
    UIVisualEffectView *_effectView;
    UIImageView *_imageView;
}
@end

@implementation MenuSheetBackgroundView

- (instancetype)initWithFrame:(CGRect)frame sizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        self.clipsToBounds = true;
        
        if (MenuSheetUseEffectView)
        {
            self.layer.cornerRadius = MenuSheetCornerRadius;
            
            _effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
            _effectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            _effectView.frame = self.bounds;
            [self addSubview:_effectView];
        }
        else
        {
            self.backgroundColor = [UIColor whiteColor];
        }
        
        [self updateTraitsWithSizeClass:sizeClass];
    }
    return self;
}

- (void)setMaskEnabled:(bool)enabled
{
    self.layer.cornerRadius = enabled ? MenuSheetCornerRadius : 0.0f;
}

- (void)updateTraitsWithSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    bool hidden = (sizeClass == UIUserInterfaceSizeClassRegular);
    _effectView.hidden = hidden;
    _imageView.hidden = hidden;
    
    [self setMaskEnabled:!hidden];
}

@end

@interface MenuSheetView () <UIScrollViewDelegate>
{
    MenuSheetBackgroundView *_headerBackgroundView;
    MenuSheetBackgroundView *_mainBackgroundView;
    MenuSheetBackgroundView *_footerBackgroundView;
    
    MenuSheetScrollView *_scrollView;
    
    NSMutableArray *_itemViews;
    NSMutableDictionary *_dividerViews;
    
    UIUserInterfaceSizeClass _sizeClass;
    
    id _panHandlingItemView;
    bool _expectsPreciseContentTouch;
}
@end

@implementation MenuSheetView

- (instancetype)initWithItemViews:(NSArray *)itemViews sizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    self = [super initWithFrame:CGRectZero];
    if (self != nil)
    {
        self.backgroundColor = [UIColor clearColor];
        
        _itemViews = [[NSMutableArray alloc] init];
        _dividerViews = [[NSMutableDictionary alloc] init];
        
        _sizeClass = sizeClass;
        
        [self addItemViews:itemViews];
    }
    return self;
}

- (void)didChangeAbsoluteFrame
{
    for (MenuSheetItemView *itemView in _itemViews)
    {
        [itemView didChangeAbsoluteFrame];
    }
}

#pragma mark -

- (void)setHandleInternalPan:(void (^)(UIPanGestureRecognizer *))handleInternalPan
{
    _handleInternalPan = [handleInternalPan copy];
    for (MenuSheetItemView *itemView in self.itemViews)
    {
        itemView.handleInternalPan = handleInternalPan;
    }
}

- (void)addItemsView:(MenuSheetItemView *)itemView
{
    [self addItemView:itemView hasHeader:self.hasHeader hasFooter:self.hasFooter];
}

- (void)addItemView:(MenuSheetItemView *)itemView hasHeader:(bool)hasHeader hasFooter:(bool)hasFooter
{
    MenuSheetItemView *previousItemView = nil;
    
    itemView.sizeClass = _sizeClass;
    itemView.tag = _itemViews.count;
    itemView.handleInternalPan = [self.handleInternalPan copy];
    
    switch (itemView.type)
    {
        case MenuSheetItemTypeDefault:
        {
            if (hasFooter)
                [_itemViews insertObject:itemView atIndex:_itemViews.count - 1];
            else
                [_itemViews addObject:itemView];
            
            if (_mainBackgroundView == nil)
            {
                _mainBackgroundView = [[MenuSheetBackgroundView alloc] initWithFrame:CGRectZero sizeClass:_sizeClass];
                [self insertSubview:_mainBackgroundView atIndex:0];
                
                _scrollView = [[MenuSheetScrollView alloc] initWithFrame:CGRectZero];
                _scrollView.delegate = self;
                [_mainBackgroundView addSubview:_scrollView];
            }
            
            [_scrollView addSubview:itemView];
            
            UIView *divider = [self createDividerForItemView:itemView previousItemView:previousItemView];
            if (divider != nil)
                [_scrollView addSubview:divider];
            
            if (itemView.requiresClearBackground)
            {
                _mainBackgroundView.backgroundColor = [UIColor clearColor];
                _expectsPreciseContentTouch = true;
            }
        }
            break;
        
        case MenuSheetItemTypeHeader:
        {
            if (hasHeader)
                return;
            
            [_itemViews insertObject:itemView atIndex:0];
            
            if (_headerBackgroundView == nil)
            {
                _headerBackgroundView = [[MenuSheetBackgroundView alloc] initWithFrame:CGRectZero sizeClass:_sizeClass];
                [self insertSubview:_headerBackgroundView atIndex:0];
            }
            
            [_headerBackgroundView addSubview:itemView];
        }
            break;
            
        case MenuSheetItemTypeFooter:
        {
            if (hasFooter)
                return;
            
            [_itemViews addObject:itemView];
            
            if (_footerBackgroundView == nil)
            {
                _footerBackgroundView = [[MenuSheetBackgroundView alloc] initWithFrame:CGRectZero sizeClass:_sizeClass];
                [self insertSubview:_footerBackgroundView atIndex:0];
            }
            
            [_footerBackgroundView addSubview:itemView];
        }
            break;
            
        default:
            break;
    }
    
    __weak MenuSheetView *weakSelf = self;
    itemView.layoutUpdateBlock = ^
    {
        __strong MenuSheetView *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        [strongSelf layoutSubviews];
        if (strongSelf.menuRelayout != nil)
            strongSelf.menuRelayout();
    };
    
    __weak MenuSheetItemView *weakItemView = itemView;
    itemView.highlightUpdateBlock = ^(bool highlighted)
    {
        __strong MenuSheetView *strongSelf = weakSelf;
        __strong MenuSheetItemView *strongItemView = weakItemView;
        if (strongSelf != nil && weakItemView != nil)
        {
            if (true)
                return;
            
            switch (strongItemView.type)
            {
                case MenuSheetItemTypeHeader:
                    [strongSelf->_headerBackgroundView setMaskEnabled:highlighted];
                    break;
                
                case MenuSheetItemTypeFooter:
                    [strongSelf->_footerBackgroundView setMaskEnabled:highlighted];
                    break;
                
                default:
                    [strongSelf->_mainBackgroundView setMaskEnabled:highlighted];
                    break;
            }
        };
    };
}

- (void)addItemViews:(NSArray *)itemViews
{
    bool hasHeader = self.hasHeader;
    bool hasFooter = self.hasFooter;
    
    for (MenuSheetItemView *itemView in itemViews)
    {
        [self addItemView:itemView hasHeader:hasHeader hasFooter:hasFooter];
        
        if (itemView.type == MenuSheetItemTypeHeader)
            hasHeader = true;
        else if (itemView.type == MenuSheetItemTypeFooter)
            hasFooter = true;
    }
}

- (UIView *)createDividerForItemView:(MenuSheetItemView *)itemView previousItemView:(MenuSheetItemView *)previousItemView
{
    if (!itemView.requiresDivider)
        return nil;
    
    UIView *topDivider = nil;
    if (previousItemView != nil)
        topDivider = _dividerViews[@(previousItemView.tag)][MenuDividerBottom];
        
    UIView *bottomDivider = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, TGScreenPixel)];
    bottomDivider.backgroundColor = TGSeparatorColor();
    
    NSMutableDictionary *dividers = [[NSMutableDictionary alloc] init];
    if (topDivider != nil)
        dividers[MenuDividerTop] = topDivider;
    dividers[MenuDividerBottom] = bottomDivider;
    _dividerViews[@(itemView.tag)] = dividers;
    
    return bottomDivider;
}

#pragma mark -

- (void)updateTraitsWithSizeClass:(UIUserInterfaceSizeClass)sizeClass
{
    _sizeClass = sizeClass;
    
    bool hideNonRegularItems = (_sizeClass == UIUserInterfaceSizeClassRegular);
    
    for (MenuSheetItemView *itemView in _itemViews)
    {
        itemView.sizeClass = sizeClass;
        if (itemView.type == MenuSheetItemTypeHeader || itemView.type == MenuSheetItemTypeFooter)
            [itemView setHidden:hideNonRegularItems animated:false];
    }
    
    [_headerBackgroundView updateTraitsWithSizeClass:sizeClass];
    [_mainBackgroundView updateTraitsWithSizeClass:sizeClass];
    [_footerBackgroundView updateTraitsWithSizeClass:sizeClass];
}

#pragma mark -

- (UIEdgeInsets)edgeInsets
{
    if (_sizeClass == UIUserInterfaceSizeClassRegular)
        return UIEdgeInsetsZero;

    return MenuSheetPhoneEdgeInsets;
}

- (CGFloat)interSectionSpacing
{
    return MenuSheetInterSectionSpacing;
}

- (CGSize)menuSize
{
    return CGSizeMake(self.menuWidth, self.menuHeight);
}

- (CGFloat)menuHeight
{
    CGFloat maxHeight = [UIScreen mainScreen].bounds.size.height;
    if (self.maxHeight > FLT_EPSILON)
        maxHeight = MIN(self.maxHeight, maxHeight);
    
    return MIN(maxHeight, [self menuHeightForWidth:self.menuWidth - self.edgeInsets.left - self.edgeInsets.right]);
}

- (CGFloat)menuHeightForWidth:(CGFloat)width
{
    CGFloat height = 0.0f;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    UIEdgeInsets edgeInsets = self.edgeInsets;
    
    bool hasRegularItems = false;
    bool hasHeader = false;
    bool hasFooter = false;
    
    for (MenuSheetItemView *itemView in self.itemViews)
    {
        bool skip = false;
        
        switch (itemView.type)
        {
            case MenuSheetItemTypeDefault:
                hasRegularItems = true;
                break;
                
            case MenuSheetItemTypeHeader:
                if (_sizeClass == UIUserInterfaceSizeClassRegular)
                    skip = true;
                else
                    hasHeader = true;
                break;
                
            case MenuSheetItemTypeFooter:
                if (_sizeClass == UIUserInterfaceSizeClassRegular)
                    skip = true;
                else
                    hasFooter = true;
                break;
                
            default:
                break;
        }
        
        if (!skip)
        {
            height += [itemView preferredHeightForWidth:width screenHeight:screenHeight];
            height += itemView.contentHeightCorrection;
        }
    }
    
    if (hasRegularItems || hasHeader || hasFooter)
        height += self.edgeInsets.top + self.edgeInsets.bottom;
    
    if ((hasRegularItems && hasHeader) || (hasRegularItems && hasFooter) || (hasHeader && hasFooter))
        height += self.interSectionSpacing;
    
    if (hasHeader && hasFooter && hasRegularItems)
        height += self.interSectionSpacing;
    
    if (self.keyboardOffset > 0)
    {
        height += self.keyboardOffset;
        height -= [self.footerItemView preferredHeightForWidth:width screenHeight:screenHeight] + self.interSectionSpacing;
    }
    
    if (fabs(height - screenHeight) <= edgeInsets.top)
        height = screenHeight;
    
    return height;
}

- (CGFloat)contentHeightCorrection
{
    CGFloat height = 0.0f;
    
    for (MenuSheetItemView *itemView in self.itemViews)
        height += itemView.contentHeightCorrection;
    
    return height;
}

#pragma mark - 

- (MenuSheetItemView *)headerItemView
{
    if (_sizeClass == UIUserInterfaceSizeClassRegular)
        return nil;
    
    if ([(MenuSheetItemView *)self.itemViews.firstObject type] == MenuSheetItemTypeHeader)
        return self.itemViews.firstObject;
    
    return nil;
}

- (MenuSheetItemView *)footerItemView
{
    if (_sizeClass == UIUserInterfaceSizeClassRegular)
        return nil;
    
    if ([(MenuSheetItemView *)self.itemViews.lastObject type] == MenuSheetItemTypeFooter)
        return self.itemViews.lastObject;
    
    return nil;
}

- (bool)hasHeader
{
    if (_sizeClass == UIUserInterfaceSizeClassRegular)
        return nil;
    
    return (self.headerItemView != nil);
}

- (bool)hasFooter
{
    if (_sizeClass == UIUserInterfaceSizeClassRegular)
        return nil;
    
    return (self.footerItemView != nil);
}

- (NSValue *)mainFrame
{
    if (_mainBackgroundView != nil)
        return [NSValue valueWithCGRect:_mainBackgroundView.frame];
    
    return nil;
}

- (NSValue *)headerFrame
{
    if (_headerBackgroundView != nil)
        return [NSValue valueWithCGRect:_headerBackgroundView.frame];
    
    return nil;
}

- (NSValue *)footerFrame
{
    if (_footerBackgroundView != nil)
        return [NSValue valueWithCGRect:_footerBackgroundView.frame];
    
    return nil;
}

#pragma mark - 

- (CGRect)activePanRect
{
    if (_panHandlingItemView == nil)
    {
        for (MenuSheetItemView *itemView in _itemViews)
        {
            if (itemView.handlesPan)
            {
                _panHandlingItemView = itemView;
                break;
            }
        }
        
        if (_panHandlingItemView == nil)
            _panHandlingItemView = [NSNull null];
    }
    
    if ([_panHandlingItemView isKindOfClass:[NSNull class]])
    {
        if (_scrollView.frame.size.height < _scrollView.contentSize.height)
            return [self convertRect:_scrollView.frame toView:self.superview.superview];
        else
            return CGRectNull;
    }
    
    MenuSheetItemView *itemView = (MenuSheetItemView *)_panHandlingItemView;
    return [itemView convertRect:itemView.bounds toView:self.superview.superview];
}

- (bool)passPanOffset:(CGFloat)offset
{
    if (_scrollView.frame.size.height < _scrollView.contentSize.height)
    {
        CGFloat bottomContentOffset = (_scrollView.contentSize.height - _scrollView.frame.size.height);
        
        if (bottomContentOffset > 0 && _scrollView.contentOffset.y > bottomContentOffset)
            return false;
        
        bool atTop = (_scrollView.contentOffset.y < FLT_EPSILON);
        bool atBottom = (_scrollView.contentOffset.y - bottomContentOffset > -FLT_EPSILON);
        
        if (atTop && offset > FLT_EPSILON)
            return true;
        
        if (atBottom && offset < 0)
            return true;
        
        return false;
    }
    else if ([_panHandlingItemView isKindOfClass:[NSNull class]])
    {
        return true;
    }
    
    MenuSheetItemView *itemView = (MenuSheetItemView *)_panHandlingItemView;
    return [itemView passPanOffset:offset];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!_expectsPreciseContentTouch)
        return [super pointInside:point withEvent:event];
    
    for (MenuSheetItemView *itemView in _itemViews)
    {
        if ([itemView pointInside:[self convertPoint:point toView:itemView] withEvent:event])
            return true;
    }
    
    return false;
}

#pragma mark - 

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat bottomContentOffset = (scrollView.contentSize.height - scrollView.frame.size.height);
    
    bool atTop = (scrollView.contentOffset.y < FLT_EPSILON);
    bool atBottom = (scrollView.contentOffset.y - bottomContentOffset > -FLT_EPSILON);

    if ((atTop || atBottom) && _sizeClass == UIUserInterfaceSizeClassCompact)
    {
        if (scrollView.isTracking && scrollView.bounces && (scrollView.contentOffset.y - bottomContentOffset) < 20.0f)
        {
            scrollView.bounces = false;
            if (atTop)
                scrollView.contentOffset = CGPointMake(0, 0);
            else if (atBottom)
                scrollView.contentOffset = CGPointMake(0, bottomContentOffset);
        }
    }
    else
    {
        scrollView.bounces = true;
    }
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat bottomContentOffset = (scrollView.contentSize.height - scrollView.frame.size.height);
    
    bool atTop = (scrollView.contentOffset.y < FLT_EPSILON);
    bool atBottom = (scrollView.contentOffset.y - bottomContentOffset > -FLT_EPSILON);
    
    if ((atTop || atBottom) && scrollView.bounces && !scrollView.isTracking && _sizeClass == UIUserInterfaceSizeClassCompact)
        scrollView.bounces = false;
}

#pragma mark -

- (void)menuWillAppearAnimated:(bool)animated
{
    for (MenuSheetItemView *itemView in self.itemViews)
        [itemView menuView:self willAppearAnimated:animated];
}

- (void)menuDidAppearAnimated:(bool)animated
{
    for (MenuSheetItemView *itemView in self.itemViews)
        [itemView menuView:self didAppearAnimated:animated];
}

- (void)menuWillDisappearAnimated:(bool)animated
{
    for (MenuSheetItemView *itemView in self.itemViews)
        [itemView menuView:self willDisappearAnimated:animated];
}

- (void)menuDidDisappearAnimated:(bool)animated
{
    for (MenuSheetItemView *itemView in self.itemViews)
        [itemView menuView:self didDisappearAnimated:animated];
}

- (void)layoutSubviews
{
    CGFloat width = self.menuWidth - self.edgeInsets.left - self.edgeInsets.right;
    CGFloat maxHeight = _sizeClass == UIUserInterfaceSizeClassCompact ? [UIScreen mainScreen].bounds.size.height : self.frame.size.height;
    
    if (_sizeClass == UIUserInterfaceSizeClassCompact && self.maxHeight > FLT_EPSILON)
        maxHeight = MIN(self.maxHeight , maxHeight);
    
    CGFloat screenHeight = maxHeight;
    bool fullscreen = fabs(maxHeight - [UIScreen mainScreen].bounds.size.height) < FLT_EPSILON;

    if (_sizeClass == UIUserInterfaceSizeClassCompact)
    {
        if (self.headerItemView != nil)
            maxHeight -= [self.headerItemView preferredHeightForWidth:width screenHeight:screenHeight] + self.interSectionSpacing;
        
        if (self.keyboardOffset > FLT_EPSILON)
            maxHeight -= self.keyboardOffset;
        else if (self.footerItemView != nil)
            maxHeight -= [self.footerItemView preferredHeightForWidth:width screenHeight:screenHeight] + self.interSectionSpacing;
    }
    
    CGFloat contentHeight = 0;
    bool hasRegularItems = false;
    
    NSUInteger i = 0;
    MenuSheetItemView *condensableItemView = nil;
    for (MenuSheetItemView *itemView in self.itemViews)
    {
        if (itemView.type == MenuSheetItemTypeDefault)
        {
            hasRegularItems = true;
            
            CGFloat height = [itemView preferredHeightForWidth:width screenHeight:screenHeight];
            itemView.screenHeight = screenHeight;
            itemView.frame = CGRectMake(0, contentHeight, width, height);
            contentHeight += height;
            
            NSUInteger lastItem = (self.footerItemView != nil) ? self.itemViews.count - 2 : self.itemViews.count - 1;
            if (itemView.requiresDivider && i != lastItem)
            {
                UIView *divider = _dividerViews[@(itemView.tag)][MenuDividerBottom];
                if (divider != nil)
                    divider.frame = CGRectMake(0, CGRectGetMaxY(itemView.frame) - divider.frame.size.height, width, divider.frame.size.height);
            }
            
            if (itemView.condensable)
                condensableItemView = itemView;
        }
        i++;
    }
    contentHeight += self.contentHeightCorrection;
    
    UIEdgeInsets edgeInsets = self.edgeInsets;
    CGSize statusBarSize = [UIApplication sharedApplication].statusBarFrame.size;
    CGFloat statusBarHeight = MIN(statusBarSize.width, statusBarSize.height);
    statusBarHeight = MAX(statusBarHeight, 20.0f);
    
    if (fullscreen)
    {
        if (contentHeight > maxHeight - edgeInsets.top - edgeInsets.bottom)
            edgeInsets.top = statusBarHeight;
    
        if (fabs(contentHeight - maxHeight + edgeInsets.bottom) <= statusBarHeight)
            edgeInsets.top = statusBarHeight;
    }
    
    if (_sizeClass == UIUserInterfaceSizeClassRegular)
        edgeInsets = UIEdgeInsetsZero;
    
    maxHeight -= edgeInsets.top + edgeInsets.bottom;
    
    if (self.keyboardOffset > FLT_EPSILON && contentHeight > maxHeight && condensableItemView != nil)
    {
        CGFloat difference = contentHeight - maxHeight;
        contentHeight -= difference;
        
        CGRect frame = condensableItemView.frame;
        condensableItemView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height - difference);
        
        if (condensableItemView.requiresDivider)
        {
            UIView *divider = _dividerViews[@(condensableItemView.tag)][MenuDividerBottom];
            if (divider != nil)
            {
                CGRect dividerFrame = divider.frame;
                divider.frame = CGRectMake(dividerFrame.origin.x, dividerFrame.origin.y - difference, dividerFrame.size.width, dividerFrame.size.height);
            }
        }
        
        bool moveNextItems = false;
        for (MenuSheetItemView *itemView in self.itemViews)
        {
            if (moveNextItems)
            {
                CGRect frame = itemView.frame;
                itemView.frame = CGRectMake(frame.origin.x, frame.origin.y - difference, frame.size.width, frame.size.height);
                
                if (itemView.requiresDivider)
                {
                    UIView *divider = _dividerViews[@(itemView.tag)][MenuDividerBottom];
                    if (divider != nil)
                    {
                        CGRect dividerFrame = divider.frame;
                        divider.frame = CGRectMake(dividerFrame.origin.x, dividerFrame.origin.y - difference, dividerFrame.size.width, dividerFrame.size.height);
                    }
                }
            }
            else if (itemView == condensableItemView)
            {
                moveNextItems = true;
            }
        }
    }
    
    for (MenuSheetItemView *itemView in self.itemViews)
        [itemView _didLayoutSubviews];
    
    CGFloat topInset = edgeInsets.top;
    if (self.headerItemView != nil)
    {
        _headerBackgroundView.frame = CGRectMake(edgeInsets.left, topInset, width, [self.headerItemView preferredHeightForWidth:width screenHeight:screenHeight]);
        self.headerItemView.frame = _headerBackgroundView.bounds;
        
        topInset = CGRectGetMaxY(_headerBackgroundView.frame) + MenuSheetInterSectionSpacing;
    }
    
    if (hasRegularItems)
    {
        _mainBackgroundView.frame = CGRectMake(edgeInsets.left, topInset, width, MIN(contentHeight, maxHeight));
        _scrollView.frame = _mainBackgroundView.bounds;
        _scrollView.contentSize = CGSizeMake(width, contentHeight);
    }
    
    if (self.footerItemView != nil)
    {
        CGFloat height = [self.footerItemView preferredHeightForWidth:width screenHeight:screenHeight];
        CGFloat top = self.menuHeight - edgeInsets.bottom - height;
        if (hasRegularItems && self.keyboardOffset < FLT_EPSILON)
            top = CGRectGetMaxY(_mainBackgroundView.frame) + MenuSheetInterSectionSpacing;
    
        _footerBackgroundView.frame = CGRectMake(edgeInsets.left, top, width, height);
        self.footerItemView.frame = _footerBackgroundView.bounds;
    }
}

@end
