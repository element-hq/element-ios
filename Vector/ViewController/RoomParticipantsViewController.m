/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "RoomParticipantsViewController.h"

#import "RageShakeManager.h"

#import "AppDelegate.h"

#import "VectorDesignValues.h"

@interface RoomParticipantsViewController ()
{
    // Add participants section
    MXKTableViewCellWithSearchBar *addParticipantsSearchBarCell;
    NSString *addParticipantsSearchText;
    
    // Search result section
    NSMutableArray *filteredParticipants;
    
    MXKAlert *currentAlert;
    
    // Mask view while processing a request
    UIActivityIndicatorView * pendingMaskSpinnerView;
    
    // The members events listener.
    id membersListener;
    
    // Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
    id leaveRoomNotificationObserver;
    
    // Internal measurement
    CGFloat actionButtonWidth;
}

@end

@implementation RoomParticipantsViewController

- (void)setNavBarButtons
{
    // this viewController can be displayed
    // 1- with a "standard" push mode
    // 2- within a segmentedViewController i.e. inside another viewcontroller
    // so, we need to use the parent controller when it is required.
    UIViewController* topViewController = (self.parentViewController) ? self.parentViewController : self;
    topViewController.navigationItem.rightBarButtonItem = nil;
    topViewController.navigationItem.leftBarButtonItem = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Setup `MXKViewControllerHandling` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"room_participants_title", @"Vector", nil);
    
    // Add each matrix session, to update the view controller appearance according to mx sessions state
    NSArray *sessions = [AppDelegate theDelegate].mxSessions;
    for (MXSession *mxSession in sessions)
    {
        [self addMatrixSession:mxSession];
    }
    
    addParticipantsSearchBarCell = [[MXKTableViewCellWithSearchBar alloc] init];
    addParticipantsSearchBarCell.mxkSearchBar.searchBarStyle = UISearchBarStyleMinimal;
    //    addParticipantsSearchBarCell.mxkSearchBar.barTintColor = [UIColor whiteColor]; // set barTint in case of UISearchBarStyleDefault (= UISearchBarStyleProminent)
    addParticipantsSearchBarCell.mxkSearchBar.returnKeyType = UIReturnKeyDone;
    addParticipantsSearchBarCell.mxkSearchBar.delegate = self;
    addParticipantsSearchBarCell.mxkSearchBar.placeholder = NSLocalizedStringFromTable(@"room_participants_invite_another_user", @"Vector", nil);
    [self refreshSearchBarItemsColor:addParticipantsSearchBarCell.mxkSearchBar];
    
    _isAddParticipantSearchBarEditing = NO;
    
    if (! mutableParticipants)
    {
        mutableParticipants = [NSMutableArray array];
    }
    
    if (! mxkContactsById)
    {
        mxkContactsById = [NSMutableDictionary dictionary];
    }
    
    // Measure the minimum width of the action button displayed in participant cells
    MXKContactTableCell *tmpCell = [[MXKContactTableCell alloc] init];
    UIButton *actionButton = tmpCell.contactAccessoryButton;
    [actionButton setTitle:NSLocalizedStringFromTable(@"leave", @"Vector", nil) forState:UIControlStateNormal];
    [actionButton setTitleColor:VECTOR_GREEN_COLOR forState:UIControlStateNormal];
    [actionButton sizeToFit];
    
    actionButtonWidth = actionButton.frame.size.width;
    [actionButton setTitle:NSLocalizedStringFromTable(@"remove", @"Vector", nil) forState:UIControlStateNormal];
    [actionButton setTitleColor:VECTOR_GREEN_COLOR forState:UIControlStateNormal];
    [actionButton sizeToFit];
    if (actionButton.frame.size.width > actionButtonWidth)
    {
        actionButtonWidth = actionButton.frame.size.width;
    }
    
    // ensure that the separator line is not displayed
    self.tableView.separatorColor = [UIColor clearColor];
    
    [self setNavBarButtons];
}

// this method is called when the viewcontroller is displayed inside another one.
- (void)didMoveToParentViewController:(nullable UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    [self setNavBarButtons];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)destroy
{
    if (leaveRoomNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:leaveRoomNotificationObserver];
        leaveRoomNotificationObserver = nil;
    }
    
    if (membersListener)
    {
        [self.mxRoom removeListener:membersListener];
        membersListener = nil;
    }
    
    _mxRoom = nil;
    
    addParticipantsSearchBarCell = nil;
    filteredParticipants = nil;
    mxkContactsById = nil;
    
    mutableParticipants = nil;
    
    if (currentAlert)
    {
        [currentAlert dismiss:NO];
        currentAlert = nil;
    }
    
    [self removePendingActionMask];
    
    [super destroy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Refresh display
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (currentAlert)
    {
        [currentAlert dismiss:NO];
        currentAlert = nil;
    }
 
    // cancel any pending search
    if (addParticipantsSearchBarCell.mxkSearchBar)
    {
        [self searchBarCancelButtonClicked:addParticipantsSearchBarCell.mxkSearchBar];
    }
}

#pragma mark -

- (void)setMxRoom:(MXRoom *)mxRoom
{
    // Remove the previous listener
    if (leaveRoomNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:leaveRoomNotificationObserver];
        leaveRoomNotificationObserver = nil;
    }
    if (membersListener)
    {
        [self.mxRoom removeListener:membersListener];
    }
    
    _mxRoom = mxRoom;
    
    // Refresh displayed participants from the current room members
    [self refreshParticipantsFromRoomMembers];
    
    if (mxRoom)
    {
        // Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
        leaveRoomNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionWillLeaveRoomNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            
            // Check whether the user will leave the room related to the displayed participants
            if (notif.object == self.mxRoom.mxSession)
            {
                NSString *roomId = notif.userInfo[kMXSessionNotificationRoomIdKey];
                if (roomId && [roomId isEqualToString:self.mxRoom.state.roomId])
                {
                    // We remove the current view controller.
                    [self withdrawViewControllerAnimated:YES completion:nil];
                }
            }
        }];
        
        // Register a listener for events that concern room members
        NSArray *mxMembersEvents = @[kMXEventTypeStringRoomMember, kMXEventTypeStringRoomPowerLevels];
        membersListener = [self.mxRoom listenToEventsOfTypes:mxMembersEvents onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {
            
            // Consider only live event
            if (direction == MXEventDirectionForwards)
            {
                switch (event.eventType)
                {
                    case MXEventTypeRoomMember:
                    {
                        // Take into account updated member
                        // Ignore here change related to the current user (this change is handled by leaveRoomNotificationObserver)
                        if ([event.userId isEqualToString:self.mxRoom.mxSession.myUser.userId] == NO)
                        {
                            MXRoomMember *mxMember = [self.mxRoom.state memberWithUserId:event.userId];
                            if (mxMember)
                            {
                                [self addRoomMemberToParticipants:mxMember];
                            }
                        }
                        
                        if ([event.stateKey isEqualToString:self.mxRoom.mxSession.myUser.userId] == NO)
                        {
                            MXRoomMember *mxMember = [self.mxRoom.state memberWithUserId:event.stateKey];
                            if (mxMember)
                            {
                                [self addRoomMemberToParticipants:mxMember];
                            }
                        }
                        
                        break;
                    }
                    case MXEventTypeRoomPowerLevels:
                    {
                        [self refreshParticipantsFromRoomMembers];
                        break;
                    }
                    default:
                        break;
                        
                }
                
                // Refresh participants display (if visible)
                if (participantsSection != -1)
                {
                    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange (participantsSection, 1)];
                    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
                }
            }
            
        }];
    }
    
    [self.tableView reloadData];
}

- (void)setIsAddParticipantSearchBarEditing:(BOOL)isAddParticipantsSearchBarEditing
{
    if (_isAddParticipantSearchBarEditing != isAddParticipantsSearchBarEditing)
    {
        _isAddParticipantSearchBarEditing = isAddParticipantsSearchBarEditing;
        
        // Switch the display between search result and participants list
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange (1, 1)];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - Internals

- (void)refreshParticipantsFromRoomMembers
{
    // Flush existing participants list
    mutableParticipants = [NSMutableArray array];
    mxkContactsById = [NSMutableDictionary dictionary];
    userMatrixId = nil;
    
    if (self.mxRoom)
    {
        NSArray *members = self.mxRoom.state.members;
        NSString *userId = self.mxRoom.mxSession.myUser.userId;
        
        for (MXRoomMember *mxMember in members)
        {
            // Update the current participants list
            if ([mxMember.userId isEqualToString:userId])
            {
                if (mxMember.membership == MXMembershipJoin || mxMember.membership == MXMembershipInvite)
                {
                    // The user is in this room
                    userMatrixId = userId;
                }
            }
            else
            {
                [self addRoomMemberToParticipants:mxMember];
            }
        }
    }
}

- (void)addRoomMemberToParticipants:(MXRoomMember*)mxMember
{
    // Remove previous occurrence of this member (if any)
    if (mutableParticipants.count)
    {
        NSUInteger index = [mutableParticipants indexOfObject:mxMember.userId];
        if (index != NSNotFound)
        {
            [mxkContactsById removeObjectForKey:mxMember.userId];
            [mutableParticipants removeObjectAtIndex:index];
        }
    }
    
    // Add this member after checking his status
    if (mxMember.membership == MXMembershipJoin || mxMember.membership == MXMembershipInvite)
    {
        // Check whether this member is admin
        BOOL isAdmin = ([self.mxRoom.state memberNormalizedPowerLevel:mxMember.userId] == 1);
        
        // Prepare the display name of this member
        NSString *displayName = mxMember.displayname;
        if (displayName.length == 0)
        {
            // Look for the corresponding MXUser in matrix session
            MXUser *mxUser = [self.mxRoom.mxSession userWithUserId:mxMember.userId];
            if (mxUser)
            {
                displayName = ((mxUser.displayname.length > 0) ? mxUser.displayname : mxMember.userId);
            }
            else
            {
                displayName = mxMember.userId;
            }
        }
        if (isAdmin)
        {
            displayName = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_participants_admin_name", @"Vector", nil), displayName];
        }
        
        // Create the contact related to this member
        MXKContact *contact = [[MXKContact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:mxMember.userId];
        [mxkContactsById setObject:contact forKey:mxMember.userId];
        
        // Add this participant (admin is in first position, the other are sorted in alphabetical order).
        NSUInteger index = 0;
        if (isAdmin)
        {
            // Check whether there is other admin
            for (NSString *userId in mutableParticipants)
            {
                if ([self.mxRoom.state memberNormalizedPowerLevel:userId] == 1)
                {
                    contact = [mxkContactsById objectForKey:userId];
                    
                    // Sort admin in alphabetical order
                    if ([displayName compare:contact.displayName options:NSCaseInsensitiveSearch] != NSOrderedDescending)
                    {
                        break;
                    }
                    index++;
                }
            }
        }
        else
        {
            for (NSString *userId in mutableParticipants)
            {
                // Pass admin(s)
                if ([self.mxRoom.state memberNormalizedPowerLevel:userId] == 1)
                {
                    index++;
                }
                else
                {
                    contact = [mxkContactsById objectForKey:userId];
                    
                    // Sort in alphabetical order
                    if ([displayName compare:contact.displayName options:NSCaseInsensitiveSearch] != NSOrderedDescending)
                    {
                        break;
                    }
                    index++;
                }
            }
        }
        
        // Add this participant
        [mutableParticipants insertObject:mxMember.userId atIndex:index];
    }
}

- (void)addPendingActionMask
{
    // Add a spinner above the tableview to avoid that the user tap on any other button
    pendingMaskSpinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    pendingMaskSpinnerView.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    pendingMaskSpinnerView.frame = self.tableView.frame;
    pendingMaskSpinnerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    
    // append it
    [self.tableView.superview addSubview:pendingMaskSpinnerView];
    
    // animate it
    [pendingMaskSpinnerView startAnimating];
}

- (void)removePendingActionMask
{
    if (pendingMaskSpinnerView)
    {
        [pendingMaskSpinnerView removeFromSuperview];
        pendingMaskSpinnerView = nil;
    }
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    addParticipantsSection = searchResultSection = participantsSection = -1;
    
    if (_isAddParticipantSearchBarEditing)
    {
        // Only "add participant" section is displayed
        addParticipantsSection = count++;
        searchResultSection = count++;
    }
    else
    {
        addParticipantsSection = count++;
        participantsSection = count++;
    }
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == addParticipantsSection)
    {
        count = 1;
    }
    else if (section == searchResultSection)
    {
        count = filteredParticipants.count;
    }
    else if (section == participantsSection)
    {
        count = mutableParticipants.count;
        if (userMatrixId)
        {
            count++;
        }
    }
    
    return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == participantsSection)
    {
        NSInteger count = mutableParticipants.count;
        if (userMatrixId)
        {
            count++;
        }
        
        if (count > 1)
        {
            return [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_participants_multi_participants", @"Vector", nil), count];
        }
        else
        {
            return NSLocalizedStringFromTable(@"room_participants_one_participant", @"Vector", nil);
        }
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == addParticipantsSection)
    {
        if (indexPath.row == 0)
        {
            cell = addParticipantsSearchBarCell;
            if (_isAddParticipantSearchBarEditing)
            {
                [addParticipantsSearchBarCell.mxkSearchBar becomeFirstResponder];
            }
        }
    }
    else if (indexPath.section == searchResultSection)
    {
        if (indexPath.row < filteredParticipants.count)
        {
            MXKContactTableCell* filteredParticipantCell = [tableView dequeueReusableCellWithIdentifier:[MXKContactTableCell defaultReuseIdentifier]];
            if (!filteredParticipantCell)
            {
                filteredParticipantCell = [[MXKContactTableCell alloc] init];
                filteredParticipantCell.thumbnailDisplayBoxType = MXKContactTableCellThumbnailDisplayBoxTypeRoundedCorner;
                filteredParticipantCell.hideMatrixPresence = YES;
            }
            
            [filteredParticipantCell render:filteredParticipants[indexPath.row]];
            
            // Show 'add' icon.
            filteredParticipantCell.contactAccessoryViewType = MXKContactTableCellAccessoryCustom;
            filteredParticipantCell.contactAccessoryViewHeightConstraint.constant = 30;
            filteredParticipantCell.contactAccessoryViewWidthConstraint.constant = 30;
            filteredParticipantCell.contactAccessoryImageView.image = [UIImage imageNamed:@"add"];
            filteredParticipantCell.contactAccessoryImageView.hidden = NO;
            filteredParticipantCell.contactAccessoryView.hidden = NO;
            
            filteredParticipantCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell = filteredParticipantCell;
        }
    }
    else if (indexPath.section == participantsSection)
    {
        MXKContactTableCell *participantCell = [tableView dequeueReusableCellWithIdentifier:[MXKContactTableCell defaultReuseIdentifier]];
        if (!participantCell)
        {
            participantCell = [[MXKContactTableCell alloc] init];
            participantCell.thumbnailDisplayBoxType = MXKContactTableCellThumbnailDisplayBoxTypeRoundedCorner;
            participantCell.hideMatrixPresence = YES;
        }
        
        if (userMatrixId && indexPath.row == 0)
        {
            MXKContact *contact = [mxkContactsById objectForKey:userMatrixId];
            if (! contact)
            {
                contact = [[MXKContact alloc] initMatrixContactWithDisplayName:NSLocalizedStringFromTable(@"you", @"Vector", nil) andMatrixID:userMatrixId];
                [mxkContactsById setObject:contact forKey:userMatrixId];
            }
            
            [participantCell render:contact];
            
            if (self.mxRoom)
            {
                // Show 'Leave' buton.
                participantCell.contactAccessoryViewType = MXKContactTableCellAccessoryCustom;
                UIButton *actionButton = participantCell.contactAccessoryButton;
                actionButton.hidden = NO;
                [actionButton setTitle:NSLocalizedStringFromTable(@"leave", @"Vector", nil) forState:UIControlStateNormal];
                [actionButton setTitleColor:VECTOR_GREEN_COLOR forState:UIControlStateNormal];
                [actionButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                actionButton.tag = 0;
                [actionButton sizeToFit];
                
                participantCell.contactAccessoryViewHeightConstraint.constant = actionButton.frame.size.height;
                participantCell.contactAccessoryViewWidthConstraint.constant = actionButtonWidth;
                [participantCell needsUpdateConstraints];
                participantCell.contactAccessoryView.hidden = NO;
            }
            else
            {
                // Hide accessory view.
                participantCell.contactAccessoryViewType = MXKContactTableCellAccessoryCustom;
            }
            
            participantCell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else
        {
            NSInteger index = indexPath.row;
            
            if (userMatrixId)
            {
                index --;
            }
            
            if (index < mutableParticipants.count)
            {
                NSString *userId = mutableParticipants[index];
                MXKContact *contact = [mxkContactsById objectForKey:userId];
                if (!contact)
                {
                    // Create this missing contact
                    // Look for the corresponding MXUser
                    NSArray *sessions = self.mxSessions;
                    MXUser *mxUser;
                    for (MXSession *session in sessions)
                    {
                        mxUser = [session userWithUserId:userId];
                        if (mxUser)
                        {
                            contact = [[MXKContact alloc] initMatrixContactWithDisplayName:((mxUser.displayname.length > 0) ? mxUser.displayname : userId) andMatrixID:userId];
                            break;
                        }
                    }
                    
                    if (contact)
                    {
                        [mxkContactsById setObject:contact forKey:userId];
                    }
                    
                }
                
                if (contact)
                {
                    [participantCell render:contact];
                }
                
                if (self.mxRoom)
                {
                    // Show 'remove' button.
                    participantCell.contactAccessoryViewType = MXKContactTableCellAccessoryCustom;
                    UIButton *actionButton = participantCell.contactAccessoryButton;
                    actionButton.hidden = NO;
                    [actionButton setTitle:NSLocalizedStringFromTable(@"remove", @"Vector", nil) forState:UIControlStateNormal];
                    [actionButton setTitleColor:VECTOR_GREEN_COLOR forState:UIControlStateNormal];
                    [actionButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                    actionButton.tag = indexPath.row;
                    [actionButton sizeToFit];
                    
                    participantCell.contactAccessoryViewHeightConstraint.constant = actionButton.frame.size.height;
                    participantCell.contactAccessoryViewWidthConstraint.constant = actionButtonWidth;
                    participantCell.contactAccessoryView.hidden = NO;
                }
                else
                {
                    // Show 'remove' icon.
                    participantCell.contactAccessoryViewType = MXKContactTableCellAccessoryCustom;
                    participantCell.contactAccessoryViewHeightConstraint.constant = 30;
                    participantCell.contactAccessoryViewWidthConstraint.constant = 30;
                    participantCell.contactAccessoryImageView.image = [UIImage imageNamed:@"remove"];
                    participantCell.contactAccessoryImageView.hidden = NO;
                    participantCell.contactAccessoryView.hidden = NO;
                }
                
                participantCell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
        }
        
        cell = participantCell;
    }
    
    return cell;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == addParticipantsSection && indexPath.row == 1)
    {
        return 10;
    }
    return 44;
}


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]])
    {
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
        tableViewHeaderFooterView.textLabel.text = [tableViewHeaderFooterView.textLabel.text capitalizedString];
        tableViewHeaderFooterView.textLabel.font = [UIFont boldSystemFontOfSize:17];
        tableViewHeaderFooterView.textLabel.textColor = VECTOR_GREEN_COLOR;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    
    if ((indexPath.section == participantsSection) && (self.mxRoom == nil))
    {
        if (userMatrixId)
        {
            index --;
        }
        
        if (index < mutableParticipants.count)
        {
            [mxkContactsById removeObjectForKey:mutableParticipants[index]];
            [mutableParticipants removeObjectAtIndex:index];
            
            // Refresh display
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            
            UITableViewHeaderFooterView *participantsSectionHeader = [tableView headerViewForSection:participantsSection];
            participantsSectionHeader.textLabel.text = [self tableView:tableView titleForHeaderInSection:participantsSection];
        }
    }
    else if (indexPath.section == searchResultSection)
    {
        if (index < filteredParticipants.count)
        {
            MXKContact *contact = filteredParticipants[index];
            
            NSArray *identifiers = contact.matrixIdentifiers;
            if (identifiers.count)
            {
                NSString *participantId = identifiers.firstObject;
                
                // Handle a mapping contact by userId for selected participants
                [mxkContactsById setObject:contact forKey:participantId];

                // Invite this user if a room is defined
                if (self.mxRoom)
                {
                    [self addPendingActionMask];
                    [self.mxRoom inviteUser:participantId success:^{
                        
                        [self removePendingActionMask];
                        
                        // Refresh display by leaving search session
                        [self searchBarCancelButtonClicked:addParticipantsSearchBarCell.mxkSearchBar];
                        
                    } failure:^(NSError *error) {
                        
                        [self removePendingActionMask];
                        
                        NSLog(@"[RoomParticipantsVC] Invite %@ failed: %@", participantId, error);
                        // Alert user
                        [[AppDelegate theDelegate] showErrorAsAlert:error];
                        
                    }];
                }
                else
                {
                    // Update here the mutable list of participants
                    [mutableParticipants addObject:participantId];
                    // Refresh display by leaving search session
                    [self searchBarCancelButtonClicked:addParticipantsSearchBarCell.mxkSearchBar];
                }
            }
            
            
        }
    }
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *actionButton = (UIButton*)sender;
        NSInteger index = actionButton.tag;
        __weak typeof(self) weakSelf = self;
        
        if (currentAlert)
        {
            [currentAlert dismiss:NO];
            currentAlert = nil;
        }
        
        if (userMatrixId && index == 0 && [actionButton.titleLabel.text isEqualToString:NSLocalizedStringFromTable(@"leave", @"Vector", nil)])
        {
            // Leave ?
            currentAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"room_participants_leave_prompt_title", @"Vector", nil)
                                                   message:NSLocalizedStringFromTable(@"room_participants_leave_prompt_msg", @"Vector", nil)
                                                     style:MXKAlertStyleAlert];
            
            currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                        style:MXKAlertActionStyleCancel
                                                                      handler:^(MXKAlert *alert) {
                                                                          
                                                                          __strong __typeof(weakSelf)strongSelf = weakSelf;
                                                                          strongSelf->currentAlert = nil;
                                                                          
                                                                      }];
            
            [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"leave", @"Vector", nil)
                                       style:MXKAlertActionStyleDefault
                                     handler:^(MXKAlert *alert) {
                                         
                                         __strong __typeof(weakSelf)strongSelf = weakSelf;
                                         strongSelf->currentAlert = nil;
                                         
                                         [strongSelf addPendingActionMask];
                                         [strongSelf.mxRoom leave:^{
                                             
                                             [strongSelf withdrawViewControllerAnimated:YES completion:nil];
                                             
                                         } failure:^(NSError *error) {
                                             
                                             [strongSelf removePendingActionMask];
                                             NSLog(@"[RoomParticipantsVC] Leave room %@ failed: %@", strongSelf.mxRoom.state.roomId, error);
                                             // Alert user
                                             [[AppDelegate theDelegate] showErrorAsAlert:error];
                                             
                                         }];
                                         
                                     }];
            
            [currentAlert showInViewController:self];
        }
        else if ([actionButton.titleLabel.text isEqualToString:NSLocalizedStringFromTable(@"remove", @"Vector", nil)])
        {
            if (userMatrixId)
            {
                index --;
            }
            
            if (index < mutableParticipants.count)
            {
                NSString *memberUserId = mutableParticipants[index];
                MXKContact *contact = [mxkContactsById objectForKey:memberUserId];
                
                // Kick ?
                NSString *promptMsg = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_participants_remove_prompt_msg", @"Vector", nil), (contact ? contact.displayName : memberUserId)];
                currentAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"room_participants_remove_prompt_title", @"Vector", nil)
                                                       message:promptMsg
                                                         style:MXKAlertStyleAlert];
                
                currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                            style:MXKAlertActionStyleCancel
                                                                          handler:^(MXKAlert *alert) {
                                                                              
                                                                              __strong __typeof(weakSelf)strongSelf = weakSelf;
                                                                              strongSelf->currentAlert = nil;
                                                                              
                                                                          }];
                
                [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"remove", @"Vector", nil)
                                           style:MXKAlertActionStyleDefault
                                         handler:^(MXKAlert *alert) {
                                             
                                             __strong __typeof(weakSelf)strongSelf = weakSelf;
                                             strongSelf->currentAlert = nil;
                                             
                                             [strongSelf addPendingActionMask];
                                             [strongSelf.mxRoom kickUser:memberUserId
                                                       reason:nil
                                                      success:^{
                                                          
                                                          [strongSelf removePendingActionMask];
                                                          
                                                          [strongSelf->mxkContactsById removeObjectForKey:memberUserId];
                                                          [strongSelf->mutableParticipants removeObjectAtIndex:index];
                                                          
                                                          // Refresh display
                                                          [strongSelf.tableView reloadData];
                                                          
                                                      } failure:^(NSError *error) {
                                                          
                                                          [strongSelf removePendingActionMask];
                                                          NSLog(@"[RoomParticipantsVC] Kick %@ failed: %@", memberUserId, error);
                                                          // Alert user
                                                          [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                          
                                                      }];
                                         }];
                
                [currentAlert showInViewController:self];
            }
        }
    }
}

#pragma mark - UISearchBar delegate

- (void)refreshSearchBarItemsColor:(UISearchBar *)searchBar
{
    // caret color
    searchBar.barTintColor = searchBar.tintColor = VECTOR_GREEN_COLOR;
    searchBar.tintColor = VECTOR_GREEN_COLOR;
    
    // text color
    UITextField *searchBarTextField = [searchBar valueForKey:@"_searchField"];
    searchBarTextField.textColor = VECTOR_GREEN_COLOR;
    
    // Magnifying glass icon.
    UIImageView *leftImageView = (UIImageView *)searchBarTextField.leftView;
    leftImageView.image = [leftImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    leftImageView.tintColor = VECTOR_GREEN_COLOR;

    // Clear button
    UIButton *clearButton = [searchBarTextField valueForKey:@"_clearButton"];
    [clearButton setImage:[clearButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    clearButton.tintColor = VECTOR_GREEN_COLOR;
    
    // place holder
    [searchBarTextField setValue:VECTOR_GREEN_COLOR forKeyPath:@"_placeholderLabel.textColor"];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSInteger previousFilteredCount = filteredParticipants.count;
    
    NSMutableArray *mxUsers;
    if (addParticipantsSearchText.length && [searchText hasPrefix:addParticipantsSearchText])
    {
        mxUsers = filteredParticipants;
    }
    else
    {
        // Retrieve all known matrix users
        NSArray *matrixContacts = [NSMutableArray arrayWithArray:[MXKContactManager sharedManager].matrixContacts];
        mxUsers = [NSMutableArray arrayWithCapacity:matrixContacts.count];
        
        // Split contacts with several ids, and remove the current participants.
        for (MXKContact* contact in matrixContacts)
        {
            NSArray *identifiers = contact.matrixIdentifiers;
            if (identifiers.count > 1)
            {
                for (NSString *userId in identifiers)
                {
                    if (!mutableParticipants || [mutableParticipants indexOfObject:userId] == NSNotFound)
                    {
                        if (![userId isEqualToString:userMatrixId])
                        {
                            MXKContact *splitContact = [[MXKContact alloc] initMatrixContactWithDisplayName:contact.displayName andMatrixID:userId];
                            [mxUsers addObject:splitContact];
                        }
                    }
                }
            }
            else if (identifiers.count)
            {
                NSString *userId = identifiers.firstObject;
                if (!mutableParticipants || [mutableParticipants indexOfObject:userId] == NSNotFound)
                {
                    if (![userId isEqualToString:userMatrixId])
                    {
                        [mxUsers addObject:contact];
                    }
                }
            }
        }
    }
    addParticipantsSearchText = searchText;
    
    filteredParticipants = [NSMutableArray array];
    NSMutableArray *indexArray = [NSMutableArray array];
    NSInteger index = 0;
    
    for (MXKContact* contact in mxUsers)
    {
        if ([contact matchedWithPatterns:@[addParticipantsSearchText]])
        {
            [filteredParticipants addObject:contact];
            [indexArray addObject:[NSIndexPath indexPathForRow:index++ inSection:0]];
        }
    }
    
    if (previousFilteredCount || filteredParticipants.count)
    {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange (searchResultSection, 1)];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    self.isAddParticipantSearchBarEditing = YES;
    searchBar.showsCancelButton = YES;
    
    [self refreshSearchBarItemsColor:searchBar];
    
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // "Done" key has been pressed
    self.isAddParticipantSearchBarEditing = NO;
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = addParticipantsSearchText = nil;
    filteredParticipants = nil;
    self.isAddParticipantSearchBarEditing = NO;
    
    // Leave search
    [searchBar resignFirstResponder];
}

@end
