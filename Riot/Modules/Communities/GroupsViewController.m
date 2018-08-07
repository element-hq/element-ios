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

#import "GroupsViewController.h"

#import "GroupTableViewCell.h"
#import "GroupInviteTableViewCell.h"

#import "AppDelegate.h"

@interface GroupsViewController ()
{
    // Tell whether a groups refresh is pending (suspended during editing mode).
    BOOL isRefreshPending;
    
    // Observe UIApplicationDidEnterBackgroundNotification to cancel editing mode when app leaves the foreground state.
    id UIApplicationDidEnterBackgroundNotificationObserver;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;
    
    MXHTTPOperation *currentRequest;
    
    // The fake search bar displayed at the top of the recents table. We switch on the actual search bar (self.groupsSearchBar)
    // when the user selects it.
    UISearchBar *tableSearchBar;
    
    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
}

@end

@implementation GroupsViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // Enable the search bar in the recents table, and remove the search option from the navigation bar.
    _enableSearchBar = YES;
    self.enableBarButtonSearch = NO;
    
    // Create the fake search bar
    tableSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 600, 44)];
    tableSearchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    tableSearchBar.showsCancelButton = NO;
    tableSearchBar.placeholder = NSLocalizedStringFromTable(@"search_default_placeholder", @"Vector", nil);
    tableSearchBar.delegate = self;
    
    // Set itself as delegate by default.
    self.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.accessibilityIdentifier = @"GroupsVCView";
    self.groupsTableView.accessibilityIdentifier = @"GroupsVCTableView";
    
    //Register here the customized cell view class used to render groups
    [self.groupsTableView registerNib:GroupTableViewCell.nib forCellReuseIdentifier:GroupTableViewCell.defaultReuseIdentifier];
    [self.groupsTableView registerNib:GroupInviteTableViewCell.nib forCellReuseIdentifier:GroupInviteTableViewCell.defaultReuseIdentifier];
    
    // Hide line separators of empty cells
    self.groupsTableView.tableFooterView = [[UIView alloc] init];
    
    // Enable self-sizing cells and section headers.
    self.groupsTableView.rowHeight = UITableViewAutomaticDimension;
    self.groupsTableView.estimatedRowHeight = 74;
    self.groupsTableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.groupsTableView.estimatedSectionHeaderHeight = 30;
    self.groupsTableView.estimatedSectionFooterHeight = 0;
    
    // Observe UIApplicationDidEnterBackgroundNotification to refresh bubbles when app leaves the foreground state.
    UIApplicationDidEnterBackgroundNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Leave potential editing mode
        [self cancelEditionMode:isRefreshPending];
        
    }];
    
    self.groupsSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.groupsSearchBar.placeholder = NSLocalizedStringFromTable(@"search_default_placeholder", @"Vector", nil);
    
    // @TODO: Add programmatically the (+) button.
    //[self addPlusButton];
    
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
    self.groupsTableView.backgroundColor = kRiotPrimaryBgColor;
    topview.backgroundColor = kRiotSecondaryBgColor;
    self.view.backgroundColor = kRiotPrimaryBgColor;
    
    tableSearchBar.barStyle = self.groupsSearchBar.barStyle = kRiotDesignSearchBarStyle;
    tableSearchBar.tintColor = self.groupsSearchBar.tintColor = kRiotDesignSearchBarTintColor;
    
    if (self.groupsTableView.dataSource)
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
    
    self.groupsTableView.editing = editing;
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
    [[Analytics sharedInstance] trackScreen:@"Groups"];
    
    // Deselect the current selected row, it will be restored on viewDidAppear (if any)
    NSIndexPath *indexPath = [self.groupsTableView indexPathForSelectedRow];
    if (indexPath)
    {
        [self.groupsTableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self scrollToTop:YES];
        
    }];
    
    [AppDelegate theDelegate].masterTabBarController.navigationItem.title = NSLocalizedStringFromTable(@"title_groups", @"Vector", nil);
    [AppDelegate theDelegate].masterTabBarController.navigationController.navigationBar.tintColor = kRiotColorBlue;
    [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor = kRiotColorBlue;
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
    
    if ([AppDelegate theDelegate].masterTabBarController.tabBar.tintColor == kRiotColorBlue && ![AppDelegate theDelegate].masterTabBarController.selectedGroup)
    {
        // Restore default tintColor
        [AppDelegate theDelegate].masterTabBarController.navigationController.navigationBar.tintColor = kRiotColorGreen;
        [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor = kRiotColorGreen;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Release the current selected item (if any) except if the second view controller is still visible.
    if (self.splitViewController.isCollapsed)
    {
        // Release the current selected group (if any).
        [[AppDelegate theDelegate].masterTabBarController releaseSelectedItem];
    }
    else
    {
        // In case of split view controller where the primary and secondary view controllers are displayed side-by-side onscreen,
        // the selected group (if any) is highlighted.
        [self refreshCurrentSelectedCell:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark - Override MXKGroupListViewController

- (void)refreshGroupsTable
{
    // Refresh the tabBar icon badges
    [[AppDelegate theDelegate].masterTabBarController refreshTabBarBadges];
    
    isRefreshPending = NO;
    
    if (editedGroupId)
    {
        // Check whether the user didn't leave the room
        if ([self.dataSource cellIndexPathWithGroupId:editedGroupId])
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
    
    [self.groupsTableView reloadData];
    
    // Check conditions to display the fake search bar into the table header
    if (_enableSearchBar && self.groupsSearchBar.isHidden && self.groupsTableView.tableHeaderView == nil)
    {
        // Add the search bar by hiding it by default.
        self.groupsTableView.tableHeaderView = tableSearchBar;
        self.groupsTableView.contentOffset = CGPointMake(0, self.groupsTableView.contentOffset.y + tableSearchBar.frame.size.height);
    }
    
    if (_shouldScrollToTopOnRefresh)
    {
        [self scrollToTop:NO];
        _shouldScrollToTopOnRefresh = NO;
    }
    
    // In case of split view controller where the primary and secondary view controllers are displayed side-by-side on screen,
    // the selected group (if any) is updated.
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
        self.groupsTableView.tableHeaderView = nil;
        self.groupsTableView.contentInset = UIEdgeInsetsZero;
    }
}

#pragma mark -

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    // Update here the index of the current selected cell (if any) - Useful in landscape mode with split view controller.
    NSIndexPath *currentSelectedCellIndexPath = nil;
    MasterTabBarController *masterTabBarController = [AppDelegate theDelegate].masterTabBarController;
    if (masterTabBarController.currentGroupDetailViewController)
    {
        // Look for the rank of this selected group in displayed groups
        currentSelectedCellIndexPath = [self.dataSource cellIndexPathWithGroupId:masterTabBarController.selectedGroup.groupId];
    }
    
    if (currentSelectedCellIndexPath)
    {
        // Select the right row
        [self.groupsTableView selectRowAtIndexPath:currentSelectedCellIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        
        if (forceVisible)
        {
            // Scroll table view to make the selected row appear at second position
            NSInteger topCellIndexPathRow = currentSelectedCellIndexPath.row ? currentSelectedCellIndexPath.row - 1: currentSelectedCellIndexPath.row;
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:topCellIndexPathRow inSection:currentSelectedCellIndexPath.section];
            [self.groupsTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    }
    else
    {
        NSIndexPath *indexPath = [self.groupsTableView indexPathForSelectedRow];
        if (indexPath)
        {
            [self.groupsTableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

- (void)cancelEditionMode:(BOOL)forceRefresh
{
    if (self.groupsTableView.isEditing || self.isEditing)
    {
        // Leave editing mode first
        isRefreshPending = forceRefresh;
        [self setEditing:NO];
    }
    else if (forceRefresh)
    {
        // Clean
        editedGroupId = nil;
        
        [self refreshGroupsTable];
    }
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    id<MXKGroupCellDataStoring> cellDataStoring = (id<MXKGroupCellDataStoring> )cellData;
    
    if (cellDataStoring.group.membership != MXMembershipInvite)
    {
        return GroupTableViewCell.class;
    }
    else
    {
        return GroupInviteTableViewCell.class;
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
    // Handle here user actions on groups for Riot app
    if ([actionIdentifier isEqualToString:kGroupInviteTableViewCellPreviewButtonPressed])
    {
        // Retrieve the invited group
        MXGroup *invitedGroup = userInfo[kGroupInviteTableViewCellRoomKey];

        // Display the room preview
        [[AppDelegate theDelegate].masterTabBarController selectGroup:invitedGroup inMatrixSession:self.mainSession];
    }
    else if ([actionIdentifier isEqualToString:kGroupInviteTableViewCellDeclineButtonPressed])
    {
        // Retrieve the invited group
        MXGroup *invitedGroup = userInfo[kGroupInviteTableViewCellRoomKey];
        
        NSIndexPath *indexPath = [self.dataSource cellIndexPathWithGroupId:invitedGroup.groupId];
        if (indexPath)
        {
            [self.dataSource leaveGroupAtIndexPath:indexPath];
        }
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

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    
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

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    MXKTableViewHeaderFooterWithLabel *sectionHeader;
    
    if (tableView.numberOfSections > 1)
    {
        sectionHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MXKTableViewHeaderFooterWithLabel.defaultReuseIdentifier];
        sectionHeader.mxkContentView.backgroundColor = kRiotSecondaryBgColor;
        sectionHeader.mxkLabel.textColor = kRiotPrimaryTextColor;
        sectionHeader.mxkLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        
        NSString* title = [self.dataSource tableView:tableView titleForHeaderInSection:section];
        NSUInteger count = [self.dataSource tableView:tableView numberOfRowsInSection:section];
        if (count)
        {
            NSString *roomCount = [NSString stringWithFormat:@"   %tu", count];
            NSMutableAttributedString *mutableSectionTitle = [[NSMutableAttributedString alloc] initWithString:title
                                                                                                    attributes:@{NSForegroundColorAttributeName: kRiotPrimaryTextColor}];
            [mutableSectionTitle appendAttributedString:[[NSMutableAttributedString alloc] initWithString:roomCount
                                                                                               attributes:@{NSForegroundColorAttributeName: kRiotAuxiliaryColor}]];

            sectionHeader.mxkLabel.attributedText = mutableSectionTitle;
        }
        else
        {
            sectionHeader.mxkLabel.text = title;
        }
    }
    
    return sectionHeader;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [self.groupsTableView cellForRowAtIndexPath:indexPath];
    
    if ([cell isKindOfClass:[GroupInviteTableViewCell class]])
    {
        // hide the selection
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    else
    {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* actions;
    
    // add the swipe to delete only on joined group
    if (indexPath.section == self.dataSource.joinedGroupsSection)
    {
        // Store the identifier of the room related to the edited cell.
        id<MXKGroupCellDataStoring> cellData = [self.dataSource cellDataAtIndex:indexPath];
        editedGroupId = cellData.group.groupId;
        
        actions = [[NSMutableArray alloc] init];
        
        // Patch: Force the width of the button by adding whitespace characters into the title string.
        UITableViewRowAction *leaveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"        "  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self.dataSource leaveGroupAtIndexPath:indexPath];
            
        }];
        
        leaveAction.backgroundColor = [MXKTools convertImageToPatternColor:@"remove_icon_blue" backgroundColor:kRiotSecondaryBgColor patternSize:CGSizeMake(74, 74) resourceSize:CGSizeMake(24, 24)];
        [actions insertObject:leaveAction atIndex:0];
    }
    
    return actions;
}
    
- (void)tableView:(UITableView*)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self cancelEditionMode:isRefreshPending];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    
    if (scrollView == self.groupsTableView)
    {
        if (!self.groupsSearchBar.isHidden)
        {
            if (!self.groupsSearchBar.text.length && (scrollView.contentOffset.y + scrollView.mxk_adjustedContentInset.top > self.groupsSearchBar.frame.size.height))
            {
                // Hide the search bar
                [self hideSearchBar:YES];
                
                // Refresh display
                [self refreshGroupsTable];
            }
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
    plusButtonImageView.image = [UIImage imageNamed:@"create_group"];
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
    
//    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_recents_start_chat_with", @"Vector", nil)
//                                                     style:UIAlertActionStyleDefault
//                                                   handler:^(UIAlertAction * action) {
//
//                                                       if (weakSelf)
//                                                       {
//                                                           typeof(self) self = weakSelf;
//                                                           self->currentAlert = nil;
//
//                                                           [self performSegueWithIdentifier:@"presentStartChat" sender:self];
//                                                       }
//
//                                                   }]];
//
//    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_recents_create_empty_room", @"Vector", nil)
//                                                     style:UIAlertActionStyleDefault
//                                                   handler:^(UIAlertAction * action) {
//
//                                                       if (weakSelf)
//                                                       {
//                                                           typeof(self) self = weakSelf;
//                                                           self->currentAlert = nil;
//
//                                                           [self createAnEmptyRoom];
//                                                       }
//
//                                                   }]];
//
//    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_recents_join_room", @"Vector", nil)
//                                                     style:UIAlertActionStyleDefault
//                                                   handler:^(UIAlertAction * action) {
//
//                                                       if (weakSelf)
//                                                       {
//                                                           typeof(self) self = weakSelf;
//                                                           self->currentAlert = nil;
//
//                                                           [self joinARoom];
//                                                       }
//
//                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }
                                                       
                                                   }]];
    
    [currentAlert popoverPresentationController].sourceView = plusButtonImageView;
    [currentAlert popoverPresentationController].sourceRect = plusButtonImageView.bounds;
    
    [currentAlert mxk_setAccessibilityIdentifier:@"GroupsVCCreateRoomAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

//- (void)joinARoom
//{
//    [currentAlert dismissViewControllerAnimated:NO completion:nil];
//
//    __weak typeof(self) weakSelf = self;
//
//    // Prompt the user to type a room id or room alias
//    currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_recents_join_room_title", @"Vector", nil)
//                                                       message:NSLocalizedStringFromTable(@"room_recents_join_room_prompt", @"Vector", nil)
//                                                preferredStyle:UIAlertControllerStyleAlert];
//
//    [currentAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
//
//        textField.secureTextEntry = NO;
//        textField.placeholder = nil;
//        textField.keyboardType = UIKeyboardTypeDefault;
//    }];
//
//    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
//                                                     style:UIAlertActionStyleDefault
//                                                   handler:^(UIAlertAction * action) {
//
//                                                       if (weakSelf)
//                                                       {
//                                                           typeof(self) self = weakSelf;
//                                                           self->currentAlert = nil;
//                                                       }
//
//                                                   }]];
//
//    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"join", @"Vector", nil)
//                                                     style:UIAlertActionStyleDefault
//                                                   handler:^(UIAlertAction * action) {
//
//                                                       if (weakSelf)
//                                                       {
//                                                           typeof(self) self = weakSelf;
//
//                                                           UITextField *textField = [self->currentAlert textFields].firstObject;
//                                                           NSString *roomAliasOrId = textField.text;
//
//                                                           self->currentAlert = nil;
//
//                                                           [self.activityIndicator startAnimating];
//
//                                                           self->currentRequest = [self.mainSession joinRoom:textField.text success:^(MXRoom *room) {
//
//                                                               self->currentRequest = nil;
//                                                               [self.activityIndicator stopAnimating];
//
//                                                               // Show the room
//                                                               [[AppDelegate theDelegate] showRoom:room.roomId andEventId:nil withMatrixSession:self.mainSession];
//
//                                                           } failure:^(NSError *error) {
//
//                                                               NSLog(@"[RecentsViewController] Join joinARoom (%@) failed", roomAliasOrId);
//
//                                                               self->currentRequest = nil;
//                                                               [self.activityIndicator stopAnimating];
//
//                                                               // Alert user
//                                                               [[AppDelegate theDelegate] showErrorAsAlert:error];
//                                                           }];
//                                                       }
//
//                                                   }]];
//
//    [currentAlert mxk_setAccessibilityIdentifier:@"RecentsVCJoinARoomAlert"];
//    [self presentViewController:currentAlert animated:YES completion:nil];
//}

#pragma mark - Table view scrolling

- (void)scrollToTop:(BOOL)animated
{
    [self.groupsTableView setContentOffset:CGPointMake(-self.groupsTableView.mxk_adjustedContentInset.left, -self.groupsTableView.mxk_adjustedContentInset.top) animated:animated];
}

#pragma mark - MXKGroupListViewControllerDelegate

- (void)groupListViewController:(MXKGroupListViewController *)groupListViewController didSelectGroup:(MXGroup *)group inMatrixSession:(MXSession *)mxSession
{
    // Open the room
    [[AppDelegate theDelegate].masterTabBarController selectGroup:group inMatrixSession:mxSession];
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    if (searchBar == tableSearchBar)
    {
        [self hideSearchBar:NO];
        [self.groupsSearchBar becomeFirstResponder];
        return NO;
    }
    
    return YES;
    
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.groupsSearchBar setShowsCancelButton:YES animated:NO];
        
    });
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self.groupsSearchBar setShowsCancelButton:NO animated:NO];
}

@end
