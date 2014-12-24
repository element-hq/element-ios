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
    
    NSMutableArray* buttonsTitles;
    
    // mask view while processing a request
    UIView* pendingRequestMask;
    UIActivityIndicatorView * pendingMaskSpinnerView;
}

// graphical objects
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *memberThumbnailButton;
@property (weak, nonatomic) IBOutlet UITextView *roomMemberMID;

@property (strong, nonatomic) CustomAlert *actionMenu;

- (IBAction)onButtonToggle:(id)sender;

@end

@implementation MemberViewController
@synthesize mxRoom;

- (void)dealloc {
    // close any pending actionsheet
    if (self.actionMenu) {
        [self.actionMenu dismiss:NO];
        self.actionMenu = nil;
    }
    
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // remove the line separator color
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.rowHeight = 44;
    self.tableView.allowsSelection = NO;
    
    buttonsTitles = [[NSMutableArray alloc] init];
    
    // ignore useless update
    if (_mxRoomMember) {
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
    
    // list on member updates
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
            
            MXRoomMember* nextRoomMember = nil;
            
            // get the updated memmber
            NSArray* membersList = [self.mxRoom.state members];
            for (MXRoomMember* member in membersList) {
                if ([member.userId isEqual:_mxRoomMember.userId]) {
                    nextRoomMember = member;
                    break;
                }
            }
            
            // does the member still exist ?
            if (nextRoomMember) {
                // Refresh members list
                _mxRoomMember = nextRoomMember;
                [self updateMemberInfo];
                [self.tableView reloadData];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.navigationController popToRootViewControllerAnimated:NO];
                    [[AppDelegate theDelegate].masterTabBarController setVisibleRoomId:nil];
                    [[AppDelegate theDelegate].masterTabBarController popRoomViewControllerAnimated:YES];
                });
            }
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
    self.title = _mxRoomMember.displayname ? _mxRoomMember.displayname : _mxRoomMember.userId;
    
    // set the thumbnail info
    [[self.memberThumbnailButton imageView] setContentMode: UIViewContentModeScaleAspectFill];
    [[self.memberThumbnailButton imageView] setClipsToBounds:YES];
    
    
    if (_mxRoomMember.avatarUrl) {
        imageLoader = [MediaManager loadPicture:_mxRoomMember.avatarUrl
                                        success:^(UIImage *image) {
                                            [self.memberThumbnailButton setImage:image forState:UIControlStateNormal];
                                            [self.memberThumbnailButton setImage:image forState:UIControlStateHighlighted];
                                        }
                                        failure:^(NSError *error) {
                                            NSLog(@"Failed to download image (%@): %@", _mxRoomMember.avatarUrl, error);
                                        }];
    }
    
    self.roomMemberMID.text = _mxRoomMember.userId;
}

- (void)setRoomMember:(MXRoomMember*) aRoomMember {
    // ignore useless update
    if (![_mxRoomMember.userId isEqualToString:aRoomMember.userId]) {
        _mxRoomMember = aRoomMember;
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
    NSUInteger memberPowerLevel = [powerLevels powerLevelOfUserWithUserID:_mxRoomMember.userId];
    NSUInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:mxHandler.userId];
    
    [buttonsTitles removeAllObjects];
    
    // Consider the case of the user himself
    if ([_mxRoomMember.userId isEqualToString:mxHandler.userId]) {
        
        [buttonsTitles addObject:@"Leave"];
    
        if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomPowerLevels]) {
            [buttonsTitles addObject:@"Set power level"];
        }
    } else {
        // Consider membership of the selected member
        switch (_mxRoomMember.membership) {
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
                    [buttonsTitles addObject:@"Unban"];
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
        
        // offer to start a new chat only if the room is not a 1:1 room with this user
        // it does not make sense : it would open the same room
        NSString* roomId = [mxHandler getRoomStartedWithMember:_mxRoomMember];
        if (![roomId isEqualToString:mxRoom.state.roomId]) {
            [buttonsTitles addObject:@"Start chat"];
        }
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

- (BOOL)hasPendingAction {
    return nil != pendingMaskSpinnerView;
}

- (void) addPendingActionMask {

    // add a spinner above the tableview to avoid that the user tap on any other button
    pendingMaskSpinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    pendingMaskSpinnerView.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    pendingMaskSpinnerView.frame = self.tableView.frame;
    pendingMaskSpinnerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    
    // append it
    [self.tableView.superview addSubview:pendingMaskSpinnerView];
    
    // animate it
    [pendingMaskSpinnerView startAnimating];
}

- (void) removePendingActionMask {
    if (pendingMaskSpinnerView) {
        [pendingMaskSpinnerView removeFromSuperview];
        pendingMaskSpinnerView = nil;
        [self.tableView reloadData];
    }
}

- (void) setUserPowerLevel:(MXRoomMember*)roomMember to:(int)value {
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    int currentPowerLevel = (int)([mxHandler getPowerLevel:roomMember inRoom:self.mxRoom] * 100);
    
    // check if the power level has not yet been set to 0
    if (value != currentPowerLevel) {
        __weak typeof(self) weakSelf = self;
        
        [weakSelf addPendingActionMask];
        
        // Reset user power level
        [self.mxRoom setPowerLevelOfUserWithUserID:roomMember.userId powerLevel:value success:^{
            [weakSelf removePendingActionMask];
        } failure:^(NSError *error) {
            [weakSelf removePendingActionMask];
            NSLog(@"Set user power (%@) failed: %@", roomMember.userId, error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    }
}

- (void) updateUserPowerLevel:(MXRoomMember*)roomMember {
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    __weak typeof(self) weakSelf = self;
    
    // Ask for userId to invite
    self.actionMenu = [[CustomAlert alloc] initWithTitle:@"Power Level"  message:nil style:CustomAlertStyleAlert];
    
    if (![mxHandler.userId isEqualToString:roomMember.userId]) {
        self.actionMenu.cancelButtonIndex = [self.actionMenu addActionWithTitle:@"Reset to default" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
            weakSelf.actionMenu = nil;
            
            [weakSelf setUserPowerLevel:roomMember to:0];
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
        
        if (textField.text.length > 0) {
            [weakSelf setUserPowerLevel:roomMember to:(int)[textField.text integerValue]];
        }
    }];
    [self.actionMenu showInViewController:self];
}

- (IBAction)onButtonToggle:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        
        // already a pending action
        if ([self hasPendingAction]) {
            return;
        }
        
        NSString* text = ((UIButton*)sender).titleLabel.text;
        
        if ([text isEqualToString:@"Leave"]) {
            [self addPendingActionMask];
            [self.mxRoom leave:^{
                [self removePendingActionMask];
                [self.navigationController popToRootViewControllerAnimated:NO];
                [[AppDelegate theDelegate].masterTabBarController setVisibleRoomId:nil];                
                [[AppDelegate theDelegate].masterTabBarController popRoomViewControllerAnimated:YES];
            } failure:^(NSError *error) {
                [self removePendingActionMask];
                NSLog(@"Leave room %@ failed: %@", mxRoom.state.roomId, error);
                //Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }];

        } else if ([text isEqualToString:@"Set power level"]) {
            [self updateUserPowerLevel:_mxRoomMember];
        } else if ([text isEqualToString:@"Kick"]) {
            [self addPendingActionMask];
            [mxRoom kickUser:_mxRoomMember.userId
                               reason:nil
                              success:^{
                                  [self removePendingActionMask];
                                  [self.navigationController popToRootViewControllerAnimated:YES];
                              }
                              failure:^(NSError *error) {
                                  [self removePendingActionMask];
                                  NSLog(@"Kick %@ failed: %@", _mxRoomMember.userId, error);
                                  //Alert user
                                  [[AppDelegate theDelegate] showErrorAsAlert:error];
                              }];
        } else if ([text isEqualToString:@"Ban"]) {
            [self addPendingActionMask];
            [mxRoom banUser:_mxRoomMember.userId
                              reason:nil
                             success:^{
                                 [self removePendingActionMask];
                             }
                             failure:^(NSError *error) {
                                 [self removePendingActionMask];
                                 NSLog(@"Ban %@ failed: %@", _mxRoomMember.userId, error);
                                 //Alert user
                                 [[AppDelegate theDelegate] showErrorAsAlert:error];
                             }];
        } else if ([text isEqualToString:@"Invite"]) {
            [self addPendingActionMask];
            [mxRoom inviteUser:_mxRoomMember.userId
                                success:^{
                                    [self removePendingActionMask];
                                }
                                failure:^(NSError *error) {
                                    [self removePendingActionMask];
                                    NSLog(@"Invite %@ failed: %@", _mxRoomMember.userId, error);
                                    //Alert user
                                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                                }];
        } else if ([text isEqualToString:@"Unban"]) {
            [self addPendingActionMask];
            [mxRoom unbanUser:_mxRoomMember.userId
                               success:^{
                                   [self removePendingActionMask];
                               }
                               failure:^(NSError *error) {
                                   [self removePendingActionMask];
                                   NSLog(@"Unban %@ failed: %@", _mxRoomMember.userId, error);
                                   //Alert user
                                   [[AppDelegate theDelegate] showErrorAsAlert:error];
                               }];
    
        } else if ([text isEqualToString:@"Start chat"]) {
            [self addPendingActionMask];
            
            MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
            NSString* roomId = [mxHandler getRoomStartedWithMember:_mxRoomMember];
            
            // if the room has already been started
            if (roomId) {
                // open it
                [[AppDelegate theDelegate].masterTabBarController showRoom:roomId];
            }
            else {
                // else create new room
                [mxHandler.mxRestClient createRoom:nil
                                        visibility:kMXRoomVisibilityPrivate
                                         roomAlias:nil
                                             topic:nil
                                           success:^(MXCreateRoomResponse *response) {
                                               [self removePendingActionMask];
                                               
                                               // add the user
                                               [mxHandler.mxRestClient inviteUser:_mxRoomMember.userId toRoom:response.roomId success:^{
                                                   //NSLog(@"%@ has been invited (roomId: %@)", roomMember.userId, response.roomId);
                                               } failure:^(NSError *error) {
                                                   NSLog(@"%@ invitation failed (roomId: %@): %@", _mxRoomMember.userId, response.roomId, error);
                                                   //Alert user
                                                   [[AppDelegate theDelegate] showErrorAsAlert:error];
                                               }];
                                               
                                               // Open created room
                                               [[AppDelegate theDelegate].masterTabBarController showRoom:response.roomId];
                                               
                                           } failure:^(NSError *error) {
                                               [self removePendingActionMask];
                                               NSLog(@"Create room failed: %@", error);
                                               //Alert user
                                               [[AppDelegate theDelegate] showErrorAsAlert:error];
                                           }];
            }
        }
    }
}

@end
