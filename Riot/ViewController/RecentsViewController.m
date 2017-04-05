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

#import "RageShakeManager.h"

#import "MXRoom+Riot.h"

#import "NSBundle+MatrixKit.h"

#import "HomeViewController.h"
#import "RoomViewController.h"

#import "RiotDesignValues.h"

#import "InviteRecentTableViewCell.h"
#import "DirectoryRecentTableViewCell.h"
#import "RoomIdOrAliasTableViewCell.h"

#import "AppDelegate.h"

@interface RecentsViewController ()
{
    // The "parent" segmented view controller
    HomeViewController *homeViewController;
    
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
}

@end

@implementation RecentsViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"title_recents", @"Vector", nil);
}

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
    // Do any additional setup after loading the view, typically from a nib.
    
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
    
    // Check whether the view controller is displayed in its "parent" segmented view controller.
    if (homeViewController)
    {
        // Screen tracking (via Google Analytics)
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        if (tracker)
        {
            NSString *screenName = homeViewController.searchBarHidden ? @"RoomsList" : @"RoomsGlobalSearch";
            NSString *currentScreenName = [tracker get:kGAIScreenName];
            
            if (!currentScreenName || ![currentScreenName isEqualToString:screenName])
            {
                [tracker set:kGAIScreenName value:screenName];
                [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
            }
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
            
            // Do not refresh if there is a pending recent drag and drop
            if (!movingCellPath)
            {
                [self refreshRecentsTable];
            }
            
        }];
    }
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
    
    // Release the current selected room (if any) except if the Room ViewController is still visible (see splitViewController.isCollapsed condition)
    if (!self.splitViewController || self.splitViewController.isCollapsed)
    {
        // Release the current selected room (if any).
        [homeViewController closeSelectedRoom];
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

#pragma mark -

- (void)displayList:(MXKRecentsDataSource*)listDataSource fromHomeViewController:(HomeViewController*)homeViewController2
{
    [super displayList:listDataSource];
    homeViewController = homeViewController2;
}

#pragma mark - Internal methods

- (void)refreshRecentsTable
{
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
    
    // In case of split view controller where the primary and secondary view controllers are displayed side-by-side on screen,
    // the selected room (if any) is updated and kept visible.
    // Note: 'isCollapsed' property is available in UISplitViewController for iOS 8 and later.
    if (self.splitViewController && (![self.splitViewController respondsToSelector:@selector(isCollapsed)] || !self.splitViewController.isCollapsed))
    {
        [self refreshCurrentSelectedCell:YES];
    }
    
    if (self.dataSource.mxSession.state == MXSessionStateRunning)
    {
        // The Directory cell is displayed when the recents list is empty
        RecentsDataSource *recentsDataSource = (RecentsDataSource*)self.dataSource;
        if (recentsDataSource.hidePublicRoomsDirectory)
        {
            recentsDataSource.hidePublicRoomsDirectory = (self.recentsTableView.numberOfSections != 0);
        }
        else if (homeViewController.searchBarHidden)
        {
            recentsDataSource.hidePublicRoomsDirectory = (self.recentsTableView.numberOfSections > 1);
        }
    }
}

- (void)scrollToTop:(BOOL)animated
{
    [self.recentsTableView setContentOffset:CGPointMake(-self.recentsTableView.contentInset.left, -self.recentsTableView.contentInset.top) animated:animated];
}

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    // Update here the index of the current selected cell (if any) - Useful in landscape mode with split view controller.
    NSIndexPath *currentSelectedCellIndexPath = nil;
    if (homeViewController.currentRoomViewController)
    {
        // Look for the rank of this selected room in displayed recents
        currentSelectedCellIndexPath = [self.dataSource cellIndexPathWithRoomId:homeViewController.selectedRoomId andMatrixSession:homeViewController.selectedRoomSession];
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
    id<MXKRecentCellDataStoring> cellDataStoring = (id<MXKRecentCellDataStoring> )cellData;
    
    if (cellDataStoring.roomSummary.room.state.membership != MXMembershipInvite)
    {
        return RecentTableViewCell.defaultReuseIdentifier;
    }
    else
    {
        return InviteRecentTableViewCell.defaultReuseIdentifier;
    }
}

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    // do not refresh if there is a pending recent drag and drop
    if (movingCellPath)
    {
        return;
    }
    
    [self refreshRecentsTable];
}

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo
{
    // Handle here user actions on recents for Vector app
    if ([actionIdentifier isEqualToString:kInviteRecentTableViewCellPreviewButtonPressed])
    {
        // Retrieve the invited room
        MXRoom *invitedRoom = userInfo[kInviteRecentTableViewCellRoomKey];
        
        // Display room preview by selecting it.
        [self.delegate recentListViewController:self didSelectRoom:invitedRoom.state.roomId inMatrixSession:invitedRoom.mxSession];
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

#pragma mark - swipe actions

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
    return [(RecentsDataSource*)self.dataSource heightForHeaderInSection:section];
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
        // Show the directory screen
        [homeViewController showPublicRoomsDirectory];
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

- (IBAction) onRecentsLongPress:(id)sender
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


@end
