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

#import <UIKit/UIKit.h>
#import <SSignalKit/SSignalKit.h>

@protocol TGTransitionAnimatorLayout <NSObject>

- (void)collectionViewAlmostCompleteTransitioning:(UICollectionView *)collectionView;
- (void)collectionViewDidCompleteTransitioning:(UICollectionView *)collectionView completed:(bool)completed finish:(bool)finish;

@end

@interface UICollectionView (Transitioning)

@property (nonatomic, readonly) bool isTransitionInProgress;

- (UICollectionViewTransitionLayout *)transitionToCollectionViewLayout:(UICollectionViewLayout *)layout duration:(NSTimeInterval)duration completion:(UICollectionViewLayoutInteractiveTransitionCompletion)completion;
- (CGPoint)toContentOffsetForLayout:(UICollectionViewTransitionLayout *)layout indexPath:(NSIndexPath *)indexPath toSize:(CGSize)toSize toContentInset:(UIEdgeInsets)toContentInset;

- (SSignal *)noOngoingTransitionSignal;

@end
