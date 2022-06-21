/*
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

#import "GroupRoomsViewController.h"

#import "GeneratedInterface-Swift.h"

#import "GroupRoomTableViewCell.h"

#import "RageShakeManager.h"

@interface GroupRoomsViewController ()
{
    // Search result
    NSString *currentSearchText;
    NSMutableArray<MXGroupRoom*> *filteredGroupRooms;
    
    // The current pushed view controller
    UIViewController *pushedViewController;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
}

@end

@implementation GroupRoomsViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)groupRoomsViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass(self.class)
                                          bundle:[NSBundle bundleForClass:self.class]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Check whether the view controller has been pushed via storyboard
    if (!self.tableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    // Adjust Top and Bottom constraints to take into account potential navBar and tabBar.
    [NSLayoutConstraint deactivateConstraints:@[_searchBarTopConstraint, _tableViewBottomConstraint]];
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"
    _searchBarTopConstraint = [NSLayoutConstraint constraintWithItem:self.topLayoutGuide
                                                           attribute:NSLayoutAttributeBottom
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.searchBarHeader
                                                           attribute:NSLayoutAttributeTop
                                                          multiplier:1.0f
                                                            constant:0.0f];
    
    _tableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.tableView
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0f
                                                               constant:0.0f];
    #pragma clang diagnostic pop
    
    [NSLayoutConstraint activateConstraints:@[_searchBarTopConstraint, _tableViewBottomConstraint]];
    
    _searchBarView.placeholder = [VectorL10n groupRoomsFilterRooms];
    _searchBarView.returnKeyType = UIReturnKeyDone;
    _searchBarView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    // Search bar header is hidden when no group is provided
    _searchBarHeader.hidden = (self.group == nil);
    
    // Enable self-sizing cells and section headers.
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 74;
    self.tableView.sectionHeaderHeight = 0;
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self.tableView registerClass:GroupRoomTableViewCell.class forCellReuseIdentifier:@"RoomTableViewCellId"];
    
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
    
    [self refreshSearchBarItemsColor:_searchBarView];
    
    _searchBarHeaderBorder.backgroundColor = ThemeService.shared.theme.headerBorderColor;
    
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

// This method is called when the viewcontroller is added or removed from a container view controller.
- (void)didMoveToParentViewController:(nullable UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
}

- (void)destroy
{
    // Release the potential pushed view controller
    [self releasePushedViewController];
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    
    _group = nil;
    _mxSession = nil;
    
    filteredGroupRooms = nil;
    
    groupRooms = nil;
    
    // Note: all observers are removed during super call.
    [super destroy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Release the potential pushed view controller
    [self releasePushedViewController];
    
    if (_group)
    {
        // Restore the listeners on the group update.
        [self registerOnGroupChangeNotifications];
        
        // Check whether the selected group is stored in the user's session, or if it is a group preview.
        // Replace the displayed group instance with the one stored in the session (if any).
        MXGroup *storedGroup = [_mxSession groupWithGroupId:_group.groupId];
        BOOL isPreview = (!storedGroup);
        
        // Force refresh
        [self refreshDisplayWithGroup:(isPreview ? _group : storedGroup)];
        
        // Prepare a block called on successful update in case of a group preview.
        // Indeed the group update notifications are triggered by the matrix session only for the user's groups.
        void (^success)(void) = ^void(void)
        {
            [self refreshDisplayWithGroup:self->_group];
        };
        
        // Trigger a refresh on the group rooms.
        [self.mxSession updateGroupRooms:_group success:(isPreview ? success : nil) failure:^(NSError *error) {
            
            MXLogDebug(@"[GroupRoomsViewController] viewWillAppear: group rooms update failed %@", self->_group.groupId);
            
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self cancelRegistrationOnGroupChangeNotifications];
    
    // cancel any pending search
    [self searchBarCancelButtonClicked:_searchBarView];
}

- (void)withdrawViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    // Check whether the current view controller is displayed inside a segmented view controller in order to withdraw the right item
    if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
    {
        [((SegmentedViewController*)self.parentViewController) withdrawViewControllerAnimated:animated completion:completion];
    }
    else
    {
        [super withdrawViewControllerAnimated:animated completion:completion];
    }
}

- (void)setGroup:(MXGroup*)group withMatrixSession:(MXSession*)mxSession
{
    // Cancel any pending search
    [self searchBarCancelButtonClicked:_searchBarView];
    
    if (_mxSession != mxSession)
    {
        [self cancelRegistrationOnGroupChangeNotifications];
        _mxSession = mxSession;
        
        [self registerOnGroupChangeNotifications];
    }
    
    [self addMatrixSession:mxSession];
    
    [self refreshDisplayWithGroup:group];
}

#pragma mark -

- (void)registerOnGroupChangeNotifications
{
    if (_mxSession)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateGroupRooms:) name:kMXSessionDidUpdateGroupRoomsNotification object:_mxSession];
    }
}

- (void)cancelRegistrationOnGroupChangeNotifications
{
    // Remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidUpdateGroupRoomsNotification object:_mxSession];
}

- (void)didUpdateGroupRooms:(NSNotification *)notif
{
    MXGroup *group = notif.userInfo[kMXSessionNotificationGroupKey];
    if (group && [group.groupId isEqualToString:_group.groupId])
    {
        // Update the current displayed group instance with the one stored in the session.
        [self refreshDisplayWithGroup:group];
    }
}

- (void)refreshDisplayWithGroup:(MXGroup *)group
{
    _group = group;
    
    if (_group)
    {
        _searchBarHeader.hidden = NO;
        groupRooms = _group.rooms.chunk;
    }
    else
    {
        // Search bar header is hidden when no group is provided
        _searchBarHeader.hidden = YES;
        groupRooms = nil;
    }
    
    // Reload search result if any
    if (currentSearchText.length)
    {
        NSString *searchText = currentSearchText;
        currentSearchText = nil;
        
        [self searchBar:_searchBarView textDidChange:searchText];
    }
    else
    {
        [self refreshTableView];
    }
}

- (void)startActivityIndicator
{
    // Check whether the current view controller is displayed inside a segmented view controller in order to run the right activity view
    if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
    {
        [((SegmentedViewController*)self.parentViewController) startActivityIndicator];
        
        // Force stop the activity view of the view controller
        [self.activityIndicator stopAnimating];
    }
    else
    {
        [super startActivityIndicator];
    }
}

- (void)stopActivityIndicator
{
    // Check whether the current view controller is displayed inside a segmented view controller in order to stop the right activity view
    if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
    {
        [((SegmentedViewController*)self.parentViewController) stopActivityIndicator];
        
        // Force stop the activity view of the view controller
        [self.activityIndicator stopAnimating];
    }
    else
    {
        [super stopActivityIndicator];
    }
}

#pragma mark - Internals

- (void)refreshTableView
{
    [self.tableView reloadData];
}

- (void)pushViewController:(UIViewController*)viewController
{
    // Keep ref on pushed view controller
    pushedViewController = viewController;
    
    // Check whether the view controller is displayed inside a segmented one.
    if (self.parentViewController.navigationController)
    {
        // Hide back button title
        [self.parentViewController vc_removeBackTitle];

        [self.parentViewController.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        // Hide back button title
        [self vc_removeBackTitle];

        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)releasePushedViewController
{
    if (pushedViewController)
    {
        if ([pushedViewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *navigationController = (UINavigationController*)pushedViewController;
            for (id subViewController in navigationController.viewControllers)
            {
                if ([subViewController respondsToSelector:@selector(destroy)])
                {
                    [subViewController destroy];
                }
            }
        }
        else if ([pushedViewController respondsToSelector:@selector(destroy)])
        {
            [(id)pushedViewController destroy];
        }
        
        pushedViewController = nil;
    }
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    
    if (currentSearchText.length)
    {
        if (filteredGroupRooms.count)
        {
            count++;
        }
    }
    else
    {
        if (groupRooms.count)
        {
            count++;
        }
    }
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (currentSearchText.length)
    {
        count = filteredGroupRooms.count;
    }
    else
    {
        count = groupRooms.count;
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GroupRoomTableViewCell* roomCell = [tableView dequeueReusableCellWithIdentifier:@"RoomTableViewCellId" forIndexPath:indexPath];
    roomCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    MXGroupRoom *room;
    NSArray *rooms;
    
    if (currentSearchText.length)
    {
        rooms = filteredGroupRooms;
    }
    else
    {
        rooms = groupRooms;
    }
    
    if (indexPath.row < rooms.count)
    {
        room = rooms[indexPath.row];
    }
    
    if (room)
    {
        [roomCell render:room withMatrixSession:self.mxSession];
    }
    
    return roomCell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    // iOS8 requires this method to enable editing (see editActionsForRowAtIndexPath).
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView.estimatedRowHeight;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
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
    
    // Refresh here the estimated row height
    tableView.estimatedRowHeight = cell.frame.size.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MXGroupRoom *room;
    NSArray *rooms;
    
    if (currentSearchText.length)
    {
        rooms = filteredGroupRooms;
    }
    else
    {
        rooms = groupRooms;
    }
    
    if (indexPath.row < rooms.count)
    {
        room = rooms[indexPath.row];
    }
    
    if (room)
    {
        // Check first if the user already joined this room.
        if ([self.mxSession roomWithRoomId:room.roomId])
        {
            // Open this room
            MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mxSession];
            [roomDataSourceManager roomDataSourceForRoom:room.roomId create:YES onComplete:^(MXKRoomDataSource *roomDataSource) {

                RoomViewController *roomViewController = [RoomViewController roomViewController];
                roomViewController.showMissedDiscussionsBadge = NO;
                [roomViewController displayRoom:roomDataSource];
                [self pushViewController:roomViewController];
            }];
        }
        else
        {
            // Prepare a preview
            RoomPreviewData *roomPreviewData = [[RoomPreviewData alloc] initWithRoomId:room.roomId andSession:self.mxSession];
            [self startActivityIndicator];
            
            // Try to get more information about the room before opening its preview
            [roomPreviewData peekInRoom:^(BOOL succeeded) {
                
                [self stopActivityIndicator];
                
                // If no data is available for this room, we name it with the known information (if any).
                if (!succeeded)
                {
                    roomPreviewData.roomName = (room.name.length ? room.name : room.canonicalAlias);
                }
                
                // Display the room preview
                RoomViewController *roomViewController = [RoomViewController roomViewController];
                roomViewController.showMissedDiscussionsBadge = NO;
                [roomViewController displayRoomPreview:roomPreviewData];
                [self pushViewController:roomViewController];
            }];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - UISearchBar delegate

- (void)refreshSearchBarItemsColor:(UISearchBar *)searchBar
{
    // bar tint color
    searchBar.barTintColor = searchBar.tintColor = ThemeService.shared.theme.tintColor;
    searchBar.tintColor = ThemeService.shared.theme.tintColor;
    
    // FIXME: this all seems incredibly fragile and tied to gutwrenching the current UISearchBar internals.
    
    // text color
    UITextField *searchBarTextField = searchBar.vc_searchTextField;
    searchBarTextField.textColor = ThemeService.shared.theme.textSecondaryColor;
    
    // Magnifying glass icon.
    UIImageView *leftImageView = (UIImageView *)searchBarTextField.leftView;
    leftImageView.image = [leftImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    leftImageView.tintColor = ThemeService.shared.theme.tintColor;
    
    // remove the gray background color
    UIView *effectBackgroundTop =  [searchBarTextField valueForKey:@"_effectBackgroundTop"];
    UIView *effectBackgroundBottom =  [searchBarTextField valueForKey:@"_effectBackgroundBottom"];
    effectBackgroundTop.hidden = YES;
    effectBackgroundBottom.hidden = YES;
    
    // place holder
    searchBarTextField.textColor = ThemeService.shared.theme.placeholderTextColor;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Update search results.
    NSUInteger index;
    MXGroupRoom *groupRoom;
    
    searchText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (!currentSearchText.length || [searchText hasPrefix:currentSearchText] == NO)
    {
        // Copy participants and invited participants
        filteredGroupRooms = [NSMutableArray arrayWithArray:groupRooms];
    }
    
    currentSearchText = searchText;
    
    // Filter group participants
    if (currentSearchText.length)
    {
        for (index = 0; index < filteredGroupRooms.count;)
        {
            groupRoom = filteredGroupRooms[index];
            
            NSString *displayName = groupRoom.name;
            if (!displayName)
            {
                displayName = groupRoom.canonicalAlias;
            }
            if (!displayName)
            {
                displayName = groupRoom.roomId;
            }
            
            if ([displayName rangeOfString:currentSearchText options:NSCaseInsensitiveSearch].location == NSNotFound)
            {
                [filteredGroupRooms removeObjectAtIndex:index];
            }
            else
            {
                index++;
            }
        }
    }
    else
    {
        filteredGroupRooms = nil;
    }
    
    // Refresh display
    [self refreshTableView];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
    
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // "Done" key has been pressed.
    
    // Dismiss keyboard
    [_searchBarView resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if (currentSearchText)
    {
        currentSearchText = nil;
        filteredGroupRooms = nil;
        
        [self refreshTableView];
    }
    
    searchBar.text = nil;
    // Leave search
    [searchBar resignFirstResponder];
}

@end
