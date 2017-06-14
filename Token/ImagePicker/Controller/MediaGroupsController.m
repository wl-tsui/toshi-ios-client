#import "MediaGroupsController.h"
#import "MediaGroupCell.h"

#import "MediaAssetMomentList.h"

#import "Common.h"

#import "MediaAssetsPickerController.h"
#import "MediaAssetsMomentsController.h"

#import "MediaPickerToolbarView.h"

@interface MediaGroupsController () <UITableViewDataSource, UITableViewDelegate>
{
    MediaAssetsControllerIntent _intent;
    MediaAssetsLibrary *_assetsLibrary;
    NSArray *_groups;
    
    SMetaDisposable *_groupsDisposable;
    
    UITableView *_tableView;
}
@end

@implementation MediaGroupsController

- (instancetype)initWithAssetsLibrary:(MediaAssetsLibrary *)assetsLibrary intent:(MediaAssetsControllerIntent)intent
{
    self = [super init];
    if (self != nil)
    {
        _assetsLibrary = assetsLibrary;
        _intent = intent;
        
        [self setTitle:TGLocalized(@"Images")];
    }
    return self;
}

- (void)dealloc
{
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    [_groupsDisposable dispose];
}

- (void)loadView
{
    [super loadView];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    _tableView.alwaysBounceVertical = true;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.delaysContentTouches = true;
    _tableView.canCancelContentTouches = true;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tableView];
    
    self.scrollViewsForAutomaticInsetsAdjustment = @[ _tableView ];
    
    self.explicitTableInset = UIEdgeInsetsMake(0, 0, MediaPickerToolbarHeight, 0);
    self.explicitScrollIndicatorInset = self.explicitTableInset;
}

- (void)loadViewIfNeeded
{
    if (iosMajorVersion() >= 9)
    {
        [super loadViewIfNeeded];
    }
    else
    {
        if (![self isViewLoaded])
        {
            [self loadView];
            [self viewDidLoad];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    __weak MediaGroupsController *weakSelf = self;
    _groupsDisposable = [[SMetaDisposable alloc] init];
    [_groupsDisposable setDisposable:[[[_assetsLibrary assetGroups] deliverOn:[SQueue mainQueue]] startWithNext:^(NSArray *next)
    {
        __strong MediaGroupsController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return ;
        
        strongSelf->_groups = next;
        [strongSelf->_tableView reloadData];
        
        if (!strongSelf.viewControllerHasEverAppeared && next.count > 0)
        {
            [strongSelf->_tableView layoutIfNeeded];
            
            for (MediaGroupCell *cell in strongSelf->_tableView.visibleCells)
            {
                if (cell.assetGroup.isCameraRoll)
                {
                    [strongSelf->_tableView selectRowAtIndexPath:[strongSelf->_tableView indexPathForCell:cell] animated:false scrollPosition:UITableViewScrollPositionNone];
                }
            }
        }
        else if ([strongSelf.navigationController isKindOfClass:[MediaAssetsController class]])
        {
            MediaAssetsPickerController *pickerController = ((MediaAssetsController *)strongSelf.navigationController).pickerController;
            if (![next containsObject:pickerController.assetGroup])
                [strongSelf.navigationController popToRootViewControllerAnimated:false];
        }
    }]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_tableView.indexPathForSelectedRow != nil)
        [_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow animated:true];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.navigationController.viewControllers.count > 1 && _tableView.indexPathForSelectedRow == nil)
    {
        MediaAssetsPickerController *controller = self.navigationController.viewControllers.lastObject;
        if ([controller isKindOfClass:[MediaAssetsPickerController class]])
        {
            for (MediaGroupCell *cell in _tableView.visibleCells)
            {
                if ([cell.assetGroup isEqual:controller.assetGroup])
                {
                    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
                    if (indexPath != nil)
                        [_tableView selectRowAtIndexPath:indexPath animated:false scrollPosition:UITableViewScrollPositionNone];
                }
            }
        }
    }
}

#pragma mark - Table View Data Source & Delegate

- (void)tableView:(UITableView *)__unused tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id group = _groups[indexPath.row];
    
    if (self.openAssetGroup != nil)
        self.openAssetGroup(group);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MediaGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:MediaGroupCellKind];
    if (cell == nil)
        cell = [[MediaGroupCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MediaGroupCellKind];
    
    id group = _groups[indexPath.row];
    
    if ([group isKindOfClass:[MediaAssetMomentList class]])
        [cell configureForMomentList:group];
    else if ([group isKindOfClass:[MediaAssetGroup class]])
        [cell configureForAssetGroup:group];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)__unused section
{
    return _groups.count;
}

- (CGFloat)tableView:(UITableView *)__unused tableView heightForRowAtIndexPath:(NSIndexPath *)__unused indexPath
{
    return MediaGroupCellHeight;
}

- (CGFloat)tableView:(UITableView *)__unused tableView heightForFooterInSection:(NSInteger)__unused section
{
    return 0.001f;
}

- (UIView *)tableView:(UITableView *)__unused tableView viewForFooterInSection:(NSInteger)__unused section
{
    return [[UIView alloc] init];
}

@end
