/*
 Copyright 2016 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd
 
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

#import "Riot-Swift.h"

#import "RoomMemberTitleView.h"

#import "AvatarGenerator.h"
#import "Tools.h"

#import "TableViewCellWithButton.h"
#import "RoomTableViewCell.h"
#import "MXRoom+Riot.h"

#define TABLEVIEW_ROW_CELL_HEIGHT         46
#define TABLEVIEW_SECTION_HEADER_HEIGHT   28

@interface RoomMemberDetailsViewController () <UIGestureRecognizerDelegate, DeviceTableViewCellDelegate, RoomMemberTitleViewDelegate, KeyVerificationCoordinatorBridgePresenterDelegate>
{
    RoomMemberTitleView* memberTitleView;
    
    NSInteger securityIndex;
    NSArray<NSNumber*> *securityActionsArray;
    
    /**
     List of the admin actions on this member.
     */
    NSMutableArray<NSNumber*> *adminActionsArray;
    NSInteger adminToolsIndex;
    
    /**
     List of the basic actions on this member.
     */
    NSMutableArray<NSNumber*> *otherActionsArray;
    NSInteger otherActionsIndex;
    
    /**
     List of the direct chats (room ids) with this member.
     */
    NSMutableArray<NSString*> *directChatsArray;
    NSInteger directChatsIndex;
    
    /**
     Devices
     */
    NSArray<MXDeviceInfo *> *devicesArray;
    NSInteger devicesIndex;
    KeyVerificationCoordinatorBridgePresenter *keyVerificationCoordinatorBridgePresenter;

    
    /**
     Observe UIApplicationWillChangeStatusBarOrientationNotification to hide/show bubbles bg.
     */
    id UIApplicationWillChangeStatusBarOrientationNotificationObserver;
    
    /**
     Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
     */
    id kThemeServiceDidChangeThemeNotificationObserver;
    
    /**
     The current visibility of the status bar in this view controller.
     */
    BOOL isStatusBarHidden;
}

@property (weak, nonatomic) IBOutlet UIView *roomMemberAvatarHeaderBackground;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *roomMemberAvatarHeaderBackgroundHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *memberHeaderView;
@property (weak, nonatomic) IBOutlet UIView *roomMemberAvatarMask;
@property (weak, nonatomic) IBOutlet UIImageView *roomMemberAvatarBadgeImageView;

@property (weak, nonatomic) IBOutlet UILabel *roomMemberNameLabel;
@property (weak, nonatomic) IBOutlet UIView *roomMemberNameLabelMask;

@property (weak, nonatomic) IBOutlet UILabel *roomMemberStatusLabel;

@property (weak, nonatomic) IBOutlet UIImageView *bottomImageView;

@property (weak, nonatomic) IBOutlet UILabel *roomMemberPowerLevelLabel;
@property (weak, nonatomic) IBOutlet UIView *roomMemberPowerLevelContainerView;

@property(nonatomic) UserEncryptionTrustLevel encryptionTrustLevel;

@property(nonatomic, strong) UserVerificationCoordinatorBridgePresenter *userVerificationCoordinatorBridgePresenter;

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

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    self.encryptionTrustLevel = UserEncryptionTrustLevelUnknown;
    
    adminActionsArray = [[NSMutableArray alloc] init];
    otherActionsArray = [[NSMutableArray alloc] init];
    directChatsArray = [[NSMutableArray alloc] init];
    
    // Keep visible the status bar by default.
    isStatusBarHidden = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    memberTitleView = [RoomMemberTitleView roomMemberTitleView];
    memberTitleView.delegate = self;
        
    // Define directly the navigation titleView with the custom title view instance. Do not use anymore a container.
    self.navigationItem.titleView = memberTitleView;
    
    // Add tap gesture on member's name
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.roomMemberNameLabelMask addGestureRecognizer:tap];
    self.roomMemberNameLabelMask.userInteractionEnabled = YES;
    
    // Add tap to show the room member avatar in fullscreen
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.roomMemberAvatarMask addGestureRecognizer:tap];
    self.roomMemberAvatarMask.userInteractionEnabled = YES;
    
    // Need to listen to the tap gesture in the title view too.
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [memberTitleView.memberAvatarMask addGestureRecognizer:tap];
    memberTitleView.memberAvatarMask.userInteractionEnabled = YES;
    
    // Register collection view cell class
    [self.tableView registerClass:TableViewCellWithButton.class forCellReuseIdentifier:[TableViewCellWithButton defaultReuseIdentifier]];
    [self.tableView registerClass:RoomTableViewCell.class forCellReuseIdentifier:[RoomTableViewCell defaultReuseIdentifier]];
    [self.tableView registerClass:DeviceTableViewCell.class forCellReuseIdentifier:[DeviceTableViewCell defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCell.class forCellReuseIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    // Enable self sizing cells
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50;
    
    // Observe UIApplicationWillChangeStatusBarOrientationNotification to hide/show bubbles bg.
    UIApplicationWillChangeStatusBarOrientationNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillChangeStatusBarOrientationNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        NSNumber *orientation = (NSNumber*)(notif.userInfo[UIApplicationStatusBarOrientationUserInfoKey]);
        self.bottomImageView.hidden = (orientation.integerValue == UIInterfaceOrientationLandscapeLeft || orientation.integerValue == UIInterfaceOrientationLandscapeRight);
    }];
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];
    self.navigationController.navigationBar.translucent = YES;

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    self.memberHeaderView.backgroundColor = ThemeService.shared.theme.baseColor;
    self.roomMemberNameLabel.textColor = ThemeService.shared.theme.textPrimaryColor;

    self.roomMemberStatusLabel.textColor = ThemeService.shared.theme.tintColor;
    self.roomMemberPowerLevelLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    
    // Check the table view style to select its bg color.
    self.tableView.backgroundColor = ((self.tableView.style == UITableViewStylePlain) ? ThemeService.shared.theme.backgroundColor : ThemeService.shared.theme.headerBackgroundColor);
    self.view.backgroundColor = self.tableView.backgroundColor;
    self.tableView.separatorColor = ThemeService.shared.theme.lineBreakColor;
    
    if (self.tableView.dataSource)
    {
        [self.tableView reloadData];
    }

    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
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
    [[Analytics sharedInstance] trackScreen:@"RoomMemberDetails"];

    [self userInterfaceThemeDidChange];

    // Hide the bottom border of the navigation bar to display the expander header
    [self hideNavigationBarBorder:YES];
    
    // Handle here the bottom image visibility
    UIInterfaceOrientation screenOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    self.bottomImageView.hidden = (screenOrientation == UIInterfaceOrientationLandscapeLeft || screenOrientation == UIInterfaceOrientationLandscapeRight);
    
    [self refreshUserEncryptionTrustLevel];
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
    
    adminActionsArray = nil;
    otherActionsArray = nil;
    directChatsArray = nil;
    devicesArray = nil;
    
    if (UIApplicationWillChangeStatusBarOrientationNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationWillChangeStatusBarOrientationNotificationObserver];
        UIApplicationWillChangeStatusBarOrientationNotificationObserver = nil;
    }
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    
    [memberTitleView removeFromSuperview];
    memberTitleView = nil;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Check whether the title view has been created and rendered.
    if (memberTitleView && memberTitleView.superview)
    {
        // Adjust the header height by taking into account the actual position of the member avatar in title view
        // This position depends automatically on the screen orientation.
        CGPoint memberAvatarOriginInTitleView = memberTitleView.memberAvatarMask.frame.origin;
        CGPoint memberAvatarActualPosition = [memberTitleView convertPoint:memberAvatarOriginInTitleView toView:self.view];
        
        CGFloat avatarHeaderHeight = memberAvatarActualPosition.y + self.memberThumbnail.frame.size.height;
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
    
    return [MXKTools paintImage:[UIImage imageNamed:@"placeholder"]
                      withColor:ThemeService.shared.theme.tintColor];
}

- (void)updateMemberInfo
{
    if (self.mxRoomMember)
    {
        self.roomMemberNameLabel.text = self.mxRoomMember.displayname ? self.mxRoomMember.displayname : self.mxRoomMember.userId;
        
        // Update member power level
        MXWeakify(self);
        [self.mxRoom state:^(MXRoomState *roomState) {
            MXStrongifyAndReturnIfNil(self);

            NSString *powerLevelTextFormat;
            
            MXRoomPowerLevels *powerLevels = [roomState powerLevels];
            NSInteger powerLevel = [powerLevels powerLevelOfUserWithUserID:self.mxRoomMember.userId];
            
            RoomPowerLevel roomPowerLevel = [RoomPowerLevelHelper roomPowerLevelFrom:powerLevel];
            
            switch (roomPowerLevel) {
                case RoomPowerLevelAdmin:
                    powerLevelTextFormat = NSLocalizedStringFromTable(@"room_member_power_level_admin_in", @"Vector", nil);
                    break;
                case RoomPowerLevelModerator:
                    powerLevelTextFormat = NSLocalizedStringFromTable(@"room_member_power_level_moderator_in", @"Vector", nil);
                    break;
                default:
                    powerLevelTextFormat = nil;
                    break;
            }
            
            NSString *powerLevelText;
            
            if (powerLevelTextFormat)
            {
                NSString *roomName = self.mxRoom.summary.displayname;
                powerLevelText = [NSString stringWithFormat:powerLevelTextFormat, roomName];
            }
            
            self.roomMemberPowerLevelLabel.text = powerLevelText;
            self.roomMemberPowerLevelContainerView.hidden = !powerLevelTextFormat;
        }];
        
        NSString* presenceText;
        
        NSString *userId = self.mxRoomMember.userId;
        
        if (userId)
        {
            MXUser *user = [self.mxRoom.mxSession userWithUserId:userId];
            presenceText = [Tools presenceText:user];
        }
        
        self.roomMemberStatusLabel.text = presenceText;
        
        self.roomMemberAvatarBadgeImageView.image = [EncryptionTrustLevelBadgeImageHelper userBadgeImageFor:self.encryptionTrustLevel];
        
        // Retrieve the existing direct chats
        [directChatsArray removeAllObjects];
        NSArray *directRoomIds = self.mainSession.directRooms[self.mxRoomMember.userId];
        // Check whether the room is still existing
        for (NSString* directRoomId in directRoomIds)
        {
            if ([self.mainSession roomWithRoomId:directRoomId])
            {
                [directChatsArray addObject:directRoomId];
            }
        }
    }
    
    // Complete data update and reload table view
    [super updateMemberInfo];
}

- (void)refreshUserEncryptionTrustLevel
{
    NSString *userId = self.mxRoomMember.userId;
    
    if (!userId)
    {
        return;
    }
    
    [self.mxRoom.mxSession.crypto downloadKeys:@[userId] forceDownload:YES success:^(MXUsersDevicesMap<MXDeviceInfo *> *usersDevicesInfoMap, NSDictionary<NSString *,MXCrossSigningInfo *> *crossSigningKeysMap) {
        [self.mxRoom encryptionTrustLevelForUserId:userId onComplete:^(UserEncryptionTrustLevel userEncryptionTrustLevel) {
            self.encryptionTrustLevel = userEncryptionTrustLevel;
            [self updateMemberInfo];
        }];
    } failure:^(NSError *error) {
        [self.mxRoom encryptionTrustLevelForUserId:userId onComplete:^(UserEncryptionTrustLevel userEncryptionTrustLevel) {
            self.encryptionTrustLevel = userEncryptionTrustLevel;
            [self updateMemberInfo];
        }];
    }];
}

- (BOOL)isRoomMemberCurrentUser
{
    return [self.mxRoomMember.userId isEqualToString:self.mainSession.myUser.userId];
}

- (void)startUserVerification
{
    [[AppDelegate theDelegate] presentUserVerificationForRoomMember:self.mxRoomMember session:self.mainSession];
}

- (void)presentUserVerification
{
    UserVerificationCoordinatorBridgePresenter *userVerificationCoordinatorBridgePresenter = [[UserVerificationCoordinatorBridgePresenter alloc] initWithPresenter:self
                                                                                                                                                           session:self.mxRoom.mxSession
                                                                                                                                                            userId:self.mxRoomMember.userId
                                                                                                                                                   userDisplayName:self.mxRoomMember.displayname];
    [userVerificationCoordinatorBridgePresenter start];
    self.userVerificationCoordinatorBridgePresenter = userVerificationCoordinatorBridgePresenter;
}

- (void)presentCompleteSecurity
{
    [[AppDelegate theDelegate] presentCompleteSecurityForSession:self.mainSession];
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

    // Main Navigation bar opacity must follow
    self.navigationController.navigationBar.translucent = isHidden;
    mainNavigationController.navigationBar.translucent = isHidden;
}

#pragma mark - TableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionCount = 0;
    
    BOOL isOneself = NO;
    
    // Check user's power level before allowing an action (kick, ban, ...)
    MXRoomPowerLevels *powerLevels = [self.mxRoom.dangerousSyncState powerLevels];
    NSInteger memberPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mxRoomMember.userId];
    NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
    
    [adminActionsArray removeAllObjects];
    [otherActionsArray removeAllObjects];
    
    // Consider the case of the user himself
    if (self.isRoomMemberCurrentUser)
    {
        isOneself = YES;
        
        [otherActionsArray addObject:@(MXKRoomMemberDetailsActionLeave)];
        
        if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomPowerLevels])
        {
            // Check whether the user is admin (in this case he may reduce his power level to become moderator or less, EXCEPT if he is the only admin).
            if (oneSelfPowerLevel >= RoomPowerLevelAdmin)
            {
                NSArray *levelValues = powerLevels.users.allValues;
                NSUInteger adminCount = 0;
                for (NSNumber *valueNumber in levelValues)
                {
                    if ([valueNumber unsignedIntegerValue] >= RoomPowerLevelAdmin)
                    {
                        adminCount ++;
                    }
                }
                
                if (adminCount > 1)
                {
                    [adminActionsArray addObject:@(MXKRoomMemberDetailsActionSetModerator)];
                    [adminActionsArray addObject:@(MXKRoomMemberDetailsActionSetDefaultPowerLevel)];
                }
            }
            // Check whether the user is moderator (in this case he may reduce his power level to become normal user).
            else if (oneSelfPowerLevel >= RoomPowerLevelModerator)
            {
                [adminActionsArray addObject:@(MXKRoomMemberDetailsActionSetDefaultPowerLevel)];
            }
        }
    }
    else if (self.mxRoomMember)
    {
        // Enumerate admin actions
        switch (self.mxRoomMember.membership)
        {
            case MXMembershipInvite:
            case MXMembershipJoin:
            {
                // update power level
                if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomPowerLevels] && oneSelfPowerLevel > memberPowerLevel)
                {
                    // Check whether user is admin
                    if (oneSelfPowerLevel >= RoomPowerLevelAdmin)
                    {
                        [adminActionsArray addObject:@(MXKRoomMemberDetailsActionSetAdmin)];
                    }
                    
                    // Check whether the member may become moderator
                    if (oneSelfPowerLevel >= RoomPowerLevelModerator && memberPowerLevel < RoomPowerLevelModerator)
                    {
                        [adminActionsArray addObject:@(MXKRoomMemberDetailsActionSetModerator)];
                    }
                    
                    if (memberPowerLevel >= RoomPowerLevelModerator)
                    {
                        [adminActionsArray addObject:@(MXKRoomMemberDetailsActionSetDefaultPowerLevel)];
                    }
                }
                
                // Check conditions to be able to kick someone
                if (oneSelfPowerLevel >= [powerLevels kick] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [adminActionsArray addObject:@(MXKRoomMemberDetailsActionKick)];
                }
                // Check conditions to be able to ban someone
                if (oneSelfPowerLevel >= [powerLevels ban] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [adminActionsArray addObject:@(MXKRoomMemberDetailsActionBan)];
                }
                
                break;
            }
            case MXMembershipLeave:
            {
                // Check conditions to be able to invite someone
                if (oneSelfPowerLevel >= [powerLevels invite])
                {
                    [adminActionsArray addObject:@(MXKRoomMemberDetailsActionInvite)];
                }
                // Check conditions to be able to ban someone
                if (oneSelfPowerLevel >= [powerLevels ban] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [adminActionsArray addObject:@(MXKRoomMemberDetailsActionBan)];
                }
                break;
            }
            case MXMembershipBan:
            {
                // Check conditions to be able to unban someone
                if (oneSelfPowerLevel >= [powerLevels ban] && oneSelfPowerLevel > memberPowerLevel)
                {
                    [adminActionsArray addObject:@(MXKRoomMemberDetailsActionUnban)];
                }
                break;
            }
            default:
            {
                break;
            }
        }
        
        // List the other actions
        if (self.enableVoipCall)
        {
            // Offer voip call options
            [otherActionsArray addObject:@(MXKRoomMemberDetailsActionStartVoiceCall)];
            [otherActionsArray addObject:@(MXKRoomMemberDetailsActionStartVideoCall)];
        }
        
        // Check whether the option Ignore may be presented
        if (RiotSettings.shared.roomMemberScreenShowIgnore && self.mxRoomMember.membership == MXMembershipJoin)
        {
            // is he already ignored ?
            if (![self.mainSession isUserIgnored:self.mxRoomMember.userId])
            {
                [otherActionsArray addObject:@(MXKRoomMemberDetailsActionIgnore)];
            }
            else
            {
                [otherActionsArray addObject:@(MXKRoomMemberDetailsActionUnignore)];
            }
        }
        
        if (self.enableMention)
        {
            // Add mention option
            [otherActionsArray addObject:@(MXKRoomMemberDetailsActionMention)];
        }
    }
    
    if (self.mxRoom.summary.isEncrypted)
    {
        securityActionsArray = @[@(MXKRoomMemberDetailsActionSecurity),
                                 @(MXKRoomMemberDetailsActionSecurityInformation)];
        
    }
    else
    {
        securityActionsArray = @[@(MXKRoomMemberDetailsActionSecurity)];
    }
    
    securityIndex = adminToolsIndex = otherActionsIndex = directChatsIndex = devicesIndex = -1;
    
    
    if (securityActionsArray.count)
    {
        securityIndex = sectionCount++;
    }
    
    if (otherActionsArray.count)
    {
        otherActionsIndex = sectionCount++;
    }
    if (adminActionsArray.count)
    {
        adminToolsIndex = sectionCount++;
    }
    
    if (!isOneself)
    {
        directChatsIndex = sectionCount++;
    }
    
    if (devicesArray.count)
    {
        devicesIndex = sectionCount++;
    }
    
    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == securityIndex)
    {
        return securityActionsArray.count;
    }
    else if (section == adminToolsIndex)
    {
        return adminActionsArray.count;
    }
    else if (section == otherActionsIndex)
    {
        return otherActionsArray.count;
    }
    else if (section == directChatsIndex)
    {
        return (directChatsArray.count + 1);
    }
    else if (section == devicesIndex)
    {
        return (devicesArray.count);
    }
    
    return 0;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == securityIndex)
    {
        return NSLocalizedStringFromTable(@"room_participants_action_section_security", @"Vector", nil);
    }
    else if (section == adminToolsIndex)
    {
        return NSLocalizedStringFromTable(@"room_participants_action_section_admin_tools", @"Vector", nil);
    }
    else if (section == otherActionsIndex)
    {
        return NSLocalizedStringFromTable(@"room_participants_action_section_other", @"Vector", nil);
    }
    else if (section == directChatsIndex)
    {
        return NSLocalizedStringFromTable(@"room_participants_action_section_direct_chats", @"Vector", nil);
    }
    else if (section == devicesIndex)
    {
        return NSLocalizedStringFromTable(@"room_participants_action_section_devices", @"Vector", nil);
    }
    
    return nil;
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
    UITableViewCell *cell;
    
    if (indexPath.section == securityIndex && indexPath.row < securityActionsArray.count)
    {
        NSNumber *actionNumber = securityActionsArray[indexPath.row];
        
        if (actionNumber.unsignedIntegerValue == MXKRoomMemberDetailsActionSecurity)
        {
            MXKTableViewCell *securityStatusCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier] forIndexPath:indexPath];
            
            NSString *statusText;
            
            switch (self.encryptionTrustLevel) {
                case UserEncryptionTrustLevelTrusted:
                    statusText = NSLocalizedStringFromTable(@"room_participants_action_security_status_verified", @"Vector", nil);
                    break;
                case UserEncryptionTrustLevelNotVerified:
                case UserEncryptionTrustLevelNoCrossSigning:
                {
                    if (self.isRoomMemberCurrentUser)
                    {
                        statusText = NSLocalizedStringFromTable(@"room_participants_action_security_status_complete_security", @"Vector", nil);
                    }
                    else
                    {
                        statusText = NSLocalizedStringFromTable(@"room_participants_action_security_status_verify", @"Vector", nil);
                    }
                }
                    break;
                case UserEncryptionTrustLevelWarning:
                    statusText = NSLocalizedStringFromTable(@"room_participants_action_security_status_warning", @"Vector", nil);
                    break;
                default:
                    statusText = NSLocalizedStringFromTable(@"room_participants_action_security_status_loading", @"Vector", nil);
                    break;
            }
            
            securityStatusCell.imageView.image = [EncryptionTrustLevelBadgeImageHelper userBadgeImageFor:self.encryptionTrustLevel];
            
            securityStatusCell.textLabel.numberOfLines = 1;
            securityStatusCell.textLabel.font = [UIFont systemFontOfSize:16.0];
            securityStatusCell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
            securityStatusCell.textLabel.text = statusText;
            
            securityStatusCell.backgroundColor = ThemeService.shared.theme.backgroundColor;
            securityStatusCell.contentView.backgroundColor = [UIColor clearColor];
            securityStatusCell.selectionStyle = UITableViewCellSelectionStyleNone;
            [securityStatusCell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
            
            cell = securityStatusCell;
        }
        else if (actionNumber.unsignedIntegerValue == MXKRoomMemberDetailsActionSecurityInformation)
        {
            MXKTableViewCell *encryptionInfoCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier] forIndexPath:indexPath];
            
            NSMutableString *encryptionInformation = [NSMutableString new];
            
            switch (self.encryptionTrustLevel) {
                case UserEncryptionTrustLevelWarning:
                case UserEncryptionTrustLevelNotVerified:
                case UserEncryptionTrustLevelNoCrossSigning:
                case UserEncryptionTrustLevelTrusted:
                {
                    NSString *info = (self.mxRoom.isDirect) ?
                    NSLocalizedStringFromTable(@"room_participants_security_information_room_encrypted_for_dm", @"Vector", nil) :
                    NSLocalizedStringFromTable(@"room_participants_security_information_room_encrypted", @"Vector", nil);
                    [encryptionInformation appendString:info];
                }
                    break;
                case UserEncryptionTrustLevelNone:
                    {
                        NSString *info = (self.mxRoom.isDirect) ?
                        NSLocalizedStringFromTable(@"room_participants_security_information_room_not_encrypted_for_dm", @"Vector", nil) :
                        NSLocalizedStringFromTable(@"room_participants_security_information_room_not_encrypted", @"Vector", nil);
                        [encryptionInformation appendString:info];
                    }
                    break;
                case UserEncryptionTrustLevelUnknown:
                    [encryptionInformation appendString:NSLocalizedStringFromTable(@"room_participants_security_information_loading", @"Vector", nil)];
                    break;
                default:
                    break;
            }
            
            if (encryptionInformation.length)
            {
                [encryptionInformation appendString:@"\n"];
            }
            
            encryptionInfoCell.textLabel.backgroundColor = [UIColor clearColor];
            encryptionInfoCell.textLabel.numberOfLines = 0;
            encryptionInfoCell.textLabel.text = encryptionInformation;
            encryptionInfoCell.textLabel.font = [UIFont systemFontOfSize:14.0];
            encryptionInfoCell.textLabel.textColor = ThemeService.shared.theme.headerTextPrimaryColor;
            
            encryptionInfoCell.selectionStyle = UITableViewCellSelectionStyleNone;
            encryptionInfoCell.accessoryType = UITableViewCellAccessoryNone;
            encryptionInfoCell.contentView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
            encryptionInfoCell.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;

            //  extend background color to safe area
            UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
            bgView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
            encryptionInfoCell.backgroundView = bgView;
            
            cell = encryptionInfoCell;
        }
    }
    else if (indexPath.section == adminToolsIndex || indexPath.section == otherActionsIndex)
    {
        TableViewCellWithButton *cellWithButton = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithButton defaultReuseIdentifier] forIndexPath:indexPath];
        
        NSNumber *actionNumber;
        if (indexPath.section == adminToolsIndex && indexPath.row < adminActionsArray.count)
        {
            actionNumber = adminActionsArray[indexPath.row];
        }
        else if (indexPath.section == otherActionsIndex && indexPath.row < otherActionsArray.count)
        {
            actionNumber = otherActionsArray[indexPath.row];
        }
        
        if (actionNumber)
        {
            NSString *title = [self actionButtonTitle:actionNumber.unsignedIntegerValue];
            
            [cellWithButton.mxkButton setTitle:title forState:UIControlStateNormal];
            [cellWithButton.mxkButton setTitle:title forState:UIControlStateHighlighted];
            
            if (actionNumber.unsignedIntegerValue == MXKRoomMemberDetailsActionKick)
            {
                [cellWithButton.mxkButton setTitleColor:ThemeService.shared.theme.warningColor forState:UIControlStateNormal];
                [cellWithButton.mxkButton setTitleColor:ThemeService.shared.theme.warningColor forState:UIControlStateHighlighted];
            }
            else
            {
                [cellWithButton.mxkButton setTitleColor:ThemeService.shared.theme.textPrimaryColor forState:UIControlStateNormal];
                [cellWithButton.mxkButton setTitleColor:ThemeService.shared.theme.textPrimaryColor forState:UIControlStateHighlighted];
            }
            
            [cellWithButton.mxkButton addTarget:self action:@selector(onActionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            cellWithButton.mxkButton.tag = actionNumber.unsignedIntegerValue;
        }
        
        cell = cellWithButton;
    }
    else if (indexPath.section == directChatsIndex)
    {
        RoomTableViewCell *roomCell = [tableView dequeueReusableCellWithIdentifier:[RoomTableViewCell defaultReuseIdentifier] forIndexPath:indexPath];
        
        if (indexPath.row < directChatsArray.count)
        {
            MXRoom *room = [self.mainSession roomWithRoomId:directChatsArray[indexPath.row]];
            if (room)
            {
                [roomCell render:room];
            }
        }
        else
        {
            roomCell.avatarImageView.image = [UIImage imageNamed:@"start_chat"];
            roomCell.avatarImageView.defaultBackgroundColor = [UIColor clearColor];
            roomCell.avatarImageView.userInteractionEnabled = NO;
            roomCell.titleLabel.text = NSLocalizedStringFromTable(@"room_participants_action_start_new_chat", @"Vector", nil);
        }
        
        cell = roomCell;
    }
    else if (indexPath.section == devicesIndex)
    {
        DeviceTableViewCell *deviceCell = [tableView dequeueReusableCellWithIdentifier:[DeviceTableViewCell defaultReuseIdentifier] forIndexPath:indexPath];
        deviceCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (indexPath.row < devicesArray.count)
        {
            MXDeviceInfo *deviceInfo = devicesArray[indexPath.row];
            [deviceCell render:deviceInfo];
            deviceCell.delegate = self;
            
            // Display here the Verify and Block buttons except if the device is the current one.
            deviceCell.verifyButton.hidden = deviceCell.blockButton.hidden = [deviceInfo.deviceId isEqualToString:self.mxRoom.mxSession.matrixRestClient.credentials.deviceId];
        }
        cell = deviceCell;
    }
    else
    {
        // Create a fake cell to prevent app from crashing
        cell = [[UITableViewCell alloc] init];
    }
    
    return cell;
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    // Update the selected background view
    if (ThemeService.shared.theme.selectedBackgroundColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = ThemeService.shared.theme.selectedBackgroundColor;
    }
    else
    {
        if (tableView.style == UITableViewStylePlain)
        {
            cell.selectedBackgroundView = nil;
        }
        else
        {
            cell.selectedBackgroundView.backgroundColor = nil;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return TABLEVIEW_SECTION_HEADER_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if (indexPath.section == securityIndex)
    {
        if (self.encryptionTrustLevel == UserEncryptionTrustLevelNotVerified)
        {
            if (self.isRoomMemberCurrentUser)
            {
                [self presentCompleteSecurity];
            }
            else
            {
                [self startUserVerification];
            }
        }
        else
        {
            [self presentUserVerification];
        }
    }
    else if (indexPath.section == directChatsIndex)
    {
        if (indexPath.row < directChatsArray.count)
        {
            // Open this room
            [[AppDelegate theDelegate] showRoom:directChatsArray[indexPath.row] andEventId:nil withMatrixSession:self.mainSession];
        }
        else
        {
            // Create a new direct chat with the member
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.tag = MXKRoomMemberDetailsActionStartChat;
            
            [super onActionButtonPressed:button];
        }
    }
    else
    {
        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        if (selectedCell && [selectedCell isKindOfClass:TableViewCellWithButton.class])
        {
            TableViewCellWithButton *cell = (TableViewCellWithButton*)selectedCell;
            
            [self onActionButtonPressed:cell.mxkButton];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
                [self.mxRoom state:^(MXRoomState *roomState) {
                    [self setPowerLevel:roomState.powerLevels.usersDefault promptUser:YES];
                }];
                break;
            }
            case MXKRoomMemberDetailsActionSetModerator:
            {
                [self setPowerLevel:RoomPowerLevelModerator promptUser:YES];
                break;
            }
            case MXKRoomMemberDetailsActionSetAdmin:
            {
                [self setPowerLevel:RoomPowerLevelAdmin promptUser:YES];
                break;
            }
            case MXKRoomMemberDetailsActionBan:
            {
                __weak typeof(self) weakSelf = self;
                
                // Ban
                currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_event_action_ban_prompt_reason", @"Vector", nil)
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
                
                [currentAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    textField.secureTextEntry = NO;
                    textField.placeholder = nil;
                    textField.keyboardType = UIKeyboardTypeDefault;
                }];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"ban", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                     
                                                                     if (weakSelf)
                                                                     {
                                                                         typeof(self) self = weakSelf;

                                                                         NSString *text = [self->currentAlert textFields].firstObject.text;

                                                                         self->currentAlert = nil;
                                                                         
                                                                         [self startActivityIndicator];
                                                                         
                                                                         // kick user
                                                                         [self.mxRoom banUser:self.mxRoomMember.userId reason:text success:^{
                                                                             
                                                                             __strong __typeof(weakSelf)self = weakSelf;
                                                                             [self stopActivityIndicator];
                                                                             
                                                                         } failure:^(NSError *error) {
                                                                             
                                                                             __strong __typeof(weakSelf)self = weakSelf;
                                                                             [self stopActivityIndicator];
                                                                             
                                                                             MXLogDebug(@"[RoomMemberDetailVC] Ban user (%@) failed", self.mxRoomMember.userId);
                                                                             //Alert user
                                                                             [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                             
                                                                         }];
                                                                     }
                                                                     
                                                                 }]];
                
                [currentAlert mxk_setAccessibilityIdentifier:@"RoomMemberDetailsVCBanAlert"];
                [self presentViewController:currentAlert animated:YES completion:nil];
                break;
            }
            case MXKRoomMemberDetailsActionKick:
            {
                __weak typeof(self) weakSelf = self;
                
                // Kick
                currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_event_action_kick_prompt_reason", @"Vector", nil)
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
                
                [currentAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    textField.secureTextEntry = NO;
                    textField.placeholder = nil;
                    textField.keyboardType = UIKeyboardTypeDefault;
                }];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"remove", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;

                                                                       NSString *text = [self->currentAlert textFields].firstObject.text;

                                                                       self->currentAlert = nil;
                                                                       
                                                                       [self startActivityIndicator];
                                                                       
                                                                       // kick user
                                                                       [self.mxRoom kickUser:self.mxRoomMember.userId reason:text success:^{
                                                                           
                                                                           __strong __typeof(weakSelf)self = weakSelf;
                                                                           [self stopActivityIndicator];
                                                                           
                                                                       } failure:^(NSError *error) {
                                                                           
                                                                           __strong __typeof(weakSelf)self = weakSelf;
                                                                           [self stopActivityIndicator];
                                                                           
                                                                           MXLogDebug(@"[RoomMemberDetailVC] Removing user (%@) failed", self.mxRoomMember.userId);
                                                                           //Alert user
                                                                           [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                           
                                                                       }];
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert mxk_setAccessibilityIdentifier:@"RoomMemberDetailsVCKickAlert"];
                [self presentViewController:currentAlert animated:YES completion:nil];
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
    else if (view == memberTitleView.memberAvatarMask || view == self.roomMemberAvatarMask)
    {
        MXWeakify(self);
        
        // Show the avatar in full screen
        __block MXKImageView * avatarFullScreenView = [[MXKImageView alloc] initWithFrame:CGRectZero];
        avatarFullScreenView.stretchable = YES;

        [avatarFullScreenView setRightButtonTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                          handler:^(MXKImageView* imageView, NSString* buttonTitle) {
                                              
                                              MXStrongifyAndReturnIfNil(self);
                                              [avatarFullScreenView dismissSelection];
                                              [avatarFullScreenView removeFromSuperview];
                                              
                                              avatarFullScreenView = nil;
                                              
                                              // Restore the status bar
                                              self->isStatusBarHidden = NO;
                                              [self setNeedsStatusBarAppearanceUpdate];
                                          }];

        [avatarFullScreenView setImageURI:self.mxRoomMember.avatarUrl
                                 withType:nil
                      andImageOrientation:UIImageOrientationUp
                             previewImage:self.memberThumbnail.image
                             mediaManager:self.mainSession.mediaManager];

        [avatarFullScreenView showFullScreen];
        
        // Hide the status bar
        isStatusBarHidden = YES;
        // Trigger status bar update
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

#pragma mark - 

- (void)deviceTableViewCell:(DeviceTableViewCell*)deviceTableViewCell updateDeviceVerification:(MXDeviceVerification)verificationStatus
{
    if (verificationStatus == MXDeviceVerified)
    {
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:self.mainSession];
        keyVerificationCoordinatorBridgePresenter.delegate = self;

        [keyVerificationCoordinatorBridgePresenter presentFrom:self otherUserId:deviceTableViewCell.deviceInfo.userId otherDeviceId:deviceTableViewCell.deviceInfo.deviceId animated:YES];
    }
    else
    {
        [self.mxRoom.mxSession.crypto setDeviceVerification:verificationStatus
                                                  forDevice:deviceTableViewCell.deviceInfo.deviceId
                                                     ofUser:self.mxRoomMember.userId
                                                    success:^{
                                                        [self updateMemberInfo];
                                                    } failure:nil];
    }
}

#pragma mark - RoomMemberTitleViewDelegate

- (void)roomMemberTitleViewDidLayoutSubview:(RoomMemberTitleView*)titleView
{
    [self viewDidLayoutSubviews];
}

#pragma mark - KeyVerificationCoordinatorBridgePresenterDelegate

- (void)keyVerificationCoordinatorBridgePresenterDelegateDidComplete:(KeyVerificationCoordinatorBridgePresenter *)coordinatorBridgePresenter otherUserId:(NSString * _Nonnull)otherUserId otherDeviceId:(NSString * _Nonnull)otherDeviceId
{
    [self dismissKeyVerificationCoordinatorBridgePresenter];
}

- (void)keyVerificationCoordinatorBridgePresenterDelegateDidCancel:(KeyVerificationCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    [self dismissKeyVerificationCoordinatorBridgePresenter];
}

- (void)dismissKeyVerificationCoordinatorBridgePresenter
{
    [keyVerificationCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    keyVerificationCoordinatorBridgePresenter = nil;
}

@end
