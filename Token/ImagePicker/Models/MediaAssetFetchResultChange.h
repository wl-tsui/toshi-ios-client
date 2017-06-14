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

#import "MediaAssetFetchResult.h"

@class PHFetchResultChangeDetails;

@interface MediaAssetFetchResultChange : NSObject

@property (nonatomic, readonly) MediaAssetFetchResult *fetchResultBeforeChanges;
@property (nonatomic, readonly) MediaAssetFetchResult *fetchResultAfterChanges;

@property (nonatomic, readonly) bool hasIncrementalChanges;

@property (nonatomic, readonly) NSIndexSet *removedIndexes;
@property (nonatomic, readonly) NSIndexSet *insertedIndexes;
@property (nonatomic, readonly) NSIndexSet *updatedIndexes;

@property (nonatomic, readonly) bool hasMoves;
- (void)enumerateMovesWithBlock:(void(^)(NSUInteger fromIndex, NSUInteger toIndex))handler;

+ (instancetype)changeWithPHFetchResultChangeDetails:(PHFetchResultChangeDetails *)changeDetails reversed:(bool)reversed;

@end
