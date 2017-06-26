#import "ModernMediaListLayout.h"

@interface ModernMediaListLayout ()
{
    bool _updatingCollectionItems;
}

@end

@implementation ModernMediaListLayout

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
    }
    return self;
}

/*- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems
 {
 _updatingCollectionItems = true;
 
 [super prepareForCollectionViewUpdates:updateItems];
 }
 
 - (void)finalizeCollectionViewUpdates
 {
 _updatingCollectionItems = false;
 
 [super finalizeCollectionViewUpdates];
 }*/

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    if (_updatingCollectionItems || itemIndexPath.section != 0)
        return [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    
    return nil;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    if (_updatingCollectionItems || itemIndexPath.section != 0)
        return [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
    
    return [self layoutAttributesForItemAtIndexPath:itemIndexPath];
}

@end
