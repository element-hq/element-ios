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

#import "RoomViewController.h"
#import "MemberViewController.h"

#import "MXKRoomBubbleTableViewCell.h"

#import "RoomTitleView.h"

#import "AppDelegate.h"

#import "RageShakeManager.h"

@interface RoomViewController () {
    
    // Members list
    id membersListener;
    
    // Voip call options
    UIButton *voipVoiceCallButton;
    UIButton *voipVideoCallButton;
    UIBarButtonItem *voipVoiceCallBarButtonItem;
    UIBarButtonItem *voipVideoCallBarButtonItem;
    
    // the user taps on a member thumbnail
    MXRoomMember *selectedRoomMember;
}

@property (weak, nonatomic) IBOutlet UINavigationItem *roomNavItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *showRoomMembersButtonItem;
@property (weak, nonatomic) IBOutlet RoomTitleView *roomTitleView;

@property (strong, nonatomic) MXKAlert *actionMenu;

@end

@implementation RoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Replace the default input toolbar view with the one based on `HPGrowingTextView`.
    [self setRoomInputToolbarViewClass:MXKRoomInputToolbarViewWithHPGrowingText.class];
    
    // Set rageShake handler
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // ensure that the titleView will be scaled when it will be required
    // during a screen rotation for example.
    self.roomTitleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // hide action
    if (self.actionMenu) {
        [self.actionMenu dismiss:NO];
        self.actionMenu = nil;
    }
    
    // Store the potential message partially typed in text input
    self.roomDataSource.partialTextMessage = self.inputToolbarView.textMessage;
    
    if (membersListener) {
        [self.roomDataSource.room removeListener:membersListener];
        membersListener = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Set visible room id
    [AppDelegate theDelegate].masterTabBarController.visibleRoomId = self.roomDataSource.roomId;
    
    // Retrieve the potential message partially typed during last room display.
    // Note: We have to wait for viewDidAppear before updating growingTextView (viewWillAppear is too early)
    self.inputToolbarView.textMessage = self.roomDataSource.partialTextMessage;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Reset visible room id
    [AppDelegate theDelegate].masterTabBarController.visibleRoomId = nil;
}

#pragma mark -

- (void)dismissKeyboard {
    
    [_roomTitleView dismissKeyboard];
    [super dismissKeyboard];
}

- (void)didMatrixSessionStateChange {
    
    [super didMatrixSessionStateChange];
    
    // Check dataSource state
    if (self.roomDataSource && self.roomDataSource.state == MXKDataSourceStatePreparing) {
        // dataSource is not ready, keep running the loading wheel
        [self.activityIndicator startAnimating];
    }
}

- (void)updateViewControllerAppearanceOnRoomDataSourceState {
    
    [super updateViewControllerAppearanceOnRoomDataSourceState];
    
    // Update UI by considering dataSource state
    if (self.roomDataSource && self.roomDataSource.state == MXKDataSourceStateReady) {
        self.roomTitleView.mxRoom = self.roomDataSource.room;
        self.roomTitleView.editable = YES;
        self.roomTitleView.hidden = NO;
        
        // Register a listener for events that concern room members
        if (!membersListener) {
            membersListener = [self.roomDataSource.room listenToEventsOfTypes:@[kMXEventTypeStringRoomMember] onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {
                
                // Consider only live event
                if (direction == MXEventDirectionForwards) {
                    
                    // Check the room Id (if any)
                    if (event.roomId && [event.roomId isEqualToString:self.roomDataSource.roomId] == NO) {
                        // This event does not concern the current room members
                        return;
                    }
                    
                    // Check whether no text field is editing before refreshing title view
                    if (!self.roomTitleView.isEditing) {
                        [self.roomTitleView refreshDisplay];
                    }
                    
                    // Update navigation bar items
                    [self updateNavigationBarButtonItems];
                }
            }];
        }
    } else {
        // Update the title except if the room has just been left
        if (!self.leftRoomReasonLabel) {
            if (self.roomDataSource && self.roomDataSource.state == MXKDataSourceStatePreparing) {
                self.roomTitleView.mxRoom = self.roomDataSource.room;
                self.roomTitleView.hidden = (!self.roomTitleView.mxRoom);
            }
            else {
                self.roomTitleView.mxRoom = nil;
                self.roomTitleView.hidden = NO;
            }
        }
        self.roomTitleView.editable = NO;
        
        // Remove members listener if any.
        if (membersListener) {
            [self.roomDataSource.room removeListener:membersListener];
            membersListener = nil;
        }
    }
    
    // Finalize room title refresh
    [self.roomTitleView refreshDisplay];
    
    // Update navigation bar items
    [self updateNavigationBarButtonItems];
}

- (void)destroy {
    if (membersListener) {
        [self.roomDataSource.room removeListener:membersListener];
        membersListener = nil;
    }
    
    if (self.actionMenu) {
        [self.actionMenu dismiss:NO];
        self.actionMenu = nil;
    }
    
    [super destroy];
}

#pragma mark - 

- (void)updateNavigationBarButtonItems {
    
    // Update navigation bar buttons according to room members count
    if (self.roomDataSource && self.roomDataSource.state == MXKDataSourceStateReady) {
        
        if (self.roomDataSource.room.state.members.count == 2) {
            if (!voipVoiceCallBarButtonItem || !voipVideoCallBarButtonItem) {
                voipVoiceCallButton = [UIButton buttonWithType:UIButtonTypeCustom];
                voipVoiceCallButton.frame = CGRectMake(0, 0, 36, 36);
                UIImage *voiceImage = [UIImage imageNamed:@"voice"];
                [voipVoiceCallButton setImage:voiceImage forState:UIControlStateNormal];
                [voipVoiceCallButton setImage:voiceImage forState:UIControlStateHighlighted];
                [voipVoiceCallButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                voipVoiceCallBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:voipVoiceCallButton];
                
                voipVideoCallButton = [UIButton buttonWithType:UIButtonTypeCustom];
                voipVideoCallButton.frame = CGRectMake(0, 0, 36, 36);
                UIImage *videoImage = [UIImage imageNamed:@"video"];
                [voipVideoCallButton setImage:videoImage forState:UIControlStateNormal];
                [voipVideoCallButton setImage:videoImage forState:UIControlStateHighlighted];
                [voipVideoCallButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                voipVideoCallBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:voipVideoCallButton];
            }
            
            _showRoomMembersButtonItem.enabled = YES;
            
            self.navigationItem.rightBarButtonItems = @[_showRoomMembersButtonItem, voipVideoCallBarButtonItem, voipVoiceCallBarButtonItem];
        } else {
            _showRoomMembersButtonItem.enabled = ([self.roomDataSource.room.state members].count != 0);
            self.navigationItem.rightBarButtonItems = @[_showRoomMembersButtonItem];
        }
    } else {
        _showRoomMembersButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItems = @[_showRoomMembersButtonItem];
    }
}

#pragma mark - MXKDataSource delegate

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo {
    
    // Override default implementation in case of tap on avatar
    if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnAvatarView]) {
        selectedRoomMember = [self.roomDataSource.room.state memberWithUserId:userInfo[kMXKRoomBubbleCellUserIdKey]];
        if (selectedRoomMember) {
            [self performSegueWithIdentifier:@"showMemberDetails" sender:self];
        }
    } else {
        // Keep default implementation for other actions
        [super dataSource:dataSource didRecognizeAction:actionIdentifier inCell:cell userInfo:userInfo];
    }
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    NSString *alertMsg = nil;
    
    if (textField == _roomTitleView.displayNameTextField) {
        // Check whether the user has enough power to rename the room
        MXRoomPowerLevels *powerLevels = [self.roomDataSource.room.state powerLevels];
        NSUInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mxSession.myUser.userId];
        if (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomName]) {
            // Only the room name is edited here, update the text field with the room name
            textField.text = self.roomDataSource.room.state.name;
            textField.backgroundColor = [UIColor whiteColor];
        } else {
            alertMsg = @"You are not authorized to edit this room name";
        }
        
        // Check whether the user is allowed to change room topic
        if (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomTopic]) {
            // Show topic text field even if the current value is nil
            _roomTitleView.hiddenTopic = NO;
            if (alertMsg) {
                // Here the user can only update the room topic, switch on room topic field (without displaying alert)
                alertMsg = nil;
                [_roomTitleView.topicTextField becomeFirstResponder];
                return NO;
            }
        }
    } else if (textField == _roomTitleView.topicTextField) {
        // Check whether the user has enough power to edit room topic
        MXRoomPowerLevels *powerLevels = [self.roomDataSource.room.state powerLevels];
        NSUInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mxSession.myUser.userId];
        if (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomTopic]) {
            textField.backgroundColor = [UIColor whiteColor];
            [self.roomTitleView stopTopicAnimation];
        } else {
            alertMsg = @"You are not authorized to edit this room topic";
        }
    }
    
    if (alertMsg) {
        // Alert user
        __weak typeof(self) weakSelf = self;
        if (self.actionMenu) {
            [self.actionMenu dismiss:NO];
        }
        self.actionMenu = [[MXKAlert alloc] initWithTitle:nil message:alertMsg style:MXKAlertStyleAlert];
        self.actionMenu.cancelButtonIndex = [self.actionMenu addActionWithTitle:@"Cancel" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            weakSelf.actionMenu = nil;
        }];
        [self.actionMenu showInViewController:self];
        return NO;
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == _roomTitleView.displayNameTextField) {
        textField.backgroundColor = [UIColor clearColor];
        
        NSString *roomName = textField.text;
        if ((roomName.length || self.roomDataSource.room.state.name.length) && [roomName isEqualToString:self.roomDataSource.room.state.name] == NO) {
            [self.activityIndicator startAnimating];
            __weak typeof(self) weakSelf = self;
            [self.roomDataSource.room setName:roomName success:^{
                [self stopActivityIndicator];
                // Refresh title display
                textField.text = weakSelf.roomDataSource.room.state.displayname;
            } failure:^(NSError *error) {
                [self stopActivityIndicator];
                // Revert change
                textField.text = weakSelf.roomDataSource.room.state.displayname;
                NSLog(@"[Console RoomVC] Rename room failed: %@", error);
                // Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }];
        } else {
            // No change on room name, restore title with room displayName
            textField.text = self.roomDataSource.room.state.displayname;
        }
    } else if (textField == _roomTitleView.topicTextField) {
        textField.backgroundColor = [UIColor clearColor];
        
        NSString *topic = textField.text;
        if ((topic.length || self.roomDataSource.room.state.topic.length) && [topic isEqualToString:self.roomDataSource.room.state.topic] == NO) {
            [self.activityIndicator startAnimating];
            __weak typeof(self) weakSelf = self;
            [self.roomDataSource.room setTopic:topic success:^{
                [self stopActivityIndicator];
                // Hide topic field if empty
                weakSelf.roomTitleView.hiddenTopic = !textField.text.length;
            } failure:^(NSError *error) {
                [self stopActivityIndicator];
                // Revert change
                textField.text = weakSelf.roomDataSource.room.state.topic;
                // Hide topic field if empty
                weakSelf.roomTitleView.hiddenTopic = !textField.text.length;
                NSLog(@"[RoomVC] Topic room change failed: %@", error);
                //Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }];
        } else {
            // Hide topic field if empty
            _roomTitleView.hiddenTopic = !topic.length;
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*) textField {
    if (textField == _roomTitleView.displayNameTextField) {
        // "Next" key has been pressed
        [_roomTitleView.topicTextField becomeFirstResponder];
    } else {
        // "Done" key has been pressed
        [textField resignFirstResponder];
    }
    return YES;
}

- (BOOL)isIRCStyleCommand:(NSString*)string {
    // Override the default behavior for `/join` command in order to open automatically the joined room
    
    if ([string hasPrefix:kCmdJoinRoom]) {
        // Join a room
        NSString *roomAlias = [string substringFromIndex:kCmdJoinRoom.length + 1];
        // Remove white space from both ends
        roomAlias = [roomAlias stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // Check
        if (roomAlias.length) {
            [self.mxSession joinRoom:roomAlias success:^(MXRoom *room) {
                // Show the room
                [[AppDelegate theDelegate].masterTabBarController showRoom:room.state.roomId];
            } failure:^(NSError *error) {
                NSLog(@"[Console RoomVC] Join roomAlias (%@) failed: %@", roomAlias, error);
                //Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }];
        } else {
            // Display cmd usage in text input as placeholder
            self.inputToolbarView.placeholder = @"Usage: /join <room_alias>";
        }
        return YES;
    }
    return [super isIRCStyleCommand:string];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showMemberList"]) {
        
        if ([[segue destinationViewController] isKindOfClass:[MXKRoomMemberListViewController class]]) {
            MXKRoomMemberListViewController* membersController = (MXKRoomMemberListViewController*)[segue destinationViewController];
            
            // Dismiss keyboard
            [self dismissKeyboard];
            
            MXKRoomMemberListDataSource *membersDataSource = [[MXKRoomMemberListDataSource alloc] initWithRoomId:self.roomDataSource.roomId andMatrixSession:self.mxSession];
            [membersController displayList:membersDataSource];
        }
    } else if ([[segue identifier] isEqualToString:@"showMemberDetails"]) {
        MemberViewController* controller = [segue destinationViewController];
        
        if (selectedRoomMember) {
            controller.mxRoomMember = selectedRoomMember;
            selectedRoomMember = nil;
        }
        controller.mxRoom = self.roomDataSource.room;
    }
}

#pragma mark - Action

- (IBAction)onButtonPressed:(id)sender {
    
    if (sender == voipVoiceCallButton || sender == voipVideoCallButton) {
        [self.mxSession.callManager placeCallInRoom:self.roomDataSource.roomId withVideo:(sender == voipVideoCallButton)];
    }
}

@end


