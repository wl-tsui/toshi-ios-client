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

@class PhotoFilter;
@class PhotoTool;

@protocol PhotoEditorCollectionViewFiltersDataSource;
@protocol PhotoEditorCollectionViewToolsDataSource;

@interface PhotoEditorCollectionView : UICollectionView <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, copy) void(^interactionEnded)(void);

@property (nonatomic, weak) id <PhotoEditorCollectionViewFiltersDataSource> filtersDataSource;
@property (nonatomic, weak) id <PhotoEditorCollectionViewToolsDataSource> toolsDataSource;
@property (nonatomic, strong) UIImage *filterThumbnailImage;

- (instancetype)initWithOrientation:(UIInterfaceOrientation)orientation cellWidth:(CGFloat)cellWidth;

- (void)setMinimumLineSpacing:(CGFloat)minimumLineSpacing;
- (void)setMinimumInteritemSpacing:(CGFloat)minimumInteritemSpacing;

@end

@protocol PhotoEditorCollectionViewFiltersDataSource <NSObject>

- (NSInteger)numberOfFiltersInCollectionView:(PhotoEditorCollectionView *)collectionView;
- (PhotoFilter *)collectionView:(PhotoEditorCollectionView *)collectionView filterAtIndex:(NSInteger)index;
- (void)collectionView:(PhotoEditorCollectionView *)collectionView didSelectFilterWithIndex:(NSInteger)index;
- (void)collectionView:(PhotoEditorCollectionView *)collectionView requestThumbnailImageForFilterAtIndex:(NSInteger)index completion:(void (^)(UIImage *thumbnailImage, bool cached, bool finished))completion;

@end

@protocol PhotoEditorCollectionViewToolsDataSource <NSObject>

- (NSInteger)numberOfToolsInCollectionView:(PhotoEditorCollectionView *)collectionView;
- (PhotoTool *)collectionView:(PhotoEditorCollectionView *)collectionView toolAtIndex:(NSInteger)index;
- (void)collectionView:(PhotoEditorCollectionView *)collectionView didSelectToolWithIndex:(NSInteger)index;

@end

