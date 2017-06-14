#import "MediaAssetsMomentsController.h"
#import "MediaAssetsModernLibrary.h"
#import "MediaAssetMomentList.h"
#import "MediaAssetFetchResult.h"

#import "MediaAssetsUtils.h"

#import "MediaPickerLayoutMetrics.h"
#import "MediaAssetsMomentsCollectionView.h"
#import "MediaAssetsMomentsCollectionLayout.h"
#import "MediaAssetsMomentsSectionHeaderView.h"
#import "MediaAssetsMomentsSectionHeader.h"

#import "MediaAssetsPhotoCell.h"
#import "MediaAssetsVideoCell.h"
#import "MediaAssetsGifCell.h"

#import "MediaPickerToolbarView.h"

#import "MediaPickerSelectionGestureRecognizer.h"

#import "Common.h"

@interface MediaAssetsMomentsController ()
{
    MediaAssetMomentList *_momentList;
    
    MediaAssetsMomentsCollectionLayout *_collectionLayout;
}
@end

@implementation MediaAssetsMomentsController

- (instancetype)initWithAssetsLibrary:(MediaAssetsLibrary *)assetsLibrary momentList:(MediaAssetMomentList *)momentList intent:(MediaAssetsControllerIntent)intent selectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext
{
    self = [super initWithAssetsLibrary:assetsLibrary assetGroup:nil intent:intent selectionContext:selectionContext editingContext:editingContext];
    if (self != nil)
    {
        _momentList = momentList;
        
        [self setTitle:TGLocalized(@"Moments")];
    }
    return self;
}

- (Class)_collectionViewClass
{
    return [MediaAssetsMomentsCollectionView class];
}

- (UICollectionViewLayout *)_collectionLayout
{
    if (_collectionLayout == nil)
        _collectionLayout = [[MediaAssetsMomentsCollectionLayout alloc] init];
    
    return _collectionLayout;
}

- (void)viewDidLoad
{
    CGSize frameSize = self.view.frame.size;
    CGRect collectionViewFrame = CGRectMake(0.0f, 0.0f, frameSize.width, frameSize.height);
    _collectionViewWidth = collectionViewFrame.size.width;
    _collectionView.frame = collectionViewFrame;
    
    _layoutMetrics = [MediaPickerLayoutMetrics defaultLayoutMetrics];
    
    _preheatMixin.imageSize = [_layoutMetrics imageSize];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [_collectionView reloadData];
        [_collectionView layoutSubviews];
        [self _adjustContentOffsetToBottom];
    });
}

- (void)collectionView:(UICollectionView *)__unused collectionView setupSectionHeaderView:(MediaAssetsMomentsSectionHeaderView *)sectionHeaderView forSectionHeader:(MediaAssetsMomentsSectionHeader *)sectionHeader
{
    MediaAssetMoment *moment = _momentList[sectionHeader.index];
    
    NSString *title = @"";
    NSString *location = @"";
    NSString *date = @"";
    if (moment.title.length > 0)
    {
        title = moment.title;
        if (moment.locationNames.count > 0)
            location = moment.locationNames.firstObject;
        date = [MediaAssetsDateUtils formattedDateRangeWithStartDate:moment.startDate endDate:moment.endDate currentDate:[NSDate date] shortDate:true];
    }
    else
    {
        title = [MediaAssetsDateUtils formattedDateRangeWithStartDate:moment.startDate endDate:moment.endDate currentDate:[NSDate date] shortDate:false];
    }
    
    [sectionHeaderView setTitle:title location:location date:date];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)__unused collectionView
{
    return _momentList.count;
}

- (NSInteger)collectionView:(UICollectionView *)__unused collectionView numberOfItemsInSection:(NSInteger)__unused section
{
    return ((MediaAssetMoment *)_momentList[section]).assetCount;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)__unused collectionView layout:(UICollectionViewLayout *)__unused collectionViewLayout insetForSectionAtIndex:(NSInteger)__unused section
{
    return UIEdgeInsetsMake(48.0f, 0.0f, 0.0f, 0.0f);
}

//- (MediaPickerModernGalleryMixin *)_galleryMixinForItem:(id)item thumbnailImage:(UIImage *)thumbnailImage selectionContext:(MediaSelectionContext *)selectionContext editingContext:(MediaEditingContext *)editingContext suggestionContext:(SuggestionContext *)suggestionContext hasCaptions:(bool)hasCaption asFile:(bool)asFile
//{
//    return [[MediaPickerModernGalleryMixin alloc] initWithItem:item momentList:_momentList parentController:self thumbnailImage:thumbnailImage selectionContext:selectionContext editingContext:editingContext suggestionContext:suggestionContext hasCaptions:hasCaption inhibitDocumentCaptions:false asFile:asFile itemsLimit:0];
//}

- (id)_itemAtIndexPath:(NSIndexPath *)indexPath
{
    MediaAssetFetchResult *fetchResult = [_momentList[indexPath.section] fetchResult];
    MediaAsset *asset = [fetchResult assetAtIndex:indexPath.row];
    return asset;
}

@end
