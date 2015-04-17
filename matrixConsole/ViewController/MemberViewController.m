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

#import "MemberViewController.h"

#import "AppDelegate.h"
#import "RoomMemberActionsCell.h"

#import "RageShakeManager.h"

@interface MemberViewController () {
    NSString *thumbnailURL;
    MXKMediaLoader* imageLoader;
    id membersListener;
    
    NSMutableArray* buttonsTitles;
    
    // mask view while processing a request
    UIView* pendingRequestMask;
    UIActivityIndicatorView * pendingMaskSpinnerView;
    
    // Observe left rooms
    id kMXSessionWillLeaveRoomNotificationObserver;
}

// graphical objects
@property (weak, nonatomic) IBOutlet UIButton *memberThumbnailButton;
@property (weak, nonatomic) IBOutlet UITextView *roomMemberMID;

@property (strong, nonatomic) MXKAlert *actionMenu;

- (IBAction)onButtonToggle:(id)sender;

@end

@implementation MemberViewController
@synthesize mxRoom;

- (void)dealloc {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // remove the line separator color
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.rowHeight = 44;
    self.tableView.allowsSelection = NO;
    
    buttonsTitles = [[NSMutableArray alloc] init];
    
    // Set rageShake handler
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // ignore useless update
    if (_mxRoomMember) {
        [self updateMemberInfo];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (mxRoom) {
        // Observe room's members update
        NSArray *mxMembersEvents = @[
                                     kMXEventTypeStringRoomMember,
                                     kMXEventTypeStringRoomPowerLevels
                                     ];
        
        
        membersListener = [mxRoom listenToEventsOfTypes:mxMembersEvents onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {
            // consider only live event
            if (direction == MXEventDirectionForwards) {
                
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
                    [self withdrawViewControllerAnimated:YES completion:nil];
                }
            }
        }];
    }
    
    // Observe kMXSessionWillLeaveRoomNotification to be notified if the user leaves the current room.
    kMXSessionWillLeaveRoomNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionWillLeaveRoomNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Check whether the user will leave the room related to the displayed member
        if (notif.object == self.mxSession) {
            NSString *roomId = notif.userInfo[kMXSessionNotificationRoomIdKey];
            if (roomId && [roomId isEqualToString:mxRoom.state.roomId]) {
                // We must remove the current view controller.
                [self withdrawViewControllerAnimated:YES completion:nil];
            }
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Remove observers
    if (kMXSessionWillLeaveRoomNotificationObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXSessionWillLeaveRoomNotificationObserver];
        kMXSessionWillLeaveRoomNotificationObserver = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (imageLoader) {
        [imageLoader cancel];
        imageLoader = nil;
    }
    
    if (membersListener && mxRoom) {
        [mxRoom removeListener:membersListener];
        membersListener = nil;
    }
}

- (void)destroy {
    
    // close any pending actionsheet
    if (self.actionMenu) {
        [self.actionMenu dismiss:NO];
        self.actionMenu = nil;
    }
    
    if (membersListener && mxRoom) {
        [mxRoom removeListener:membersListener];
        membersListener = nil;
    }
    
    // Remove observers
    if (kMXSessionWillLeaveRoomNotificationObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXSessionWillLeaveRoomNotificationObserver];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (imageLoader) {
        [imageLoader cancel];
        imageLoader = nil;
    }
}

- (void)updateMemberInfo {
    self.title = _mxRoomMember.displayname ? _mxRoomMember.displayname : _mxRoomMember.userId;
    
    // set the thumbnail info
    [[self.memberThumbnailButton imageView] setContentMode: UIViewContentModeScaleAspectFill];
    [[self.memberThumbnailButton imageView] setClipsToBounds:YES];
    
    // Remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_mxRoomMember.avatarUrl) {
        // Suppose this url is a matrix content uri, we use SDK to get the well adapted thumbnail from server
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        thumbnailURL = [mxHandler.mxSession.matrixRestClient urlOfContentThumbnail:_mxRoomMember.avatarUrl toFitViewSize:self.memberThumbnailButton.frame.size withMethod:MXThumbnailingMethodCrop];
        NSString *cacheFilePath = [MXKMediaManager cachePathForMediaWithURL:thumbnailURL inFolder:kMXKMediaManagerAvatarThumbnailFolder];
        
        // Check whether the image download is in progress
        id loader = [MXKMediaManager existingDownloaderWithOutputFilePath:cacheFilePath];
        if (loader) {
            // Add observers
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMXKMediaDownloadDidFinishNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMXKMediaDownloadDidFailNotification object:nil];
        } else {
            // Retrieve the image from cache
            UIImage* image = [MXKMediaManager loadPictureFromFilePath:cacheFilePath];
            if (image) {
                [self.memberThumbnailButton setImage:image forState:UIControlStateNormal];
                [self.memberThumbnailButton setImage:image forState:UIControlStateHighlighted];
            } else {
                // Cancel potential download in progress
                if (imageLoader) {
                    [imageLoader cancel];
                }
                // Add observers
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMXKMediaDownloadDidFinishNotification object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMXKMediaDownloadDidFailNotification object:nil];
                imageLoader = [MXKMediaManager downloadMediaFromURL:thumbnailURL andSaveAtFilePath:cacheFilePath];
            }
        }
    } else {
        UIImage *image = [UIImage imageNamed:@"default-profile"];
        if (image) {
            [self.memberThumbnailButton setImage:image forState:UIControlStateNormal];
            [self.memberThumbnailButton setImage:image forState:UIControlStateHighlighted];
        }
    }
    
    self.roomMemberMID.text = _mxRoomMember.userId;
}

- (void)onMediaDownloadEnd:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* url = notif.object;
        NSString* cacheFilePath = notif.userInfo[kMXKMediaLoaderFilePathKey];
        
        if ([url isEqualToString:thumbnailURL] && cacheFilePath.length) {
            // update the image
            UIImage* image = [MXKMediaManager loadPictureFromFilePath:cacheFilePath];
            if (image == nil) {
                image = [UIImage imageNamed:@"default-profile"];
            }
            if (image) {
                [self.memberThumbnailButton setImage:image forState:UIControlStateNormal];
                [self.memberThumbnailButton setImage:image forState:UIControlStateHighlighted];
            }
            // remove the observers
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            imageLoader = nil;
        }
    }
}

- (void)setRoomMember:(MXRoomMember*) aRoomMember {
    // ignore useless update
    if (![_mxRoomMember.userId isEqualToString:aRoomMember.userId]) {
        _mxRoomMember = aRoomMember;
        [self updateMemberInfo];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    
    // Check user's power level before allowing an action (kick, ban, ...)
    MXRoomPowerLevels *powerLevels = [mxRoom.state powerLevels];
    NSUInteger memberPowerLevel = [powerLevels powerLevelOfUserWithUserID:_mxRoomMember.userId];
    NSUInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:mxHandler.userId];
    
    [buttonsTitles removeAllObjects];
    
    // Consider the case of the user himself
    if ([_mxRoomMember.userId isEqualToString:mxHandler.userId]) {
        
        [buttonsTitles addObject:@"Leave"];
    
        if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomPowerLevels]) {
            [buttonsTitles addObject:@"Set Power Level"];
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
            [buttonsTitles addObject:@"Set Power Level"];
        }
        
        // offer to start a new chat only if the room is not a 1:1 room with this user
        // it does not make sense : it would open the same room
        NSString* roomId = [mxHandler privateOneToOneRoomIdWithUserId:_mxRoomMember.userId];
        if (![roomId isEqualToString:mxRoom.state.roomId]) {
            [buttonsTitles addObject:@"Start Chat"];
        }
    }
    
    return (buttonsTitles.count + 1) / 2;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.tableView == aTableView) {
        NSInteger row = indexPath.row;
        RoomMemberActionsCell* memberActionsCell = (RoomMemberActionsCell*)[aTableView dequeueReusableCellWithIdentifier:@"MemberActionsCell" forIndexPath:indexPath];
        
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
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
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
            NSLog(@"[MemberVC] Set user power (%@) failed: %@", roomMember.userId, error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    }
}

- (void) updateUserPowerLevel:(MXRoomMember*)roomMember {
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    __weak typeof(self) weakSelf = self;
    
    // Ask for userId to invite
    self.actionMenu = [[MXKAlert alloc] initWithTitle:@"Power Level"  message:nil style:MXKAlertStyleAlert];
    
    if (![mxHandler.userId isEqualToString:roomMember.userId]) {
        self.actionMenu.cancelButtonIndex = [self.actionMenu addActionWithTitle:@"Reset to default" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
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
    [self.actionMenu addActionWithTitle:@"OK" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
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
                [self withdrawViewControllerAnimated:YES completion:nil];
            } failure:^(NSError *error) {
                [self removePendingActionMask];
                NSLog(@"[MemberVC] Leave room %@ failed: %@", mxRoom.state.roomId, error);
                //Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }];

        } else if ([text isEqualToString:@"Set Power Level"]) {
            [self updateUserPowerLevel:_mxRoomMember];
        } else if ([text isEqualToString:@"Kick"]) {
            [self addPendingActionMask];
            [mxRoom kickUser:_mxRoomMember.userId
                               reason:nil
                              success:^{
                                  [self removePendingActionMask];
                                  // Pop/Dismiss the current view controller if the left members are hidden
                                  if (![[MXKAppSettings standardAppSettings] showLeftMembersInRoomMemberList]) {
                                      [self withdrawViewControllerAnimated:YES completion:nil];
                                  }
                              }
                              failure:^(NSError *error) {
                                  [self removePendingActionMask];
                                  NSLog(@"[MemberVC] Kick %@ failed: %@", _mxRoomMember.userId, error);
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
                                 NSLog(@"[MemberVC] Ban %@ failed: %@", _mxRoomMember.userId, error);
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
                                    NSLog(@"[MemberVC] Invite %@ failed: %@", _mxRoomMember.userId, error);
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
                                   NSLog(@"[MemberVC] Unban %@ failed: %@", _mxRoomMember.userId, error);
                                   //Alert user
                                   [[AppDelegate theDelegate] showErrorAsAlert:error];
                               }];
    
        } else if ([text isEqualToString:@"Start Chat"]) {
            [self addPendingActionMask];
            [[MatrixSDKHandler sharedHandler] startPrivateOneToOneRoomWithUserId:_mxRoomMember.userId];
        }
    }
}

@end
