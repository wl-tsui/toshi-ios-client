#import "MediaAssetsMomentsCollectionView.h"

#import "MediaAssetsMomentsCollectionLayout.h"
#import "MediaAssetsMomentsSectionHeader.h"
#import "MediaAssetsMomentsSectionHeaderView.h"

@interface MediaAssetsMomentsCollectionView ()
{
    NSMutableArray *_sectionHeaderViewQueue;
    NSMutableArray *_visibleSectionHeaderViews;
}

@end

@implementation MediaAssetsMomentsCollectionView

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
    for (MediaAssetsMomentsSectionHeaderView *headerView in _visibleSectionHeaderViews)
    {
        [self enqueueSectionHeaderView:headerView];
    }
    [_visibleSectionHeaderViews removeAllObjects];
    
    [super reloadData];
}

- (MediaAssetsMomentsSectionHeaderView *)dequeueSectionHeaderView
{
    MediaAssetsMomentsSectionHeaderView *headerView = [_sectionHeaderViewQueue lastObject];
    if (headerView != nil)
    {
        [_sectionHeaderViewQueue removeLastObject];
        return headerView;
    }
    else
    {
        headerView = [[MediaAssetsMomentsSectionHeaderView alloc] init];
        return headerView;
    }
}

- (void)enqueueSectionHeaderView:(MediaAssetsMomentsSectionHeaderView *)headerView
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
    
    for (MediaAssetsMomentsSectionHeader *sectionHeader in [(MediaAssetsMomentsCollectionLayout *)self.collectionViewLayout sectionHeaders])
    {
        CGRect headerFloatingBounds = sectionHeader.floatingFrame;
        
        if (CGRectIntersectsRect(bounds, headerFloatingBounds))
        {
            MediaAssetsMomentsSectionHeaderView *headerView = nil;
            for (MediaAssetsMomentsSectionHeaderView *visibleHeaderView in _visibleSectionHeaderViews)
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
                id<MediaAssetsMomentsCollectionViewDelegate> delegate = (id<MediaAssetsMomentsCollectionViewDelegate>)self.delegate;
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
            for (MediaAssetsMomentsSectionHeaderView *headerView in _visibleSectionHeaderViews)
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
