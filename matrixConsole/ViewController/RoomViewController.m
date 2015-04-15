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

#import "RoomMemberTableCell.h"
#import "RoomTitleView.h"

#import "MatrixSDKHandler.h"
#import "AppDelegate.h"

#import "RageShakeManager.h"

// TODO GFO
#define ROOMVIEWCONTROLLER_UPLOAD_FILE_SIZE 5000000


@interface RoomViewController () {
    
    // Members list
    NSArray *members;
    id membersListener;
    
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
    
    // Register a listener for events that concern room members
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    NSArray *mxMembersEvents = @[
                                 kMXEventTypeStringRoomMember,
                                 kMXEventTypeStringRoomPowerLevels,
                                 kMXEventTypeStringPresence
                                 ];
    membersListener = [mxHandler.mxSession listenToEventsOfTypes:mxMembersEvents onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {
        // consider only live event
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

            // refresh the
            if (members.count > 0) {
                // Hide potential action sheet
                if (self.actionMenu) {
                    [self.actionMenu dismiss:NO];
                    self.actionMenu = nil;
                }
            }
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    
    // hide action
    if (self.actionMenu) {
        [self.actionMenu dismiss:NO];
        self.actionMenu = nil;
    }
    
    // Store the potential message partially typed in text input
    [mxHandler storePartialTextMessage:self.inputToolbarView.textMessage forRoomId:self.roomDataSource.roomId];
    
    if (membersListener) {
        [mxHandler.mxSession removeListener:membersListener];
        membersListener = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Set visible room id
    [AppDelegate theDelegate].masterTabBarController.visibleRoomId = self.roomDataSource.roomId;

    [self updateUI];
    
    // Retrieve the potential message partially typed during last room display.
    // Note: We have to wait for viewDidAppear before updating growingTextView (viewWillAppear is too early)
    self.inputToolbarView.textMessage = [[MatrixSDKHandler sharedHandler] partialTextMessageForRoomId:self.roomDataSource.roomId];
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

- (void)updateUI {
    
    // Update UI by considering dataSource state
    if (self.roomDataSource && self.roomDataSource.state == MXKDataSourceStateReady) {
        // Here the activityIndicator should be stopped, we call `didMatrixSessionStateChange` to take
        // into account mxSession state before stopping activity indicator.
        [super didMatrixSessionStateChange];
        
        // Show input tool bar
        self.inputToolbarView.hidden = NO;
        
        // Check room members to enable/disable members button in nav bar
        self.showRoomMembersButtonItem.enabled = ([self.roomDataSource.room.state members].count != 0);
        
        self.roomTitleView.mxRoom = self.roomDataSource.room;
        self.roomTitleView.editable = YES;
        self.roomTitleView.hidden = NO;
    }
    else {
        self.inputToolbarView.hidden = YES;
        self.showRoomMembersButtonItem.enabled = NO;
        
        if (self.roomDataSource && self.roomDataSource.state == MXKDataSourceStatePreparing) {
            self.roomTitleView.mxRoom = self.roomDataSource.room;
            self.roomTitleView.hidden = (!self.roomTitleView.mxRoom);
        } else {
            self.roomTitleView.mxRoom = nil;
            self.roomTitleView.hidden = NO;
        }
        self.roomTitleView.editable = NO;
    }
    
    [self.roomTitleView refreshDisplay];
}

#pragma mark -

- (void)displayRoom:(MXKRoomDataSource*)roomDataSource {
    [super displayRoom:roomDataSource];
    
    [self updateUI];
}

- (void)destroy {
    members = nil;
    if (membersListener) {
        membersListener = nil;
    }
    
    if (self.actionMenu) {
        [self.actionMenu dismiss:NO];
        self.actionMenu = nil;
    }
    
    [super destroy];
}

#pragma mark - MXKDataSource delegate

- (void)dataSource:(MXKDataSource *)dataSource didStateChange:(MXKDataSourceState)state {
    // Take into account dataSource state to update UI
    [self updateUI];
    
    if ([super respondsToSelector:@selector(dataSource:didStateChange:)]) {
        [super dataSource:dataSource didStateChange:state];
    }
}

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
        NSUInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:[MatrixSDKHandler sharedHandler].userId];
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
        NSUInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:[MatrixSDKHandler sharedHandler].userId];
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
                // Here the activityIndicator should be stopped, we call `didMatrixSessionStateChange` to take
                // into account mxSession state before stopping activity indicator.
                [super didMatrixSessionStateChange];
                // Refresh title display
                textField.text = weakSelf.roomDataSource.room.state.displayname;
            } failure:^(NSError *error) {
                [super didMatrixSessionStateChange];
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
                // Here the activityIndicator should be stopped, we call `didMatrixSessionStateChange` to take
                // into account mxSession state before stopping activity indicator.
                [super didMatrixSessionStateChange];
                // Hide topic field if empty
                weakSelf.roomTitleView.hiddenTopic = !textField.text.length;
            } failure:^(NSError *error) {
                [super didMatrixSessionStateChange];
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


// TODO GFO move this method into dataSource
- (BOOL)isIRCStyleCommand:(NSString*)string {
    // Override the default behavior for `/join` command in order to open automatically the joined room
    
    if ([string hasPrefix:kCmdJoinRoom]) {
        // Join a room
        NSString *roomAlias = [string substringFromIndex:kCmdJoinRoom.length + 1];
        // Remove white space from both ends
        roomAlias = [roomAlias stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // Check
        if (roomAlias.length) {
            [[MatrixSDKHandler sharedHandler].mxSession joinRoom:roomAlias success:^(MXRoom *room) {
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
            
            MXKRoomMemberListDataSource *membersDataSource = [[MXKRoomMemberListDataSource alloc] initWithRoomId:self.roomDataSource.roomId andMatrixSession:[MatrixSDKHandler sharedHandler].mxSession];
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

@end


