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

#import "AppDelegate.h"

#import "VectorContactTableViewCell.h"

#import "VectorDesignValues.h"

@interface RoomCreationStep2ViewController ()
{
    UIBarButtonItem *createBarButtonItem;

    MXHTTPOperation *roomCreationRequest;
}

@end

@implementation RoomCreationStep2ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"room_creation_title", @"Vector", nil);
    
    createBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"create", @"Vector", nil) style:UIBarButtonItemStylePlain target:self action:@selector(onButtonPressed:)];
    self.navigationItem.rightBarButtonItem = createBarButtonItem;
}

- (void)destroy
{
    if (roomCreationRequest)
    {
        [roomCreationRequest cancel];
        roomCreationRequest = nil;
    }

    createBarButtonItem = nil;
    
    [super destroy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    createBarButtonItem.enabled = (_roomCreationInputs.mxSession != nil);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Update the selected participants
    _roomCreationInputs.roomParticipants = mutableParticipants;
    
    // TODO Shall we cancel room creation on Back? Shall we prompt user? Shall we disable back during room creation
//    [roomCreationRequest cancel];
//    roomCreationRequest = nil;
}

#pragma mark - 

- (void)setRoomCreationInputs:(MXKRoomCreationInputs *)roomCreationInputs
{
    _roomCreationInputs = roomCreationInputs;
    
    if (roomCreationInputs.mxSession)
    {
        userMatrixId = roomCreationInputs.mxSession.myUser.userId;
    }
    
    mutableParticipants = [NSMutableArray arrayWithArray:roomCreationInputs.roomParticipants];
}

#pragma mark - Override RoomParticipantsViewController

- (void)setIsAddParticipantSearchBarEditing:(BOOL)isAddParticipantSearchBarEditing
{
    if (isAddParticipantSearchBarEditing)
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = createBarButtonItem;
    }
    
    super.isAddParticipantSearchBarEditing = isAddParticipantSearchBarEditing;
}

#pragma mark - UITableView delegate

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[NSMutableArray alloc] init];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if ([cell isKindOfClass:[VectorContactTableViewCell class]])
    {
        cell.accessoryView = nil;
        
        if (indexPath.section == participantsSection)
        {
            if (!userMatrixId || (indexPath.row != 0))
            {
                UIImageView* accessView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
                accessView.image = [UIImage imageNamed:@"remove_icon"];
                accessView.tag = indexPath.row;
                accessView.userInteractionEnabled = YES;
                
                UITapGestureRecognizer * accessViewTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDeleteTap:)];
                [accessViewTapGesture setNumberOfTouchesRequired:1];
                [accessViewTapGesture setNumberOfTapsRequired:1];
                [accessView addGestureRecognizer:accessViewTapGesture];
                
                cell.accessoryView = accessView;
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else
        {
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
    
    return cell;
}



#pragma mark - Actions

- (void)onDeleteTap:(UIGestureRecognizer*)gestureRecognizer
{
    NSInteger row = gestureRecognizer.view.tag;
    
    if (userMatrixId)
    {
        row --;
    }
    
    if (row < mutableParticipants.count)
    {
        [mutableParticipants removeObjectAtIndex:row];
        [self.tableView reloadData];
    }
}

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == createBarButtonItem && _roomCreationInputs.mxSession)
    {
        // Disable button to prevent multiple request
        createBarButtonItem.enabled = NO;
        [self startActivityIndicator];
        
        // Update the selected participants
        _roomCreationInputs.roomParticipants = mutableParticipants;
        
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
                                              
                                              [self.navigationController dismissViewControllerAnimated:YES completion:^{
                                                  [[AppDelegate theDelegate] showRoom:room.state.roomId withMatrixSession:_roomCreationInputs.mxSession];
                                              }];
                                              
                                          } failure:^(NSError *error) {
                                              
                                              createBarButtonItem.enabled = YES;
                                              
                                              roomCreationRequest = nil;
                                              [self stopActivityIndicator];
                                              
                                              NSLog(@"[RoomCreation] Create room (%@ %@) failed: %@", _roomCreationInputs.roomName, _roomCreationInputs.roomAlias, error);
                                              
                                              // Alert user
                                              [[AppDelegate theDelegate] showErrorAsAlert:error];
                                              
                                          }];
    }
}

@end
