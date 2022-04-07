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

#import "GeneratedInterface-Swift.h"

@interface DirectoryViewController () <RoomNotificationSettingsCoordinatorBridgePresenterDelegate, RoomContextActionServiceDelegate>
{
    PublicRoomsDirectoryDataSource *dataSource;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;

    // The animated view displayed at the table view bottom when paginating
    UIView* footerSpinnerView;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
}

@property (nonatomic) AnalyticsScreenTracker *screenTracker;

@property (nonatomic, strong) RoomNotificationSettingsCoordinatorBridgePresenter *roomNotificationSettingsCoordinatorBridgePresenter;

@property (nonatomic, strong) PublicRoomContextMenuProvider *contextMenuProvider;

@end

@implementation DirectoryViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    self.contextMenuProvider = [PublicRoomContextMenuProvider new];
    self.contextMenuProvider.serviceDelegate = self;

    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    self.screenTracker = [[AnalyticsScreenTracker alloc] initWithScreen:AnalyticsScreenRoomDirectory];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = [VectorL10n directoryTitle];

    self.tableView.delegate = self;

    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    // Check the table view style to select its bg color.
    self.tableView.backgroundColor = ((self.tableView.style == UITableViewStylePlain) ? ThemeService.shared.theme.backgroundColor : ThemeService.shared.theme.headerBackgroundColor);
    self.view.backgroundColor = self.tableView.backgroundColor;
    self.tableView.separatorColor = ThemeService.shared.theme.lineBreakColor;
    
    if (self.tableView.dataSource)
    {
        [self.tableView reloadData];
    }

    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)destroy
{
    [super destroy];
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.tableView setContentOffset:CGPointMake(-self.tableView.adjustedContentInset.left, -self.tableView.adjustedContentInset.top) animated:YES];
        
    }];

    [self.tableView reloadData];
    [self.screenTracker trackScreen];
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    // Update the selected background view
    if (ThemeService.shared.theme.selectedBackgroundColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = ThemeService.shared.theme.selectedBackgroundColor;
    }
    else
    {
        if (tableView.style == UITableViewStylePlain)
        {
            cell.selectedBackgroundView = nil;
        }
        else
        {
            cell.selectedBackgroundView.backgroundColor = nil;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MXPublicRoom *publicRoom = [dataSource roomAtIndexPath:indexPath];

    [self showRoomWithPublicRoom:publicRoom];
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

- (void)showRoomWithId:(NSString*)roomId inMatrixSession:(MXSession*)mxSession
{
    ScreenPresentationParameters *presentationParameters = [[ScreenPresentationParameters alloc] initWithRestoreInitialDisplay:NO stackAboveVisibleViews:NO];
    
    RoomNavigationParameters *parameters = [[RoomNavigationParameters alloc] initWithRoomId:roomId
                                                                                    eventId:nil
                                                                                  mxSession:mxSession
                                                                           threadParameters:nil
                                                                     presentationParameters:presentationParameters];
    Analytics.shared.viewRoomTrigger = AnalyticsViewRoomTriggerRoomDirectory;
    [[AppDelegate theDelegate] showRoomWithParameters:parameters];
}

- (void)showRoomPreviewWithData:(RoomPreviewData*)roomPreviewData
{
    Analytics.shared.joinedRoomTrigger = AnalyticsJoinedRoomTriggerRoomDirectory;
    ScreenPresentationParameters *presentationParameters = [[ScreenPresentationParameters alloc] initWithRestoreInitialDisplay:NO stackAboveVisibleViews:NO];
    
    RoomPreviewNavigationParameters *parameters = [[RoomPreviewNavigationParameters alloc] initWithPreviewData:roomPreviewData presentationParameters:presentationParameters];
    [[AppDelegate theDelegate] showRoomPreviewWithParameters:parameters];
}

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    MasterTabBarController *masterTabBarController = [AppDelegate theDelegate].masterTabBarController;

    // Update here the index of the current selected cell (if any) - Useful in landscape mode with split view controller.
    NSIndexPath *currentSelectedCellIndexPath = nil;
    if (masterTabBarController.selectedRoomId)
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

- (void)showRoomWithPublicRoom:(MXPublicRoom*)publicRoom
{
    // Check whether the user has already joined the selected public room
    if ([dataSource.mxSession isJoinedOnRoom:publicRoom.roomId])
    {
        // Open the public room.
        [self showRoomWithId:publicRoom.roomId inMatrixSession:dataSource.mxSession];
    }
    else
    {
        // Preview the public room
        if (publicRoom.worldReadable)
        {
            RoomPreviewData *roomPreviewData = [[RoomPreviewData alloc] initWithPublicRoom:publicRoom andSession:dataSource.mxSession];
            
            [self startActivityIndicator];
            
            // Try to get more information about the room before opening its preview
            [roomPreviewData peekInRoom:^(BOOL succeeded) {
                
                [self stopActivityIndicator];
                
                [self showRoomPreviewWithData:roomPreviewData];
            }];
        }
        else
        {
            RoomPreviewData *roomPreviewData = [[RoomPreviewData alloc] initWithPublicRoom:publicRoom andSession:dataSource.mxSession];
            [self showRoomPreviewWithData:roomPreviewData];
        }
        
    }
}

- (void)changeRoomNotificationSettingsForRoomWithId:(NSString*)roomId
{
    MXRoom *room = [dataSource.mxSession roomWithRoomId:roomId];
    if (room)
    {
       // navigate
        self.roomNotificationSettingsCoordinatorBridgePresenter = [[RoomNotificationSettingsCoordinatorBridgePresenter alloc] initWithRoom:room];
        self.roomNotificationSettingsCoordinatorBridgePresenter.delegate = self;
        [self.roomNotificationSettingsCoordinatorBridgePresenter presentFrom:self animated:YES];
    }
}

#pragma mark - Context Menu

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0))
{
    MXPublicRoom *publicRoom = [dataSource roomAtIndexPath:indexPath];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (!publicRoom || !cell)
    {
        return nil;
    }
    
    return [self.contextMenuProvider contextMenuConfigurationWith:publicRoom from:cell session:dataSource.mxSession];
}

- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator API_AVAILABLE(ios(13.0))
{
    MXPublicRoom *publicRoom = [self.contextMenuProvider publicRoomFrom:configuration.identifier];
    if (!publicRoom)
    {
        return;
    }
    
    [animator addCompletion:^{
        [self showRoomWithPublicRoom:publicRoom];
    }];
}

#pragma mark - RoomContextActionServiceDelegate

- (void)roomContextActionServiceDidJoinRoom:(id<RoomContextActionServiceProtocol>)service
{
    // Nothing to do here
}

- (void)roomContextActionServiceDidLeaveRoom:(id<RoomContextActionServiceProtocol>)service
{
    // Nothing to do here
}

- (void)roomContextActionService:(id<RoomContextActionServiceProtocol>)service presentAlert:(UIAlertController *)alertController
{
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)roomContextActionService:(id<RoomContextActionServiceProtocol>)service updateActivityIndicator:(BOOL)isActive
{
    if (isActive)
    {
        [self startActivityIndicator];
    }
    else
    {
        [self stopActivityIndicator];
    }
}

- (void)roomContextActionService:(id<RoomContextActionServiceProtocol>)service showRoomNotificationSettingsForRoomWithId:(NSString *)roomId
{
    [self changeRoomNotificationSettingsForRoomWithId:roomId];
}

#pragma mark - RoomNotificationSettingsCoordinatorBridgePresenterDelegate

-(void)roomNotificationSettingsCoordinatorBridgePresenterDelegateDidComplete:(RoomNotificationSettingsCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.roomNotificationSettingsCoordinatorBridgePresenter = nil;
}

@end
