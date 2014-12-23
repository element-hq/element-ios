/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "MemberViewController.h"

#import "AppDelegate.h"
#import "MemberActionsCell.h"
#import "MediaManager.h"

@interface MemberViewController () {
    id imageLoader;
    id membersListener;
}

@property (strong, nonatomic) CustomAlert *actionMenu;

@end

@implementation MemberViewController
@synthesize mxRoom;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // remove the line separator color
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.rowHeight = 44;
    self.tableView.allowsSelection = NO;
    
    buttonsTitles = [[NSMutableArray alloc] init];
    
    // ignore useless update
    if (_roomMember) {
        [self updateMemberInfo];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
    NSArray *mxMembersEvents = @[
                                 kMXEventTypeStringRoomMember,
                                 kMXEventTypeStringRoomPowerLevels
                                 ];
    
    membersListener = [mxHandler.mxSession listenToEventsOfTypes:mxMembersEvents onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {
        // consider only live event
        if (direction == MXEventDirectionForwards) {
            // Check the room Id (if any)
            if (event.roomId && [event.roomId isEqualToString:mxRoom.state.roomId] == NO) {
                // This event does not concern the current room members
                return;
            }
            
            // Hide potential action sheet
            if (self.actionMenu) {
                [self.actionMenu dismiss:NO];
                self.actionMenu = nil;
            }
            // Refresh members list
            [self updateMemberInfo];
            [self.tableView reloadData];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (imageLoader) {
        [MediaManager cancel:imageLoader];
        imageLoader = nil;
    }
    
    if (membersListener) {
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        [mxHandler.mxSession removeListener:membersListener];
        membersListener = nil;
    }
}

- (void) updateMemberInfo {
    self.title = _roomMember.displayname;
    
    // set the thumbnail info
    [[self.memberThumbnailButton imageView] setContentMode: UIViewContentModeScaleAspectFill];
    [[self.memberThumbnailButton imageView] setClipsToBounds:YES];
    
    
    imageLoader = [MediaManager loadPicture:_roomMember.avatarUrl
                                    success:^(UIImage *image) {
                                        [self.memberThumbnailButton setImage:image forState:UIControlStateNormal];
                                        [self.memberThumbnailButton setImage:image forState:UIControlStateHighlighted];
                                    }
                                    failure:^(NSError *error) {
                                        NSLog(@"Failed to download image (%@): %@", _roomMember.avatarUrl, error);
                                    }];
    
    self.roomMemberMID.text = _roomMember.userId;
}

- (void)setRoomMember:(MXRoomMember*) aRoomMember {
    // ignore useless update
    if (![self.roomMember.userId isEqualToString:aRoomMember.userId]) {
        _roomMember = aRoomMember;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
    // Check user's power level before allowing an action (kick, ban, ...)
    MXRoomPowerLevels *powerLevels = [mxRoom.state powerLevels];
    NSUInteger memberPowerLevel = [powerLevels powerLevelOfUserWithUserID:_roomMember.userId];
    NSUInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:mxHandler.userId];
    
    [buttonsTitles removeAllObjects];
    
    // Consider the case of the user himself
    if ([_roomMember.userId isEqualToString:mxHandler.userId]) {
        
        [buttonsTitles addObject:@"Leave"];
    
        if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomPowerLevels]) {
            [buttonsTitles addObject:@"Set power level"];
        }
    } else {
        // Consider membership of the selected member
        switch (_roomMember.membership) {
            case MXMembershipInvite:
            case MXMembershipJoin: {
                // Check conditions to be able to kick someone
                if (oneSelfPowerLevel >= [powerLevels kick] && oneSelfPowerLevel >= memberPowerLevel) {
                    [buttonsTitles addObject:@"Kick"];
                }
                // Check conditions to be able to ban someone
                if (oneSelfPowerLevel >= [powerLevels ban] && oneSelfPowerLevel >= memberPowerLevel) {
                    [buttonsTitles addObject:@"Ban"];
                }
                break;
            }
            case MXMembershipLeave: {
                // Check conditions to be able to invite someone
                if (oneSelfPowerLevel >= [powerLevels invite]) {
                    [buttonsTitles addObject:@"Invite"];
                }
                // Check conditions to be able to ban someone
                if (oneSelfPowerLevel >= [powerLevels ban] && oneSelfPowerLevel >= memberPowerLevel) {
                    [buttonsTitles addObject:@"Ban"];
                }
                break;
            }
            case MXMembershipBan: {
                // Check conditions to be able to unban someone
                if (oneSelfPowerLevel >= [powerLevels ban] && oneSelfPowerLevel >= memberPowerLevel) {
                    [buttonsTitles addObject:@"Ban"];
                }
                break;
            }
            default: {
                break;
            }
        }
        
        // update power level
        if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomPowerLevels]) {
            [buttonsTitles addObject:@"Set power level"];
        }
        
        [buttonsTitles addObject:@"Start chat"];
    }
    
    return (buttonsTitles.count + 1) / 2;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.tableView == aTableView) {
        NSInteger row = indexPath.row;
        MemberActionsCell* memberActionsCell = (MemberActionsCell*)[aTableView dequeueReusableCellWithIdentifier:@"MemberActionsCell" forIndexPath:indexPath];
        
        NSString* leftTitle = nil;
        NSString* rightTitle = nil;
        
        if ((row * 2) < buttonsTitles.count) {
            leftTitle = [buttonsTitles objectAtIndex:row * 2];
        }
        
        if (((row * 2) + 1) < buttonsTitles.count) {
            rightTitle = [buttonsTitles objectAtIndex:(row * 2) + 1];
        }
        
        [memberActionsCell setLeftButtonText:leftTitle];
        [memberActionsCell setRightButtonText:rightTitle];
        
        return memberActionsCell;
    }
    
    return nil;
}


#pragma mark - button management

- (void) updateUserPowerLevel:(MXRoomMember*)roomMember
{
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    __weak typeof(self) weakSelf = self;
    
    // Ask for userId to invite
    self.actionMenu = [[CustomAlert alloc] initWithTitle:@"Power Level"  message:nil style:CustomAlertStyleAlert];
    
    if (![mxHandler.userId isEqualToString:roomMember.userId]) {
        self.actionMenu.cancelButtonIndex = [self.actionMenu addActionWithTitle:@"Reset to default" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
            weakSelf.actionMenu = nil;
            
            // Reset user power level
            [weakSelf.mxRoom setPowerLevelOfUserWithUserID:roomMember.userId powerLevel:0 success:^{
            } failure:^(NSError *error) {
                NSLog(@"Reset user power (%@) failed: %@", roomMember.userId, error);
                //Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }];
            
        }];
    }
    [self.actionMenu addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = NO;
        textField.text = [NSString stringWithFormat:@"%d", (int)([mxHandler getPowerLevel:roomMember inRoom:weakSelf.mxRoom] * 100)];
        textField.placeholder = nil;
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    [self.actionMenu addActionWithTitle:@"OK" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
        UITextField *textField = [alert textFieldAtIndex:0];
        weakSelf.actionMenu = nil;
        
        // Set user power level
        [weakSelf.mxRoom setPowerLevelOfUserWithUserID:roomMember.userId powerLevel:[textField.text integerValue] success:^{
        } failure:^(NSError *error) {
            NSLog(@"Set user power (%@) failed: %@", roomMember.userId, error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
        
    }];
    [self.actionMenu showInViewController:self];
}

- (IBAction)onButtonToggle:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        NSString* text = ((UIButton*)sender).titleLabel.text;
        
        if ([text isEqualToString:@"Leave"]) {
            
            [self.mxRoom leave:^{
                // Back to recents
                [[AppDelegate theDelegate].masterTabBarController popRoomViewControllerAnimated:YES];
            } failure:^(NSError *error) {
                NSLog(@"Leave room %@ failed: %@", mxRoom.state.roomId, error);
                //Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }];

        } else if ([text isEqualToString:@"Set power level"]) {
            [self updateUserPowerLevel:_roomMember];
        } else if ([text isEqualToString:@"Kick"]) {
            [mxRoom kickUser:_roomMember.userId
                               reason:nil
                              success:^{
                              }
                              failure:^(NSError *error) {
                                  NSLog(@"Kick %@ failed: %@", _roomMember.userId, error);
                                  //Alert user
                                  [[AppDelegate theDelegate] showErrorAsAlert:error];
                              }];
        } else if ([text isEqualToString:@"Ban"]) {
            [mxRoom banUser:_roomMember.userId
                              reason:nil
                             success:^{
                             }
                             failure:^(NSError *error) {
                                 NSLog(@"Ban %@ failed: %@", _roomMember.userId, error);
                                 //Alert user
                                 [[AppDelegate theDelegate] showErrorAsAlert:error];
                             }];
        } else if ([text isEqualToString:@"Invite"]) {
            [mxRoom inviteUser:_roomMember.userId
                                success:^{
                                }
                                failure:^(NSError *error) {
                                    NSLog(@"Invite %@ failed: %@", _roomMember.userId, error);
                                    //Alert user
                                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                                }];
        } else if ([text isEqualToString:@"Unban"]) {
            [mxRoom unbanUser:_roomMember.userId
                               success:^{
                               }
                               failure:^(NSError *error) {
                                   NSLog(@"Unban %@ failed: %@", _roomMember.userId, error);
                                   //Alert user
                                   [[AppDelegate theDelegate] showErrorAsAlert:error];
                               }];
    
        } else if ([text isEqualToString:@"Start chat"]) {
            MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
            
            // Create new room
            [mxHandler.mxRestClient createRoom:(_roomMember.displayname) ? _roomMember.displayname : _roomMember.userId
                                    visibility:kMXRoomVisibilityPrivate
                                     roomAlias:nil
                                         topic:nil
                                       success:^(MXCreateRoomResponse *response) {
                                           // add the user
                                           [mxHandler.mxRestClient inviteUser:_roomMember.userId toRoom:response.roomId success:^{
                                               //NSLog(@"%@ has been invited (roomId: %@)", roomMember.userId, response.roomId);
                                           } failure:^(NSError *error) {
                                               NSLog(@"%@ invitation failed (roomId: %@): %@", _roomMember.userId, response.roomId, error);
                                               //Alert user
                                               [[AppDelegate theDelegate] showErrorAsAlert:error];
                                           }];
                                           
                                           // Open created room
                                           [[AppDelegate theDelegate].masterTabBarController showRoom:response.roomId];
                                           
                                       } failure:^(NSError *error) {
                                           NSLog(@"Create room failed: %@", error);
                                           //Alert user
                                           [[AppDelegate theDelegate] showErrorAsAlert:error];
                                       }];            
        }
    }
}

@end
