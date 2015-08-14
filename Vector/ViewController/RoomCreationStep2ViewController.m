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

#import "RoomCreationStep2ViewController.h"

#import "RageShakeManager.h"

#import "AppDelegate.h"

@interface RoomCreationStep2ViewController ()
{
    // Create
    NSInteger createButtonSection;
    UIButton *createButton;
    MXHTTPOperation *roomCreationRequest;
    
    // Add participants
    NSInteger addParticipantsSection;
    UISearchBar *addParticipantsSearchBar;
    NSString *addParticipantsSearchText;
    NSMutableArray *filteredParticipants;
    
    // Participants
    NSInteger participantsSection;
    NSMutableDictionary *participantsByIds;
}

@end

@implementation RoomCreationStep2ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Setup `MXKViewControllerHandling` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // Add each matrix session, to update the view controller appearance according to mx sessions state
    NSArray *sessions = [AppDelegate theDelegate].masterTabBarController.mxSessions;
    for (MXSession *mxSession in sessions)
    {
        [self addMatrixSession:mxSession];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)destroy
{
    createButton = nil;
    addParticipantsSearchBar = nil;
    filteredParticipants = nil;
    participantsByIds = nil;
    
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
    
    // TODO Shall we cancel room creation on Back? Shall we prompt user? Shall we disable back during room creation
//    [roomCreationRequest cancel];
//    roomCreationRequest = nil;
}

#pragma mark - Internal methods

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == createButton)
    {
        // Disable button to prevent multiple request
        createButton.enabled = NO;
        [self startActivityIndicator];
        
        // Create new room
        roomCreationRequest = [_roomCreationInputs.mxSession createRoom:_roomCreationInputs.roomName
                                       visibility:(_roomCreationInputs.roomVisibility == kMXRoomVisibilityPrivate) ? kMXRoomVisibilityPrivate :kMXRoomVisibilityPublic
                                        roomAlias:_roomCreationInputs.roomAlias
                                            topic:_roomCreationInputs.roomTopic
                                          success:^(MXRoom *room) {
                                              
                                              roomCreationRequest = nil;
                                              
                                              // Check whether some users must be invited
                                              NSArray *invitedUsers = _roomCreationInputs.roomParticipants;
                                              for (NSString *userId in invitedUsers)
                                              {
                                                  [room inviteUser:userId success:^{
                                                      
                                                      NSLog(@"[RoomCreation] %@ has been invited (roomId: %@)", userId, room.state.roomId);
                                                      
                                                  } failure:^(NSError *error) {
                                                      
                                                      NSLog(@"[RoomCreation] %@ invitation failed (roomId: %@): %@", userId, room.state.roomId, error);
                                                      
                                                      // Alert user
                                                      [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                      
                                                  }];
                                              }
                                              
                                              [self stopActivityIndicator];
                                              
                                              [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                                              [[AppDelegate theDelegate].masterTabBarController showRoom:room.state.roomId withMatrixSession:_roomCreationInputs.mxSession];
                                              
                                          } failure:^(NSError *error) {
                                              
                                              createButton.enabled = YES;
                                              
                                              roomCreationRequest = nil;
                                              [self stopActivityIndicator];
                                              
                                              NSLog(@"[RoomCreation] Create room (%@ %@) failed: %@", _roomCreationInputs.roomName, _roomCreationInputs.roomAlias, error);
                                              
                                              // Alert user
                                              [[AppDelegate theDelegate] showErrorAsAlert:error];
                                              
                                          }];
    }
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    createButtonSection = addParticipantsSection = participantsSection = -1;
    
    createButtonSection = count++;
    addParticipantsSection = count++;
    participantsSection = count++;
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if (section == createButtonSection)
    {
        count = 1;
    }
    else if (section == addParticipantsSection)
    {
        count = 1 + filteredParticipants.count;
    }
    else if (section == participantsSection)
    {
        count = _roomCreationInputs.roomParticipants.count;
        if (_roomCreationInputs.mxSession)
        {
            count++;
        }
    }
    
    return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == addParticipantsSection)
    {
        return NSLocalizedStringFromTable(@"room_creation_add_participants", @"Vector", nil);
    }
    else if (section == participantsSection)
    {
        return NSLocalizedStringFromTable(@"room_creation_participants", @"Vector", nil);
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == createButtonSection)
    {
        MXKTableViewCellWithButton *createButtonCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
        if (!createButtonCell)
        {
            createButtonCell = [[MXKTableViewCellWithButton alloc] init];
        }
        
        createButton = createButtonCell.mxkButton;
        [createButton setTitle:NSLocalizedStringFromTable(@"room_creation_create", @"Vector", nil) forState:UIControlStateNormal];
        [createButton setTitle:NSLocalizedStringFromTable(@"room_creation_create", @"Vector", nil) forState:UIControlStateHighlighted];
        
        [createButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        [createButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        createButton.enabled = (_roomCreationInputs.mxSession && _roomCreationInputs.roomName.length);
        
        cell = createButtonCell;
    }
    else if (indexPath.section == addParticipantsSection)
    {
        if (indexPath.row == 0)
        {
            MXKTableViewCellWithSearchBar *addParticipantsSearchCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithSearchBar defaultReuseIdentifier]];
            if (!addParticipantsSearchCell)
            {
                addParticipantsSearchCell = [[MXKTableViewCellWithSearchBar alloc] init];
            }
            
            addParticipantsSearchBar = addParticipantsSearchCell.mxkSearchBar;
            addParticipantsSearchBar.backgroundColor = [UIColor clearColor];
            addParticipantsSearchBar.text = addParticipantsSearchText;
            addParticipantsSearchBar.returnKeyType = UIReturnKeyDone;
            addParticipantsSearchBar.delegate = self;
            if (addParticipantsSearchText.length)
            {
                [addParticipantsSearchBar becomeFirstResponder];
            }
            
            cell = addParticipantsSearchCell;
        }
        else
        {
            NSInteger index = indexPath.row - 1;
            if (index < filteredParticipants.count)
            {
                MXKContactTableCell* filteredParticipantCell = [tableView dequeueReusableCellWithIdentifier:[MXKContactTableCell defaultReuseIdentifier]];
                if (!filteredParticipantCell)
                {
                    filteredParticipantCell = [[MXKContactTableCell alloc] init];
                }
                
                [filteredParticipantCell render:filteredParticipants[index]];
                
                // Trick, the 'add' icon is displayed here by using the matrixUserIconview which is visible for matrix contact only.
                filteredParticipantCell.matrixUserIconViewHeightConstraint.constant = 30;
                filteredParticipantCell.matrixUserIconView.image = [UIImage imageNamed:@"add"];
                filteredParticipantCell.selectionStyle = UITableViewCellSelectionStyleDefault;
                
                cell = filteredParticipantCell;
            }
        }
    }
    else if (indexPath.section == participantsSection)
    {
        MXKContactTableCell *participantCell = [tableView dequeueReusableCellWithIdentifier:[MXKContactTableCell defaultReuseIdentifier]];
        if (!participantCell)
        {
            participantCell = [[MXKContactTableCell alloc] init];
        }
        
        if (_roomCreationInputs.mxSession && indexPath.row == 0)
        {
           MXKContact *contact = [[MXKContact alloc] initMatrixContactWithDisplayName:NSLocalizedStringFromTable(@"you", @"Vector", nil) andMatrixID:_roomCreationInputs.mxSession.myUser.userId];
            
            [participantCell render:contact];
            
            // Trick, remove matrixUserIconview image to hide it.
            participantCell.matrixUserIconView.image = nil;
            participantCell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else
        {
            NSInteger index = indexPath.row;
            NSArray *participants = _roomCreationInputs.roomParticipants;
            
            if (_roomCreationInputs.mxSession)
            {
                index --;
            }
            
            if (index < participants.count)
            {
                NSString *userId = participants[index];
                MXKContact *contact = [participantsByIds objectForKey:userId];
                // Note: contact may be nil here if the participant has not been added into _roomCreationInputs by self.
                if (!contact)
                {
                    // Create this missing contact
                    // Look for the correpsonding MXUser
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
                        if (!participantsByIds)
                        {
                            participantsByIds = [NSMutableDictionary dictionary];
                        }
                        [participantsByIds setObject:contact forKey:userId];
                    }
                    
                }
                
                if (contact)
                {
                    [participantCell render:contact];
                }
                
                // Trick, the 'remove' icon is displayed here by using the matrixUserIconview which is visible for matrix contact only.
                participantCell.matrixUserIconViewHeightConstraint.constant = 30;
                participantCell.matrixUserIconView.image = [UIImage imageNamed:@"remove"];
                participantCell.selectionStyle = UITableViewCellSelectionStyleDefault;
            }
        }
        
        cell = participantCell;
    }
    
    return cell;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == createButtonSection)
    {
        return 0;
    }
    
    return 30;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]])
    {
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
        tableViewHeaderFooterView.textLabel.text = [tableViewHeaderFooterView.textLabel.text capitalizedString];
        tableViewHeaderFooterView.textLabel.font = [UIFont boldSystemFontOfSize:17];
        tableViewHeaderFooterView.textLabel.textColor = [UIColor blackColor];
    }
}

//- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    return 1;
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == addParticipantsSection && indexPath.row)
    {
        NSInteger index = indexPath.row - 1;
        if (index < filteredParticipants.count)
        {
            MXKContact *contact = filteredParticipants[index];
            
            NSArray *identifiers = contact.matrixIdentifiers;
            if (identifiers.count)
            {
                [_roomCreationInputs addParticipant:identifiers.firstObject];
                
                // Handle a mapping contact by userId for selected participants
                if (!participantsByIds)
                {
                    participantsByIds = [NSMutableDictionary dictionary];
                }
                [participantsByIds setObject:contact forKey:identifiers.firstObject];
            }
            
            [filteredParticipants removeObjectAtIndex:index];
            
            // Refresh display
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange (addParticipantsSection, 2)];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
        }
    }
    else if (indexPath.section == participantsSection)
    {
        NSInteger index = indexPath.row;
        
        if (_roomCreationInputs.mxSession)
        {
            index --;
        }
        
        NSArray *participants = _roomCreationInputs.roomParticipants;
        if (index < participants.count)
        {
            NSInteger firstSectionToRefresh = participantsSection;
            
            [_roomCreationInputs removeParticipant:participants[index]];
            
            // Check whether this removed participant must be added to the search result if any
            MXKContact *contact = [participantsByIds objectForKey:participants[index]];
            if (contact && addParticipantsSearchText.length && [contact matchedWithPatterns:@[addParticipantsSearchText]])
            {
                [filteredParticipants addObject:contact];
                firstSectionToRefresh = addParticipantsSection;
            }
            [participantsByIds removeObjectForKey:participants[index]];
            
            // Refresh display
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange (firstSectionToRefresh, 2)];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISearchBar delegate

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
        NSArray *participants = _roomCreationInputs.roomParticipants;
        for (MXKContact* contact in matrixContacts)
        {
            NSArray *identifiers = contact.matrixIdentifiers;
            if (identifiers.count > 1)
            {
                for (NSString *userId in identifiers)
                {
                    if (!participants || [participants indexOfObject:userId] == NSNotFound)
                    {
                        if (![userId isEqualToString:_roomCreationInputs.mxSession.myUser.userId])
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
                if (!participants || [participants indexOfObject:userId] == NSNotFound)
                {
                    if (![userId isEqualToString:_roomCreationInputs.mxSession.myUser.userId])
                    {
                        [mxUsers addObject:contact];
                    }
                }
            }
        }
    }
    addParticipantsSearchText = searchText;
    
    filteredParticipants = [NSMutableArray array];
    
    for (MXKContact* contact in mxUsers)
    {
        if ([contact matchedWithPatterns:@[addParticipantsSearchText]])
        {
            [filteredParticipants addObject:contact];
        }
    }
    
    if (previousFilteredCount || filteredParticipants.count)
    {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange (addParticipantsSection, 1)];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
    }
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
    // "Done" key has been pressed
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // Leave search
    [searchBar resignFirstResponder];
    addParticipantsSearchBar = nil;
    addParticipantsSearchText = nil;
    filteredParticipants = nil;
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange (addParticipantsSection, 1)];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
}

@end
