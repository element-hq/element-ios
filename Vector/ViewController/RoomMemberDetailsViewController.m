/*
 Copyright 2016 OpenMarket Ltd
 
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

#import "RoomMemberDetailsViewController.h"

#import "AppDelegate.h"

#import "RoomMemberTitleView.h"

#import "VectorDesignValues.h"

#import "RageShakeManager.h"

#import "AvatarGenerator.h"
#import "Tools.h"

#import "TableViewCellWithButton.h"

@interface RoomMemberDetailsViewController ()
{
    RoomMemberTitleView* memberTitleView;
    
    /**
     Observe UIApplicationWillChangeStatusBarOrientationNotification to hide/show bubbles bg.
     */
    id UIApplicationWillChangeStatusBarOrientationNotificationObserver;
}
@end

@implementation RoomMemberDetailsViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)roomMemberDetailsViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass(self.class)
                                          bundle:[NSBundle bundleForClass:self.class]];
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    self.memberHeaderView.backgroundColor = kVectorColorLightGrey;
    self.roomMemberNameLabel.textColor = kVectorTextColorBlack;
    self.roomMemberStatusLabel.textColor = kVectorColorGreen;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.roomMemberNameLabelMask addGestureRecognizer:tap];
    self.roomMemberNameLabelMask.userInteractionEnabled = YES;
    
    self.navigationItem.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 600, 40)];
    
    memberTitleView = [RoomMemberTitleView roomMemberTitleView];
    self.memberThumbnail = memberTitleView.memberAvatar;

    // Add tap to show the room member avatar in fullscreen
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.memberThumbnail addGestureRecognizer:tap];
    self.memberThumbnail.userInteractionEnabled = YES;

    // Need to listen tap gesture on the area part of the avatar image that is outside
    // of the navigation bar, its parent but smaller view.
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.roomMemberAvatarMask addGestureRecognizer:tap];
    self.roomMemberAvatarMask.userInteractionEnabled = YES;

    // Add the title view and define edge constraints
    memberTitleView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.navigationItem.titleView addSubview:memberTitleView];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:memberTitleView
                                                                        attribute:NSLayoutAttributeTop
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.navigationItem.titleView
                                                                        attribute:NSLayoutAttributeTop
                                                                       multiplier:1.0f
                                                                         constant:0.0f];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:memberTitleView
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.navigationItem.titleView
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1.0f
                                                                         constant:0.0f];
    NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:memberTitleView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.navigationItem.titleView
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0f
                                                                      constant:0.0f];
    NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:memberTitleView
                                                                        attribute:NSLayoutAttributeTrailing
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.navigationItem.titleView
                                                                        attribute:NSLayoutAttributeTrailing
                                                                       multiplier:1.0f
                                                                         constant:0.0f];
    [NSLayoutConstraint activateConstraints:@[topConstraint, bottomConstraint, leadingConstraint, trailingConstraint]];
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    // Observe UIApplicationWillChangeStatusBarOrientationNotification to hide/show bubbles bg.
    UIApplicationWillChangeStatusBarOrientationNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillChangeStatusBarOrientationNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        NSNumber *orientation = (NSNumber*)(notif.userInfo[UIApplicationStatusBarOrientationUserInfoKey]);
        self.bottomImageView.hidden = (orientation.integerValue == UIInterfaceOrientationLandscapeLeft || orientation.integerValue == UIInterfaceOrientationLandscapeRight);
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:@"RoomMemberDetails"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
    
    // Hide the bottom border of the navigation bar to display the expander header
    [self hideNavigationBarBorder:YES];
    
    // Handle here the bottom image visibility
    UIInterfaceOrientation screenOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    self.bottomImageView.hidden = (screenOrientation == UIInterfaceOrientationLandscapeLeft || screenOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Restore navigation bar display
    [self hideNavigationBarBorder:NO];
    
    self.bottomImageView.hidden = YES;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Restore navigation bar display
    [self hideNavigationBarBorder:NO];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(coordinator.transitionDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // Hide the bottom border of the navigation bar
        [self hideNavigationBarBorder:YES];
        
    });
}

- (void)destroy
{
    [super destroy];
    
    if (UIApplicationWillChangeStatusBarOrientationNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationWillChangeStatusBarOrientationNotificationObserver];
        UIApplicationWillChangeStatusBarOrientationNotificationObserver = nil;
    }
    
    [memberTitleView removeFromSuperview];
    memberTitleView = nil;
}

- (void)viewDidLayoutSubviews
{
    if (memberTitleView)
    {
        // Adjust the header height by taking into account the actual position of the member avatar in title view
        // This position depends automatically on the screen orientation.
        CGRect memberAvatarFrame = memberTitleView.memberAvatar.frame;
        CGPoint memberAvatarActualPosition = [memberTitleView convertPoint:memberAvatarFrame.origin toView:self.view];
        
        CGFloat avatarHeaderHeight = memberAvatarActualPosition.y + memberAvatarFrame.size.height;
        if (_roomMemberAvatarHeaderBackgroundHeightConstraint.constant != avatarHeaderHeight)
        {
            _roomMemberAvatarHeaderBackgroundHeightConstraint.constant = avatarHeaderHeight;
            
            // Force the layout of the header
            [self.memberHeaderView layoutIfNeeded];
        }
    }
}

#pragma mark -

- (UIImage*)picturePlaceholder
{
    if (self.mxRoomMember)
    {
        // Use the vector style placeholder
        return [AvatarGenerator generateAvatarForMatrixItem:self.mxRoomMember.userId withDisplayName:self.mxRoomMember.displayname];
    }
    
    return [UIImage imageNamed:@"placeholder"];
}

- (void)updateMemberInfo
{
    [super updateMemberInfo];
    
    if (self.mxRoomMember)
    {
        self.roomMemberNameLabel.text = self.mxRoomMember.displayname ? self.mxRoomMember.displayname : self.mxRoomMember.userId;
        
        // Update member badge
        MXRoomPowerLevels *powerLevels = [self.mxRoom.state powerLevels];
        NSInteger powerLevel = [powerLevels powerLevelOfUserWithUserID:self.mxRoomMember.userId];
        if (powerLevel >= kVectorRoomAdminLevel)
        {
            memberTitleView.memberBadge.image = [UIImage imageNamed:@"admin_icon"];
            memberTitleView.memberBadge.hidden = NO;
        }
        else if (powerLevel >= kVectorRoomModeratorLevel)
        {
            memberTitleView.memberBadge.image = [UIImage imageNamed:@"mod_icon"];
            memberTitleView.memberBadge.hidden = NO;
        }
        else
        {
            memberTitleView.memberBadge.hidden = YES;
        }
        
        NSString* presenceText;
        
        if (self.mxRoomMember.userId)
        {
            MXUser *user = [self.mxRoom.mxSession userWithUserId:self.mxRoomMember.userId];
            presenceText = [Tools presenceText:user];
        }
        
        self.roomMemberStatusLabel.text = presenceText;
    }
}

#pragma mark - Hide/Show navigation bar border

- (void)hideNavigationBarBorder:(BOOL)isHidden
{
    // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
    UINavigationController *mainNavigationController = self.navigationController;
    if (self.splitViewController && self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
    {
        mainNavigationController = self.splitViewController.viewControllers.firstObject;
    }
    
    if (isHidden)
    {
        // The default shadow image is nil. When non-nil, this property represents a custom shadow image to show instead
        // of the default. For a custom shadow image to be shown, a custom background image must also be set with the
        // setBackgroundImage:forBarMetrics: method. If the default background image is used, then the default shadow
        // image will be used regardless of the value of this property.
        [mainNavigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
        [mainNavigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    }
    else
    {
        // Restore default navigationbar settings
        [mainNavigationController.navigationBar setShadowImage:nil];
        [mainNavigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    }
}

#pragma mark - TableView data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Check user's power level before allowing an action (kick, ban, ...)
    MXRoomPowerLevels *powerLevels = [self.mxRoom.state powerLevels];
    NSInteger memberPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mxRoomMember.userId];
    NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
    
    [actionsArray removeAllObjects];
    
    // Consider the case of the user himself
    if ([self.mxRoomMember.userId isEqualToString:self.mainSession.myUser.userId])
    {
        [actionsArray addObject:@(MXKRoomMemberDetailsActionLeave)];
        
        if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomPowerLevels])
        {
            // Check whether the user is admin (in this case he may reduce his power level to become moderator or less, EXCEPT if he is the only admin).
            if (oneSelfPowerLevel >= kVectorRoomAdminLevel)
            {
                NSArray *levelValues = powerLevels.users.allValues;
                NSUInteger adminCount = 0;
                for (NSNumber *valueNumber in levelValues)
                {
                    if ([valueNumber unsignedIntegerValue] >= kVectorRoomAdminLevel)
                    {
                        adminCount ++;
                    }
                }
                
                if (adminCount > 1)
                {
                    [actionsArray addObject:@(MXKRoomMemberDetailsActionSetModerator)];
                    [actionsArray addObject:@(MXKRoomMemberDetailsActionSetDefaultPowerLevel)];
                }
            }
            // Check whether the user is moderator (in this case he may reduce his power level to become normal user).
            else if (oneSelfPowerLevel >= kVectorRoomModeratorLevel)
            {
                [actionsArray addObject:@(MXKRoomMemberDetailsActionSetDefaultPowerLevel)];
            }
        }
    }
    else if (self.mxRoomMember)
    {
        // offer to start a new chat only if the room is not a 1:1 room with this user
        // it does not make sense : it would open the same room
        MXRoom* room = [self.mainSession privateOneToOneRoomWithUserId:self.mxRoomMember.userId];
        if (!room || (![room.state.roomId isEqualToString:self.mxRoom.state.roomId]))
        {
            [actionsArray addObject:@(MXKRoomMemberDetailsActionStartChat)];
        }
        
        if (self.enableVoipCall)
        {
            // Offer voip call options
            [actionsArray addObject:@(MXKRoomMemberDetailsActionStartVoiceCall)];
            [actionsArray addObject:@(MXKRoomMemberDetailsActionStartVideoCall)];
        }
        
        // Consider membership of the selected member
        switch (self.mxRoomMember.membership)
        {
            case MXMembershipInvite:
            case MXMembershipJoin:
            {
                // update power level
                if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomPowerLevels] && oneSelfPowerLevel > memberPowerLevel)
                {
                    // Check whether user is admin
                    if (oneSelfPowerLevel >= kVectorRoomAdminLevel)
                    {
                        [actionsArray addObject:@(MXKRoomMemberDetailsActionSetAdmin)];
                    }
                    
                    // Check whether the member may become moderator
                    if (oneSelfPowerLevel >= kVectorRoomModeratorLevel && memberPowerLevel < kVectorRoomModeratorLevel)
                    {
                        [actionsArray addObject:@(MXKRoomMemberDetailsActionSetModerator)];
                    }
                    
                    if (memberPowerLevel >= kVectorRoomModeratorLevel)
                    {
                        [actionsArray addObject:@(MXKRoomMemberDetailsActionSetDefaultPowerLevel)];
                    }
                }
                
                // Check conditions to be able to kick someone
                if (oneSelfPowerLevel >= [powerLevels kick] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [actionsArray addObject:@(MXKRoomMemberDetailsActionKick)];
                }
                // Check conditions to be able to ban someone
                if (oneSelfPowerLevel >= [powerLevels ban] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [actionsArray addObject:@(MXKRoomMemberDetailsActionBan)];
                }
                
                // Check whether the option Ignore may be presented
                if (self.mxRoomMember.membership == MXMembershipJoin)
                {
                    // is he already ignored ?
                    if (![self.mainSession isUserIgnored:self.mxRoomMember.userId])
                    {
                        [actionsArray addObject:@(MXKRoomMemberDetailsActionIgnore)];
                    }
                    else
                    {
                        [actionsArray addObject:@(MXKRoomMemberDetailsActionUnignore)];
                    }
                }
                break;
            }
            case MXMembershipLeave:
            {
                // Check conditions to be able to invite someone
                if (oneSelfPowerLevel >= [powerLevels invite])
                {
                    [actionsArray addObject:@(MXKRoomMemberDetailsActionInvite)];
                }
                // Check conditions to be able to ban someone
                if (oneSelfPowerLevel >= [powerLevels ban] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [actionsArray addObject:@(MXKRoomMemberDetailsActionBan)];
                }
                break;
            }
            case MXMembershipBan:
            {
                // Check conditions to be able to unban someone
                if (oneSelfPowerLevel >= [powerLevels ban] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [actionsArray addObject:@(MXKRoomMemberDetailsActionUnban)];
                }
                break;
            }
            default:
            {
                break;
            }
        }
    }
    
    if (self.enableMention)
    {
        // Add mention option
        [actionsArray addObject:@(MXKRoomMemberDetailsActionMention)];
    }
    
    return actionsArray.count;
}

- (NSString*)actionButtonTitle:(MXKRoomMemberDetailsAction)action
{
    NSString *title;
    
    switch (action)
    {
        case MXKRoomMemberDetailsActionInvite:
            title = NSLocalizedStringFromTable(@"room_participants_action_invite", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionLeave:
            title = NSLocalizedStringFromTable(@"room_participants_action_leave", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionKick:
            title = NSLocalizedStringFromTable(@"room_participants_action_remove", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionBan:
            title = NSLocalizedStringFromTable(@"room_participants_action_ban", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionUnban:
            title = NSLocalizedStringFromTable(@"room_participants_action_unban", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionIgnore:
            title = NSLocalizedStringFromTable(@"room_participants_action_ignore", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionUnignore:
            title = NSLocalizedStringFromTable(@"room_participants_action_unignore", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionSetDefaultPowerLevel:
            title = NSLocalizedStringFromTable(@"room_participants_action_set_default_power_level", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionSetModerator:
            title = NSLocalizedStringFromTable(@"room_participants_action_set_moderator", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionSetAdmin:
            title = NSLocalizedStringFromTable(@"room_participants_action_set_admin", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionStartChat:
            title = NSLocalizedStringFromTable(@"room_participants_action_start_chat", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionStartVoiceCall:
            title = NSLocalizedStringFromTable(@"room_participants_action_start_voice_call", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionStartVideoCall:
            title = NSLocalizedStringFromTable(@"room_participants_action_start_video_call", @"Vector", nil);
            break;
        case MXKRoomMemberDetailsActionMention:
            title = NSLocalizedStringFromTable(@"room_participants_action_mention", @"Vector", nil);
            break;
        default:
            break;
    }
    
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    TableViewCellWithButton *cell  = [[TableViewCellWithButton alloc] init];
    
    if (row < actionsArray.count)
    {
        NSNumber *actionNumber = [actionsArray objectAtIndex:row];
        
        NSString *title = [self actionButtonTitle:actionNumber.unsignedIntegerValue];
        
        [cell.mxkButton setTitle:title forState:UIControlStateNormal];
        [cell.mxkButton setTitle:title forState:UIControlStateHighlighted];
        
        if (actionNumber.unsignedIntegerValue == MXKRoomMemberDetailsActionKick)
        {
            [cell.mxkButton setTitleColor:kVectorColorPinkRed forState:UIControlStateNormal];
            [cell.mxkButton setTitleColor:kVectorColorPinkRed forState:UIControlStateHighlighted];
        }
        else
        {
            [cell.mxkButton setTitleColor:kVectorTextColorBlack forState:UIControlStateNormal];
            [cell.mxkButton setTitleColor:kVectorTextColorBlack forState:UIControlStateHighlighted];
        }
        
        [cell.mxkButton addTarget:self action:@selector(onActionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        cell.mxkButton.tag = actionNumber.unsignedIntegerValue;
    }
    
    return cell;
}

#pragma mark - TableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    if (selectedCell && [selectedCell isKindOfClass:TableViewCellWithButton.class])
    {
        TableViewCellWithButton *cell = (TableViewCellWithButton*)selectedCell;
        
        [self onActionButtonPressed:cell.mxkButton];
    }
}

#pragma mark - Action

- (void)onActionButtonPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        // already a pending action
        if ([self hasPendingAction])
        {
            return;
        }
        
        UIButton *button = (UIButton*)sender;
        
        switch (button.tag)
        {
            case MXKRoomMemberDetailsActionSetDefaultPowerLevel:
            {
                [self setPowerLevel:self.mxRoom.state.powerLevels.usersDefault promptUser:YES];
                break;
            }
            case MXKRoomMemberDetailsActionSetModerator:
            {
                [self setPowerLevel:kVectorRoomModeratorLevel promptUser:YES];
                break;
            }
            case MXKRoomMemberDetailsActionSetAdmin:
            {
                [self setPowerLevel:kVectorRoomAdminLevel promptUser:YES];
                break;
            }
            default:
            {
                [super onActionButtonPressed:sender];
            }
        }
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer
{
    UIView *view = tapGestureRecognizer.view;
    
    if (view == self.roomMemberNameLabelMask && self.mxRoomMember.displayname)
    {
        if ([self.roomMemberNameLabel.text isEqualToString:self.mxRoomMember.displayname])
        {
            // Display room member matrix id
            self.roomMemberNameLabel.text = self.mxRoomMember.userId;
        }
        else
        {
            // Restore display name
            self.roomMemberNameLabel.text = self.mxRoomMember.displayname;
        }
    }
    else if (view == self.memberThumbnail || view == self.roomMemberAvatarMask)
    {
        // Show the avatar in full screen
        __block MXKImageView * avatarFullScreenView = [[MXKImageView alloc] initWithFrame:CGRectZero];
        avatarFullScreenView.stretchable = YES;

        [avatarFullScreenView setRightButtonTitle:[NSBundle mxk_localizedStringForKey:@"ok"] handler:^(MXKImageView* imageView, NSString* buttonTitle) {
            [avatarFullScreenView dismissSelection];
            [avatarFullScreenView removeFromSuperview];

            avatarFullScreenView = nil;
        }];

        NSString *avatarURL = nil;
        if (self.mxRoomMember.avatarUrl)
        {
            avatarURL = [self.mainSession.matrixRestClient urlOfContent:self.mxRoomMember.avatarUrl];
        }

        [avatarFullScreenView setImageURL:avatarURL
                                 withType:nil
                      andImageOrientation:UIImageOrientationUp
                             previewImage:self.memberThumbnail.image];

        [avatarFullScreenView showFullScreen];
    }
}

@end
