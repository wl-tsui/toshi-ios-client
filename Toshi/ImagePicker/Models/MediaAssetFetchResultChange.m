#import "MediaAssetFetchResultChange.h"

#import <Photos/Photos.h>

@interface MediaAssetFetchResultChangeMovePair : NSObject

@property (nonatomic, assign) NSUInteger from;
@property (nonatomic, assign) NSUInteger to;

@end


@interface MediaAssetFetchResultChange ()
{
    NSArray *_moves;
}
@end

@implementation MediaAssetFetchResultChange

- (void)enumerateMovesWithBlock:(void (^)(NSUInteger, NSUInteger))handler
{
    if (handler == nil)
        return;
    
    for (MediaAssetFetchResultChangeMovePair *move in _moves)
        handler(move.from, move.to);
}

+ (instancetype)changeWithPHFetchResultChangeDetails:(PHFetchResultChangeDetails *)changeDetails reversed:(bool)reversed
{
    if (changeDetails == nil)
        return nil;
    
    MediaAssetFetchResultChange *change = [[MediaAssetFetchResultChange alloc] init];
    change->_fetchResultBeforeChanges = [[MediaAssetFetchResult alloc] initWithPHFetchResult:changeDetails.fetchResultBeforeChanges reversed:reversed];
    change->_fetchResultAfterChanges = [[MediaAssetFetchResult alloc] initWithPHFetchResult:changeDetails.fetchResultAfterChanges reversed:reversed];
    change->_hasIncrementalChanges = changeDetails.hasIncrementalChanges;
    change->_removedIndexes = [self transponedIndexSet:changeDetails.removedIndexes reversed:reversed initialCount:changeDetails.fetchResultBeforeChanges.count removedCount:0 insertedCount:0]; //changeDetails.removedIndexes;
    change->_insertedIndexes = [self transponedIndexSet:changeDetails.insertedIndexes reversed:reversed initialCount:changeDetails.fetchResultBeforeChanges.count removedCount:changeDetails.removedIndexes.count insertedCount:changeDetails.insertedIndexes.count]; //changeDetails.insertedIndexes;
    change->_updatedIndexes = [self transponedIndexSet:changeDetails.changedIndexes reversed:reversed initialCount:changeDetails.fetchResultBeforeChanges.count removedCount:changeDetails.removedIndexes.count insertedCount:changeDetails.insertedIndexes.count]; //changeDetails.changedIndexes;
    change->_hasMoves = changeDetails.hasMoves;
    
    if (changeDetails.hasMoves)
    {
        NSMutableArray *moves = [[NSMutableArray alloc] init];
        [changeDetails enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex)
        {
            MediaAssetFetchResultChangeMovePair *move = [[MediaAssetFetchResultChangeMovePair alloc] init];
            move.from = [self transponedIndex:fromIndex reversed:reversed initialCount:changeDetails.fetchResultBeforeChanges.count removedCount:change->_removedIndexes.count insertedCount:change->_insertedIndexes.count]; //fromIndex;
            move.to = [self transponedIndex:toIndex reversed:reversed initialCount:changeDetails.fetchResultBeforeChanges.count removedCount:change->_removedIndexes.count insertedCount:change->_insertedIndexes.count];
            [moves addObject:move];
        }];
        change->_moves = moves;
    }
    
    return change;
}

+ (NSInteger)transponedIndex:(NSInteger)index reversed:(bool)reversed initialCount:(NSInteger)initialCount removedCount:(NSInteger)removedCount insertedCount:(NSInteger)insertedCount
{
    return reversed ? initialCount - removedCount + insertedCount - index - 1 : index;
}

+ (NSIndexSet *)transponedIndexSet:(NSIndexSet *)indexSet reversed:(bool)reversed initialCount:(NSInteger)initialCount removedCount:(NSInteger)removedCount insertedCount:(NSInteger)insertedCount
{
    if (!reversed)
        return indexSet;
    
    NSMutableIndexSet *transponedIndexSet = [[NSMutableIndexSet alloc] init];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, __unused BOOL *stop)
    {
        [transponedIndexSet addIndex:[self transponedIndex:idx reversed:reversed initialCount:initialCount removedCount:removedCount insertedCount:insertedCount]];
    }];
    return transponedIndexSet;
}

@end


@implementation MediaAssetFetchResultChangeMovePair

@end
