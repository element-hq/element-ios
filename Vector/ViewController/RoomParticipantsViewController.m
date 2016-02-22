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

#import "VectorDesignValues.h"

#import "RageShakeManager.h"

#import "AppDelegate.h"

#import "AvatarGenerator.h"

#import "Contact.h"

@interface RoomParticipantsViewController ()
{
    // Add participants section
    MXKTableViewCellWithSearchBar *addParticipantsSearchBarCell;
    NSString *addParticipantsSearchText;
    
    UIView* searchBarSeparator;
    
    // Search result section
    NSMutableArray *filteredParticipants;
    
    MXKAlert *currentAlert;
    
    // Mask view while processing a request
    UIActivityIndicatorView * pendingMaskSpinnerView;
    
    // The members events listener.
    id membersListener;
    
    // Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
    id leaveRoomNotificationObserver;
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
    
    addParticipantsSearchBarCell = [[MXKTableViewCellWithSearchBar alloc] init];
    addParticipantsSearchBarCell.contentView.backgroundColor = [UIColor whiteColor];
    addParticipantsSearchBarCell.mxkSearchBar.searchBarStyle = UISearchBarStyleMinimal;
    addParticipantsSearchBarCell.mxkSearchBar.returnKeyType = UIReturnKeyDone;
    addParticipantsSearchBarCell.mxkSearchBar.keyboardType = UIKeyboardTypeEmailAddress;
    addParticipantsSearchBarCell.mxkSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
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

    // ensure that the separator line is not displayed
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
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
        [self.mxRoom.liveTimeLine removeListener:membersListener];
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
        [self.mxRoom.liveTimeLine removeListener:membersListener];
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
        membersListener = [self.mxRoom.liveTimeLine listenToEventsOfTypes:mxMembersEvents onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {
            
            // Consider only live event
            if (direction == MXEventDirectionForwards)
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
                                [self addRoomMemberToParticipants:mxMember];
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
        [self.tableView reloadData];
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
                [self addRoomMemberToParticipants:mxMember];
            }
        }

        for (MXRoomThirdPartyInvite *roomThirdPartyInvite in roomThirdPartyInvites)
        {
            [self addRoomThirdPartyInviteToParticipants:roomThirdPartyInvite];
        }
    }
}

- (void)addRoomMemberToParticipants:(MXRoomMember*)mxMember
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
        Contact *contact = [[Contact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:mxMember.userId];
        contact.mxMember = mxMember;
        [mxkContactsById setObject:contact forKey:mxMember.userId];

        [self addContactToParticipants:contact withKey:mxMember.userId isAdmin:isAdmin];
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

        [self addContactToParticipants:contact withKey:roomThirdPartyInvite.token isAdmin:NO];
    }
}

- (void)addContactToParticipants:(Contact*)theContact withKey:(NSString*)key isAdmin:(BOOL)isAdmin
{
    // Add this participant (admin is in first position, the other are sorted in alphabetical order by trimming special character ('@', '_'...).
    NSUInteger index = 0;
    NSCharacterSet *specialCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"_!~`@#$%^&*-+();:={}[],.<>?\\/\"\'"];
    NSString *trimmedDisplayName = [theContact.displayName stringByTrimmingCharactersInSet:specialCharacterSet];
    if (isAdmin)
    {
        // Check whether there is other admin
        for (NSString *userId in mutableParticipants)
        {
            if ([self.mxRoom.state memberNormalizedPowerLevel:userId] == 1)
            {
                Contact *contact = [mxkContactsById objectForKey:userId];

                // Sort admin in alphabetical order (skip symbols before comparing)
                NSString *trimmedContactName = [contact.displayName stringByTrimmingCharactersInSet:specialCharacterSet];
                if (!trimmedContactName.length)
                {
                    if (trimmedDisplayName.length || [theContact.displayName compare:contact.displayName options:NSCaseInsensitiveSearch] != NSOrderedDescending)
                    {
                        break;
                    }
                }
                else if (trimmedDisplayName.length && [trimmedDisplayName compare:trimmedContactName options:NSCaseInsensitiveSearch] != NSOrderedDescending)
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
                Contact *contact = [mxkContactsById objectForKey:userId];

                // Sort in alphabetical order (skip symbols before comparing)
                NSString *trimmedContactName = [contact.displayName stringByTrimmingCharactersInSet:specialCharacterSet];
                if (!trimmedContactName.length)
                {
                    if (trimmedDisplayName.length || [theContact.displayName compare:contact.displayName options:NSCaseInsensitiveSearch] != NSOrderedDescending)
                    {
                        break;
                    }
                }
                else if (trimmedDisplayName.length && [trimmedDisplayName compare:trimmedContactName options:NSCaseInsensitiveSearch] != NSOrderedDescending)
                {
                    break;
                }

                index++;
            }
        }
    }

    // Add this participant
    [mutableParticipants insertObject:key atIndex:index];
}

// key is a room member user id or a room 3pid invite token
- (void)removeParticipantByKey:(NSString*)key
{
    if (mutableParticipants.count)
    {
        NSUInteger index = [mutableParticipants indexOfObject:key];
        if (index != NSNotFound)
        {
            [mxkContactsById removeObjectForKey:key];
            [mutableParticipants removeObjectAtIndex:index];
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
    
    searchResultSection = participantsSection = -1;
    
    if (_isAddParticipantSearchBarEditing)
    {
        searchResultSection = count++;
    }
    else
    {
        participantsSection = count++;
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

- (void)customizeContactCell:(ContactTableViewCell*)contactCell atIndexPath:(NSIndexPath*) indexPath
{
    // TODO by the inherited class
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if ((indexPath.section == searchResultSection) || (indexPath.section == participantsSection))
    {
        ContactTableViewCell* participantCell = [tableView dequeueReusableCellWithIdentifier:[ContactTableViewCell defaultReuseIdentifier]];
        
        if (!participantCell)
        {
            participantCell = [[ContactTableViewCell alloc] init];
            // do not show the custom accessory view
            participantCell.showCustomAccessoryView = NO;
        }
    
        participantCell.mxRoom = self.mxRoom;
        
        Contact *contact = nil;
        
        // oneself dedicated cell
        if ((indexPath.section == participantsSection && userMatrixId && indexPath.row == 0))
        {
            contact = [mxkContactsById objectForKey:userMatrixId];
            
            if (!contact)
            {
                // Check whether user is admin
                BOOL isAdmin = ([self.mxRoom.state memberNormalizedPowerLevel:userMatrixId] == 1);
                
                NSString *displayName = NSLocalizedStringFromTable(@"you", @"Vector", nil);
                if (isAdmin)
                {
                    displayName = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_participants_admin_name", @"Vector", nil), displayName];
                }
                
                contact = [[Contact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:userMatrixId];
                contact.mxMember = [self.mxRoom.state memberWithUserId:userMatrixId];
                [mxkContactsById setObject:contact forKey:userMatrixId];
            }
        }
        else if (indexPath.section == searchResultSection)
        {
            contact = filteredParticipants[indexPath.row];
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
                contact = [mxkContactsById objectForKey:userId];
                
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
                            contact = [[Contact alloc] initMatrixContactWithDisplayName:((mxUser.displayname.length > 0) ? mxUser.displayname : userId) andMatrixID:userId];
                            contact.mxMember = [self.mxRoom.state memberWithUserId:userId];
                            break;
                        }
                    }
                    
                    if (contact)
                    {
                        [mxkContactsById setObject:contact forKey:userId];
                    }
                    
                }
            }
        }
        
        if (indexPath.section == searchResultSection)
        {
            participantCell.selectionStyle = UITableViewCellSelectionStyleDefault;
            participantCell.bottomLineSeparator.hidden = ((indexPath.row+1) != filteredParticipants.count);
        }
        else
        {
            participantCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (userMatrixId)
            {
                participantCell.bottomLineSeparator.hidden = ((indexPath.row) != mutableParticipants.count);
            }
            else
            {
                participantCell.bottomLineSeparator.hidden = ((indexPath.row+1) != mutableParticipants.count);
            }
        }
        
        [self customizeContactCell:participantCell atIndexPath:indexPath];
        [participantCell render:contact];
    
        cell = participantCell;
    }
    
    return cell;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    // iOS8 requires this method to enable editing (see editActionsForRowAtIndexPath).
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return addParticipantsSearchBarCell.contentView.frame.size.height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return addParticipantsSearchBarCell.contentView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 74.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    if (indexPath.section == searchResultSection)
    {
        if (row == 0)
        {
            // This is the text entered by the user
            // Try to invite what he typed
            MXKContact *contact = filteredParticipants[row];

            // Invite this user if a room is defined
            if (self.mxRoom)
            {
                NSString *participantId = contact.displayName;

                // Is it an email or a Matrix user ID?
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\S+@\\S+\\.\\S+$" options:NSRegularExpressionCaseInsensitive error:nil];
                BOOL isEmailAddress = (nil != [regex firstMatchInString:participantId options:0 range:NSMakeRange(0, participantId.length)]);

                // Sanity check the input
                if (!isEmailAddress &&
                    ([participantId characterAtIndex:0] != '@' || [participantId containsString:@":"] == NO))
                {
                    __weak typeof(self) weakSelf = self;
                    currentAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"room_participants_invite_malformed_id_title", @"Vector", nil)
                                                           message:NSLocalizedStringFromTable(@"room_participants_invite_malformed_id", @"Vector", nil)
                                                             style:MXKAlertStyleAlert];

                    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                                                style:MXKAlertActionStyleCancel
                                                                              handler:^(MXKAlert *alert) {

                                                                                  __strong __typeof(weakSelf)strongSelf = weakSelf;
                                                                                  strongSelf->currentAlert = nil;

                                                                              }];
                    [currentAlert showInViewController:self];
                }
                else
                {
                    if (isEmailAddress)
                    {
                        [self addPendingActionMask];
                        [self.mxRoom inviteUserByEmail:participantId success:^{

                            [self removePendingActionMask];

                            // Refresh display by leaving search session
                            [self searchBarCancelButtonClicked:addParticipantsSearchBarCell.mxkSearchBar];

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
                            [self searchBarCancelButtonClicked:addParticipantsSearchBarCell.mxkSearchBar];

                        } failure:^(NSError *error) {

                            [self removePendingActionMask];
                            
                            NSLog(@"[RoomParticipantsVC] Invite %@ failed", participantId);
                            // Alert user
                            [[AppDelegate theDelegate] showErrorAsAlert:error];
                        }];
                    }
                }
            }
        }
        else if (row < filteredParticipants.count)
        {
            MXKContact *contact = filteredParticipants[row];
            
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
                        
                        NSLog(@"[RoomParticipantsVC] Invite %@ failed", participantId);
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
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* actions = [[NSMutableArray alloc] init];
    
    // add the swipe to delete on search and participants section
    if (indexPath.section == participantsSection)
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
    
    if (section == participantsSection)
    {
        __weak typeof(self) weakSelf = self;
        
        if (currentAlert)
        {
            [currentAlert dismiss:NO];
            currentAlert = nil;
        }
        
        if (userMatrixId && (0 == row))
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
            if (userMatrixId)
            {
                row --;
            }
            
            if (row < mutableParticipants.count)
            {
                NSString *memberUserId = mutableParticipants[row];
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
                                                                     [strongSelf->mutableParticipants removeObjectAtIndex:row];
                                                                     
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
    // caret color
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
    
    NSMutableArray *constacts;
    
    if (addParticipantsSearchText.length && [searchText hasPrefix:addParticipantsSearchText])
    {
        constacts = filteredParticipants;
    }
    else
    {
        // Retrieve all known matrix users
        NSArray *matrixContacts = [NSMutableArray arrayWithArray:[MXKContactManager sharedManager].matrixContacts];
        constacts = [NSMutableArray arrayWithCapacity:matrixContacts.count];
        
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
                            Contact *splitContact = [[Contact alloc] initMatrixContactWithDisplayName:contact.displayName andMatrixID:userId];
                            splitContact.mxMember = [self.mxRoom.state memberWithUserId:userId];
                            [constacts addObject:splitContact];
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
                        [constacts addObject:contact];
                    }
                }
            }
        }
    }
    addParticipantsSearchText = searchText;
    
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

    for (MXKContact* contact in constacts)
    {
        if ([contact matchedWithPatterns:@[addParticipantsSearchText]])
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
