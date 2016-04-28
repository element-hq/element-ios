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

#import "RoomMemberDetailsViewController.h"

#import "VectorDesignValues.h"

#import "RageShakeManager.h"

#import "AppDelegate.h"

#import "AvatarGenerator.h"

#import "Contact.h"

@interface RoomParticipantsViewController ()
{
    // Search session
    NSString *currentSearchText;
    UIView* searchBarSeparator;
    
    // Search results
    NSMutableArray *invitableContacts;
    NSMutableArray *filteredActualParticipants;
    NSMutableArray *filteredInvitedParticipants;
    
    // Contact instances by matrix user id, or room 3pid invite token.
    NSMutableDictionary *contactsById;
    
    MXKAlert *currentAlert;
    
    // Mask view while processing a request
    UIActivityIndicatorView *pendingMaskSpinnerView;
    
    // The members events listener.
    id membersListener;
    
    // Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
    id leaveRoomNotificationObserver;
    
    RoomMemberDetailsViewController *detailsViewController;
}

@end

@implementation RoomParticipantsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"room_participants_title", @"Vector", nil);
    
    // Add each matrix session, to update the view controller appearance according to mx sessions state
    NSArray *sessions = [AppDelegate theDelegate].mxSessions;
    for (MXSession *mxSession in sessions)
    {
        [self addMatrixSession:mxSession];
    }
    
    _isAddParticipantSearchBarEditing = NO;
    
    _searchBarView.placeholder = NSLocalizedStringFromTable(@"room_participants_invite_another_user", @"Vector", nil);
    [self refreshSearchBarItemsColor:_searchBarView];
    
    _searchBarHeaderBorder.backgroundColor = kVectorColorSilver;
    
    // Search bar header is hidden when no room is provided
    _searchBarHeader.hidden = (self.mxRoom == nil);
    
    [self setNavBarButtons];
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
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
        [self.mxRoom.liveTimeline removeListener:membersListener];
        membersListener = nil;
    }
    
    _mxRoom = nil;
    
    invitableContacts = nil;
    filteredActualParticipants = nil;
    filteredInvitedParticipants = nil;
    
    contactsById = nil;
    
    actualParticipants = nil;
    invitedParticipants = nil;
    userContact = nil;
    
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
    
    if (detailsViewController)
    {
        [detailsViewController destroy];
        detailsViewController = nil;
    }
    
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
    [self searchBarCancelButtonClicked:_searchBarView];
}

#pragma mark -

- (void)setMxRoom:(MXRoom *)mxRoom
{
    // Cancel any pending search
    [self searchBarCancelButtonClicked:_searchBarView];
    
    // Remove the previous listener
    if (leaveRoomNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:leaveRoomNotificationObserver];
        leaveRoomNotificationObserver = nil;
    }
    if (membersListener)
    {
        [_mxRoom.liveTimeline removeListener:membersListener];
        membersListener = nil;
    }
    
    _mxRoom = mxRoom;
    
    // Search bar header is hidden when no room is provided
    _searchBarHeader.hidden = (self.mxRoom == nil);
    
    if (_mxRoom)
    {
        // Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
        leaveRoomNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionWillLeaveRoomNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            
            // Check whether the user will leave the room related to the displayed participants
            if (notif.object == _mxRoom.mxSession)
            {
                NSString *roomId = notif.userInfo[kMXSessionNotificationRoomIdKey];
                if (roomId && [roomId isEqualToString:_mxRoom.state.roomId])
                {
                    // We remove the current view controller.
                    [self withdrawViewControllerAnimated:YES completion:nil];
                }
            }
        }];
        
        // Register a listener for events that concern room members
        NSArray *mxMembersEvents = @[kMXEventTypeStringRoomMember, kMXEventTypeStringRoomThirdPartyInvite, kMXEventTypeStringRoomPowerLevels];
        membersListener = [_mxRoom.liveTimeline listenToEventsOfTypes:mxMembersEvents onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {
            
            // Consider only live event
            if (direction == MXTimelineDirectionForwards)
            {
                switch (event.eventType)
                {
                    case MXEventTypeRoomMember:
                    {
                        // Take into account updated member
                        // Ignore here change related to the current user (this change is handled by leaveRoomNotificationObserver)
                        if ([event.stateKey isEqualToString:self.mxRoom.mxSession.myUser.userId] == NO)
                        {
                            MXRoomMember *mxMember = [self.mxRoom.state memberWithUserId:event.stateKey];
                            if (mxMember)
                            {
                                // Remove previous occurrence of this member (if any)
                                [self removeParticipantByKey:mxMember.userId];
                                
                                // If any, remove 3pid invite corresponding to this room member
                                if (mxMember.thirdPartyInviteToken)
                                {
                                    [self removeParticipantByKey:mxMember.thirdPartyInviteToken];
                                }
                                
                                [self handleRoomMember:mxMember];
                                
                                [self finalizeParticipantsList];
                                
                                [self.tableView reloadData];
                            }
                        }
                        
                        break;
                    }
                    case MXEventTypeRoomThirdPartyInvite:
                    {
                        MXRoomThirdPartyInvite *thirdPartyInvite = [self.mxRoom.state thirdPartyInviteWithToken:event.stateKey];
                        if (thirdPartyInvite)
                        {
                            [self addRoomThirdPartyInviteToParticipants:thirdPartyInvite];
                            
                            [self finalizeParticipantsList];
                            
                            [self.tableView reloadData];
                        }
                        break;
                    }
                    case MXEventTypeRoomPowerLevels:
                    {
                        [self refreshParticipantsFromRoomMembers];
                        
                        [self.tableView reloadData];
                        break;
                    }
                    default:
                        break;
                }
            }
            
        }];
    }
    
    // Refresh the members list.
    [self refreshParticipantsFromRoomMembers];
    
    [self.tableView reloadData];
}

- (void)setIsAddParticipantSearchBarEditing:(BOOL)isAddParticipantsSearchBarEditing
{
    if (_isAddParticipantSearchBarEditing != isAddParticipantsSearchBarEditing)
    {
        _isAddParticipantSearchBarEditing = isAddParticipantsSearchBarEditing;
        
        // Switch the display between search result and participants list
        [self.tableView reloadData];
    }
}

#pragma mark - Internals

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

- (void)refreshParticipantsFromRoomMembers
{
    actualParticipants = [NSMutableArray array];
    invitedParticipants = [NSMutableArray array];
    userContact = nil;
    
    if (self.mxRoom)
    {
        // Retrieve the current members from the room state
        NSArray *members = self.mxRoom.state.members;
        NSString *userId = self.mxRoom.mxSession.myUser.userId;
        NSArray *roomThirdPartyInvites = self.mxRoom.state.thirdPartyInvites;
        
        for (MXRoomMember *mxMember in members)
        {
            // Update the current participants list
            if ([mxMember.userId isEqualToString:userId])
            {
                if (mxMember.membership == MXMembershipJoin || mxMember.membership == MXMembershipInvite)
                {
                    // The user is in this room
                    NSString *displayName = NSLocalizedStringFromTable(@"you", @"Vector", nil);
                    
                    userContact = [[Contact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:userId];
                    userContact.mxMember = [self.mxRoom.state memberWithUserId:userId];
                }
            }
            else
            {
                [self handleRoomMember:mxMember];
            }
        }

        for (MXRoomThirdPartyInvite *roomThirdPartyInvite in roomThirdPartyInvites)
        {
            [self addRoomThirdPartyInviteToParticipants:roomThirdPartyInvite];
        }

        [self finalizeParticipantsList];
    }
}

- (void)handleRoomMember:(MXRoomMember*)mxMember
{
    // Add this member after checking his status
    if (mxMember.membership == MXMembershipJoin || mxMember.membership == MXMembershipInvite)
    {
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
        
        // Create the contact related to this member
        Contact *contact = [[Contact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:mxMember.userId];
        contact.mxMember = mxMember;

        if (mxMember.membership == MXMembershipInvite)
        {
            [invitedParticipants addObject:contact];
        }
        else
        {
            [actualParticipants addObject:contact];
        }
    }
}

- (void)addRoomThirdPartyInviteToParticipants:(MXRoomThirdPartyInvite*)roomThirdPartyInvite
{
    // If the homeserver has converted the 3pid invite into a room member, do no show it
    if (![self.mxRoom.state memberWithThirdPartyInviteToken:roomThirdPartyInvite.token])
    {
        Contact *contact = [[Contact alloc] initMatrixContactWithDisplayName:roomThirdPartyInvite.displayname andMatrixID:nil];
        contact.isThirdPartyInvite = YES;
        contact.mxThirdPartyInvite = roomThirdPartyInvite;

        [invitedParticipants addObject:contact];
    }
}

// key is a room member user id or a room 3pid invite token
- (void)removeParticipantByKey:(NSString*)key
{
    NSUInteger index;

    if (actualParticipants.count)
    {
        for (index = 0; index < actualParticipants.count; index++)
        {
            Contact *contact = actualParticipants[index];
            
            if (contact.mxMember && [contact.mxMember.userId isEqualToString:key])
            {
                [actualParticipants removeObjectAtIndex:index];
                return;
            }
        }
    }
    
    if (invitedParticipants.count)
    {
        for (index = 0; index < invitedParticipants.count; index++)
        {
            Contact *contact = invitedParticipants[index];
            
            if (contact.mxMember && [contact.mxMember.userId isEqualToString:key])
            {
                [invitedParticipants removeObjectAtIndex:index];
                return;
            }
            
            if (contact.mxThirdPartyInvite && [contact.mxThirdPartyInvite.token isEqualToString:key])
            {
                [invitedParticipants removeObjectAtIndex:index];
                return;
            }
        }
    }
}

- (void)finalizeParticipantsList
{
    // Sort contacts in alphabetical order (Use sortingDisplayName in which symbols are skipped)
    NSComparator comparator = ^NSComparisonResult(Contact *contact1, Contact *contact2) {

        // Order first by power levels (admins then moderators then others)
        MXRoomPowerLevels *powerLevels = [self.mxRoom.state powerLevels];
        NSInteger powerLevel1 = [powerLevels powerLevelOfUserWithUserID:contact1.mxMember.userId];
        NSInteger powerLevel2 = [powerLevels powerLevelOfUserWithUserID:contact2.mxMember.userId];

        if (powerLevel1 < powerLevel2)
        {
            return NSOrderedDescending;
        }
        else if (powerLevel1 > powerLevel2)
        {
            return NSOrderedAscending;
        }

        // Then order by name
        if (contact1.sortingDisplayName.length && contact2.sortingDisplayName.length)
        {
            return [contact1.sortingDisplayName compare:contact2.sortingDisplayName options:NSCaseInsensitiveSearch];
        }
        else if (contact1.sortingDisplayName.length)
        {
            return NSOrderedAscending;
        }
        else if (contact2.sortingDisplayName.length)
        {
            return NSOrderedDescending;
        }
        
        return [contact1.displayName compare:contact2.displayName options:NSCaseInsensitiveSearch];
        
    };
    
    // Sort each participants list in alphabetical order
    [actualParticipants sortUsingComparator:comparator];
    [invitedParticipants sortUsingComparator:comparator];
    
    // Refer all used contacts in only one dictionary.
    contactsById = [NSMutableDictionary dictionary];
    for (Contact *contact in actualParticipants)
    {
        [contactsById setObject:contact forKey:contact.mxMember.userId];
    }
    for (Contact *contact in invitedParticipants)
    {
        if (contact.mxMember)
        {
            [contactsById setObject:contact forKey:contact.mxMember.userId];
        }
        else if (contact.mxThirdPartyInvite)
        {
            [contactsById setObject:contact forKey:contact.mxThirdPartyInvite.token];
        }
    }
    if (userContact)
    {
        [contactsById setObject:userContact forKey:userContact.mxMember.userId];
    }
}

- (void)addPendingActionMask
{
    // Remove potential existing mask
    [self removePendingActionMask];
    
    // Add a spinner above the tableview to avoid that the user tap on any other button
    pendingMaskSpinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    pendingMaskSpinnerView.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.5];
    pendingMaskSpinnerView.frame = self.tableView.frame;
    pendingMaskSpinnerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    
    // append it
    [self.tableView.superview addSubview:pendingMaskSpinnerView];
    
    // animate it
    [pendingMaskSpinnerView startAnimating];
    
    // Show the spinner after a delay so that if it is removed in a short future,
    // it is not displayed to the end user.
    pendingMaskSpinnerView.alpha = 0;
    [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        
        pendingMaskSpinnerView.alpha = 1;
        
    } completion:^(BOOL finished) {
    }];
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
    
    invitableSection = participantsSection = invitedSection = -1;
    
    if (_isAddParticipantSearchBarEditing)
    {
        invitableSection = count++;
        
        if (filteredActualParticipants.count)
        {
            participantsSection = count++;
        }
        
        if (filteredInvitedParticipants.count)
        {
            invitedSection = count++;
        }
    }
    else
    {
        if (userContact || actualParticipants.count)
        {
            participantsSection = count++;
        }
        
        if (invitedParticipants.count)
        {
            invitedSection = count++;
        }
    }
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == invitableSection)
    {
        count = invitableContacts.count;
    }
    else if (section == participantsSection)
    {
        if (_isAddParticipantSearchBarEditing)
        {
            count = filteredActualParticipants.count;
        }
        else
        {
            count = actualParticipants.count;
            if (userContact)
            {
                count++;
            }
        }
    }
    else if (section == invitedSection)
    {
        if (_isAddParticipantSearchBarEditing)
        {
            count = filteredInvitedParticipants.count;
        }
        else
        {
            count = invitedParticipants.count;
        }
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactTableViewCell* participantCell = [tableView dequeueReusableCellWithIdentifier:[ContactTableViewCell defaultReuseIdentifier]];
    
    if (!participantCell)
    {
        participantCell = [[ContactTableViewCell alloc] init];
    }
    else
    {
        // Restore default values
        participantCell.accessoryView = nil;
        participantCell.contentView.alpha = 1;
        participantCell.userInteractionEnabled = YES;
        
        participantCell.thumbnailBadgeView.hidden = YES;
    }
    
    participantCell.mxRoom = self.mxRoom;
    
    Contact *contact = nil;
    
    // oneself dedicated cell
    if ((indexPath.section == participantsSection && userContact && indexPath.row == 0) && !_isAddParticipantSearchBarEditing)
    {
        contact = userContact;
        
        participantCell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else if (indexPath.section == invitableSection)
    {
        if (indexPath.row < invitableContacts.count)
        {
            contact = invitableContacts[indexPath.row];
            
            participantCell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
    else
    {
        NSInteger index = indexPath.row;
        NSArray *participants;
        
        if (indexPath.section == participantsSection)
        {
            if (_isAddParticipantSearchBarEditing)
            {
                participants = filteredActualParticipants;
            }
            else
            {
                participants = actualParticipants;
                
                if (userContact)
                {
                    index --;
                }
            }
        }
        else
        {
            if (_isAddParticipantSearchBarEditing)
            {
                participants = filteredInvitedParticipants;
            }
            else
            {
                participants = invitedParticipants;
            }
        }
        
        if (index < participants.count)
        {
            contact = participants[index];
        }
        
        participantCell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if (contact)
    {
        [participantCell render:contact];
        
        // The search displays contacts to invite. Add a plus icon to the cell
        // in order to make it more understandable for the end user
        if (indexPath.section == invitableSection)
        {
            if (indexPath.row == 0)
            {
                // This is the text entered by the user
                NSString *searchText = contact.displayName;
                
                // Check whether this input is a valid email or a Matrix user ID before adding the plus icon.
                if (![MXTools isEmailAddress:searchText] && ([searchText characterAtIndex:0] != '@' || [searchText containsString:@":"] == NO))
                {
                    participantCell.contentView.alpha = 0.5;
                    participantCell.userInteractionEnabled = NO;
                }
                else
                {
                    participantCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus_icon"]];
                }
            }
            else
            {
                participantCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus_icon"]];
            }
        }
        else if (contact.mxMember)
        {
            // Update member badge
            MXRoomPowerLevels *powerLevels = [self.mxRoom.state powerLevels];
            NSInteger powerLevel = [powerLevels powerLevelOfUserWithUserID:contact.mxMember.userId];
            if (powerLevel >= kVectorRoomAdminLevel)
            {
                participantCell.thumbnailBadgeView.image = [UIImage imageNamed:@"admin_icon"];
                participantCell.thumbnailBadgeView.hidden = NO;
            }
            else if (powerLevel >= kVectorRoomModeratorLevel)
            {
                participantCell.thumbnailBadgeView.image = [UIImage imageNamed:@"mod_icon"];
                participantCell.thumbnailBadgeView.hidden = NO;
            }
        }
    }
    
    return participantCell;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    // iOS8 requires this method to enable editing (see editActionsForRowAtIndexPath).
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == invitedSection)
    {
        return 30.0;
    }
    else if (section == participantsSection && _isAddParticipantSearchBarEditing)
    {
        return 1;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* sectionHeader;
    
    if (section == invitedSection)
    {
        sectionHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 30)];
        sectionHeader.backgroundColor = kVectorColorLightGrey;
        
        CGRect frame = sectionHeader.frame;
        frame.origin.x = 20;
        frame.origin.y = 5;
        frame.size.width = sectionHeader.frame.size.width - 10;
        frame.size.height -= 10;
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
        headerLabel.font = [UIFont boldSystemFontOfSize:15.0];
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.text = NSLocalizedStringFromTable(@"room_participants_invited_section", @"Vector", nil);
        [sectionHeader addSubview:headerLabel];
    }
    else if (section == participantsSection && _isAddParticipantSearchBarEditing)
    {
        sectionHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 1)];
        
        sectionHeader.backgroundColor = [UIColor blackColor];
    }
    return sectionHeader;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 74.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Sanity check
    if (!self.mxRoom)
    {
        return;
    }
    
    NSInteger row = indexPath.row;
    
    if (indexPath.section == invitableSection)
    {
        if (row == 0)
        {
            // This is the text entered by the user
            // Try to invite what he typed
            MXKContact *contact = invitableContacts[row];

            // Invite this user
            NSString *participantId = contact.displayName;
            
            // Is it an email or a Matrix user ID?
            if ([MXTools isEmailAddress:participantId])
            {
                [self addPendingActionMask];
                [self.mxRoom inviteUserByEmail:participantId success:^{
                    
                    [self removePendingActionMask];
                    
                    // Refresh display by leaving search session
                    [self searchBarCancelButtonClicked:_searchBarView];
                    
                } failure:^(NSError *error) {
                    
                    [self removePendingActionMask];
                    
                    NSLog(@"[RoomParticipantsVC] Invite be email %@ failed", participantId);
                    // Alert user
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                }];
            }
            else
            {
                [self addPendingActionMask];
                [self.mxRoom inviteUser:participantId success:^{
                    
                    [self removePendingActionMask];
                    
                    // Refresh display by leaving search session
                    [self searchBarCancelButtonClicked:_searchBarView];
                    
                } failure:^(NSError *error) {
                    
                    [self removePendingActionMask];
                    
                    NSLog(@"[RoomParticipantsVC] Invite %@ failed", participantId);
                    // Alert user
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                }];
            }
        }
        else if (row < invitableContacts.count)
        {
            MXKContact *contact = invitableContacts[row];
            
            NSArray *identifiers = contact.matrixIdentifiers;
            if (identifiers.count)
            {
                NSString *participantId = identifiers.firstObject;

                // Invite this user if a room is defined
                [self addPendingActionMask];
                [self.mxRoom inviteUser:participantId success:^{
                    
                    [self removePendingActionMask];
                    
                    // Refresh display by leaving search session
                    [self searchBarCancelButtonClicked:_searchBarView];
                    
                } failure:^(NSError *error) {
                    
                    [self removePendingActionMask];
                    
                    NSLog(@"[RoomParticipantsVC] Invite %@ failed", participantId);
                    // Alert user
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                }];
            }
            else
            {
                // This is a local email contact
                NSString *emailAddress = contact.displayName;
                
                // Sanity check
                if ([MXTools isEmailAddress:emailAddress])
                {
                    // Invite this user if a room is defined
                    [self addPendingActionMask];
                    [self.mxRoom inviteUserByEmail:emailAddress success:^{
                        
                        [self removePendingActionMask];
                        
                        // Refresh display by leaving search session
                        [self searchBarCancelButtonClicked:_searchBarView];
                        
                    } failure:^(NSError *error) {
                        
                        [self removePendingActionMask];
                        
                        NSLog(@"[RoomParticipantsVC] Invite be email %@ failed", emailAddress);
                        // Alert user
                        [[AppDelegate theDelegate] showErrorAsAlert:error];
                    }];
                }
            }
        }
    }
    else
    {
        Contact *contact;
        
        // oneself dedicated cell
        if ((indexPath.section == participantsSection && userContact && indexPath.row == 0) && !_isAddParticipantSearchBarEditing)
        {
            contact = userContact;
        }
        else
        {
            NSInteger index = indexPath.row;
            NSArray *participants;
            
            if (indexPath.section == participantsSection)
            {
                if (_isAddParticipantSearchBarEditing)
                {
                    participants = filteredActualParticipants;
                }
                else
                {
                    participants = actualParticipants;
                    
                    if (userContact)
                    {
                        index --;
                    }
                }
            }
            else
            {
                if (_isAddParticipantSearchBarEditing)
                {
                    participants = filteredInvitedParticipants;
                }
                else
                {
                    participants = invitedParticipants;
                }
            }
            
            if (index < participants.count)
            {
                contact = participants[index];
            }
        }
        
        if (contact.mxMember)
        {
            detailsViewController = [RoomMemberDetailsViewController roomMemberDetailsViewController];
            [detailsViewController displayRoomMember:contact.mxMember withMatrixRoom:self.mxRoom];
            
            // Check whether the view controller is displayed inside a segmented one.
            if (self.segmentedViewController)
            {
                // Hide back button title
                self.segmentedViewController.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
                
                [self.segmentedViewController.navigationController pushViewController:detailsViewController animated:YES];
            }
            else
            {
                // Hide back button title
                self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
                
                [self.navigationController pushViewController:detailsViewController animated:YES];
            }
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* actions = [[NSMutableArray alloc] init];
    
    // add the swipe to delete only on participants sections
    if (indexPath.section == participantsSection || indexPath.section == invitedSection)
    {
        NSString* title = @"        ";
        
        UITableViewRowAction *leaveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:title  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self onDeleteAt:indexPath];
        
        }];
        
        leaveAction.backgroundColor = [MXKTools convertImageToPatternColor:@"remove_icon" backgroundColor:kVectorColorLightGrey patternSize:CGSizeMake(74, 74) resourceSize:CGSizeMake(30, 30)];
        [actions insertObject:leaveAction atIndex:0];
    }
    
    return actions;
}


#pragma mark - Actions

- (void)onDeleteAt:(NSIndexPath*)path
{
    NSUInteger section = path.section;
    NSUInteger row = path.row;
    
    if (section == participantsSection || section == invitedSection)
    {
        __weak typeof(self) weakSelf = self;
        
        if (currentAlert)
        {
            [currentAlert dismiss:NO];
            currentAlert = nil;
        }
        
        if (section == participantsSection && userContact && (0 == row))
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
                                             
                                             // check if there is a parent view controller
                                             if (strongSelf.parentViewController)
                                             {
                                                 [strongSelf.navigationController popViewControllerAnimated:YES];
                                             }
                                             else
                                             {
                                                 [strongSelf withdrawViewControllerAnimated:YES completion:nil];
                                             }
                                             
                                         } failure:^(NSError *error) {
                                             
                                             [strongSelf removePendingActionMask];
                                             NSLog(@"[RoomParticipantsVC] Leave room %@ failed", strongSelf.mxRoom.state.roomId);
                                             // Alert user
                                             [[AppDelegate theDelegate] showErrorAsAlert:error];
                                             
                                         }];
                                         
                                     }];
            
            [currentAlert showInViewController:self];
        }
        else
        {
            NSMutableArray *participants;
            
            if (section == participantsSection)
            {
                participants = actualParticipants;
                
                if (userContact)
                {
                    row --;
                }
            }
            else
            {
                participants = invitedParticipants;
            }
            
            if (row < participants.count)
            {
                Contact *contact = participants[row];
                NSString *memberUserId = contact.mxMember ? contact.mxMember.userId : contact.mxThirdPartyInvite.token;
                
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
                                                                     
                                                                     [participants removeObjectAtIndex:row];
                                                                     
                                                                     // Refresh display
                                                                     [strongSelf.tableView reloadData];
                                                                     
                                                                 } failure:^(NSError *error) {
                                                                     
                                                                     [strongSelf removePendingActionMask];
                                                                     NSLog(@"[RoomParticipantsVC] Kick %@ failed", memberUserId);
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
    // bar tint color
    searchBar.barTintColor = searchBar.tintColor = kVectorColorGreen;
    searchBar.tintColor = kVectorColorGreen;
    
    // text color
    UITextField *searchBarTextField = [searchBar valueForKey:@"_searchField"];
    searchBarTextField.textColor = kVectorTextColorGray;
    
    // Magnifying glass icon.
    UIImageView *leftImageView = (UIImageView *)searchBarTextField.leftView;
    leftImageView.image = [leftImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    leftImageView.tintColor = kVectorColorGreen;
    
    // remove the gray background color
    UIView *effectBackgroundTop =  [searchBarTextField valueForKey:@"_effectBackgroundTop"];
    UIView *effectBackgroundBottom =  [searchBarTextField valueForKey:@"_effectBackgroundBottom"];
    effectBackgroundTop.hidden = YES;
    effectBackgroundBottom.hidden = YES;
    
    // add line separator under the textfield
    if (!searchBarSeparator)
    {
        searchBarSeparator = [[UIView alloc] init];
        searchBarSeparator.backgroundColor = kVectorColorGreen;
        
        [searchBarTextField addSubview:searchBarSeparator];
        
        searchBarSeparator.translatesAutoresizingMaskIntoConstraints = NO;
        
        
        NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem:searchBarSeparator
                                                      attribute:NSLayoutAttributeLeading
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:searchBarTextField
                                                      attribute:NSLayoutAttributeLeading
                                                     multiplier:1
                                                       constant:0];
            
        NSLayoutConstraint* widthConstraint = [NSLayoutConstraint constraintWithItem:searchBarSeparator
                                                                          attribute:NSLayoutAttributeWidth
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:searchBarTextField
                                                                          attribute:NSLayoutAttributeWidth
                                                                         multiplier:1
                                                                           constant:0];
        
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:searchBarSeparator
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:1];
        NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:searchBarSeparator
                                                                           attribute:NSLayoutAttributeBottom
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:searchBarTextField
                                                                           attribute:NSLayoutAttributeBottom
                                                                          multiplier:1
                                                                            constant:0];
        
        
        [NSLayoutConstraint activateConstraints:@[leftConstraint, widthConstraint, heightConstraint, bottomConstraint]];
    }
    
    
    // place holder
    [searchBarTextField setValue:kVectorTextColorGray forKeyPath:@"_placeholderLabel.textColor"];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Update search results.
    NSMutableArray *contacts;
    NSMutableArray *participantsArray;
    NSMutableArray *invitedParticipantsArray;
    
    if (currentSearchText.length && [searchText hasPrefix:currentSearchText])
    {
        contacts = invitableContacts;
        participantsArray = filteredActualParticipants;
        invitedParticipantsArray = filteredInvitedParticipants;
    }
    else
    {
        // Retrieve all known matrix users
        NSArray *matrixContacts = [NSMutableArray arrayWithArray:[MXKContactManager sharedManager].matrixContacts];
        
        // Retrieve all known email addresses from local contacts
        NSArray *localEmailContacts = [MXKContactManager sharedManager].localEmailContacts;
        
        contacts = [NSMutableArray arrayWithCapacity:(matrixContacts.count + localEmailContacts.count)];
        
        // Add first email contacts
        if (localEmailContacts.count)
        {
            [contacts addObjectsFromArray:localEmailContacts];
        }
        
        // Matrix ids: split contacts with several ids, and remove the current participants.
        for (MXKContact* contact in matrixContacts)
        {
            NSArray *identifiers = contact.matrixIdentifiers;
            if (identifiers.count > 1)
            {
                for (NSString *userId in identifiers)
                {
                    if ([contactsById objectForKey:userId] == nil)
                    {
                        Contact *splitContact = [[Contact alloc] initMatrixContactWithDisplayName:contact.displayName andMatrixID:userId];
                        splitContact.mxMember = [self.mxRoom.state memberWithUserId:userId];
                        [contacts addObject:splitContact];
                    }
                }
            }
            else if (identifiers.count)
            {
                NSString *userId = identifiers.firstObject;
                if ([contactsById objectForKey:userId] == nil)
                {
                    [contacts addObject:contact];
                }
            }
        }
        
        // Copy participants and invited participants
        participantsArray = [actualParticipants copy];
        invitedParticipantsArray = [invitedParticipants copy];
    }
    currentSearchText = searchText;
    
    // Update invitable contacts list:
    invitableContacts = [NSMutableArray array];
    if (searchText.length)
    {
        // Show what the user is typing in a cell. So that he can click on it
        MXKContact *contact = [[MXKContact alloc] initMatrixContactWithDisplayName:searchText andMatrixID:nil];
        [invitableContacts addObject:contact];
    }
    for (MXKContact* contact in contacts)
    {
        if ([contact matchedWithPatterns:@[currentSearchText]])
        {
            [invitableContacts addObject:contact];
        }
    }
    
    // Update filtered participants list
    filteredActualParticipants = [NSMutableArray array];
    for (Contact *contact in participantsArray)
    {
        if ([contact matchedWithPatterns:@[currentSearchText]])
        {
            [filteredActualParticipants addObject:contact];
        }
    }
    
    // Update filtered invited participants list
    filteredInvitedParticipants = [NSMutableArray array];
    for (Contact *contact in invitedParticipantsArray)
    {
        if ([contact matchedWithPatterns:@[currentSearchText]])
        {
            [filteredInvitedParticipants addObject:contact];
        }
    }
    
    // Refresh display
    [self.tableView reloadData];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    self.isAddParticipantSearchBarEditing = YES;
    searchBar.showsCancelButton = YES;
    
    if (![MXKAppSettings standardAppSettings].syncLocalContacts)
    {
        // Allow local contacts sync in order to add address book emails in search result
        [MXKAppSettings standardAppSettings].syncLocalContacts = YES;
    }
    
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // "Done" key has been pressed. Cancel the invitation process
    [self searchBarCancelButtonClicked:searchBar];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = currentSearchText = nil;
    invitableContacts = nil;
    filteredActualParticipants = nil;
    filteredInvitedParticipants = nil;
    self.isAddParticipantSearchBarEditing = NO;
    
    // Leave search
    [searchBar resignFirstResponder];
}

@end
