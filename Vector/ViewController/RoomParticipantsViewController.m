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
    
    // Search result section
    NSMutableArray *filteredParticipants;
    
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
    
    if (!actualMembers)
    {
        actualMembers = [NSMutableArray array];
    }
    if (!invitedMembers)
    {
        invitedMembers = [NSMutableArray array];
    }
    
    if (!mxkContactsById)
    {
        mxkContactsById = [NSMutableDictionary dictionary];
    }
    
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
    
    filteredParticipants = nil;
    mxkContactsById = nil;
    
    actualMembers = nil;
    invitedMembers = nil;
    
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
    // Remove the previous listener
    if (leaveRoomNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:leaveRoomNotificationObserver];
        leaveRoomNotificationObserver = nil;
    }
    if (membersListener)
    {
        [self.mxRoom.liveTimeline removeListener:membersListener];
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
        NSArray *mxMembersEvents = @[kMXEventTypeStringRoomMember, kMXEventTypeStringRoomThirdPartyInvite, kMXEventTypeStringRoomPowerLevels];
        membersListener = [self.mxRoom.liveTimeline listenToEventsOfTypes:mxMembersEvents onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {
            
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
                                [self handleRoomMember:mxMember];
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
                if (membersSection != -1 || invitedSection != -1)
                {
                    [self.tableView reloadData];
                }
            }
            
        }];
    }
    
    // Search bar header is hidden when no room is provided
    _searchBarHeader.hidden = (self.mxRoom == nil);
    
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
    // Flush existing participants list
    actualMembers = [NSMutableArray array];
    invitedMembers = [NSMutableArray array];
    mxkContactsById = [NSMutableDictionary dictionary];
    userMatrixId = nil;
    
    if (self.mxRoom)
    {
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
                    userMatrixId = userId;
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
    }
}

- (void)handleRoomMember:(MXRoomMember*)mxMember
{
    // Remove previous occurrence of this member (if any)
    [self removeParticipantByKey:mxMember.userId];

    // If any, remove 3pid invite corresponding to this room member
    if (mxMember.thirdPartyInviteToken)
    {
        [self removeParticipantByKey:mxMember.thirdPartyInviteToken];
    }
    
    // Add this member after checking his status
    if (mxMember.membership == MXMembershipJoin || mxMember.membership == MXMembershipInvite)
    {
        // Check whether this member is admin
        MXRoomPowerLevels *powerLevels = [self.mxRoom.state powerLevels];
        BOOL isAdmin = ([powerLevels powerLevelOfUserWithUserID:mxMember.userId] >= kVectorRoomAdminLevel);
        
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
        Contact *contact = [[Contact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:mxMember.userId];
        contact.mxMember = mxMember;
        [mxkContactsById setObject:contact forKey:mxMember.userId];

        [self handleContact:contact withKey:mxMember.userId isAdmin:isAdmin isInvited:(mxMember.membership == MXMembershipInvite)];
    }
}

- (void)addRoomThirdPartyInviteToParticipants:(MXRoomThirdPartyInvite*)roomThirdPartyInvite
{
    // If the homeserver has converted the 3pid invite into a room member, do no show it
    if (![self.mxRoom.state memberWithThirdPartyInviteToken:roomThirdPartyInvite.token])
    {
        Contact *contact = [[Contact alloc] initMatrixContactWithDisplayName:roomThirdPartyInvite.displayname andMatrixID:nil];
        contact.isThirdPartyInvite = YES;
        mxkContactsById[roomThirdPartyInvite.token] = contact;

        [self handleContact:contact withKey:roomThirdPartyInvite.token isAdmin:NO isInvited:YES];
    }
}

- (void)handleContact:(Contact*)contact withKey:(NSString*)key isAdmin:(BOOL)isAdmin isInvited:(BOOL)isInvited
{
    // Select the right array
    NSMutableArray *memberIds = (isInvited ? invitedMembers : actualMembers);
    
    // Add this participant (admin is in first position, the other are sorted in alphabetical order by trimming special character ('@', '_'...).
    NSUInteger index = 0;
    NSCharacterSet *specialCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"_!~`@#$%^&*-+();:={}[],.<>?\\/\"\'"];
    NSString *trimmedName = [contact.displayName stringByTrimmingCharactersInSet:specialCharacterSet];
    
    MXRoomPowerLevels *powerLevels = [self.mxRoom.state powerLevels];
    
    if (isAdmin)
    {
        // Check whether there is other admin
        for (NSString *userId in memberIds)
        {
            if ([powerLevels powerLevelOfUserWithUserID:userId] >= kVectorRoomAdminLevel)
            {
                Contact *otherContact = [mxkContactsById objectForKey:userId];

                // Sort admin in alphabetical order (skip symbols before comparing)
                NSString *trimmedOtherName = [otherContact.displayName stringByTrimmingCharactersInSet:specialCharacterSet];
                if (!trimmedOtherName.length)
                {
                    if (trimmedName.length || [contact.displayName compare:otherContact.displayName options:NSCaseInsensitiveSearch] != NSOrderedDescending)
                    {
                        break;
                    }
                }
                else if (trimmedName.length && [trimmedName compare:trimmedOtherName options:NSCaseInsensitiveSearch] != NSOrderedDescending)
                {
                    break;
                }

                index++;
            }
            else
            {
                break;
            }
        }
    }
    else
    {
        for (NSString *userId in memberIds)
        {
            // Pass admin(s)
            if ([powerLevels powerLevelOfUserWithUserID:userId] >= kVectorRoomAdminLevel)
            {
                index++;
            }
            else
            {
                Contact *otherContact = [mxkContactsById objectForKey:userId];

                // Sort in alphabetical order (skip symbols before comparing)
                NSString *trimmedOtherName = [otherContact.displayName stringByTrimmingCharactersInSet:specialCharacterSet];
                if (!trimmedOtherName.length)
                {
                    if (trimmedName.length || [contact.displayName compare:otherContact.displayName options:NSCaseInsensitiveSearch] != NSOrderedDescending)
                    {
                        break;
                    }
                }
                else if (trimmedName.length && [trimmedName compare:trimmedOtherName options:NSCaseInsensitiveSearch] != NSOrderedDescending)
                {
                    break;
                }

                index++;
            }
        }
    }

    // Add this participant
    [memberIds insertObject:key atIndex:index];
}

// key is a room member user id or a room 3pid invite token
- (void)removeParticipantByKey:(NSString*)key
{
    if (actualMembers.count)
    {
        NSUInteger index = [actualMembers indexOfObject:key];
        if (index != NSNotFound)
        {
            [mxkContactsById removeObjectForKey:key];
            [actualMembers removeObjectAtIndex:index];
            return;
        }
    }
    
    if (invitedMembers.count)
    {
        NSUInteger index = [invitedMembers indexOfObject:key];
        if (index != NSNotFound)
        {
            [mxkContactsById removeObjectForKey:key];
            [invitedMembers removeObjectAtIndex:index];
        }
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
    
    searchResultSection = membersSection = invitedSection = -1;
    
    if (_isAddParticipantSearchBarEditing)
    {
        searchResultSection = count++;
    }
    else
    {
        if (userMatrixId || actualMembers.count)
        {
            membersSection = count++;
        }
        
        if (invitedMembers.count)
        {
            invitedSection = count++;
        }
    }
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == searchResultSection)
    {
        count = filteredParticipants.count;
    }
    else if (section == membersSection)
    {
        count = actualMembers.count;
        if (userMatrixId)
        {
            count++;
        }
    }
    else if (section == invitedSection)
    {
        count = invitedMembers.count;
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
    if ((indexPath.section == membersSection && userMatrixId && indexPath.row == 0))
    {
        contact = [mxkContactsById objectForKey:userMatrixId];
        
        if (!contact)
        {
            // Check whether user is admin
            MXRoomPowerLevels *powerLevels = [self.mxRoom.state powerLevels];
            BOOL isAdmin = ([powerLevels powerLevelOfUserWithUserID:userMatrixId] >= kVectorRoomAdminLevel);
            
            NSString *displayName = NSLocalizedStringFromTable(@"you", @"Vector", nil);
            if (isAdmin)
            {
                displayName = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_participants_admin_name", @"Vector", nil), displayName];
            }
            
            contact = [[Contact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:userMatrixId];
            contact.mxMember = [self.mxRoom.state memberWithUserId:userMatrixId];
            [mxkContactsById setObject:contact forKey:userMatrixId];
        }
        
        participantCell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else if (indexPath.section == searchResultSection)
    {
        contact = filteredParticipants[indexPath.row];
        
        participantCell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else
    {
        NSInteger index = indexPath.row;
        NSArray *memberIds;
        
        if (indexPath.section == membersSection)
        {
            memberIds = actualMembers;
            
            if (userMatrixId)
            {
                index --;
            }
        }
        else
        {
            memberIds = invitedMembers;
        }
        
        if (index < memberIds.count)
        {
            NSString *userId = memberIds[index];
            contact = [mxkContactsById objectForKey:userId];
        }
        
        participantCell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if (contact)
    {
        [participantCell render:contact];
        
        // The search displays contacts to invite. Add a plus icon to the cell
        // in order to make it more understandable for the end user
        if (indexPath.section == searchResultSection)
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
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == invitedSection)
    {
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 30)];
        
        label.text = [NSString stringWithFormat:@"   %@", NSLocalizedStringFromTable(@"room_participants_invited_section", @"Vector", nil)];
        label.font = [UIFont boldSystemFontOfSize:15.0];
        label.backgroundColor = kVectorColorLightGrey;
        
        return label;
    }
    return nil;
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
    
    if (indexPath.section == searchResultSection)
    {
        if (row == 0)
        {
            // This is the text entered by the user
            // Try to invite what he typed
            MXKContact *contact = filteredParticipants[row];

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
        else if (row < filteredParticipants.count)
        {
            MXKContact *contact = filteredParticipants[row];
            
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
        if (indexPath.section == membersSection && userMatrixId && indexPath.row == 0)
        {
            contact = [mxkContactsById objectForKey:userMatrixId];
        }
        else
        {
            NSInteger index = indexPath.row;
            NSArray *memberIds;
            
            if (indexPath.section == membersSection)
            {
                memberIds = actualMembers;
                
                if (userMatrixId)
                {
                    index --;
                }
            }
            else
            {
                memberIds = invitedMembers;
            }
            
            if (index < memberIds.count)
            {
                NSString *userId = memberIds[index];
                contact = [mxkContactsById objectForKey:userId];
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
    if (indexPath.section == membersSection || indexPath.section == invitedSection)
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
    
    if (section == membersSection || section == invitedSection)
    {
        __weak typeof(self) weakSelf = self;
        
        if (currentAlert)
        {
            [currentAlert dismiss:NO];
            currentAlert = nil;
        }
        
        if (section == membersSection && userMatrixId && (0 == row))
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
            NSMutableArray *memberIds;
            
            if (section == membersSection)
            {
                memberIds = actualMembers;
                
                if (userMatrixId)
                {
                    row --;
                }
            }
            else
            {
                memberIds = invitedMembers;
            }
            
            if (row < memberIds.count)
            {
                NSString *memberUserId = memberIds[row];
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
                                                                     [memberIds removeObjectAtIndex:row];
                                                                     
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
    NSInteger previousFilteredCount = filteredParticipants.count;
    
    NSMutableArray *contacts;
    
    if (currentSearchText.length && [searchText hasPrefix:currentSearchText])
    {
        contacts = filteredParticipants;
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
                    if ([actualMembers indexOfObject:userId] == NSNotFound && [invitedMembers indexOfObject:userId] == NSNotFound)
                    {
                        if (![userId isEqualToString:userMatrixId])
                        {
                            Contact *splitContact = [[Contact alloc] initMatrixContactWithDisplayName:contact.displayName andMatrixID:userId];
                            splitContact.mxMember = [self.mxRoom.state memberWithUserId:userId];
                            [contacts addObject:splitContact];
                        }
                    }
                }
            }
            else if (identifiers.count)
            {
                NSString *userId = identifiers.firstObject;
                if ([actualMembers indexOfObject:userId] == NSNotFound || [invitedMembers indexOfObject:userId] == NSNotFound)
                {
                    if (![userId isEqualToString:userMatrixId])
                    {
                        [contacts addObject:contact];
                    }
                }
            }
        }
    }
    currentSearchText = searchText;
    
    filteredParticipants = [NSMutableArray array];
    NSMutableArray *indexArray = [NSMutableArray array];
    NSInteger index = 0;

    // Show what the user is typing in a cell
    // So that he can click on it
    if (searchText.length)
    {
        MXKContact *contact = [[MXKContact alloc] initMatrixContactWithDisplayName:searchText andMatrixID:nil];
        [filteredParticipants addObject:contact];
        [indexArray addObject:[NSIndexPath indexPathForRow:index++ inSection:0]];
    }

    for (MXKContact* contact in contacts)
    {
        if ([contact matchedWithPatterns:@[currentSearchText]])
        {
            [filteredParticipants addObject:contact];
            [indexArray addObject:[NSIndexPath indexPathForRow:index++ inSection:0]];
        }
    }
    
    if ((searchResultSection != -1) && (previousFilteredCount || filteredParticipants.count))
    {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(searchResultSection, 1)];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
    }
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
    filteredParticipants = nil;
    self.isAddParticipantSearchBarEditing = NO;
    
    // Leave search
    [searchBar resignFirstResponder];
}

@end
