/*
 Copyright 2017 Vector Creations Ltd
 
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

#import "GroupHomeViewController.h"

#import "AppDelegate.h"

#import "RiotDesignValues.h"

#import "MXGroup+Riot.h"

@interface GroupHomeViewController ()
{
    MXHTTPOperation *currentRequest;
    
    /**
     The current visibility of the status bar in this view controller.
     */
    BOOL isStatusBarHidden;
    
    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
}
@end

@implementation GroupHomeViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)groupHomeViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass(self.class)
                                          bundle:[NSBundle bundleForClass:self.class]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // Keep visible the status bar by default.
    isStatusBarHidden = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.leftButton setTitle:NSLocalizedStringFromTable(@"decline", @"Vector", nil) forState:UIControlStateNormal];
    [self.leftButton setTitle:NSLocalizedStringFromTable(@"decline", @"Vector", nil) forState:UIControlStateHighlighted];
    [self.rightButton setTitle:NSLocalizedStringFromTable(@"join", @"Vector", nil) forState:UIControlStateNormal];
    [self.rightButton setTitle:NSLocalizedStringFromTable(@"join", @"Vector", nil) forState:UIControlStateHighlighted];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [_groupNameMask addGestureRecognizer:tap];
    _groupNameMask.userInteractionEnabled = YES;
    
    // Add tap to show the group avatar in fullscreen
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [_groupAvatarMask addGestureRecognizer:tap];
    _groupAvatarMask.userInteractionEnabled = YES;
    
    // Observe user interface theme change.
    kRiotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    self.defaultBarTintColor = kRiotSecondaryBgColor;
    self.barTitleColor = kRiotPrimaryTextColor;
    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    self.view.backgroundColor = kRiotPrimaryBgColor;
    self.mainHeaderContainer.backgroundColor = kRiotSecondaryBgColor;
    
    _groupName.textColor = kRiotPrimaryTextColor;
    
    _groupDescription.textColor = kRiotTopicTextColor;
    _groupDescription.numberOfLines = 0;
    
    self.inviteLabel.textColor = kRiotTopicTextColor;
    self.inviteLabel.numberOfLines = 0;
    
    self.separatorView.backgroundColor = kRiotSecondaryBgColor;
    
    _groupLongDescription.textColor = kRiotSecondaryTextColor;
    _groupLongDescription.tintColor = kRiotColorBlue;
    
    [self.leftButton.layer setCornerRadius:5];
    self.leftButton.clipsToBounds = YES;
    self.leftButton.backgroundColor = kRiotColorBlue;
    
    [self.rightButton.layer setCornerRadius:5];
    self.rightButton.clipsToBounds = YES;
    self.rightButton.backgroundColor = kRiotColorBlue;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return kRiotDesignStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden
{
    // Return the current status bar visibility.
    return isStatusBarHidden;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking
    [[AppDelegate theDelegate] trackScreen:@"GroupDetailsHome"];
    
    if (_group)
    {
        // Restore the listeners on the group update.
        [self registerOnGroupChangeNotifications];
        
        // Check whether the selected group is stored in the user's session, or if it is a group preview.
        // Replace the displayed group instance with the one stored in the session (if any).
        MXGroup *storedGroup = [_mxSession groupWithGroupId:_group.groupId];
        BOOL isPreview = (!storedGroup);
        
        // Force refresh
        [self refreshDisplayWithGroup:(isPreview ? _group : storedGroup)];
        
        // Prepare a block called on successful update in case of a group preview.
        // Indeed the group update notifications are triggered by the matrix session only for the user's groups.
        void (^success)(void) = ^void(void)
        {
            [self refreshDisplayWithGroup:_group];
        };
        
        // Trigger a refresh on the group summary.
        [self.mxSession updateGroupSummary:_group success:(isPreview ? success : nil) failure:^(NSError *error) {
            
            NSLog(@"[GroupHomeViewController] viewWillAppear: group summary update failed %@", _group.groupId);
            
        }];
        // Trigger a refresh on the group members (ignore here the invited users).
        [self.mxSession updateGroupUsers:_group success:(isPreview ? success : nil) failure:^(NSError *error) {
            
            NSLog(@"[GroupHomeViewController] viewWillAppear: group members update failed %@", _group.groupId);
            
        }];
        // Trigger a refresh on the group rooms.
        [self.mxSession updateGroupRooms:_group success:(isPreview ? success : nil) failure:^(NSError *error) {
            
            NSLog(@"[GroupHomeViewController] viewWillAppear: group rooms update failed %@", _group.groupId);
            
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self cancelRegistrationOnGroupChangeNotifications];
}

- (void)destroy
{
    // Note: all observers are removed during super call.
    [super destroy];
    
    _group = nil;
    _mxSession = nil;
    
    [currentRequest cancel];
    currentRequest = nil;
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
    }
}

- (void)setGroup:(MXGroup*)group withMatrixSession:(MXSession*)mxSession
{
    if (_mxSession != mxSession)
    {
        [self cancelRegistrationOnGroupChangeNotifications];
        _mxSession = mxSession;
        
        [self registerOnGroupChangeNotifications];
    }
    
    [self addMatrixSession:mxSession];
    
    [self refreshDisplayWithGroup:group];
}

#pragma mark -

- (void)registerOnGroupChangeNotifications
{
    if (_mxSession)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateGroupDetails:) name:kMXSessionDidUpdateGroupSummaryNotification object:_mxSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateGroupDetails:) name:kMXSessionDidUpdateGroupUsersNotification object:_mxSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateGroupDetails:) name:kMXSessionDidUpdateGroupRoomsNotification object:_mxSession];
    }
}

- (void)cancelRegistrationOnGroupChangeNotifications
{
    // Remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidUpdateGroupSummaryNotification object:_mxSession];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidUpdateGroupUsersNotification object:_mxSession];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidUpdateGroupRoomsNotification object:_mxSession];
}

- (void)didUpdateGroupDetails:(NSNotification *)notif
{
    MXGroup *group = notif.userInfo[kMXSessionNotificationGroupKey];
    if (group && [group.groupId isEqualToString:_group.groupId])
    {
        // Update the current displayed group instance with the one stored in the session
        [self refreshDisplayWithGroup:group];
    }
}

- (void)refreshDisplayWithGroup:(MXGroup*)group
{
    _group = group;
    
    if (_group)
    {
        [_group setGroupAvatarImageIn:_groupAvatar matrixSession:self.mxSession];
        
        _groupName.text = _group.summary.profile.name;
        if (!_groupName.text.length)
        {
            _groupName.text = _group.groupId;
        }
        
        _groupDescription.text = _group.summary.profile.shortDescription;
        
        if (_group.users.totalUserCountEstimate == 1)
        {
            _membersCountLabel.text = NSLocalizedStringFromTable(@"group_home_one_member_format", @"Vector", nil);
            _membersCountContainer.hidden = NO;
        }
        else if (_group.users.totalUserCountEstimate > 1)
        {
            _membersCountLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"group_home_multi_members_format", @"Vector", nil), _group.users.totalUserCountEstimate];
            _membersCountContainer.hidden = NO;
        }
        else
        {
            _membersCountLabel.text = nil;
            _membersCountContainer.hidden = YES;
        }
        
        if (_group.rooms.totalRoomCountEstimate == 1)
        {
            _roomsCountLabel.text = NSLocalizedStringFromTable(@"group_home_one_room_format", @"Vector", nil);
            _roomsCountContainer.hidden = NO;
        }
        else if (_group.rooms.totalRoomCountEstimate > 1)
        {
            _roomsCountLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"group_home_multi_rooms_format", @"Vector", nil), _group.rooms.totalRoomCountEstimate];
            _roomsCountContainer.hidden = NO;
        }
        else
        {
            _roomsCountLabel.text = nil;
            _roomsCountContainer.hidden = YES;
        }
        
        _countsContainer.hidden = (_membersCountContainer.isHidden && _roomsCountContainer.isHidden);
        
        if (_group.membership == MXMembershipInvite)
        {
            self.inviteContainer.hidden = NO;
            
            if (_group.inviter)
            {
                NSString *inviter = _group.inviter;
                
                if ([MXTools isMatrixUserIdentifier:inviter])
                {
                    // Get the user that corresponds to this member
                    MXUser *user = [self.mxSession userWithUserId:inviter];
                    if (user.displayname.length)
                    {
                        inviter = user.displayname;
                    }
                }
                
                self.inviteLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"group_invitation_format", @"Vector", nil), inviter];
            }
            else
            {
                self.inviteLabel.text = nil;
            }
            
            [self.inviteContainer layoutIfNeeded];
            
            if (_separatorViewTopConstraint.constant != self.inviteContainer.frame.size.height)
            {
                _separatorViewTopConstraint.constant = self.inviteContainer.frame.size.height;
                [self.view layoutIfNeeded];
            }
        }
        else
        {
            self.inviteContainer.hidden = YES;
            if (_separatorViewTopConstraint.constant != 0)
            {
                _separatorViewTopConstraint.constant = 0;
                [self.view layoutIfNeeded];
            }
        }
        
        if (_group.summary.profile.longDescription.length)
        {
            //@TODO: implement a specific html renderer to support h1/h2 and handle the Matrix media content URI (in the form of "mxc://...").
            MXKEventFormatter *eventFormatter = [[MXKEventFormatter alloc] initWithMatrixSession:self.mxSession];
            _groupLongDescription.attributedText = [eventFormatter renderHTMLString:_group.summary.profile.longDescription forEvent:nil];
            _groupLongDescription.contentOffset = CGPointZero;
        }
        else
        {
            _groupLongDescription.text = nil;
        }
    }
    else
    {
        _groupAvatar.image = nil;
        
        _groupName.text = nil;
        _groupDescription.text = nil;
        
        self.inviteLabel.text = nil;
        _groupLongDescription.text = nil;
        
        self.inviteContainer.hidden = YES;
        
        _groupLongDescription.text = nil;
        _separatorViewTopConstraint.constant = 0;
        
        _membersCountLabel.text = nil;
        _roomsCountLabel.text = nil;
        _countsContainer.hidden = YES;
    }
    
    // Round image view for thumbnail
    _groupAvatar.layer.cornerRadius = _groupAvatar.frame.size.width / 2;
    _groupAvatar.clipsToBounds = YES;
    
    _groupAvatar.defaultBackgroundColor = kRiotSecondaryBgColor;
}

#pragma mark - Action

- (IBAction)onButtonPressed:(id)sender
{
    if (!currentRequest)
    {
        if (sender == self.rightButton)
        {
            // Accept the invite
            __weak typeof(self) weakSelf = self;
            [self startActivityIndicator];
            
            currentRequest = [self.mxSession acceptGroupInvite:_group.groupId success:^{
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    self->currentRequest = nil;
                    [self stopActivityIndicator];
                    
                    [self refreshDisplayWithGroup:[_mxSession groupWithGroupId:_group.groupId]];
                }
                
            } failure:^(NSError *error) {
                
                NSLog(@"[GroupDetailsViewController] join group (%@) failed", _group.groupId);
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    self->currentRequest = nil;
                    [self stopActivityIndicator];
                }
                
                // Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
                
            }];
        }
        else if (sender == self.leftButton)
        {
            // Decline the invite
            __weak typeof(self) weakSelf = self;
            [self startActivityIndicator];
            
            currentRequest = [self.mxSession leaveGroup:_group.groupId success:^{
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    self->currentRequest = nil;
                    [self stopActivityIndicator];
                    
                    [self withdrawViewControllerAnimated:YES completion:nil];
                }
                
            } failure:^(NSError *error) {
                
                NSLog(@"[GroupDetailsViewController] leave group (%@) failed", _group.groupId);
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    self->currentRequest = nil;
                    [self stopActivityIndicator];
                }
                
                // Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
                
            }];
        }
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer
{
    UIView *view = tapGestureRecognizer.view;
    
    if (view == _groupNameMask && _group.summary.profile.name)
    {
        if ([_groupName.text isEqualToString:_group.summary.profile.name])
        {
            // Display group's matrix id
            _groupName.text = _group.groupId;
        }
        else
        {
            // Restore display name
            _groupName.text = _group.summary.profile.name;
        }
    }
    else if (view == _groupAvatarMask)
    {
        // Show the avatar in full screen
        __block MXKImageView * avatarFullScreenView = [[MXKImageView alloc] initWithFrame:CGRectZero];
        avatarFullScreenView.stretchable = YES;
        
        [avatarFullScreenView setRightButtonTitle:[NSBundle mxk_localizedStringForKey:@"ok"] handler:^(MXKImageView* imageView, NSString* buttonTitle) {
            [avatarFullScreenView dismissSelection];
            [avatarFullScreenView removeFromSuperview];
            
            avatarFullScreenView = nil;
            
            isStatusBarHidden = NO;
            // Trigger status bar update
            [self setNeedsStatusBarAppearanceUpdate];
        }];
        
        NSString *avatarURL = [self.mainSession.matrixRestClient urlOfContent:_group.summary.profile.avatarUrl];
        [avatarFullScreenView setImageURL:avatarURL
                                 withType:nil
                      andImageOrientation:UIImageOrientationUp
                             previewImage:self.groupAvatar.image];
        
        [avatarFullScreenView showFullScreen];
        isStatusBarHidden = YES;
        
        // Trigger status bar update
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

@end
