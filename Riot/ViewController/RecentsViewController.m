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

#import "RecentsViewController.h"
#import "RecentsDataSource.h"
#import "RecentTableViewCell.h"

#import "UnifiedSearchViewController.h"

#import "MXRoom+Riot.h"

#import "NSBundle+MatrixKit.h"

#import "RoomViewController.h"

#import "InviteRecentTableViewCell.h"
#import "DirectoryRecentTableViewCell.h"
#import "RoomIdOrAliasTableViewCell.h"

#import "AppDelegate.h"

@interface RecentsViewController ()
{
    // The room identifier related to the cell which is in editing mode (if any).
    NSString *editedRoomId;
    
    // Tell whether a recents refresh is pending (suspended during editing mode).
    BOOL isRefreshPending;
    
    // recents drag and drop management
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
    
    // The gradient view displayed above the screen
    CAGradientLayer* tableViewMaskLayer;
    
    MXHTTPOperation *roomCreationRequest;
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

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kRiotNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // Set default screen name
    _screenName = @"RecentsScreen";
    
    _enableStickyHeaders = NO;
    
    displayedSectionHeaders = [NSMutableArray array];
    
    // Set itself as delegate by default.
    self.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Adjust Bottom constraint to take into account tabBar.
    [NSLayoutConstraint deactivateConstraints:@[_stickyHeadersBottomContainerBottomConstraint]];
    _stickyHeadersBottomContainerBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                                                 attribute:NSLayoutAttributeTop
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:self.stickyHeadersBottomContainer
                                                                                 attribute:NSLayoutAttributeBottom
                                                                                multiplier:1.0f
                                                                                  constant:0.0f];
    [NSLayoutConstraint activateConstraints:@[_stickyHeadersBottomContainerBottomConstraint]];
    
    self.recentsTableView.accessibilityIdentifier = @"RecentsVCTableView";
    
    // Register here the customized cell view class used to render recents
    [self.recentsTableView registerNib:RecentTableViewCell.nib forCellReuseIdentifier:RecentTableViewCell.defaultReuseIdentifier];
    [self.recentsTableView registerNib:InviteRecentTableViewCell.nib forCellReuseIdentifier:InviteRecentTableViewCell.defaultReuseIdentifier];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onRecentsLongPress:)];
    [self.recentsTableView addGestureRecognizer:longPress];

    self.recentsTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    // Hide line separators of empty cells
    self.recentsTableView.tableFooterView = [[UIView alloc] init];
    
    // Observe UIApplicationDidEnterBackgroundNotification to refresh bubbles when app leaves the foreground state.
    UIApplicationDidEnterBackgroundNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Leave potential editing mode
        [self setEditing:NO];
        
    }];
}

- (void)destroy
{
    [super destroy];
    
    if (currentAlert)
    {
        [currentAlert dismiss:NO];
        currentAlert = nil;
    }
    
    if (UIApplicationDidEnterBackgroundNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationDidEnterBackgroundNotificationObserver];
        UIApplicationDidEnterBackgroundNotificationObserver = nil;
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
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:_screenName];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
    
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
    [self setEditing:NO];
    
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
    
    // sanity check
    if (tableViewMaskLayer)
    {
        CGRect frame = self.view.frame;
        frame.size.height -= self.bottomLayoutGuide.length;
        tableViewMaskLayer.frame = frame;
    }
}

#pragma mark - Override MXKRecentListViewController

- (void)refreshRecentsTable
{
    // do not refresh if there is a pending recent drag and drop
    if (movingCellPath)
    {
        return;
    }
    
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
            // Cancel the editing mode
            editedRoomId = nil;
        }
    }
    
    isRefreshPending = NO;
    
    [self.recentsTableView reloadData];
    
    if (_shouldScrollToTopOnRefresh)
    {
        [self scrollToTop:NO];
        _shouldScrollToTopOnRefresh = NO;
    }
    
    [self updateStickyHeaders];
    
    // In case of split view controller where the primary and secondary view controllers are displayed side-by-side on screen,
    // the selected room (if any) is updated and kept visible.
    if (!self.splitViewController.isCollapsed)
    {
        [self refreshCurrentSelectedCell:YES];
    }
}

- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    // Deduce the bottom constraint for the table view (Don't forget the potential tabBar)
    CGFloat tableViewBottomConst = keyboardHeight - self.bottomLayoutGuide.length;
    // Check whether the keyboard is over the tabBar
    if (tableViewBottomConst < 0)
    {
        tableViewBottomConst = 0;
    }
    
    // Update constraints
    _stickyHeadersBottomContainerBottomConstraint.constant = tableViewBottomConst;
    
    // Force layout immediately to take into account new constraint
    [self.view layoutIfNeeded];
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

#pragma mark -

- (void)setEnableStickyHeaders:(BOOL)enableStickyHeaders
{
    if (_enableStickyHeaders != enableStickyHeaders)
    {
        _enableStickyHeaders = enableStickyHeaders;
        
        [self refreshRecentsTable];
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
    firstDisplayedSectionHeaderPosY = 0;
}

- (void)updateStickyHeaders
{
    // Force reset existing sticky headers if any
    [self resetStickyHeaders];
    
    NSInteger sectionsCount = self.recentsTableView.numberOfSections;
    
    if (self.enableStickyHeaders && sectionsCount)
    {
        NSUInteger topContainerOffset = 0;
        NSUInteger bottomContainerOffset = 0;
        CGRect frame;
        
        UIView *sectionHeader = [self tableView:self.recentsTableView viewForStickyHeaderInSection:0];
        sectionHeader.tag = 0;
        [self.stickyHeadersTopContainer addSubview:sectionHeader];
        topContainerOffset = sectionHeader.frame.size.height;
        
        for (NSUInteger index = 1; index < sectionsCount - 1; index++)
        {
            sectionHeader = [self tableView:self.recentsTableView viewForStickyHeaderInSection:index];
            sectionHeader.tag = index;
            frame = sectionHeader.frame;
            frame.origin.y = topContainerOffset;
            sectionHeader.frame = frame;
            [self.stickyHeadersTopContainer addSubview:sectionHeader];
            topContainerOffset += frame.size.height;
            
            sectionHeader = [self tableView:self.recentsTableView viewForStickyHeaderInSection:index];
            sectionHeader.tag = index;
            frame = sectionHeader.frame;
            frame.origin.y = bottomContainerOffset;
            sectionHeader.frame = frame;
            [self.stickyHeadersBottomContainer addSubview:sectionHeader];
            bottomContainerOffset += frame.size.height;
        }
        
        if (sectionsCount > 1)
        {
            sectionHeader = [self tableView:self.recentsTableView viewForStickyHeaderInSection:sectionsCount - 1];
            sectionHeader.tag = sectionsCount - 1;
            frame = sectionHeader.frame;
            frame.origin.y = bottomContainerOffset;
            sectionHeader.frame = frame;
            [self.stickyHeadersBottomContainer addSubview:sectionHeader];
        }
    }
}

#pragma mark - Internal methods

- (void)scrollToTop:(BOOL)animated
{
    [self.recentsTableView setContentOffset:CGPointMake(-self.recentsTableView.contentInset.left, -self.recentsTableView.contentInset.top) animated:animated];
}

-(void)showPublicRoomsDirectory
{
    // Here the recents view controller is displayed inside a unified search view controller.
    // Sanity check
    if (self.parentViewController && [self.parentViewController isKindOfClass:UnifiedSearchViewController.class])
    {
        // Show the directory screen
        [((UnifiedSearchViewController*)self.parentViewController) showPublicRoomsDirectory];
    }
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    id<MXKRecentCellDataStoring> cellDataStoring = (id<MXKRecentCellDataStoring> )cellData;
    
    if (cellDataStoring.roomSummary.room.state.membership != MXMembershipInvite)
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
        [[AppDelegate theDelegate].masterTabBarController selectRoomWithId:invitedRoom.state.roomId andEventId:nil inMatrixSession:invitedRoom.mxSession];
    }
    else if ([actionIdentifier isEqualToString:kInviteRecentTableViewCellDeclineButtonPressed])
    {
        // Retrieve the invited room
        MXRoom *invitedRoom = userInfo[kInviteRecentTableViewCellRoomKey];
        
        [self setEditing:NO];
        
        // Decline the invitation
        [invitedRoom leave:^{
            
            [self.recentsTableView reloadData];
            
        } failure:^(NSError *error) {
            
            NSLog(@"[RecentsViewController] Failed to reject an invited room (%@)", invitedRoom.state.roomId);
            
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
        if (room.state.membership == MXMembershipInvite)
        {
            return actions;
        }
        
        // Store the identifier of the room related to the edited cell.
        editedRoomId = room.state.roomId;
        
        NSString* title = @"      ";
        
        // Direct chat toggle
        BOOL isDirect = room.isDirect;
        
        UITableViewRowAction *directAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self makeDirectEditedRoom:!isDirect];
            
        }];
        
        UIImage *actionIcon = isDirect ? [UIImage imageNamed:@"directChatOff"] : [UIImage imageNamed:@"directChatOn"];
        directAction.backgroundColor = [MXKTools convertImageToPatternColor:isDirect ? @"directChatOff" : @"directChatOn" backgroundColor:kRiotColorLightGrey patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
        [actions insertObject:directAction atIndex:0];
        
        
        // Notification toggle
        BOOL isMuted = room.isMute || room.isMentionsOnly;
        
        UITableViewRowAction *muteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self muteEditedRoomNotifications:!isMuted];
            
        }];
        
        actionIcon = isMuted ? [UIImage imageNamed:@"notifications"] : [UIImage imageNamed:@"notificationsOff"];
        muteAction.backgroundColor = [MXKTools convertImageToPatternColor:isMuted ? @"notifications" : @"notificationsOff" backgroundColor:kRiotColorLightGrey patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
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
            action.backgroundColor = [MXKTools convertImageToPatternColor:@"favouriteOff" backgroundColor:kRiotColorLightGrey patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
            [actions insertObject:action atIndex:0];
        }
        else
        {
            UITableViewRowAction* action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self updateEditedRoomTag:kMXRoomTagFavourite];
                
            }];
            
            actionIcon = [UIImage imageNamed:@"favourite"];
            action.backgroundColor = [MXKTools convertImageToPatternColor:@"favourite" backgroundColor:kRiotColorLightGrey patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
            [actions insertObject:action atIndex:0];
        }
        
        if (currentTag && [kMXRoomTagLowPriority isEqualToString:currentTag.name])
        {
            UITableViewRowAction* action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self updateEditedRoomTag:nil];
                
            }];
            
            actionIcon = [UIImage imageNamed:@"priorityHigh"];
            action.backgroundColor = [MXKTools convertImageToPatternColor:@"priorityHigh" backgroundColor:kRiotColorLightGrey patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
            [actions insertObject:action atIndex:0];
        }
        else
        {
            UITableViewRowAction* action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:title handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self updateEditedRoomTag:kMXRoomTagLowPriority];
                
            }];
            
            actionIcon = [UIImage imageNamed:@"priorityLow"];
            action.backgroundColor = [MXKTools convertImageToPatternColor:@"priorityLow" backgroundColor:kRiotColorLightGrey patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
            [actions insertObject:action atIndex:0];
        }
        
        UITableViewRowAction *leaveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:title  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self leaveEditedRoom];
            
        }];
        
        actionIcon = [UIImage imageNamed:@"leave"];
        leaveAction.backgroundColor = [MXKTools convertImageToPatternColor:@"leave" backgroundColor:kRiotColorLightGrey patternSize:CGSizeMake(74, 74) resourceSize:actionIcon.size];
        
        [actions insertObject:leaveAction atIndex:0];
    }
    
    return actions;
}

- (void)tableView:(UITableView*)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    editedRoomId = nil;
    
    if (isRefreshPending)
    {
        [self refreshRecentsTable];
    }
}

- (void)leaveEditedRoom
{
    if (editedRoomId)
    {
        // Check whether the user didn't leave the room yet
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (room)
        {
            [self startActivityIndicator];
            
            // cancel pending uploads/downloads
            // they are useless by now
            [MXMediaManager cancelDownloadsInCacheFolder:room.state.roomId];
            
            // TODO GFO cancel pending uploads related to this room
            
            NSLog(@"[RecentsViewController] Leave room (%@)", room.state.roomId);
            
            [room leave:^{
                
                [self stopActivityIndicator];
                
                // Force table refresh
                editedRoomId = nil;
                [self refreshRecentsTable];
                
            } failure:^(NSError *error) {
                
                NSLog(@"[RecentsViewController] Failed to leave room (%@)", room.state.roomId);
                
                // Notify MatrixKit user
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                
                [self stopActivityIndicator];
                
                // Leave editing mode
                [self setEditing:NO];
            }];
        }
        else
        {
            // Leave editing mode
            [self setEditing:NO];
        }
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
                editedRoomId = nil;
                [self refreshRecentsTable];
                
            }];
        }
        else
        {
            // Leave editing mode
            [self setEditing:NO];
        }
    }
}

- (void)makeDirectEditedRoom:(BOOL)isDirect
{
    if (editedRoomId)
    {
        // Check whether the user didn't leave the room
        MXRoom *room = [self.mainSession roomWithRoomId:editedRoomId];
        if (room)
        {
            [self startActivityIndicator];
            
            [room setIsDirect:isDirect withUserId:nil success:^{
                
                [self stopActivityIndicator];
                
                // Leave editing mode
                [self setEditing:NO];

                
            } failure:^(NSError *error) {
                
                [self stopActivityIndicator];
                
                NSLog(@"[RecentsViewController] Failed to update direct tag of the room (%@)", editedRoomId);
                
                // Notify MatrixKit user
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                
                // Leave editing mode
                [self setEditing:NO];
                
            }];
        }
        else
        {
            // Leave editing mode
            [self setEditing:NO];
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
                    [self setEditing:NO];
                    
                }];
            }
            else
            {
                [room allMessages:^{
                    
                    [self stopActivityIndicator];
                    
                    // Leave editing mode
                    [self setEditing:NO];
                    
                }];
            }
        }
        else
        {
            // Leave editing mode
            [self setEditing:NO];
        }
    }
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0f;
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
            
            firstDisplayedSectionHeaderPosY = view.frame.origin.y;
        }
        else
        {
            [displayedSectionHeaders addObject:view];
            
            // Update the layout of the bottom sticky headers container
            CGFloat containerHeight = 0;
            CGRect bounds = self.stickyHeadersBottomContainer.frame;
            for (UIView *header in _stickyHeadersBottomContainer.subviews)
            {
                if (header.tag > section)
                {
                    if (header.tag == section + 1)
                    {
                        bounds.origin.y = header.frame.origin.y;
                    }
                    
                    containerHeight += header.frame.size.height;
                }
            }
            self.stickyHeadersBottomContainerHeightConstraint.constant = containerHeight;
            self.stickyHeadersBottomContainer.bounds = bounds;
        }
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
                
                firstDisplayedSectionHeader = displayedSectionHeaders.firstObject;
                firstDisplayedSectionHeaderPosY = firstDisplayedSectionHeader.frame.origin.y;
                
                // Update the layout of the top sticky headers container
                CGFloat containerHeight = 0;
                for (UIView *header in _stickyHeadersTopContainer.subviews)
                {
                    if (header.tag <= section)
                    {
                        containerHeight += header.frame.size.height;
                    }
                    else
                    {
                        break;
                    }
                }
                self.stickyHeadersTopContainerHeightConstraint.constant = containerHeight;
            }
            else
            {
                [displayedSectionHeaders removeLastObject];
                
                // Update the layout of the bottom sticky headers container
                CGFloat containerHeight = 0;
                CGRect bounds = self.stickyHeadersBottomContainer.frame;
                for (UIView *header in _stickyHeadersBottomContainer.subviews)
                {
                    if (header.tag == section)
                    {
                        bounds.origin.y = header.frame.origin.y;
                        containerHeight = header.frame.size.height;
                    }
                    else if (header.tag > section)
                    {
                        containerHeight += header.frame.size.height;
                    }
                }
                self.stickyHeadersBottomContainerHeightConstraint.constant = containerHeight;
                self.stickyHeadersBottomContainer.bounds = bounds;
            }
        }
    }
}

#pragma mark - UIScrollViewDelegate

//- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
//{
//    [super scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
//}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_enableStickyHeaders)
    {
        UIView *firstDisplayedSectionHeader = displayedSectionHeaders.firstObject;
        
        //    NSLog(@"RecentsViewController: scrollViewDidScroll first header %tu ", firstDisplayedSectionHeader.tag);
        //    NSLog(@"RecentsViewController: scrollViewDidScroll contentOffsetY %f (%f)", self.recentsTableView.contentOffset.y, firstDisplayedSectionHeader.frame.origin.y);
        
        if (firstDisplayedSectionHeader)
        {
            if (firstDisplayedSectionHeader.frame.origin.y == firstDisplayedSectionHeaderPosY)
            {
                if (self.recentsTableView.contentOffset.y > firstDisplayedSectionHeader.frame.origin.y)
                {
                    CGFloat delta = self.recentsTableView.contentOffset.y - firstDisplayedSectionHeader.frame.origin.y;
                    
                    // Update the layout of the top sticky headers container
                    CGFloat containerHeight = 0;
                    for (UIView *header in _stickyHeadersTopContainer.subviews)
                    {
                        if (header.tag < firstDisplayedSectionHeader.tag)
                        {
                            containerHeight += header.frame.size.height;
                        }
                        else if (header.tag == firstDisplayedSectionHeader.tag)
                        {
                            if (delta < header.frame.size.height)
                            {
                                containerHeight += delta;
                            }
                            else
                            {
                                containerHeight += header.frame.size.height;
                            }
                            
                        }
                    }
                    self.stickyHeadersTopContainerHeightConstraint.constant = containerHeight;
                }
            }
            else
            {
                // Update the layout of the top sticky headers container
                CGFloat containerHeight = 0;
                for (UIView *header in _stickyHeadersTopContainer.subviews)
                {
                    if (header.tag < firstDisplayedSectionHeader.tag)
                    {
                        containerHeight += header.frame.size.height;
                    }
                }
                self.stickyHeadersTopContainerHeightConstraint.constant = containerHeight;
                firstDisplayedSectionHeaderPosY = firstDisplayedSectionHeader.frame.origin.y;
            }
        }
    }
    
    [super scrollViewDidScroll:scrollView];
}

#pragma mark - recents drag & drop management

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
    
    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
    UIGestureRecognizerState state = longPress.state;
    
    // check if there is a moving cell during the long press managemnt
    if ((state != UIGestureRecognizerStateBegan) && !movingCellPath)
    {
        return;
    }
    
    CGPoint location = [longPress locationInView:self.recentsTableView];
    
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

#pragma mark - Room creation

- (void)addRoomCreationButton
{
    // Add blur mask programmatically
    tableViewMaskLayer = [CAGradientLayer layer];
    
    CGColorRef opaqueWhiteColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
    CGColorRef transparentWhiteColor = [UIColor colorWithWhite:1.0 alpha:0].CGColor;
    
    tableViewMaskLayer.colors = [NSArray arrayWithObjects:(__bridge id)transparentWhiteColor, (__bridge id)transparentWhiteColor, (__bridge id)opaqueWhiteColor, nil];
    
    // display a gradient to the rencents bottom (20% of the bottom of the screen)
    tableViewMaskLayer.locations = [NSArray arrayWithObjects:
                                    [NSNumber numberWithFloat:0],
                                    [NSNumber numberWithFloat:0.85],
                                    [NSNumber numberWithFloat:1.0], nil];
    
    tableViewMaskLayer.frame = self.recentsTableView.frame;
    tableViewMaskLayer.anchorPoint = CGPointZero;
    
    // CAConstraint is not supported on IOS.
    // it seems only being supported on Mac OS.
    // so viewDidLayoutSubviews will refresh the layout bounds.
    [self.view.layer addSublayer:tableViewMaskLayer];
    
    // Add room create button
    createNewRoomImageView = [[UIImageView alloc] init];
    [createNewRoomImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:createNewRoomImageView];
    
    createNewRoomImageView.backgroundColor = [UIColor clearColor];
    createNewRoomImageView.contentMode = UIViewContentModeCenter;
    createNewRoomImageView.image = [UIImage imageNamed:@"create_room"];
    
    CGFloat side = 78.0f;
    NSLayoutConstraint* widthConstraint = [NSLayoutConstraint constraintWithItem:createNewRoomImageView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1
                                                                        constant:side];
    
    NSLayoutConstraint* heightConstraint = [NSLayoutConstraint constraintWithItem:createNewRoomImageView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1
                                                                         constant:side];
    
    NSLayoutConstraint* trailingConstraint = [NSLayoutConstraint constraintWithItem:createNewRoomImageView
                                                                          attribute:NSLayoutAttributeTrailing
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.view
                                                                          attribute:NSLayoutAttributeTrailing
                                                                         multiplier:1
                                                                           constant:0];
    
    NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                                        attribute:NSLayoutAttributeTop
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:createNewRoomImageView
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1
                                                                         constant:9];
    
    // Available on iOS 8 and later
    [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint, trailingConstraint, bottomConstraint]];
    
    createNewRoomImageView.userInteractionEnabled = YES;
    
    // Handle tap gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRoomCreationButtonPressed)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [createNewRoomImageView addGestureRecognizer:tap];
}

- (void)onRoomCreationButtonPressed
{
    [self createAnEmptyRoom];
}

- (void)createAnEmptyRoom
{
    // Sanity check
    if (self.mainSession)
    {
        // Create one room at time
        if (!roomCreationRequest)
        {
            [self startActivityIndicator];
            
            // Create an empty room.
            roomCreationRequest = [self.mainSession createRoom:nil
                                                    visibility:kMXRoomDirectoryVisibilityPrivate
                                                     roomAlias:nil
                                                         topic:nil
                                                       success:^(MXRoom *room) {
                                                           
                                                           roomCreationRequest = nil;
                                                           [self stopActivityIndicator];
                                                           if (currentAlert)
                                                           {
                                                               [currentAlert dismiss:NO];
                                                               currentAlert = nil;
                                                           }
                                                           
                                                           [[AppDelegate theDelegate].masterTabBarController selectRoomWithId:room.state.roomId andEventId:nil inMatrixSession:self.mainSession];
                                                           
                                                           // Force the expanded header
                                                           [AppDelegate theDelegate].masterTabBarController.currentRoomViewController.showExpandedHeader = YES;
                                                           
                                                       } failure:^(NSError *error) {
                                                           
                                                           roomCreationRequest = nil;
                                                           [self stopActivityIndicator];
                                                           if (currentAlert)
                                                           {
                                                               [currentAlert dismiss:NO];
                                                               currentAlert = nil;
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
            currentAlert = [[MXKAlert alloc] initWithTitle:nil
                                                   message:NSLocalizedStringFromTable(@"room_creation_wait_for_creation", @"Vector", nil)
                                                     style:MXKAlertStyleAlert];
            
            currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                                        style:MXKAlertActionStyleCancel
                                                                      handler:^(MXKAlert *alert) {
                                                                          
                                                                          __strong __typeof(weakSelf)strongSelf = weakSelf;
                                                                          strongSelf->currentAlert = nil;
                                                                          
                                                                      }];
            currentAlert.mxkAccessibilityIdentifier = @"RecentsVCRoomCreationInProgressAlert";
            [currentAlert showInViewController:self];
        }
    }
}

#pragma mark - MXKRecentListViewControllerDelegate

- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoom:(NSString *)roomId inMatrixSession:(MXSession *)matrixSession
{
    // Open the room
    [[AppDelegate theDelegate].masterTabBarController selectRoomWithId:roomId andEventId:nil inMatrixSession:matrixSession];
}

@end
