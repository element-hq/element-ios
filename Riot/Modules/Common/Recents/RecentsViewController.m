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

#import <MatrixKit/MatrixKit.h>

#import "RoomViewController.h"

#import "InviteRecentTableViewCell.h"
#import "DirectoryRecentTableViewCell.h"
#import "RoomIdOrAliasTableViewCell.h"

#import "AppDelegate.h"

@interface RecentsViewController ()
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
    id UIApplicationDidEnterBackgroundNotificationObserver;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;
    
    // Observe kMXNotificationCenterDidUpdateRules to update missed messages counts.
    id kMXNotificationCenterDidUpdateRulesObserver;
    
    MXHTTPOperation *currentRequest;
    
    // The fake search bar displayed at the top of the recents table. We switch on the actual search bar (self.recentsSearchBar)
    // when the user selects it.
    UISearchBar *tableSearchBar;
    
    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
}

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
    
    // Set default screen name
    _screenName = @"RecentsScreen";
    
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
    tableSearchBar.placeholder = NSLocalizedStringFromTable(@"search_default_placeholder", @"Vector", nil);
    tableSearchBar.delegate = self;
    
    displayedSectionHeaders = [NSMutableArray array];
    
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
    
    // Hide line separators of empty cells
    self.recentsTableView.tableFooterView = [[UIView alloc] init];
    
    // Apply dragging settings
    self.enableDragging = _enableDragging;
    
    // Observe UIApplicationDidEnterBackgroundNotification to refresh bubbles when app leaves the foreground state.
    UIApplicationDidEnterBackgroundNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Leave potential editing mode
        [self cancelEditionMode:isRefreshPending];
        
    }];
    
    self.recentsSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.recentsSearchBar.placeholder = NSLocalizedStringFromTable(@"search_default_placeholder", @"Vector", nil);
    
    // Observe user interface theme change.
    kRiotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    self.defaultBarTintColor = kRiotSecondaryBgColor;
    self.barTitleColor = kRiotPrimaryTextColor;
    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    // Use the primary bg color for the recents table view in plain style.
    self.recentsTableView.backgroundColor = kRiotPrimaryBgColor;
    topview.backgroundColor = kRiotSecondaryBgColor;
    self.view.backgroundColor = kRiotPrimaryBgColor;
    
    tableSearchBar.barStyle = self.recentsSearchBar.barStyle = kRiotDesignSearchBarStyle;
    tableSearchBar.tintColor = self.recentsSearchBar.tintColor = kRiotDesignSearchBarTintColor;
    
    if (self.recentsTableView.dataSource)
    {
        // Force table refresh
        [self cancelEditionMode:YES];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return kRiotDesignStatusBarStyle;
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
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
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

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:_screenName];

    // Reset back user interactions
    self.userInteractionEnabled = YES;
    
    // Deselect the current selected row, it will be restored on viewDidAppear (if any)
    NSIndexPath *indexPath = [self.recentsTableView indexPathForSelectedRow];
    if (indexPath)
    {
        [self.recentsTableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self scrollToTop:YES];
        
    }];
    
    // Observe kMXNotificationCenterDidUpdateRules to refresh missed messages counts
    kMXNotificationCenterDidUpdateRulesObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterDidUpdateRules object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        [self refreshRecentsTable];
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
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
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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
    // Refresh the tabBar icon badges
    [[AppDelegate theDelegate].masterTabBarController refreshTabBarBadges];
    
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
    if (masterTabBarController.currentRoomViewController)
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
            [self.recentsTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
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
            CGFloat maxVisiblePosY = self.recentsTableView.contentOffset.y + self.recentsTableView.frame.size.height - self.recentsTableView.mxk_adjustedContentInset.bottom;
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

- (void)dispayRoomWithRoomId:(NSString*)roomId inMatrixSession:(MXSession*)matrixSession
{
    // Avoid multiple openings of rooms
    self.userInteractionEnabled = NO;

    [[AppDelegate theDelegate].masterTabBarController selectRoomWithId:roomId andEventId:nil inMatrixSession:matrixSession];
}

// Disable UI interactions in this screen while we are going to open another screen.
// Interactions on reset on viewWillAppear.
- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    self.view.userInteractionEnabled = userInteractionEnabled;
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    id<MXKRecentCellDataStoring> cellDataStoring = (id<MXKRecentCellDataStoring> )cellData;
    
    if (cellDataStoring.roomSummary.room.summary.membership != MXMembershipInvite)
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
        
        // Display the room preview
        [self dispayRoomWithRoomId:invitedRoom.roomId inMatrixSession:invitedRoom.mxSession];
    }
    else if ([actionIdentifier isEqualToString:kInviteRecentTableViewCellDeclineButtonPressed])
    {
        // Retrieve the invited room
        MXRoom *invitedRoom = userInfo[kInviteRecentTableViewCellRoomKey];
        
        [self cancelEditionMode:isRefreshPending];
        
        // Decline the invitation
        [invitedRoom leave:^{
            
            [self.recentsTableView reloadData];
            
        } failure:^(NSError *error) {
            
            NSLog(@"[RecentsViewController] Failed to reject an invited room (%@)", invitedRoom.roomId);
            
        }];
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

#pragma mark - Swipe actions

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* actions = [[NSMutableArray alloc] init];
    MXRoom* room = [self.dataSource getRoomAtIndexPath:indexPath];
    
    if (room)
    {
        // Display no action for the invited room
        if (room.summary.membership == MXMembershipInvite)
        {
            return actions;
        }
        
        // Store the identifier of the room related to the edited cell.
        editedRoomId = room.roomId;
        
        NSString* title = @"      ";
        
        // Direct chat toggle
        BOOL isDirect = room.isDirect;
        
        UITableViewRowAction *directAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self makeDirectEditedRoom:!isDirect];
            
        }];
        
        UIImage *actionIcon = isDirect ? [UIImage imageNamed:@"directChatOff"] : [UIImage imageNamed:@"directChatOn"];
        directAction.backgroundColor = [MXKTools convertImageToPatternColor:isDirect ? @"directChatOff" : @"directChatOn" backgroundColor:kRiotSecondaryBgColor patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
        [actions insertObject:directAction atIndex:0];
        
        
        // Notification toggle
        BOOL isMuted = room.isMute || room.isMentionsOnly;
        
        UITableViewRowAction *muteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self muteEditedRoomNotifications:!isMuted];
            
        }];
        
        actionIcon = isMuted ? [UIImage imageNamed:@"notifications"] : [UIImage imageNamed:@"notificationsOff"];
        muteAction.backgroundColor = [MXKTools convertImageToPatternColor:isMuted ? @"notifications" : @"notificationsOff" backgroundColor:kRiotSecondaryBgColor patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
        [actions insertObject:muteAction atIndex:0];
        
        // Favorites management
        MXRoomTag* currentTag = nil;
        
        // Get the room tag (use only the first one).
        if (room.accountData.tags)
        {
            NSArray<MXRoomTag*>* tags = room.accountData.tags.allValues;
            if (tags.count)
            {
                currentTag = [tags objectAtIndex:0];
            }
        }
        
        if (currentTag && [kMXRoomTagFavourite isEqualToString:currentTag.name])
        {
            UITableViewRowAction* action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self updateEditedRoomTag:nil];
                
            }];
            
            actionIcon = [UIImage imageNamed:@"favouriteOff"];
            action.backgroundColor = [MXKTools convertImageToPatternColor:@"favouriteOff" backgroundColor:kRiotSecondaryBgColor patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
            [actions insertObject:action atIndex:0];
        }
        else
        {
            UITableViewRowAction* action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self updateEditedRoomTag:kMXRoomTagFavourite];
                
            }];
            
            actionIcon = [UIImage imageNamed:@"favourite"];
            action.backgroundColor = [MXKTools convertImageToPatternColor:@"favourite" backgroundColor:kRiotSecondaryBgColor patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
            [actions insertObject:action atIndex:0];
        }
        
        if (currentTag && [kMXRoomTagLowPriority isEqualToString:currentTag.name])
        {
            UITableViewRowAction* action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self updateEditedRoomTag:nil];
                
            }];
            
            actionIcon = [UIImage imageNamed:@"priorityHigh"];
            action.backgroundColor = [MXKTools convertImageToPatternColor:@"priorityHigh" backgroundColor:kRiotSecondaryBgColor patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
            [actions insertObject:action atIndex:0];
        }
        else
        {
            UITableViewRowAction* action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self updateEditedRoomTag:kMXRoomTagLowPriority];
                
            }];
            
            actionIcon = [UIImage imageNamed:@"priorityLow"];
            action.backgroundColor = [MXKTools convertImageToPatternColor:@"priorityLow" backgroundColor:kRiotSecondaryBgColor patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
            [actions insertObject:action atIndex:0];
        }
        
        UITableViewRowAction *leaveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:title  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self leaveEditedRoom];
            
        }];
        
        actionIcon = [UIImage imageNamed:@"leave"];
        leaveAction.backgroundColor = [MXKTools convertImageToPatternColor:@"leave" backgroundColor:kRiotSecondaryBgColor patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
        
        [actions insertObject:leaveAction atIndex:0];
    }
    
    return actions;
}

- (void)tableView:(UITableView*)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self cancelEditionMode:isRefreshPending];
}

- (void)leaveEditedRoom
{
    if (editedRoomId)
    {
        NSString *currentRoomId = editedRoomId;
        
        __weak typeof(self) weakSelf = self;
        
        // confirm leave
        NSString *promptMessage = NSLocalizedStringFromTable(@"room_participants_leave_prompt_msg", @"Vector", nil);
        currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_participants_leave_prompt_title", @"Vector", nil)
                                                           message:promptMessage
                                                    preferredStyle:UIAlertControllerStyleAlert];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                           }
                                                           
                                                       }]];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"leave", @"Vector", nil)
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
                                                                     [self startActivityIndicator];
                                                                     
                                                                     // cancel pending uploads/downloads
                                                                     // they are useless by now
                                                                     [MXMediaManager cancelDownloadsInCacheFolder:room.roomId];
                                                                     
                                                                     // TODO GFO cancel pending uploads related to this room
                                                                     
                                                                     NSLog(@"[RecentsViewController] Leave room (%@)", room.roomId);
                                                                     
                                                                     [room leave:^{
                                                                         
                                                                         if (weakSelf)
                                                                         {
                                                                             typeof(self) self = weakSelf;
                                                                             [self stopActivityIndicator];
                                                                             // Force table refresh
                                                                             [self cancelEditionMode:YES];
                                                                         }
                                                                         
                                                                     } failure:^(NSError *error) {
                                                                         
                                                                         NSLog(@"[RecentsViewController] Failed to leave room");
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
                                                                             [self cancelEditionMode:isRefreshPending];
                                                                         }
                                                                         
                                                                     }];
                                                                 }
                                                                 else
                                                                 {
                                                                     // Leave editing mode
                                                                     [self cancelEditionMode:isRefreshPending];
                                                                 }
                                                             }
                                                             
                                                         }]];
        
        [currentAlert mxk_setAccessibilityIdentifier:@"LeaveEditedRoomAlert"];
        [self presentViewController:currentAlert animated:YES completion:nil];
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
        __weak typeof(self) weakSelf = self;
        
        // Check whether the user didn't leave the room
        // TODO: handle multi-account
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (room)
        {
            [self startActivityIndicator];
            
            [room setIsDirect:isDirect withUserId:nil success:^{
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    [self stopActivityIndicator];
                    // Leave editing mode
                    [self cancelEditionMode:isRefreshPending];
                }
                
            } failure:^(NSError *error) {
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    [self stopActivityIndicator];
                    
                    NSLog(@"[RecentsViewController] Failed to update direct tag of the room (%@)", editedRoomId);
                    
                    // Notify the end user
                    NSString *userId = self.mainSession.myUser.userId; // TODO: handle multi-account
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification
                                                                        object:error
                                                                      userInfo:userId ? @{kMXKErrorUserIdKey: userId} : nil];
                    
                    // Leave editing mode
                    [self cancelEditionMode:isRefreshPending];
                }
                
            }];
        }
        else
        {
            // Leave editing mode
            [self cancelEditionMode:isRefreshPending];
        }
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
                    [self cancelEditionMode:isRefreshPending];
                    
                }];
            }
            else
            {
                [room allMessages:^{
                    
                    [self stopActivityIndicator];
                    
                    // Leave editing mode
                    [self cancelEditionMode:isRefreshPending];
                    
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
    cell.backgroundColor = kRiotPrimaryBgColor;
    
    // Update the selected background view
    if (kRiotSelectedBgColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = kRiotSelectedBgColor;
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
        // hide the selection
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
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
            // Open the room or preview it
            NSString *fragment = [NSString stringWithFormat:@"/room/%@", [roomIdOrAlias stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            [[AppDelegate theDelegate] handleUniversalLinkFragment:fragment];
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self refreshStickyHeadersContainersHeight];
        
    });
    
    [super scrollViewDidScroll:scrollView];
    
    if (scrollView == self.recentsTableView)
    {
        if (!self.recentsSearchBar.isHidden)
        {
            if (!self.recentsSearchBar.text.length && (scrollView.contentOffset.y + scrollView.mxk_adjustedContentInset.top > self.recentsSearchBar.frame.size.height))
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
                cell.backgroundColor = kRiotPrimaryBgColor;
                
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

- (void)addPlusButton
{
    // Add room options button
    plusButtonImageView = [[UIImageView alloc] init];
    [plusButtonImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:plusButtonImageView];
    
    plusButtonImageView.backgroundColor = [UIColor clearColor];
    plusButtonImageView.contentMode = UIViewContentModeCenter;
    plusButtonImageView.image = [UIImage imageNamed:@"create_room"];
    plusButtonImageView.layer.shadowOpacity = 0.3;
    plusButtonImageView.layer.shadowOffset = CGSizeMake(0, 3);
    
    CGFloat side = 78.0f;
    NSLayoutConstraint* widthConstraint = [NSLayoutConstraint constraintWithItem:plusButtonImageView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1
                                                                        constant:side];
    
    NSLayoutConstraint* heightConstraint = [NSLayoutConstraint constraintWithItem:plusButtonImageView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1
                                                                         constant:side];
    
    NSLayoutConstraint* trailingConstraint = [NSLayoutConstraint constraintWithItem:plusButtonImageView
                                                                          attribute:NSLayoutAttributeTrailing
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.view
                                                                          attribute:NSLayoutAttributeTrailing
                                                                         multiplier:1
                                                                           constant:0];
    
    NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                                        attribute:NSLayoutAttributeTop
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:plusButtonImageView
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1
                                                                         constant:9];
    
    [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint, trailingConstraint, bottomConstraint]];
    
    plusButtonImageView.userInteractionEnabled = YES;
    
    // Handle tap gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onPlusButtonPressed)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [plusButtonImageView addGestureRecognizer:tap];
}

- (void)onPlusButtonPressed
{
    __weak typeof(self) weakSelf = self;
    
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    currentAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_recents_start_chat_with", @"Vector", nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           [self performSegueWithIdentifier:@"presentStartChat" sender:self];
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_recents_create_empty_room", @"Vector", nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           [self createAnEmptyRoom];
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_recents_join_room", @"Vector", nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           [self joinARoom];
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }
                                                       
                                                   }]];
    
    [currentAlert popoverPresentationController].sourceView = plusButtonImageView;
    [currentAlert popoverPresentationController].sourceRect = plusButtonImageView.bounds;
    
    [currentAlert mxk_setAccessibilityIdentifier:@"RecentsVCCreateRoomAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

- (void)createAnEmptyRoom
{
    // Sanity check
    if (self.mainSession)
    {
        // Create one room at time
        if (!currentRequest)
        {
            [self startActivityIndicator];
            
            // Create an empty room.
            MXWeakify(self);
            currentRequest = [self.mainSession createRoom:nil
                                               visibility:kMXRoomDirectoryVisibilityPrivate
                                                roomAlias:nil
                                                    topic:nil
                                                  success:^(MXRoom *room) {
                                                      MXStrongifyAndReturnIfNil(self);
                                                      
                                                      self->currentRequest = nil;
                                                      [self stopActivityIndicator];
                                                      if (self->currentAlert)
                                                      {
                                                          [self->currentAlert dismissViewControllerAnimated:NO completion:nil];
                                                          self->currentAlert = nil;
                                                      }

                                                      [self dispayRoomWithRoomId:room.roomId inMatrixSession:self.mainSession];
                                                      
                                                      [[AppDelegate theDelegate].masterTabBarController selectRoomWithId:room.roomId andEventId:nil inMatrixSession:self.mainSession];

                                                  } failure:^(NSError *error) {
                                                      MXStrongifyAndReturnIfNil(self);
                                                      
                                                      self->currentRequest = nil;
                                                      [self stopActivityIndicator];
                                                      if (self->currentAlert)
                                                      {
                                                          [self->currentAlert dismissViewControllerAnimated:NO completion:nil];
                                                          self->currentAlert = nil;
                                                      }
                                                      
                                                      NSLog(@"[RecentsViewController] Create new room failed");
                                                      
                                                      // Alert user
                                                      [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                      
                                                  }];
        }
        else
        {
            // Ask the user to wait
            __weak __typeof(self) weakSelf = self;
            currentAlert = [UIAlertController alertControllerWithTitle:nil
                                                               message:NSLocalizedStringFromTable(@"room_creation_wait_for_creation", @"Vector", nil)
                                                        preferredStyle:UIAlertControllerStyleAlert];
            
            [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                               }
                                                               
                                                           }]];
            
            [currentAlert mxk_setAccessibilityIdentifier:@"RecentsVCRoomCreationInProgressAlert"];
            [self presentViewController:currentAlert animated:YES completion:nil];
        }
    }
}

- (void)joinARoom
{
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    __weak typeof(self) weakSelf = self;
    
    // Prompt the user to type a room id or room alias
    currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_recents_join_room_title", @"Vector", nil)
                                                       message:NSLocalizedStringFromTable(@"room_recents_join_room_prompt", @"Vector", nil)
                                                preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        
        textField.secureTextEntry = NO;
        textField.placeholder = nil;
        textField.keyboardType = UIKeyboardTypeDefault;
    }];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"join", @"Vector", nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           
                                                           UITextField *textField = [self->currentAlert textFields].firstObject;
                                                           NSString *roomAliasOrId = textField.text;
                                                           
                                                           self->currentAlert = nil;
                                                           
                                                           [self.activityIndicator startAnimating];
                                                           
                                                           self->currentRequest = [self.mainSession joinRoom:textField.text success:^(MXRoom *room) {
                                                               
                                                               self->currentRequest = nil;
                                                               [self.activityIndicator stopAnimating];
                                                               
                                                               // Show the room
                                                               [[AppDelegate theDelegate] showRoom:room.roomId andEventId:nil withMatrixSession:self.mainSession];
                                                               
                                                           } failure:^(NSError *error) {
                                                               
                                                               NSLog(@"[RecentsViewController] Join joinARoom (%@) failed", roomAliasOrId);
                                                               
                                                               self->currentRequest = nil;
                                                               [self.activityIndicator stopAnimating];
                                                               
                                                               // Alert user
                                                               [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                           }];
                                                       }
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier:@"RecentsVCJoinARoomAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

#pragma mark - Table view scrolling

- (void)scrollToTop:(BOOL)animated
{
    [self.recentsTableView setContentOffset:CGPointMake(-self.recentsTableView.mxk_adjustedContentInset.left, -self.recentsTableView.mxk_adjustedContentInset.top) animated:animated];
}

- (void)scrollToTheTopTheNextRoomWithMissedNotificationsInSection:(NSInteger)section
{
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
        
        if (!cellData && [self.recentsTableView numberOfRowsInSection:section] > 0)
        {
            // Scroll back to the top.
            [self.recentsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
}

#pragma mark - MXKRecentListViewControllerDelegate

- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoom:(NSString *)roomId inMatrixSession:(MXSession *)matrixSession
{
    [self dispayRoomWithRoomId:roomId inMatrixSession:matrixSession];
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

@end
