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

#import "MediaAssetFetchResultChange.h"
#import "MediaAssetImageSignals.h"

@class MediaAsset;
@class MediaSelectionContext;

@interface MediaAssetsPreheatMixin : NSObject

@property (nonatomic, copy) NSInteger (^assetCount)(void);
@property (nonatomic, copy) MediaAsset *(^assetAtIndexPath)(NSIndexPath *);

@property (nonatomic, assign) MediaAssetImageType imageType;
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, assign) bool reversed;

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView scrollDirection:(UICollectionViewScrollDirection)scrollDirection;
- (void)update;
- (void)stop;

@end


@interface MediaAssetsCollectionViewIncrementalUpdater : NSObject

+ (void)updateCollectionView:(UICollectionView *)collectionView withChange:(MediaAssetFetchResultChange *)change completion:(void (^)(bool incremental))completion;

@end


@interface MediaAssetsSaveToCameraRoll : NSObject

+ (void)saveImageAtURL:(NSURL *)url;
+ (void)saveImageWithData:(NSData *)imageData;
+ (void)saveVideoAtURL:(NSURL *)url;

@end


@interface MediaAssetsDateUtils : NSObject

+ (NSString *)formattedDateRangeWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate currentDate:(NSDate *)currentDate shortDate:(bool)shortDate;

@end
