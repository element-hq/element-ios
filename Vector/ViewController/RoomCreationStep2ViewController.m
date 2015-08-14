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
    
    // Add participant
    NSInteger addParticipantSection;
    UISearchBar *participantsSearchBar;
    NSMutableArray *filteredParticipants;
    
    // Participants
    NSInteger participantsSection;
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
    participantsSearchBar = nil;
    filteredParticipants = nil;
    
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
    createButtonSection = addParticipantSection = participantsSection = -1;
    
    createButtonSection = count++;
    addParticipantSection = count++;
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
    else if (section == addParticipantSection)
    {
        count = 1 + filteredParticipants.count;
    }
    else if (section == participantsSection)
    {
        count = _roomCreationInputs.roomParticipants.count;
    }
    
    return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == addParticipantSection)
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
    else if (indexPath.section == addParticipantSection)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"roomPictureCell"];
        cell.textLabel.text = @"todo";
    }
    else if (indexPath.section == participantsSection)
    {
        //TODO
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

//- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    return 1;
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

@end
