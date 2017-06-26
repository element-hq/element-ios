/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "DirectoryViewController.h"

#import "PublicRoomsDirectoryDataSource.h"

#import "AppDelegate.h"

@interface DirectoryViewController ()
{
    PublicRoomsDirectoryDataSource *dataSource;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;

    // The animated view displayed at the table view bottom when paginating
    UIView* footerSpinnerView;
}

@end

@implementation DirectoryViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kRiotNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedStringFromTable(@"directory_title", @"Vector", nil);

    self.tableView.delegate = self;

    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:@"Directory"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
    
    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.tableView setContentOffset:CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top) animated:YES];
        
    }];

    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Release the current selected item (room/contact...) except if the second view controller is still visible (see splitViewController.isCollapsed condition)
    if (self.splitViewController && self.splitViewController.isCollapsed)
    {
        [[AppDelegate theDelegate].masterTabBarController releaseSelectedItem];
    }
    else
    {
        // In case of split view controller where the primary and secondary view controllers are displayed side-by-side onscreen,
        // the selected room (if any) is highlighted.
        [self refreshCurrentSelectedCell:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }
    
    [super viewWillDisappear:animated];
}

- (void)displayWitDataSource:(PublicRoomsDirectoryDataSource *)dataSource2
{
    // Let the data source provide cells
    dataSource = dataSource2;
    self.tableView.dataSource = dataSource;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MXPublicRoom *publicRoom = [dataSource roomAtIndexPath:indexPath];

    // Check whether the user has already joined the selected public room
    if ([dataSource.mxSession roomWithRoomId:publicRoom.roomId])
    {
        // Open the public room.
        [self openRoomWithId:publicRoom.roomId inMatrixSession:dataSource.mxSession];
    }
    else
    {
        // Preview the public room
        if (publicRoom.worldReadable)
        {
            RoomPreviewData *roomPreviewData = [[RoomPreviewData alloc] initWithRoomId:publicRoom.roomId andSession:dataSource.mxSession];
            
            [self startActivityIndicator];
            
            // Try to get more information about the room before opening its preview
            [roomPreviewData peekInRoom:^(BOOL succeeded) {
                
                [self stopActivityIndicator];
                
                [[AppDelegate theDelegate].masterTabBarController showRoomPreview:roomPreviewData];
            }];
        }
        else
        {
            RoomPreviewData *roomPreviewData = [[RoomPreviewData alloc] initWithPublicRoom:publicRoom andSession:dataSource.mxSession];
            [[AppDelegate theDelegate].masterTabBarController showRoomPreview:roomPreviewData];
        }
        
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Trigger inconspicuous pagination when user scrolls down
    if ((scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.frame.size.height) < 300)
    {
        [self triggerPagination];
    }
}

#pragma mark - Private methods

- (void)openRoomWithId:(NSString*)roomId inMatrixSession:(MXSession*)mxSession
{
    [[AppDelegate theDelegate].masterTabBarController selectRoomWithId:roomId andEventId:nil inMatrixSession:mxSession];
}

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    MasterTabBarController *masterTabBarController = [AppDelegate theDelegate].masterTabBarController;

    // Update here the index of the current selected cell (if any) - Useful in landscape mode with split view controller.
    NSIndexPath *currentSelectedCellIndexPath = nil;
    if (masterTabBarController.currentRoomViewController)
    {
        // Look for the rank of this selected room in displayed recents
        currentSelectedCellIndexPath = [dataSource cellIndexPathWithRoomId:masterTabBarController.selectedRoomId andMatrixSession:masterTabBarController.selectedRoomSession];
    }

    if (currentSelectedCellIndexPath)
    {
        // Select the right row
        [self.tableView selectRowAtIndexPath:currentSelectedCellIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];

        if (forceVisible)
        {
            // Scroll table view to make the selected row appear at second position
            NSInteger topCellIndexPathRow = currentSelectedCellIndexPath.row ? currentSelectedCellIndexPath.row - 1: currentSelectedCellIndexPath.row;
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:topCellIndexPathRow inSection:currentSelectedCellIndexPath.section];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    }
    else
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath)
        {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

- (void)triggerPagination
{
    if (dataSource.hasReachedPaginationEnd || footerSpinnerView)
    {
        // We got all public rooms or we are already paginating
        // Do nothing
        return;
    }

    [self addSpinnerFooterView];

    __weak __typeof(self) weakSelf = self;

    [dataSource paginate:^(NSUInteger roomsAdded) {

        if (weakSelf)
        {
            __strong __typeof(weakSelf) self = weakSelf;

            if (roomsAdded)
            {
                [self.tableView reloadData];
            }
            
            [self removeSpinnerFooterView];
        }

    } failure:^(NSError *error) {

        if (weakSelf)
        {
            __strong __typeof(weakSelf) self = weakSelf;

            [self removeSpinnerFooterView];
        }
    }];
}

- (void)addSpinnerFooterView
{
    if (!footerSpinnerView)
    {
        UIActivityIndicatorView* spinner  = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinner.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
        CGRect frame = spinner.frame;
        frame.size.height = 80; // 80 * 0.75 = 60
        spinner.bounds = frame;

        spinner.color = [UIColor darkGrayColor];
        spinner.hidesWhenStopped = NO;
        spinner.backgroundColor = [UIColor clearColor];
        [spinner startAnimating];

        // No need to manage constraints here, iOS defines them
        self.tableView.tableFooterView = footerSpinnerView = spinner;
    }
}

- (void)removeSpinnerFooterView
{
    if (footerSpinnerView)
    {
        footerSpinnerView = nil;

        // Hide line separators of empty cells
        self.tableView.tableFooterView = [[UIView alloc] init];;
    }
}

@end
