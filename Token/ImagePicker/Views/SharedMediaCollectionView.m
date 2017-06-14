#import "SharedMediaCollectionView.h"

#import "SharedMediaCollectionLayout.h"
#import "SharedMediaSectionHeader.h"
#import "SharedMediaSectionHeaderView.h"

@interface SharedMediaCollectionView ()
{
    NSMutableArray *_sectionHeaderViewQueue;
    NSMutableArray *_visibleSectionHeaderViews;
}

@end

@implementation  SharedMediaCollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self != nil)
    {
        _sectionHeaderViewQueue = [[NSMutableArray alloc] init];
        _visibleSectionHeaderViews = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)reloadData
{
    for ( SharedMediaSectionHeaderView *headerView in _visibleSectionHeaderViews)
    {
        [self enqueueSectionHeaderView:headerView];
    }
    [_visibleSectionHeaderViews removeAllObjects];
    
    [super reloadData];
}

- ( SharedMediaSectionHeaderView *)dequeueSectionHeaderView
{
     SharedMediaSectionHeaderView *headerView = [_sectionHeaderViewQueue lastObject];
    if (headerView != nil)
    {
        [_sectionHeaderViewQueue removeLastObject];
        return headerView;
    }
    else
    {
        headerView = [[ SharedMediaSectionHeaderView alloc] init];
        return headerView;
    }
}

- (void)enqueueSectionHeaderView:( SharedMediaSectionHeaderView *)headerView
{
    [headerView removeFromSuperview];
    [_sectionHeaderViewQueue addObject:headerView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    UIEdgeInsets insets = self.contentInset;
    
    UIView *topmostViewForHeaders = nil;
    
    for (SharedMediaSectionHeader *sectionHeader in [(SharedMediaCollectionLayout *)self.collectionViewLayout sectionHeaders])
    {
        CGRect headerFloatingBounds = sectionHeader.floatingFrame;
        
        if (CGRectIntersectsRect(bounds, headerFloatingBounds))
        {
             SharedMediaSectionHeaderView *headerView = nil;
            for ( SharedMediaSectionHeaderView *visibleHeaderView in _visibleSectionHeaderViews)
            {
                if (visibleHeaderView.index == sectionHeader.index)
                {
                    headerView = visibleHeaderView;
                    break;
                }
            }
            
            if (headerView == nil)
            {
                headerView = [self dequeueSectionHeaderView];
                headerView.index = sectionHeader.index;
                id< SharedMediaCollectionViewDelegate> delegate = (id< SharedMediaCollectionViewDelegate>)self.delegate;
                [delegate collectionView:self setupSectionHeaderView:headerView forSectionHeader:sectionHeader];
                [_visibleSectionHeaderViews addObject:headerView];
                
                if (topmostViewForHeaders == nil)
                    topmostViewForHeaders = [[self visibleCells] lastObject];
                
                if (topmostViewForHeaders == nil)
                    [self insertSubview:headerView atIndex:0];
                else
                    [self insertSubview:headerView aboveSubview:topmostViewForHeaders];
            }
            
            CGRect headerFrame = sectionHeader.bounds;
            headerFrame.origin.y = MIN(headerFloatingBounds.origin.y + headerFloatingBounds.size.height - headerFrame.size.height, MAX(headerFloatingBounds.origin.y, bounds.origin.y + insets.top));
            headerView.frame = headerFrame;
            [headerView.layer removeAllAnimations];
        }
        else
        {
            NSInteger index = -1;
            for ( SharedMediaSectionHeaderView *headerView in _visibleSectionHeaderViews)
            {
                index++;
                if (headerView.index == sectionHeader.index)
                {
                    [self enqueueSectionHeaderView:headerView];
                    [_visibleSectionHeaderViews removeObjectAtIndex:index];
                    break;
                }
            }
        }
    }
}

@end
