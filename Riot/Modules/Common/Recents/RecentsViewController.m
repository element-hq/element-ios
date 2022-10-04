/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd
 
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

#import "RecentsViewController.h"
#import "RecentsDataSource.h"
#import "RecentTableViewCell.h"

#import "UnifiedSearchViewController.h"

#import "MXRoom+Riot.h"

#import "RoomViewController.h"

#import "InviteRecentTableViewCell.h"
#import "DirectoryRecentTableViewCell.h"
#import "RoomIdOrAliasTableViewCell.h"
#import "TableViewCellWithCollectionView.h"
#import "SectionHeaderView.h"

#import "GeneratedInterface-Swift.h"

NSString *const RecentsViewControllerDataReadyNotification = @"RecentsViewControllerDataReadyNotification";

@interface RecentsViewController () <CreateRoomCoordinatorBridgePresenterDelegate, RoomsDirectoryCoordinatorBridgePresenterDelegate, RoomNotificationSettingsCoordinatorBridgePresenterDelegate, DialpadViewControllerDelegate, ExploreRoomCoordinatorBridgePresenterDelegate, SpaceChildRoomDetailBridgePresenterDelegate, RoomContextActionServiceDelegate, RecentCellContextMenuProviderDelegate>
{
    // Tell whether a recents refresh is pending (suspended during editing mode).
    BOOL isRefreshPending;
    
    // Recents drag and drop management
    UILongPressGestureRecognizer *longPressGestureRecognizer;
    UIImageView *cellSnapshot;
    NSIndexPath* movingCellPath;
    MXRoom* movingRoom;
    
    NSIndexPath* lastPotentialCellPath;
    
    // Observe UIApplicationDidEnterBackgroundNotification to cancel editing mode when app leaves the foreground state.
    __weak id UIApplicationDidEnterBackgroundNotificationObserver;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    __weak id kAppDelegateDidTapStatusBarNotificationObserver;
    
    // Observe kMXNotificationCenterDidUpdateRules to update missed messages counts.
    __weak id kMXNotificationCenterDidUpdateRulesObserver;
    
    MXHTTPOperation *currentRequest;
    
    // The fake search bar displayed at the top of the recents table. We switch on the actual search bar (self.recentsSearchBar)
    // when the user selects it.
    UISearchBar *tableSearchBar;
    
    // Flag indicating whether the view controller is (at least partially) visible and not dissapearing
    BOOL isViewVisible;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    __weak id kThemeServiceDidChangeThemeNotificationObserver;
    
    // Cancel handler of any ongoing loading indicator
    UserIndicatorCancel loadingIndicatorCancel;
}

@property (nonatomic, strong) CreateRoomCoordinatorBridgePresenter *createRoomCoordinatorBridgePresenter;

@property (nonatomic, strong) RoomsDirectoryCoordinatorBridgePresenter *roomsDirectoryCoordinatorBridgePresenter;

@property (nonatomic, strong) ExploreRoomCoordinatorBridgePresenter *exploreRoomsCoordinatorBridgePresenter;

@property (nonatomic, strong) SpaceFeatureUnavailablePresenter *spaceFeatureUnavailablePresenter;

@property (nonatomic, strong) CustomSizedPresentationController *customSizedPresentationController;

@property (nonatomic, strong) RoomNotificationSettingsCoordinatorBridgePresenter *roomNotificationSettingsCoordinatorBridgePresenter;

@property (nonatomic, strong) SpaceChildRoomDetailBridgePresenter *spaceChildPresenter;

@end

@implementation RecentsViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([RecentsViewController class])
                          bundle:[NSBundle bundleForClass:[RecentsViewController class]]];
}

+ (instancetype)recentListViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([RecentsViewController class])
                                          bundle:[NSBundle bundleForClass:[RecentsViewController class]]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // Enable the search bar in the recents table, and remove the search option from the navigation bar.
    _enableSearchBar = YES;
    self.enableBarButtonSearch = NO;
    
    _enableDragging = NO;
    
    _enableStickyHeaders = NO;
    _stickyHeaderHeight = 30.0;
    
    // Create the fake search bar
    tableSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 600, 44)];
    tableSearchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    tableSearchBar.showsCancelButton = NO;
    tableSearchBar.placeholder = [VectorL10n searchFilterPlaceholder];
    [tableSearchBar setImage:AssetImages.filterOff.image
            forSearchBarIcon:UISearchBarIconSearch
                       state:UIControlStateNormal];

    tableSearchBar.delegate = self;
    
    displayedSectionHeaders = [NSMutableArray array];
    
    _contextMenuProvider = [RecentCellContextMenuProvider new];
    self.contextMenuProvider.serviceDelegate = self;
    self.contextMenuProvider.menuProviderDelegate = self;

    // Set itself as delegate by default.
    self.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.recentsTableView.accessibilityIdentifier = @"RecentsVCTableView";
    
    // Register here the customized cell view class used to render recents
    [self.recentsTableView registerNib:RecentTableViewCell.nib forCellReuseIdentifier:RecentTableViewCell.defaultReuseIdentifier];
    [self.recentsTableView registerNib:InviteRecentTableViewCell.nib forCellReuseIdentifier:InviteRecentTableViewCell.defaultReuseIdentifier];
    
    // Register key backup banner cells
    [self.recentsTableView registerNib:SecureBackupBannerCell.nib forCellReuseIdentifier:SecureBackupBannerCell.defaultReuseIdentifier];

    // Register key verification banner cells
    [self.recentsTableView registerNib:CrossSigningSetupBannerCell.nib forCellReuseIdentifier:CrossSigningSetupBannerCell.defaultReuseIdentifier];

    [self.recentsTableView registerClass:SectionHeaderView.class
      forHeaderFooterViewReuseIdentifier:SectionHeaderView.defaultReuseIdentifier];
    
    // Hide line separators of empty cells
    self.recentsTableView.tableFooterView = [[UIView alloc] init];
    
    // Apply dragging settings
    self.enableDragging = _enableDragging;
    
    MXWeakify(self);
    
    // Observe UIApplicationDidEnterBackgroundNotification to refresh bubbles when app leaves the foreground state.
    UIApplicationDidEnterBackgroundNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        // Leave potential editing mode
        [self cancelEditionMode:self->isRefreshPending];
        
    }];
    
    self.recentsSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.recentsSearchBar.placeholder = [VectorL10n searchFilterPlaceholder];
    [self.recentsSearchBar setImage:AssetImages.filterOff.image
                   forSearchBarIcon:UISearchBarIconSearch
                              state:UIControlStateNormal];

    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    // Use the primary bg color for the recents table view in plain style.
    self.recentsTableView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.recentsTableView.separatorColor = ThemeService.shared.theme.lineBreakColor;
    topview.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    self.view.backgroundColor = ThemeService.shared.theme.backgroundColor;

    [ThemeService.shared.theme applyStyleOnSearchBar:tableSearchBar];
    [ThemeService.shared.theme applyStyleOnSearchBar:self.recentsSearchBar];

    // Force table refresh
    [self.recentsTableView reloadData];
    
    [self.emptyView updateWithTheme:ThemeService.shared.theme];

    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)destroy
{
    [super destroy];
    
    longPressGestureRecognizer = nil;
    
    if (currentRequest)
    {
        [currentRequest cancel];
        currentRequest = nil;
    }
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    if (UIApplicationDidEnterBackgroundNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationDidEnterBackgroundNotificationObserver];
        UIApplicationDidEnterBackgroundNotificationObserver = nil;
    }
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.recentsTableView.editing = editing;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    isViewVisible = YES;
    
    [self.screenTracker trackScreen];

    // Reset back user interactions
    self.userInteractionEnabled = YES;
    
    // Deselect the current selected row, it will be restored on viewDidAppear (if any)
    NSIndexPath *indexPath = [self.recentsTableView indexPathForSelectedRow];
    if (indexPath)
    {
        [self.recentsTableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    MXWeakify(self);
    
    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        [self scrollToTop:YES];
        
    }];
    
    // Observe kMXNotificationCenterDidUpdateRules to refresh missed messages counts
    kMXNotificationCenterDidUpdateRulesObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterDidUpdateRules object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        MXStrongifyAndReturnIfNil(self);
        
        [self refreshRecentsTable];
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    isViewVisible = NO;
    
    // Leave potential editing mode
    [self cancelEditionMode:NO];
    
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }
    
    if (kMXNotificationCenterDidUpdateRulesObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXNotificationCenterDidUpdateRulesObserver];
        kMXNotificationCenterDidUpdateRulesObserver = nil;
    }
    
    [self stopActivityIndicator];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Release the current selected item (if any) except if the second view controller is still visible.
    if (self.splitViewController.isCollapsed)
    {
        // Release the current selected room (if any).
        [[AppDelegate theDelegate].masterTabBarController releaseSelectedItem];
    }
    else
    {
        // In case of split view controller where the primary and secondary view controllers are displayed side-by-side onscreen,
        // the selected room (if any) is highlighted.
        [self refreshCurrentSelectedCell:YES];
    }

    if (self.recentsDataSource)
    {
        [self refreshRecentsTable];
        [self showEmptyViewIfNeeded];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self refreshStickyHeadersContainersHeight];
        
    });
}

#pragma mark - Override MXKRecentListViewController

- (void)refreshRecentsTable
{
    if (!self.recentsUpdateEnabled)
    {
        isRefreshNeeded = YES;
        return;
    }
    
    isRefreshNeeded = NO;
    
    // Refresh the tabBar icon badges
    if (!BuildSettings.newAppLayoutEnabled)
    {
        // Refresh the tabBar icon badges
        [[AppDelegate theDelegate].masterTabBarController refreshTabBarBadges];
    }
    
    // do not refresh if there is a pending recent drag and drop
    if (movingCellPath)
    {
        return;
    }
    
    isRefreshPending = NO;
    
    if (editedRoomId)
    {
        // Check whether the user didn't leave the room
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (room)
        {
            isRefreshPending = YES;
            return;
        }
        else
        {
            // Cancel the editing mode, a new refresh will be triggered.
            [self cancelEditionMode:YES];
            return;
        }
    }
    
    // Force reset existing sticky headers if any
    [self resetStickyHeaders];
    
    [self.recentsTableView reloadData];
    
    // Check conditions to display the fake search bar into the table header
    if (_enableSearchBar && self.recentsSearchBar.isHidden && self.recentsTableView.tableHeaderView == nil)
    {
        // Add the search bar by hiding it by default.
        self.recentsTableView.tableHeaderView = tableSearchBar;
        self.recentsTableView.contentOffset = CGPointMake(0, self.recentsTableView.contentOffset.y + tableSearchBar.frame.size.height);
    }
    
    if (_shouldScrollToTopOnRefresh)
    {
        [self scrollToTop:NO];
        _shouldScrollToTopOnRefresh = NO;
    }
    
    [self prepareStickyHeaders];
    
    // In case of split view controller where the primary and secondary view controllers are displayed side-by-side on screen,
    // the selected room (if any) is updated.
    if (!self.splitViewController.isCollapsed)
    {
        [self refreshCurrentSelectedCell:NO];
    }
}

- (void)hideSearchBar:(BOOL)hidden
{
    [super hideSearchBar:hidden];
    
    if (!hidden)
    {
        // Remove the fake table header view if any
        self.recentsTableView.tableHeaderView = nil;
        self.recentsTableView.contentInset = UIEdgeInsetsZero;
    }
}

#pragma mark -

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    // Update here the index of the current selected cell (if any) - Useful in landscape mode with split view controller.
    NSIndexPath *currentSelectedCellIndexPath = nil;
    MasterTabBarController *masterTabBarController = [AppDelegate theDelegate].masterTabBarController;
    if (masterTabBarController.selectedRoomId)
    {
        // Look for the rank of this selected room in displayed recents
        currentSelectedCellIndexPath = [self.dataSource cellIndexPathWithRoomId:masterTabBarController.selectedRoomId andMatrixSession:masterTabBarController.selectedRoomSession];
    }
    
    if (currentSelectedCellIndexPath)
    {
        // Select the right row
        [self.recentsTableView selectRowAtIndexPath:currentSelectedCellIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        
        if (forceVisible)
        {
            // Scroll table view to make the selected row appear at second position
            NSInteger topCellIndexPathRow = currentSelectedCellIndexPath.row ? currentSelectedCellIndexPath.row - 1: currentSelectedCellIndexPath.row;
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:topCellIndexPathRow inSection:currentSelectedCellIndexPath.section];
            if ([self.recentsTableView vc_hasIndexPath:indexPath])
            {
                [self.recentsTableView scrollToRowAtIndexPath:indexPath
                                             atScrollPosition:UITableViewScrollPositionTop
                                                     animated:NO];
            }
        }
    }
    else
    {
        NSIndexPath *indexPath = [self.recentsTableView indexPathForSelectedRow];
        if (indexPath)
        {
            [self.recentsTableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

- (void)cancelEditionMode:(BOOL)forceRefresh
{
    if (self.recentsTableView.isEditing || self.isEditing)
    {
        // Leave editing mode first
        isRefreshPending = forceRefresh;
        [self setEditing:NO];
    }
    else
    {
        // Clean
        editedRoomId = nil;
        
        if (forceRefresh)
        {
            [self refreshRecentsTable];
        }
    }
}

- (void)joinRoom:(MXRoom*)room completion:(void(^)(BOOL succeed))completion
{
    [room join:^{
        // `recentsTableView` will be reloaded `roomChangeMembershipStateDataSourceDidChangeRoomMembershipState` function
        
        if (completion)
        {
            completion(YES);
        }
        
    } failure:^(NSError * _Nonnull error) {
        MXLogDebug(@"[RecentsViewController] Failed to join an invited room (%@)", room.roomId);
        [self presentRoomJoinFailedAlertForError:error completion:^{
            if (completion)
            {
                completion(NO);
            }
        }];
    }];
}

- (void)leaveRoom:(MXRoom*)room completion:(void(^)(BOOL succeed))completion
{
    // Decline the invitation
    [room leave:^{
        
        // `recentsTableView` will be reloaded `roomChangeMembershipStateDataSourceDidChangeRoomMembershipState` function
        
        if (completion)
        {
            completion(YES);
        }
    } failure:^(NSError * _Nonnull error) {
        MXLogDebug(@"[RecentsViewController] Failed to reject an invited room (%@)", room.roomId);
        [[AppDelegate theDelegate] showErrorAsAlert:error];
        
        if (completion)
        {
            completion(NO);
        }
    }];
}

- (void)presentRoomJoinFailedAlertForError:(NSError*)error completion:(void(^)(void))completion
{
    MXWeakify(self);
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    if ([msg isEqualToString:@"No known servers"])
    {
        // minging kludge until https://matrix.org/jira/browse/SYN-678 is fixed
        // 'Error when trying to join an empty room should be more explicit'
        msg = [VectorL10n roomErrorJoinFailedEmptyRoom];
    }
    
    [self->currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:[VectorL10n roomErrorJoinFailedTitle]
                                                                        message:msg
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [errorAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * action) {
        MXStrongifyAndReturnIfNil(self);
        self->currentAlert = nil;
        
        if (completion)
        {
            completion();
        }
    }]];
    
    [self presentViewController:errorAlert animated:YES completion:nil];
    currentAlert = errorAlert;
}

#pragma mark - Sticky Headers

- (void)setEnableStickyHeaders:(BOOL)enableStickyHeaders
{
    _enableStickyHeaders = enableStickyHeaders;
    
    // Refresh the table display if it is already rendered.
    if (self.recentsTableView.contentSize.height)
    {
        [self refreshRecentsTable];
    }
}

- (void)setStickyHeaderHeight:(CGFloat)stickyHeaderHeight
{
    if (_stickyHeaderHeight != stickyHeaderHeight)
    {
        _stickyHeaderHeight = stickyHeaderHeight;
        
        // Force a sticky headers refresh
        self.enableStickyHeaders = _enableStickyHeaders;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForStickyHeaderInSection:(NSInteger)section
{
    // Return the section header by default.
    return [self tableView:tableView viewForHeaderInSection:section];
}

- (void)resetStickyHeaders
{
    // Release sticky header
    _stickyHeadersTopContainerHeightConstraint.constant = 0;
    _stickyHeadersBottomContainerHeightConstraint.constant = 0;
    
    for (UIView *view in _stickyHeadersTopContainer.subviews)
    {
        [view removeFromSuperview];
    }
    for (UIView *view in _stickyHeadersBottomContainer.subviews)
    {
        [view removeFromSuperview];
    }
    
    [displayedSectionHeaders removeAllObjects];
    
    self.recentsTableView.contentInset = UIEdgeInsetsZero;
}

- (void)prepareStickyHeaders
{
    // We suppose here [resetStickyHeaders] has been already called if need.
    
    NSInteger sectionsCount = self.recentsTableView.numberOfSections;
    
    if (self.enableStickyHeaders && sectionsCount)
    {
        NSUInteger topContainerOffset = 0;
        NSUInteger bottomContainerOffset = 0;
        CGRect frame;
        
        UIView *stickyHeader = [self viewForStickyHeaderInSection:0 withSwipeGestureRecognizerInDirection:UISwipeGestureRecognizerDirectionDown];
        frame = stickyHeader.frame;
        frame.origin.y = topContainerOffset;
        stickyHeader.frame = frame;
        [self.stickyHeadersTopContainer addSubview:stickyHeader];
        topContainerOffset = stickyHeader.frame.size.height;
        
        for (NSUInteger index = 1; index < sectionsCount; index++)
        {
            stickyHeader = [self viewForStickyHeaderInSection:index withSwipeGestureRecognizerInDirection:UISwipeGestureRecognizerDirectionDown];
            frame = stickyHeader.frame;
            frame.origin.y = topContainerOffset;
            stickyHeader.frame = frame;
            [self.stickyHeadersTopContainer addSubview:stickyHeader];
            topContainerOffset += frame.size.height;
            
            stickyHeader = [self viewForStickyHeaderInSection:index withSwipeGestureRecognizerInDirection:UISwipeGestureRecognizerDirectionUp];
            frame = stickyHeader.frame;
            frame.origin.y = bottomContainerOffset;
            stickyHeader.frame = frame;
            [self.stickyHeadersBottomContainer addSubview:stickyHeader];
            bottomContainerOffset += frame.size.height;
        }
        
        [self refreshStickyHeadersContainersHeight];
    }
}

- (UIView *)viewForStickyHeaderInSection:(NSInteger)section withSwipeGestureRecognizerInDirection:(UISwipeGestureRecognizerDirection)swipeDirection
{
    UIView *stickyHeader = [self tableView:self.recentsTableView viewForStickyHeaderInSection:section];
    stickyHeader.tag = section;
    stickyHeader.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    // Remove existing gesture recognizers
    while (stickyHeader.gestureRecognizers.count)
    {
        UIGestureRecognizer *gestureRecognizer = stickyHeader.gestureRecognizers.lastObject;
        [stickyHeader removeGestureRecognizer:gestureRecognizer];
    }
    
    // Handle tap gesture, the section is moved up on the tap.
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnSectionHeader:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [stickyHeader addGestureRecognizer:tap];
    
    // Handle vertical swipe gesture with the provided direction, by default the section will be moved up on this swipe.
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeOnSectionHeader:)];
    [swipe setNumberOfTouchesRequired:1];
    [swipe setDirection:swipeDirection];
    [stickyHeader addGestureRecognizer:swipe];
    
    return stickyHeader;
}

- (void)didTapOnSectionHeader:(UIGestureRecognizer*)gestureRecognizer
{
    UIView *view = gestureRecognizer.view;
    NSInteger section = view.tag;
    
    // Scroll to the top of this section
    if ([self.recentsTableView numberOfRowsInSection:section] > 0)
    {
        [self.recentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)didSwipeOnSectionHeader:(UISwipeGestureRecognizer*)gestureRecognizer
{
    UIView *view = gestureRecognizer.view;
    NSInteger section = view.tag;
    
    if ([self.recentsTableView numberOfRowsInSection:section] > 0)
    {
        // Check whether the first cell of this section is already visible.
        UITableViewCell *firstSectionCell = [self.recentsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        if (firstSectionCell)
        {
            // Scroll to the top of the previous section (if any)
            if (section && [self.recentsTableView numberOfRowsInSection:(section - 1)] > 0)
            {
                [self.recentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:(section - 1)] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        }
        else
        {
            // Scroll to the top of this section
            [self.recentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
}

- (void)refreshStickyHeadersContainersHeight
{
    if (_enableStickyHeaders)
    {
        NSUInteger lowestSectionInBottomStickyHeader = NSNotFound;
        CGFloat containerHeight;
        
        // Retrieve the first header actually visible in the recents table view.
        // Caution: In some cases like the screen rotation, some displayed section headers are temporarily not visible.
        UIView *firstDisplayedSectionHeader;
        for (UIView *header in displayedSectionHeaders)
        {
            if (header.frame.origin.y + header.frame.size.height > self.recentsTableView.contentOffset.y)
            {
                firstDisplayedSectionHeader = header;
                break;
            }
        }
        
        if (firstDisplayedSectionHeader)
        {
            // Initialize the top container height by considering the headers which are before the first visible section header.
            containerHeight = 0;
            for (UIView *header in _stickyHeadersTopContainer.subviews)
            {
                if (header.tag < firstDisplayedSectionHeader.tag)
                {
                    containerHeight += self.stickyHeaderHeight;
                }
            }
            
            // Check whether the first visible section header is partially hidden.
            if (firstDisplayedSectionHeader.frame.origin.y < self.recentsTableView.contentOffset.y)
            {
                // Compute the height of the hidden part.
                CGFloat delta = self.recentsTableView.contentOffset.y - firstDisplayedSectionHeader.frame.origin.y;
                
                if (delta < self.stickyHeaderHeight)
                {
                    containerHeight += delta;
                }
                else
                {
                    containerHeight += self.stickyHeaderHeight;
                }
            }
            
            if (containerHeight)
            {
                self.stickyHeadersTopContainerHeightConstraint.constant = containerHeight;
                self.recentsTableView.contentInset = UIEdgeInsetsMake(-self.stickyHeaderHeight, 0, 0, 0);
            }
            else
            {
                self.stickyHeadersTopContainerHeightConstraint.constant = 0;
                self.recentsTableView.contentInset = UIEdgeInsetsZero;
            }
            
            // Look for the lowest section index visible in the bottom sticky headers.
            CGFloat maxVisiblePosY = self.recentsTableView.contentOffset.y + self.recentsTableView.frame.size.height - self.recentsTableView.adjustedContentInset.bottom;
            UIView *lastDisplayedSectionHeader = displayedSectionHeaders.lastObject;
            
            for (UIView *header in _stickyHeadersBottomContainer.subviews)
            {
                if (header.tag > lastDisplayedSectionHeader.tag)
                {
                    maxVisiblePosY -= self.stickyHeaderHeight;
                }
            }
            
            for (NSInteger index = displayedSectionHeaders.count; index > 0;)
            {
                lastDisplayedSectionHeader = displayedSectionHeaders[--index];
                if (lastDisplayedSectionHeader.frame.origin.y + self.stickyHeaderHeight > maxVisiblePosY)
                {
                    maxVisiblePosY -= self.stickyHeaderHeight;
                }
                else
                {
                    lowestSectionInBottomStickyHeader = lastDisplayedSectionHeader.tag + 1;
                    break;
                }
            }
        }
        else
        {
            // Handle here the case where no section header is currently displayed in the table.
            // No more than one section is then displayed, we retrieve this section by checking the first visible cell.
            NSIndexPath *firstCellIndexPath = [self.recentsTableView indexPathForRowAtPoint:CGPointMake(0, self.recentsTableView.contentOffset.y)];
            if (firstCellIndexPath)
            {
                NSInteger section = firstCellIndexPath.section;
                
                // Refresh top container of the sticky headers
                CGFloat containerHeight = 0;
                for (UIView *header in _stickyHeadersTopContainer.subviews)
                {
                    if (header.tag <= section)
                    {
                        containerHeight += header.frame.size.height;
                    }
                }
                
                self.stickyHeadersTopContainerHeightConstraint.constant = containerHeight;
                if (containerHeight)
                {
                    self.recentsTableView.contentInset = UIEdgeInsetsMake(-self.stickyHeaderHeight, 0, 0, 0);
                }
                else
                {
                    self.recentsTableView.contentInset = UIEdgeInsetsZero;
                }
                
                // Set the lowest section index visible in the bottom sticky headers.
                lowestSectionInBottomStickyHeader = section + 1;
            }
        }
        
        // Update here the height of the bottom container of the sticky headers thanks to lowestSectionInBottomStickyHeader.
        containerHeight = 0;
        CGRect bounds = _stickyHeadersBottomContainer.frame;
        bounds.origin.y = 0;
        
        for (UIView *header in _stickyHeadersBottomContainer.subviews)
        {
            if (header.tag > lowestSectionInBottomStickyHeader)
            {
                containerHeight += self.stickyHeaderHeight;
            }
            else if (header.tag == lowestSectionInBottomStickyHeader)
            {
                containerHeight += self.stickyHeaderHeight;
                bounds.origin.y = header.frame.origin.y;
            }
        }
        
        if (self.stickyHeadersBottomContainerHeightConstraint.constant != containerHeight)
        {
            self.stickyHeadersBottomContainerHeightConstraint.constant = containerHeight;
            self.stickyHeadersBottomContainer.bounds = bounds;
        }
    }
}

#pragma mark - Internal methods

- (void)showPublicRoomsDirectory
{
    // Here the recents view controller is displayed inside a unified search view controller.
    // Sanity check
    if (self.parentViewController && [self.parentViewController isKindOfClass:UnifiedSearchViewController.class])
    {
        // Show the directory screen
        [((UnifiedSearchViewController*)self.parentViewController) showPublicRoomsDirectory];
    }
}

- (void)showRoomWithRoomId:(NSString*)roomId inMatrixSession:(MXSession*)matrixSession
{
    [self showRoomWithRoomId:roomId andAutoJoinInvitedRoom:false inMatrixSession:matrixSession];
}

- (void)showRoomWithRoomId:(NSString*)roomId andAutoJoinInvitedRoom:(BOOL)autoJoinInvitedRoom inMatrixSession:(MXSession*)matrixSession
{
    MXRoom *room = [matrixSession roomWithRoomId:roomId];
    if (room.summary.membership == MXMembershipInvite)
    {
        Analytics.shared.joinedRoomTrigger = AnalyticsJoinedRoomTriggerInvite;
    }

    // Avoid multiple openings of rooms
    self.userInteractionEnabled = NO;

    // Do not stack views when showing room
    ScreenPresentationParameters *presentationParameters = [[ScreenPresentationParameters alloc] initWithRestoreInitialDisplay:NO stackAboveVisibleViews:NO];
    
    RoomNavigationParameters *parameters = [[RoomNavigationParameters alloc] initWithRoomId:roomId
                                                                                    eventId:nil
                                                                                  mxSession:matrixSession
                                                                           threadParameters:nil
                                                                     presentationParameters:presentationParameters
                                                                        autoJoinInvitedRoom:autoJoinInvitedRoom];
    
    [[AppDelegate theDelegate] showRoomWithParameters:parameters completion:^{
        self.userInteractionEnabled = YES;
    }];
}

- (void)showRoomPreviewWithData:(RoomPreviewData*)roomPreviewData
{
    Analytics.shared.joinedRoomTrigger = AnalyticsJoinedRoomTriggerRoomDirectory;

    // Do not stack views when showing room
    ScreenPresentationParameters *presentationParameters = [[ScreenPresentationParameters alloc] initWithRestoreInitialDisplay:NO stackAboveVisibleViews:NO sender:nil sourceView:nil];
    
    RoomPreviewNavigationParameters *parameters = [[RoomPreviewNavigationParameters alloc] initWithPreviewData:roomPreviewData presentationParameters:presentationParameters];
    
    [[AppDelegate theDelegate] showRoomPreviewWithParameters:parameters];
}

// Disable UI interactions in this screen while we are going to open another screen.
// Interactions on reset on viewWillAppear.
- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    self.view.userInteractionEnabled = userInteractionEnabled;
}

- (RecentsDataSource*)recentsDataSource
{
    RecentsDataSource* recentsDataSource = nil;
    
    if ([self.dataSource isKindOfClass:[RecentsDataSource class]])
    {
        recentsDataSource = (RecentsDataSource*)self.dataSource;
    }
    
    return recentsDataSource;
}

- (void)showSpaceInviteNotAvailable
{
    if (!self.spaceFeatureUnavailablePresenter)
    {
        self.spaceFeatureUnavailablePresenter = [SpaceFeatureUnavailablePresenter new];
    }
    
    [self.spaceFeatureUnavailablePresenter presentUnavailableFeatureFrom:self animated:YES];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    id<MXKRecentCellDataStoring> cellDataStoring = (id<MXKRecentCellDataStoring> )cellData;
    
    if (cellDataStoring.roomSummary.membership != MXMembershipInvite)
    {
        return RecentTableViewCell.class;
    }
    else
    {
        return InviteRecentTableViewCell.class;
    }
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    Class class = [self cellViewClassForCellData:cellData];
    
    if ([class respondsToSelector:@selector(defaultReuseIdentifier)])
    {
        return [class defaultReuseIdentifier];
    }
    
    return nil;
}

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo
{
    // Handle here user actions on recents for Riot app
    if ([actionIdentifier isEqualToString:kInviteRecentTableViewCellPreviewButtonPressed])
    {
        // Retrieve the invited room
        MXRoom *invitedRoom = userInfo[kInviteRecentTableViewCellRoomKey];
                
        if (invitedRoom.summary.roomType == MXRoomTypeSpace)
        {
            // Indicates that spaces are not supported
            [self showSpaceInviteNotAvailable];
            return;
        }
        
        // Display the room preview
        [self showRoomWithRoomId:invitedRoom.roomId inMatrixSession:invitedRoom.mxSession];
    }
    else if ([actionIdentifier isEqualToString:kInviteRecentTableViewCellAcceptButtonPressed])
    {
        // Retrieve the invited room
        MXRoom *invitedRoom = userInfo[kInviteRecentTableViewCellRoomKey];
                
        if (invitedRoom.summary.roomType == MXRoomTypeSpace)
        {
            // Indicates that spaces are not supported
            [self showSpaceInviteNotAvailable];
            return;
        }
        
        // Accept invitation and display the room
        Analytics.shared.joinedRoomTrigger = AnalyticsJoinedRoomTriggerInvite;
        [self showRoomWithRoomId:invitedRoom.roomId andAutoJoinInvitedRoom:true inMatrixSession:invitedRoom.mxSession];
    }
    else if ([actionIdentifier isEqualToString:kInviteRecentTableViewCellDeclineButtonPressed])
    {
        // Retrieve the invited room
        MXRoom *invitedRoom = userInfo[kInviteRecentTableViewCellRoomKey];
        
        [self cancelEditionMode:isRefreshPending];
        
        // Decline the invitation
        [self leaveRoom:invitedRoom completion:nil];
    }
    else
    {
        // Keep default implementation for other actions if any
        if ([super respondsToSelector:@selector(cell:didRecognizeAction:userInfo:)])
        {
            [super dataSource:dataSource didRecognizeAction:actionIdentifier inCell:cell userInfo:userInfo];
        }
    }
}

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    if (!self.recentsUpdateEnabled)
    {
        [super dataSource:dataSource didCellChange:changes];
        return;
    }

    if ([changes isKindOfClass:NSIndexPath.class])
    {
        NSIndexPath *indexPath = (NSIndexPath *)changes;
        UITableViewCell *cell = [self.recentsTableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:TableViewCellWithCollectionView.class])
        {
            MXLogDebug(@"[RecentsViewController]: Reloading nested collection view cell in section %ld", indexPath.section);
            
            TableViewCellWithCollectionView *collectionViewCell = (TableViewCellWithCollectionView *)cell;
            [collectionViewCell.collectionView reloadData];

            CGRect headerFrame = [self.recentsTableView rectForHeaderInSection:indexPath.section];
            UIView *headerView = [self.recentsTableView headerViewForSection:indexPath.section];
            UIView *updatedHeaderView = [self.dataSource viewForHeaderInSection:indexPath.section withFrame:headerFrame inTableView:self.recentsTableView];
            if ([headerView isKindOfClass:SectionHeaderView.class]
                && [updatedHeaderView isKindOfClass:SectionHeaderView.class])
            {
                SectionHeaderView *sectionHeaderView = (SectionHeaderView *)headerView;
                SectionHeaderView *updatedSectionHeaderView = (SectionHeaderView *)updatedHeaderView;
                sectionHeaderView.headerLabel = updatedSectionHeaderView.headerLabel;
                sectionHeaderView.accessoryView = updatedSectionHeaderView.accessoryView;
                sectionHeaderView.rightAccessoryView = updatedSectionHeaderView.rightAccessoryView;
            }
        }
        else
        {
            // Ideally we would call tableView.reloadSections, but this can lead to crashes if multiple sections need such an update and they
            // vertically depend on each other. It is unclear whether this is due to further issues in the data model (e.g. data race)
            // or some undocumented table view behavior. To avoid this we reload the entire table view, even if this means reloading
            // multiple times for several section updates.
            MXLogDebug(@"[RecentsViewController]: Reloading the entire table view due to updates in section %ld", indexPath.section);
            [self refreshRecentsTable];
        }
    }
    else if (!changes)
    {
        MXLogDebug(@"[RecentsViewController]: Reloading the entire table view");
        [self refreshRecentsTable];
    }
    
    if (!BuildSettings.newAppLayoutEnabled)
    {
        // Since we've enabled room list pagination, `refreshRecentsTable` not called in this case.
        // Refresh tab bar badges separately.
        [[AppDelegate theDelegate].masterTabBarController refreshTabBarBadges];
    }
    
    [self showEmptyViewIfNeeded];

    if (dataSource.state == MXKDataSourceStateReady)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:RecentsViewControllerDataReadyNotification
                                                            object:self];
    }
}

#pragma mark - Swipe actions

- (void)leaveEditedRoom
{
    if (editedRoomId)
    {
        NSString *currentRoomId = editedRoomId;
        
        __weak typeof(self) weakSelf = self;
        
        NSString *title, *message;
        if ([self.mainSession roomWithRoomId:currentRoomId].isDirect)
        {
            title = [VectorL10n roomParticipantsLeavePromptTitleForDm];
            message = [VectorL10n roomParticipantsLeavePromptMsgForDm];
        }
        else
        {
            title = [VectorL10n roomParticipantsLeavePromptTitle];
            message = [VectorL10n roomParticipantsLeavePromptMsg];
        }
        
        // confirm leave
        UIAlertController *leavePrompt = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
        
        [leavePrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                           }
                                                           
                                                       }]];
        
        [leavePrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n leave]
                                                        style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                             
                                                             if (weakSelf)
                                                             {
                                                                 typeof(self) self = weakSelf;
                                                                 self->currentAlert = nil;
                                                                 
                                                                 // Check whether the user didn't leave the room yet
                                                                 // TODO: Handle multi-account
                                                                 MXRoom *room = [self.mainSession roomWithRoomId:currentRoomId];
                                                                 if (room)
                                                                 {
                                                                     [self startActivityIndicatorWithLabel:[VectorL10n roomParticipantsLeaveProcessing]];
                                                                     // cancel pending uploads/downloads
                                                                     // they are useless by now
                                                                     [MXMediaManager cancelDownloadsInCacheFolder:room.roomId];
                                                                     
                                                                     // TODO GFO cancel pending uploads related to this room
                                                                     
                                                                     MXLogDebug(@"[RecentsViewController] Leave room (%@)", room.roomId);
                                                                     
                                                                     [room leave:^{
                                                                         
                                                                         if (weakSelf)
                                                                         {
                                                                             typeof(self) self = weakSelf;
                                                                             [self stopActivityIndicator];
                                                                             [self.userIndicatorStore presentSuccessWithLabel:[VectorL10n roomParticipantsLeaveSuccess]];
                                                                             // Force table refresh
                                                                             [self cancelEditionMode:YES];
                                                                         }
                                                                         
                                                                     } failure:^(NSError *error) {
                                                                         
                                                                         MXLogDebug(@"[RecentsViewController] Failed to leave room");
                                                                         if (weakSelf)
                                                                         {
                                                                             typeof(self) self = weakSelf;
                                                                             // Notify the end user
                                                                             NSString *userId = room.mxSession.myUser.userId;
                                                                             [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification
                                                                                                                                 object:error
                                                                                                                               userInfo:userId ? @{kMXKErrorUserIdKey: userId} : nil];
                                                                             
                                                                             [self stopActivityIndicator];
                                                                             
                                                                             // Leave editing mode
                                                                             [self cancelEditionMode:self->isRefreshPending];
                                                                         }
                                                                         
                                                                     }];
                                                                 }
                                                                 else
                                                                 {
                                                                     // Leave editing mode
                                                                     [self cancelEditionMode:self->isRefreshPending];
                                                                 }
                                                             }
                                                             
                                                         }]];
        
        [leavePrompt mxk_setAccessibilityIdentifier:@"LeaveEditedRoomAlert"];
        [self presentViewController:leavePrompt animated:YES completion:nil];
        currentAlert = leavePrompt;
    }
}

- (void)updateEditedRoomTag:(NSString*)tag
{
    if (editedRoomId)
    {
        // Check whether the user didn't leave the room
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (room)
        {
            [self startActivityIndicator];
            
            [room setRoomTag:tag completion:^{
                
                [self stopActivityIndicator];
                
                // Force table refresh
                [self cancelEditionMode:YES];
                
            }];
        }
        else
        {
            // Leave editing mode
            [self cancelEditionMode:isRefreshPending];
        }
    }
}

- (void)makeDirectEditedRoom:(BOOL)isDirect
{
    if (editedRoomId)
    {
        // Check whether the user didn't leave the room
        // TODO: handle multi-account
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (room)
        {
            [self startActivityIndicator];
            
            MXWeakify(self);
            
            [room setIsDirect:isDirect withUserId:nil success:^{
                
                MXStrongifyAndReturnIfNil(self);
                
                [self stopActivityIndicator];
                // Leave editing mode
                [self cancelEditionMode:self->isRefreshPending];
                
            } failure:^(NSError *error) {
                
                MXStrongifyAndReturnIfNil(self);
                
                [self stopActivityIndicator];
                
                MXLogDebug(@"[RecentsViewController] Failed to update direct tag of the room (%@)", self->editedRoomId);
                
                // Notify the end user
                NSString *userId = self.mainSession.myUser.userId; // TODO: handle multi-account
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification
                                                                    object:error
                                                                  userInfo:userId ? @{kMXKErrorUserIdKey: userId} : nil];
                
                // Leave editing mode
                [self cancelEditionMode:self->isRefreshPending];
                
            }];
        }
        else
        {
            // Leave editing mode
            [self cancelEditionMode:isRefreshPending];
        }
    }
}

- (void)changeEditedRoomNotificationSettings
{
    if (editedRoomId)
    {
        // Check whether the user didn't leave the room
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (room)
        {
           // navigate
            self.roomNotificationSettingsCoordinatorBridgePresenter = [[RoomNotificationSettingsCoordinatorBridgePresenter alloc] initWithRoom:room];
            self.roomNotificationSettingsCoordinatorBridgePresenter.delegate = self;
            [self.roomNotificationSettingsCoordinatorBridgePresenter presentFrom:self animated:YES];
        }
        [self cancelEditionMode:isRefreshPending];
    }
}

- (void)muteEditedRoomNotifications:(BOOL)mute
{
    if (editedRoomId)
    {
        // Check whether the user didn't leave the room
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (room)
        {
            [self startActivityIndicator];

            if (mute)
            {
                [room mentionsOnly:^{

                    [self stopActivityIndicator];

                    // Leave editing mode
                    [self cancelEditionMode:self->isRefreshPending];

                }];
            }
            else
            {
                [room allMessages:^{

                    [self stopActivityIndicator];

                    // Leave editing mode
                    [self cancelEditionMode:self->isRefreshPending];

                }];
            }
        }
        else
        {
            // Leave editing mode
            [self cancelEditionMode:isRefreshPending];
        }
    }
}

#pragma mark - UITableView delegate

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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *sectionHeader = [super tableView:tableView viewForHeaderInSection:section];
    sectionHeader.tag = section;
    
    while (sectionHeader.gestureRecognizers.count)
    {
        UIGestureRecognizer *gestureRecognizer = sectionHeader.gestureRecognizers.lastObject;
        [sectionHeader removeGestureRecognizer:gestureRecognizer];
    }
    
    // Handle tap gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnSectionHeader:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [sectionHeader addGestureRecognizer:tap];
    
    return sectionHeader;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [self.recentsTableView cellForRowAtIndexPath:indexPath];
    
    if ([cell isKindOfClass:[InviteRecentTableViewCell class]])
    {
        id<MXKRecentCellDataStoring> cellData = [self.dataSource cellDataAtIndexPath:indexPath];

        // Retrieve the invited room
        
        if (cellData.roomSummary.roomType == MXRoomTypeSpace)
        {
            // Indicates that spaces are not supported
            [self showSpaceInviteNotAvailable];
        }
        // Check if can show preview for the invited room 
        else if ([self canShowRoomPreviewFor:cellData.roomSummary])
        {
            // Display the room preview
            [self showRoomWithRoomId:cellData.roomIdentifier inMatrixSession:cellData.mxSession];
        }
        else
        {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
    else if ([cell isKindOfClass:[DirectoryRecentTableViewCell class]])
    {
        [self showPublicRoomsDirectory];
    }
    else if ([cell isKindOfClass:[RoomIdOrAliasTableViewCell class]])
    {
        NSString *roomIdOrAlias = ((RoomIdOrAliasTableViewCell*)cell).titleLabel.text;
        
        if (roomIdOrAlias.length)
        {
            // Create a permalink to open or preview the room.
            NSString *permalink = [MXTools permalinkToRoom:roomIdOrAlias];
            NSURL *permalinkURL = [NSURL URLWithString:permalink];
            [[AppDelegate theDelegate] handleUniversalLinkURL:permalinkURL];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    else
    {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (_enableStickyHeaders)
    {
        view.tag = section;
        
        UIView *firstDisplayedSectionHeader = displayedSectionHeaders.firstObject;
        
        if (!firstDisplayedSectionHeader || section < firstDisplayedSectionHeader.tag)
        {
            [displayedSectionHeaders insertObject:view atIndex:0];
        }
        else
        {
            [displayedSectionHeaders addObject:view];
        }
        
        [self refreshStickyHeadersContainersHeight];
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (_enableStickyHeaders)
    {
        UIView *firstDisplayedSectionHeader = displayedSectionHeaders.firstObject;
        if (firstDisplayedSectionHeader)
        {
            if (section == firstDisplayedSectionHeader.tag)
            {
                [displayedSectionHeaders removeObjectAtIndex:0];
                
                [self refreshStickyHeadersContainersHeight];
            }
            else
            {
                // This section header is the last displayed one.
                // Add a sanity check in case of the header has been already removed.
                UIView *lastDisplayedSectionHeader = displayedSectionHeaders.lastObject;
                if (section == lastDisplayedSectionHeader.tag)
                {
                    [displayedSectionHeaders removeLastObject];
                    
                    [self refreshStickyHeadersContainersHeight];
                }
            }
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [VectorL10n leave];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.recentsSearchBar)
    {
        [super scrollViewDidScroll:scrollView];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self refreshStickyHeadersContainersHeight];
        
    });
    
    [super scrollViewDidScroll:scrollView];
    
    if (scrollView == self.recentsTableView)
    {
        if (!self.recentsSearchBar.isHidden)
        {
            if (!self.recentsSearchBar.text.length && (scrollView.contentOffset.y + scrollView.adjustedContentInset.top > self.recentsSearchBar.frame.size.height))
            {
                // Hide the search bar
                [self hideSearchBar:YES];
                
                // Refresh display
                [self refreshRecentsTable];
            }
        }
    }
}

#pragma mark - Recents drag & drop management

- (void)setEnableDragging:(BOOL)enableDragging
{
    _enableDragging = enableDragging;
    
    if (_enableDragging && !longPressGestureRecognizer && self.recentsTableView)
    {
        longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onRecentsLongPress:)];
        [self.recentsTableView addGestureRecognizer:longPressGestureRecognizer];
    }
    else if (longPressGestureRecognizer)
    {
        [self.recentsTableView removeGestureRecognizer:longPressGestureRecognizer];
        longPressGestureRecognizer = nil;
    }
}

- (void)onRecentsDragEnd
{
    [cellSnapshot removeFromSuperview];
    cellSnapshot = nil;
    movingCellPath = nil;
    movingRoom = nil;
    
    lastPotentialCellPath = nil;
    ((RecentsDataSource*)self.dataSource).droppingCellIndexPath = nil;
    ((RecentsDataSource*)self.dataSource).hiddenCellIndexPath = nil;
    
    [self.activityIndicator stopAnimating];
}

- (IBAction)onRecentsLongPress:(id)sender
{
    if (sender != longPressGestureRecognizer)
    {
        return;
    }
    
    RecentsDataSource* recentsDataSource = nil;
    
    if ([self.dataSource isKindOfClass:[RecentsDataSource class]])
    {
        recentsDataSource = (RecentsDataSource*)self.dataSource;
    }
    
    // only support RecentsDataSource
    if (!recentsDataSource)
    {
        return;
    }
    
    UIGestureRecognizerState state = longPressGestureRecognizer.state;
    
    // check if there is a moving cell during the long press managemnt
    if ((state != UIGestureRecognizerStateBegan) && !movingCellPath)
    {
        return;
    }
    
    CGPoint location = [longPressGestureRecognizer locationInView:self.recentsTableView];
    
    switch (state)
    {
            // step 1 : display the selected cell
        case UIGestureRecognizerStateBegan:
        {
            NSIndexPath *indexPath = [self.recentsTableView indexPathForRowAtPoint:location];
            
            // check if the cell can be moved
            if (indexPath && [recentsDataSource isDraggableCellAt:indexPath])
            {
                UITableViewCell *cell = [self.recentsTableView cellForRowAtIndexPath:indexPath];
                cell.backgroundColor = ThemeService.shared.theme.backgroundColor;
                
                // snapshot the cell
                UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0);
                [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
                UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                cellSnapshot = [[UIImageView alloc] initWithImage:image];
                recentsDataSource.droppingCellBackGroundView = [[UIImageView alloc] initWithImage:image];
                
                // display the selected cell over the tableview
                CGPoint center = cell.center;
                center.y = location.y;
                cellSnapshot.center = center;
                cellSnapshot.alpha = 0.5f;
                [self.recentsTableView addSubview:cellSnapshot];
                
                // Store the selected room and the original index path of its cell.
                movingCellPath = indexPath;
                movingRoom = [recentsDataSource getRoomAtIndexPath:movingCellPath];
                
                lastPotentialCellPath = indexPath;
                recentsDataSource.droppingCellIndexPath = indexPath;
                recentsDataSource.hiddenCellIndexPath = indexPath;
            }
            break;
        }
            
            // step 2 : the cell must follow the finger
        case UIGestureRecognizerStateChanged:
        {
            CGPoint center = cellSnapshot.center;
            CGFloat halfHeight = cellSnapshot.frame.size.height / 2.0f;
            CGFloat cellTop = location.y - halfHeight;
            CGFloat cellBottom = location.y + halfHeight;
            
            CGPoint contentOffset =  self.recentsTableView.contentOffset;
            CGFloat height = MIN(self.recentsTableView.frame.size.height, self.recentsTableView.contentSize.height);
            CGFloat bottomOffset = contentOffset.y + height;
            
            // check if the moving cell is trying to move under the tableview
            if (cellBottom > self.recentsTableView.contentSize.height)
            {
                // force the cell to stay at the tableview bottom
                location.y = self.recentsTableView.contentSize.height - halfHeight;
            }
            // check if the cell is moving over the displayed tableview bottom
            else if (cellBottom > bottomOffset)
            {
                CGFloat diff = cellBottom - bottomOffset;
                
                // moving down the cell
                location.y -= diff;
                // scroll up the tableview
                contentOffset.y += diff;
            }
            // the moving is tryin to move over the tableview topmost
            else if (cellTop < 0)
            {
                // force to stay in the topmost
                contentOffset.y  = 0;
                location.y = contentOffset.y + halfHeight;
            }
            // the moving cell is displayed over the current scroll top
            else if (cellTop < contentOffset.y)
            {
                CGFloat diff = contentOffset.y - cellTop;
                
                // move up the cell and the table up
                location.y -= diff;
                contentOffset.y -= diff;
            }
            
            // move the cell to follow the user finger
            center.y = location.y;
            cellSnapshot.center = center;
            
            // scroll the tableview if it is required
            if (contentOffset.y != self.recentsTableView.contentOffset.y)
            {
                [self.recentsTableView setContentOffset:contentOffset animated:NO];
            }
            
            NSIndexPath *indexPath = [self.recentsTableView indexPathForRowAtPoint:location];
            
            if (![indexPath isEqual:lastPotentialCellPath])
            {
                if ([recentsDataSource canCellMoveFrom:movingCellPath to:indexPath])
                {
                    [self.recentsTableView beginUpdates];
                    if (recentsDataSource.droppingCellIndexPath && recentsDataSource.hiddenCellIndexPath)
                    {
                        [self.recentsTableView moveRowAtIndexPath:lastPotentialCellPath toIndexPath:indexPath];
                    }
                    else if (indexPath)
                    {
                        [self.recentsTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        [self.recentsTableView deleteRowsAtIndexPaths:@[movingCellPath] withRowAnimation:UITableViewRowAnimationNone];
                    }
                    recentsDataSource.hiddenCellIndexPath = movingCellPath;
                    recentsDataSource.droppingCellIndexPath = indexPath;
                    [self.recentsTableView endUpdates];
                }
                // the cell cannot be moved
                else if (recentsDataSource.droppingCellIndexPath)
                {
                    NSIndexPath* pathToDelete = recentsDataSource.droppingCellIndexPath;
                    NSIndexPath* pathToAdd = recentsDataSource.hiddenCellIndexPath;
                    
                    // remove it
                    [self.recentsTableView beginUpdates];
                    [self.recentsTableView deleteRowsAtIndexPaths:@[pathToDelete] withRowAnimation:UITableViewRowAnimationNone];
                    [self.recentsTableView insertRowsAtIndexPaths:@[pathToAdd] withRowAnimation:UITableViewRowAnimationNone];
                    recentsDataSource.droppingCellIndexPath = nil;
                    recentsDataSource.hiddenCellIndexPath = nil;
                    [self.recentsTableView endUpdates];
                }
                
                lastPotentialCellPath = indexPath;
            }
            
            break;
        }
            
            // step 3 : remove the view
            // and insert when it is possible.
        case UIGestureRecognizerStateEnded:
        {
            [cellSnapshot removeFromSuperview];
            cellSnapshot = nil;
            
            [self.activityIndicator startAnimating];
            
            [recentsDataSource moveRoomCell:movingRoom from:movingCellPath to:lastPotentialCellPath success:^{
                
                [self onRecentsDragEnd];
                
            } failure:^(NSError *error) {
                
                [self onRecentsDragEnd];
                
            }];
            
            break;
        }
            
            // default behaviour
            // remove the cell and cancel the insertion
        default:
        {
            [self onRecentsDragEnd];
            break;
        }
    }
}

#pragma mark - Room handling

- (void)onPlusButtonPressed
{
    __weak typeof(self) weakSelf = self;
    
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n roomRecentsStartChatWith]
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           [self startChat];
                                                       }
                                                       
                                                   }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n roomRecentsCreateEmptyRoom]
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           [self createNewRoom];
                                                       }
                                                       
                                                   }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n roomRecentsJoinRoom]
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           [self joinARoom];
                                                       }
                                                       
                                                   }]];
    
    if (self.mainSession.callManager.supportsPSTN)
    {
        [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n roomOpenDialpad]
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
        
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
            
                                                           [self openDialpad];
                                                       }
        
                                                   }]];
    }

    [actionSheet addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                    style:UIAlertActionStyleCancel
                                                  handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }
                                                       
                                                   }]];
    
    [actionSheet popoverPresentationController].sourceView = plusButtonImageView;
    [actionSheet popoverPresentationController].sourceRect = plusButtonImageView.bounds;
    
    [actionSheet mxk_setAccessibilityIdentifier:@"RecentsVCCreateRoomAlert"];
    [self presentViewController:actionSheet animated:YES completion:nil];
    currentAlert = actionSheet;
}

- (void)openDialpad
{
    DialpadViewController *controller = [DialpadViewController instantiateWithConfiguration:[DialpadConfiguration default]];
    controller.delegate = self;
    self.customSizedPresentationController = [[CustomSizedPresentationController alloc] initWithPresentedViewController:controller presentingViewController:self];
    self.customSizedPresentationController.dismissOnBackgroundTap = NO;
    self.customSizedPresentationController.cornerRadius = 16;
    
    controller.transitioningDelegate = self.customSizedPresentationController;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)dialpadViewControllerDidTapCall:(DialpadViewController *)viewController withPhoneNumber:(NSString *)phoneNumber
{
    if (self.mainSession.callManager && phoneNumber.length > 0)
    {
        [self startActivityIndicator];
        
        [viewController dismissViewControllerAnimated:YES completion:^{
            MXWeakify(self);
            [self.mainSession.callManager placeCallAgainst:phoneNumber withVideo:NO success:^(MXCall * _Nonnull call) {
                MXStrongifyAndReturnIfNil(self);
                [self stopActivityIndicator];
                self.customSizedPresentationController = nil;
                
                //  do nothing extra here. UI will be handled automatically by the CallService.
            } failure:^(NSError * _Nullable error) {
                MXStrongifyAndReturnIfNil(self);
                [self stopActivityIndicator];
            }];
        }];
    }
}

- (void)dialpadViewControllerDidTapClose:(DialpadViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:nil];
    self.customSizedPresentationController = nil;
}

- (void)startChat {
    [self performSegueWithIdentifier:@"presentStartChat" sender:self];
}

- (void)createNewRoom
{
    // Sanity check
    if (self.mainSession)
    {
        CreateRoomCoordinatorParameter *parameters = [[CreateRoomCoordinatorParameter alloc] initWithSession:self.mainSession parentSpace: self.dataSource.currentSpace];
        self.createRoomCoordinatorBridgePresenter = [[CreateRoomCoordinatorBridgePresenter alloc] initWithParameters:parameters];
        self.createRoomCoordinatorBridgePresenter.delegate = self;
        [self.createRoomCoordinatorBridgePresenter presentFrom:self animated:YES];
    }
}

- (void)joinARoom
{
    [self showRoomDirectory];
}

- (void)showRoomDirectory
{
    if (!self.self.mainSession)
    {
        MXLogDebug(@"[RecentsViewController] Fail to show room directory, session is nil");
        return;
    }
    
    if (self.dataSource.currentSpace)
    {
        self.exploreRoomsCoordinatorBridgePresenter = [[ExploreRoomCoordinatorBridgePresenter alloc] initWithSession:self.mainSession spaceId:self.dataSource.currentSpace.spaceId];
        self.exploreRoomsCoordinatorBridgePresenter.delegate = self;
        [self.exploreRoomsCoordinatorBridgePresenter presentFrom:self animated:YES];
    }
    else if (RiotSettings.shared.roomsAllowToJoinPublicRooms)
    {
        self.roomsDirectoryCoordinatorBridgePresenter = [[RoomsDirectoryCoordinatorBridgePresenter alloc] initWithSession:self.mainSession dataSource:[self.recentsDataSource.publicRoomsDirectoryDataSource copy]];
        self.roomsDirectoryCoordinatorBridgePresenter.delegate = self;
        [self.roomsDirectoryCoordinatorBridgePresenter presentFrom:self animated:YES];
    }
    else
    {
        [self createNewRoom];
    }
}

- (void)openPublicRoom:(MXPublicRoom *)publicRoom
{
    if (!self.recentsDataSource)
    {
        MXLogDebug(@"[RecentsViewController] Fail to open public room, dataSource is not kind of class MXKRecentsDataSource");
        return;
    }
    
    // Check whether the user has already joined the selected public room
    if ([self.recentsDataSource.publicRoomsDirectoryDataSource.mxSession isJoinedOnRoom:publicRoom.roomId])
    {
        Analytics.shared.viewRoomTrigger = AnalyticsViewRoomTriggerRoomDirectory;
        
        // Open the public room
        [self showRoomWithRoomId:publicRoom.roomId
                 inMatrixSession:self.recentsDataSource.publicRoomsDirectoryDataSource.mxSession];
    }
    else
    {
        // Preview the public room
        if (publicRoom.worldReadable)
        {
            RoomPreviewData *roomPreviewData = [[RoomPreviewData alloc] initWithPublicRoom:publicRoom andSession:self.recentsDataSource.publicRoomsDirectoryDataSource.mxSession];
            
            [self startActivityIndicator];

            // Try to get more information about the room before opening its preview
            [roomPreviewData peekInRoom:^(BOOL succeeded) {
                [self stopActivityIndicator];
                
                [self showRoomPreviewWithData:roomPreviewData];
            }];
        }
        else
        {
            RoomPreviewData *roomPreviewData = [[RoomPreviewData alloc] initWithPublicRoom:publicRoom andSession:self.recentsDataSource.publicRoomsDirectoryDataSource.mxSession];
            
            [self showRoomPreviewWithData:roomPreviewData];
        }
    }
}

#pragma mark - Table view scrolling

- (void)scrollToTop:(BOOL)animated
{
    [self.recentsTableView setContentOffset:CGPointMake(-self.recentsTableView.adjustedContentInset.left, -self.recentsTableView.adjustedContentInset.top) animated:animated];
}

- (void)scrollToTheTopTheNextRoomWithMissedNotificationsInSection:(NSInteger)section
{
    if (section < 0)
    {
        return;
    }
    
    UITableViewCell *firstVisibleCell;
    NSIndexPath *firstVisibleCellIndexPath;
    
    UIView *firstSectionHeader = displayedSectionHeaders.firstObject;
    
    if (firstSectionHeader && firstSectionHeader.frame.origin.y <= self.recentsTableView.contentOffset.y)
    {
        // Compute the height of the hidden part of the section header.
        CGFloat hiddenPart = self.recentsTableView.contentOffset.y - firstSectionHeader.frame.origin.y;
        CGFloat firstVisibleCellPosY = self.recentsTableView.contentOffset.y + (firstSectionHeader.frame.size.height - hiddenPart);
        firstVisibleCellIndexPath = [self.recentsTableView indexPathForRowAtPoint:CGPointMake(0, firstVisibleCellPosY)];
        firstVisibleCell = [self.recentsTableView cellForRowAtIndexPath:firstVisibleCellIndexPath];
    }
    else
    {
        firstVisibleCell = self.recentsTableView.visibleCells.firstObject;
        firstVisibleCellIndexPath = [self.recentsTableView indexPathForCell:firstVisibleCell];
    }
    
    if (firstVisibleCell)
    {
        NSInteger nextCellRow = (firstVisibleCellIndexPath.section == section) ? firstVisibleCellIndexPath.row + 1 : 0;
        
        // Look for the next room with missed notifications.
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:nextCellRow inSection:section];
        nextCellRow++;
        id<MXKRecentCellDataStoring> cellData = [self.dataSource cellDataAtIndexPath:nextIndexPath];
        
        while (cellData)
        {
            if (cellData.notificationCount)
            {
                [self.recentsTableView scrollToRowAtIndexPath:nextIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
                break;
            }
            nextIndexPath = [NSIndexPath indexPathForRow:nextCellRow inSection:section];
            nextCellRow++;
            cellData = [self.dataSource cellDataAtIndexPath:nextIndexPath];
        }
        
        if (!cellData && section < self.recentsTableView.numberOfSections && [self.recentsTableView numberOfRowsInSection:section] > 0)
        {
            // Scroll back to the top.
            [self.recentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        else if (section >= self.recentsTableView.numberOfSections)
        {
            NSDictionary *details = @{
                @"section": @(section),
                @"number_of_sections": @(self.recentsTableView.numberOfSections)
            };
            MXLogFailureDetails(@"[RecentsViewController] Section in a table view is invalid", details);
        }
    }
}

#pragma mark - MXKRecentListViewControllerDelegate

- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoom:(NSString *)roomId inMatrixSession:(MXSession *)matrixSession
{
    Analytics.shared.viewRoomTrigger = AnalyticsViewRoomTriggerRoomList;
    [self showRoomWithRoomId:roomId inMatrixSession:matrixSession];
}

- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectSuggestedRoom:(MXSpaceChildInfo *)childInfo from:(UIView* _Nullable)sourceView
{
    Analytics.shared.joinedRoomTrigger = AnalyticsJoinedRoomTriggerSpaceHierarchy;
    
    self.spaceChildPresenter = [[SpaceChildRoomDetailBridgePresenter alloc] initWithSession:self.mainSession childInfo:childInfo];
    self.spaceChildPresenter.delegate = self;
    [self.spaceChildPresenter presentFrom:self sourceView:sourceView animated:YES];
}

#pragma mark - UISearchBarDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [super scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    if (searchBar == tableSearchBar)
    {
        [self hideSearchBar:NO];
        [self.recentsSearchBar becomeFirstResponder];
        return NO;
    }
    
    return YES;
    
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.recentsSearchBar setShowsCancelButton:YES animated:NO];
        
    });
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self.recentsSearchBar setShowsCancelButton:NO animated:NO];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [super searchBar:searchBar textDidChange:searchText];

    UIImage *filterIcon = searchText.length > 0 ? AssetImages.filterOn.image : AssetImages.filterOff.image;
    [self.recentsSearchBar setImage:filterIcon
                   forSearchBarIcon:UISearchBarIconSearch
                              state:UIControlStateNormal];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.recentsSearchBar resignFirstResponder];
    [self hideSearchBar:YES];
    self.recentsTableView.contentOffset = CGPointMake(0, self.recentsSearchBar.frame.size.height);
    self.recentsTableView.tableHeaderView = nil;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.recentsDataSource searchWithPatterns:nil];
        [self.recentsSearchBar setText:nil];
    });
}

#pragma mark - CreateRoomCoordinatorBridgePresenterDelegate

- (void)createRoomCoordinatorBridgePresenterDelegate:(CreateRoomCoordinatorBridgePresenter *)coordinatorBridgePresenter didCreateNewRoom:(MXRoom *)room
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        Analytics.shared.viewRoomTrigger = AnalyticsViewRoomTriggerCreated;
        [self showRoomWithRoomId:room.roomId inMatrixSession:self.mainSession];
    }];
    coordinatorBridgePresenter = nil;
}

- (void)createRoomCoordinatorBridgePresenterDelegateDidCancel:(CreateRoomCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    coordinatorBridgePresenter = nil;
}

- (void)createRoomCoordinatorBridgePresenterDelegate:(CreateRoomCoordinatorBridgePresenter *)coordinatorBridgePresenter didAddRoomsWithIds:(NSArray<NSString *> *)roomIds
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    coordinatorBridgePresenter = nil;
}

#pragma mark - Empty view management

- (void)showEmptyViewIfNeeded
{
    [self showEmptyView:[self shouldShowEmptyView]];
}

- (void)showEmptyView:(BOOL)show
{
    if (!self.viewIfLoaded)
    {
        return;
    }
    
    if (show && !self.emptyView)
    {
        RootTabEmptyView *emptyView = [RootTabEmptyView instantiate];
        [emptyView updateWithTheme:ThemeService.shared.theme];
        [self addEmptyView:emptyView];
        
        self.emptyView = emptyView;
        
        [self updateEmptyView];
    }
    else if (!show)
    {
        [self.emptyView removeFromSuperview];
    }
    
    self.recentsTableView.hidden = show;
    self.stickyHeadersTopContainer.hidden = show;
    self.stickyHeadersBottomContainer.hidden = show;
}

- (void)updateEmptyView
{
    
}

- (void)addEmptyView:(RootTabEmptyView*)emptyView
{
    if (!self.isViewLoaded)
    {
        return;
    }
    
    NSLayoutConstraint *emptyViewBottomConstraint;
    NSLayoutConstraint *contentViewBottomConstraint;
    
    if (plusButtonImageView && plusButtonImageView.isHidden == NO)
    {
        [self.view insertSubview:emptyView belowSubview:plusButtonImageView];
        
        contentViewBottomConstraint = [NSLayoutConstraint constraintWithItem:emptyView.contentView
                                                                   attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationLessThanOrEqual toItem:plusButtonImageView
                                                                   attribute:NSLayoutAttributeTop
                                                                  multiplier:1.0
                                                                    constant:0];
    }
    else
    {
        [self.view addSubview:emptyView];
    }
    
    NSLayoutYAxisAnchor *bottomAnchor = self.emptyViewBottomAnchor ?: emptyView.superview.bottomAnchor;
    emptyViewBottomConstraint = [emptyView.bottomAnchor constraintEqualToAnchor:bottomAnchor constant:-1]; // 1pt spacing for UIToolbar's divider.
    
    emptyView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [emptyView.topAnchor constraintEqualToAnchor:emptyView.superview.topAnchor],
        [emptyView.leftAnchor constraintEqualToAnchor:emptyView.superview.leftAnchor],
        [emptyView.rightAnchor constraintEqualToAnchor:emptyView.superview.rightAnchor],
        emptyViewBottomConstraint
    ]];
    
    if (contentViewBottomConstraint)
    {
        contentViewBottomConstraint.active = YES;
    }
}

- (BOOL)shouldShowEmptyView
{
    // Do not present empty screen while searching
    if (self.recentsDataSource.searchPatternsList.count)
    {
        return NO;
    }
    
    return self.recentsDataSource.totalVisibleItemCount == 0;
}

#pragma mark - RoomsDirectoryCoordinatorBridgePresenterDelegate

- (void)roomsDirectoryCoordinatorBridgePresenterDelegateDidComplete:(RoomsDirectoryCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.roomsDirectoryCoordinatorBridgePresenter = nil;
}

- (void)roomsDirectoryCoordinatorBridgePresenterDelegate:(RoomsDirectoryCoordinatorBridgePresenter *)coordinatorBridgePresenter didSelectRoom:(MXPublicRoom *)room
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        [self openPublicRoom:room];
    }];
    self.roomsDirectoryCoordinatorBridgePresenter = nil;
}

- (void)roomsDirectoryCoordinatorBridgePresenterDelegateDidTapCreateNewRoom:(RoomsDirectoryCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        [self createNewRoom];
    }];
    self.roomsDirectoryCoordinatorBridgePresenter = nil;
}

- (void)roomsDirectoryCoordinatorBridgePresenterDelegate:(RoomsDirectoryCoordinatorBridgePresenter *)coordinatorBridgePresenter didSelectRoomWithIdOrAlias:(NSString * _Nonnull)roomIdOrAlias
{
    MXRoom *room = [self.mainSession vc_roomWithIdOrAlias:roomIdOrAlias];
    
    if (room)
    {
        // Room is known show it directly
        [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
            [self showRoomWithRoomId:room.roomId
                     inMatrixSession:self.mainSession];
        }];
        coordinatorBridgePresenter = nil;
    }
    else if ([MXTools isMatrixRoomAlias:roomIdOrAlias])
    {
        // Room preview doesn't support room alias
        [[AppDelegate theDelegate] showAlertWithTitle:[VectorL10n error] message:[VectorL10n roomRecentsUnknownRoomErrorMessage]];
    }
    else
    {
        // Try to preview the room from his id
        RoomPreviewData *roomPreviewData = [[RoomPreviewData alloc] initWithRoomId:roomIdOrAlias
                                                                        andSession:self.mainSession];
        
        [self startActivityIndicator];

        // Try to get more information about the room before opening its preview
        MXWeakify(self);
        
        [roomPreviewData peekInRoom:^(BOOL succeeded) {
            
            MXStrongifyAndReturnIfNil(self);
            
            [self stopActivityIndicator];
                        
            if (succeeded) {
                [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
                    
                    [self showRoomPreviewWithData:roomPreviewData];
                }];
                self.roomsDirectoryCoordinatorBridgePresenter = nil;
            } else {
                [[AppDelegate theDelegate] showAlertWithTitle:[VectorL10n error] message:[VectorL10n roomRecentsUnknownRoomErrorMessage]];
            }
        }];
    }
}

#pragma mark - ExploreRoomCoordinatorBridgePresenterDelegate

- (void)exploreRoomCoordinatorBridgePresenterDelegateDidComplete:(ExploreRoomCoordinatorBridgePresenter *)coordinatorBridgePresenter {
    MXWeakify(self);
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        MXStrongifyAndReturnIfNil(self);
        self.exploreRoomsCoordinatorBridgePresenter = nil;
    }];
}

#pragma mark - RoomNotificationSettingsCoordinatorBridgePresenterDelegate
-(void)roomNotificationSettingsCoordinatorBridgePresenterDelegateDidComplete:(RoomNotificationSettingsCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.roomNotificationSettingsCoordinatorBridgePresenter = nil;
}

#pragma mark - SpaceChildRoomDetailBridgePresenterDelegate
- (void)spaceChildRoomDetailBridgePresenterDidCancel:(SpaceChildRoomDetailBridgePresenter *)coordinator
{
    [self.spaceChildPresenter dismissWithAnimated:YES completion:^{
        self.spaceChildPresenter = nil;
    }];
}

- (void)spaceChildRoomDetailBridgePresenter:(SpaceChildRoomDetailBridgePresenter *)coordinator didOpenRoomWith:(NSString *)roomId
{
    [self showRoomWithRoomId:roomId inMatrixSession:self.mainSession];

    [self.spaceChildPresenter dismissWithAnimated:YES completion:^{
        self.spaceChildPresenter = nil;
    }];
}

#pragma mark - Activity Indicator

- (BOOL)providesCustomActivityIndicator {
    return self.userIndicatorStore != nil;
}

- (void)startActivityIndicatorWithLabel:(NSString *)label {
    if (self.userIndicatorStore && isViewVisible) {
        // The app is very liberal with calling `startActivityIndicator` (often not matched by corresponding `stopActivityIndicator`),
        // so there is no reason to keep adding new indicators if there is one already showing.
        if (loadingIndicatorCancel) {
            return;
        }
        
        MXLogDebug(@"[RecentsViewController] Present loading indicator")
        loadingIndicatorCancel = [self.userIndicatorStore presentLoadingWithLabel:label isInteractionBlocking:NO];
    } else {
        [super startActivityIndicator];
    }
}

- (void)startActivityIndicator {
    [self startActivityIndicatorWithLabel:[VectorL10n homeSyncing]];
}

- (void)stopActivityIndicator {
    if (self.userIndicatorStore) {
        if (loadingIndicatorCancel) {
            MXLogDebug(@"[RecentsViewController] Dismiss loading indicator")
            loadingIndicatorCancel();
            loadingIndicatorCancel = nil;
        }
    } else {
        [super stopActivityIndicator];
    }
}

#pragma mark - Context Menu

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0))
{
    id<MXKRecentCellDataStoring> cellData = [self.dataSource cellDataAtIndexPath:indexPath];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (!cellData || !cell)
    {
        return nil;
    }
    
    return [self.contextMenuProvider contextMenuConfigurationWith:cellData from:cell session:self.dataSource.mxSession];
}

- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator API_AVAILABLE(ios(13.0))
{
    NSString *roomId = [self.contextMenuProvider roomIdFrom:configuration.identifier];
    
    if (!roomId)
    {
        self.recentsUpdateEnabled = YES;
        return;
    }
    
    [animator addCompletion:^{
        self.recentsUpdateEnabled = YES;
        [self showRoomWithRoomId:roomId inMatrixSession:self.mainSession];
    }];
}

- (UITargetedPreview *)tableView:(UITableView *)tableView previewForDismissingContextMenuWithConfiguration:(UIContextMenuConfiguration *)configuration API_AVAILABLE(ios(13.0))
{
    self.recentsUpdateEnabled = YES;
    return nil;
}

#pragma mark - RoomContextActionServiceDelegate

- (void)roomContextActionServiceDidJoinRoom:(id<RoomContextActionServiceProtocol>)service
{
    [self showRoomWithRoomId:service.roomId inMatrixSession:service.session];
}

- (void)roomContextActionServiceDidLeaveRoom:(id<RoomContextActionServiceProtocol>)service
{
    [self.userIndicatorStore presentSuccessWithLabel:VectorL10n.roomParticipantsLeaveSuccess];
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
    else if ([self canStopActivityIndicator])
    {
        [self stopActivityIndicator];
    }
}

- (void)roomContextActionService:(id<RoomContextActionServiceProtocol>)service showRoomNotificationSettingsForRoomWithId:(NSString *)roomId
{
    editedRoomId = roomId;
    [self changeEditedRoomNotificationSettings];
    editedRoomId = nil;
}

#pragma mark - RecentCellContextMenuProviderDelegate

- (void)recentCellContextMenuProviderDidStartShowingPreview:(RecentCellContextMenuProvider *)menuProvider
{
    self.recentsUpdateEnabled = NO;
}

@end
