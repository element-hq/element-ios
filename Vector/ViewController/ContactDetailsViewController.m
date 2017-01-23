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

#import "ContactDetailsViewController.h"

#import "AppDelegate.h"

#import "RoomMemberTitleView.h"

#import "VectorDesignValues.h"

#import "RageShakeManager.h"

#import "AvatarGenerator.h"
#import "Tools.h"

#import "TableViewCellWithButton.h"
#import "RoomTableViewCell.h"

#import "TableViewCellWithButton.h"

#import "GBDeviceInfo_iOS.h"

#define TABLEVIEW_ROW_CELL_HEIGHT         46
#define TABLEVIEW_SECTION_HEADER_HEIGHT   28
#define TABLEVIEW_SECTION_HEADER_HEIGHT_WHEN_HIDDEN 0.01f

@interface ContactDetailsViewController ()
{
    RoomMemberTitleView* contactTitleView;
    MXKImageView *contactAvatar;
    
    // HTTP Request
    MXHTTPOperation *roomCreationRequest;
    
    /**
     Observe UIApplicationWillChangeStatusBarOrientationNotification to hide/show bubbles bg.
     */
    id UIApplicationWillChangeStatusBarOrientationNotificationObserver;
    
    /**
     The observer of the presence for matrix user.
     */
    id mxPresenceObserver;
    
    /**
     List of the basic actions on this contact.
     */
    NSMutableArray<NSNumber*> *actionsArray;
    NSInteger actionsIndex;
    
    /**
     List of the direct chats (room ids) with this contact.
     */
    NSMutableArray<NSString*> *directChatsArray;
    NSInteger directChatsIndex;
    
    /**
     mask view while processing a request
     */
    UIActivityIndicatorView * pendingMaskSpinnerView;
    
    /**
     Current alert (if any).
     */
    MXKAlert *currentAlert;
}
@end

@implementation ContactDetailsViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)contactDetailsViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass(self.class)
                                          bundle:[NSBundle bundleForClass:self.class]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Check whether the view controller has been pushed via storyboard
    if (!_tableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    actionsArray = [[NSMutableArray alloc] init];
    directChatsArray = [[NSMutableArray alloc] init];
    
    self.headerView.backgroundColor = kVectorColorLightGrey;
    self.contactNameLabel.textColor = kVectorTextColorBlack;
    self.contactStatusLabel.textColor = kVectorColorGreen;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.contactNameLabelMask addGestureRecognizer:tap];
    self.contactNameLabelMask.userInteractionEnabled = YES;
    
    self.navigationItem.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 600, 40)];
    
    contactTitleView = [RoomMemberTitleView roomMemberTitleView];
    contactAvatar = contactTitleView.memberAvatar;
    contactAvatar.contentMode = UIViewContentModeScaleAspectFill;
    contactAvatar.backgroundColor = [UIColor clearColor];

    // Add tap to show the contact avatar in fullscreen
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [contactAvatar addGestureRecognizer:tap];
    contactAvatar.userInteractionEnabled = YES;

    // Need to listen tap gesture on the area part of the avatar image that is outside
    // of the navigation bar, its parent but smaller view.
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.contactAvatarMask addGestureRecognizer:tap];
    self.contactAvatarMask.userInteractionEnabled = YES;

    // Add the title view and define edge constraints
    contactTitleView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.navigationItem.titleView addSubview:contactTitleView];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:contactTitleView
                                                                        attribute:NSLayoutAttributeTop
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.navigationItem.titleView
                                                                        attribute:NSLayoutAttributeTop
                                                                       multiplier:1.0f
                                                                         constant:0.0f];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:contactTitleView
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.navigationItem.titleView
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1.0f
                                                                         constant:0.0f];
    NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:contactTitleView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.navigationItem.titleView
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0f
                                                                      constant:0.0f];
    NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:contactTitleView
                                                                        attribute:NSLayoutAttributeTrailing
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.navigationItem.titleView
                                                                        attribute:NSLayoutAttributeTrailing
                                                                       multiplier:1.0f
                                                                         constant:0.0f];
    [NSLayoutConstraint activateConstraints:@[topConstraint, bottomConstraint, leadingConstraint, trailingConstraint]];
    
    // Register collection view cell class
    [self.tableView registerClass:TableViewCellWithButton.class forCellReuseIdentifier:[TableViewCellWithButton defaultReuseIdentifier]];
    [self.tableView registerClass:RoomTableViewCell.class forCellReuseIdentifier:[RoomTableViewCell defaultReuseIdentifier]];
    
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
        [tracker set:kGAIScreenName value:@"ContactDetails"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
    
    // Hide the bottom border of the navigation bar to display the expander header
    [self hideNavigationBarBorder:YES];
    
    // Handle here the bottom image visibility
    UIInterfaceOrientation screenOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    self.bottomImageView.hidden = (screenOrientation == UIInterfaceOrientationLandscapeLeft || screenOrientation == UIInterfaceOrientationLandscapeRight);
    
    // Report matrix session from AppDelegate
    NSArray *mxSessions = [AppDelegate theDelegate].mxSessions;
    for (MXSession *mxSession in mxSessions)
    {
        [self addMatrixSession:mxSession];
    }
    
    if (_contact)
    {
        // Register on notifications related to the contact change
        [self registerOnContactChangeNotifications];
        
        // Force refresh
        [self refreshContactDetails];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self cancelRegistrationOnContactChangeNotifications];
    
    // Restore navigation bar display
    [self hideNavigationBarBorder:NO];
    
    self.bottomImageView.hidden = YES;
}

- (void)destroy
{
    [super destroy];
    
    if (roomCreationRequest)
    {
        [roomCreationRequest cancel];
        roomCreationRequest = nil;
    }
    
    [self cancelRegistrationOnContactChangeNotifications];
    
    if (UIApplicationWillChangeStatusBarOrientationNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationWillChangeStatusBarOrientationNotificationObserver];
        UIApplicationWillChangeStatusBarOrientationNotificationObserver = nil;
    }
    
    [contactTitleView removeFromSuperview];
    contactTitleView = nil;
    
    actionsArray = nil;
    directChatsArray = nil;
    
    [self removePendingActionMask];
    
    [currentAlert dismiss:NO];
    currentAlert = nil;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (contactTitleView)
    {
        // Adjust the header height by taking into account the actual position of the member avatar in title view
        // This position depends automatically on the screen orientation.
        CGRect memberAvatarFrame = contactTitleView.memberAvatar.frame;
        CGPoint memberAvatarActualPosition = [contactTitleView convertPoint:memberAvatarFrame.origin toView:self.view];
        
        CGFloat avatarHeaderHeight = memberAvatarActualPosition.y + memberAvatarFrame.size.height;
        if (_contactAvatarHeaderBackgroundHeightConstraint.constant != avatarHeaderHeight)
        {
            _contactAvatarHeaderBackgroundHeightConstraint.constant = avatarHeaderHeight;
            
            // Force the layout of the header
            [self.headerView layoutIfNeeded];
        }
    }
}

#pragma mark -

- (void)setContact:(MXKContact *)contact
{
    [self cancelRegistrationOnContactChangeNotifications];
    
    _contact = contact;
    
    [self registerOnContactChangeNotifications];
    
    if (!_contact.isMatrixContact)
    {
        // Refresh matrix info of the contact
        [[MXKContactManager sharedManager] updateMatrixIDsForLocalContact:_contact];
    }
    
    [self refreshContactDetails];
}

- (void)setEnableVoipCall:(BOOL)enableVoipCall
{
    if (_enableVoipCall != enableVoipCall)
    {
        _enableVoipCall = enableVoipCall;
        
        // Refresh displayed options
        [self.tableView reloadData];
    }
}

#pragma mark -

- (void)registerOnContactChangeNotifications
{
    // Be warned when the thumbnail is updated
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onThumbnailUpdate:) name:kMXKContactThumbnailUpdateNotification object:nil];
    
    // Observe contact presence change
    mxPresenceObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKContactManagerMatrixUserPresenceChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        NSString* matrixId = self.firstMatrixId;
        
        if (matrixId && [matrixId isEqualToString:notif.object])
        {
            [self refreshContactPresence];
        }
    }];
    
    // Observe 'MXKContactManager' notifications
    if (_contact.isMatrixContact)
    {
        // Observe 'MXKContactManager' notification on Matrix contacts to refresh details.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactManagerNotification:)  name:kMXKContactManagerDidUpdateMatrixContactsNotification object:nil];
    }
    else
    {
        // Observe 'MXKContactManager' notifications on Local contacts to refresh details.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactManagerNotification:)  name:kMXKContactManagerDidUpdateLocalContactsNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactManagerNotification:)  name:kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification object:nil];
    }
}

- (void)cancelRegistrationOnContactChangeNotifications
{
    // Remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (mxPresenceObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxPresenceObserver];
        mxPresenceObserver = nil;
    }
}

- (void)onContactManagerNotification:(NSNotification *)notif
{
    // Check whether a contact Id is provided
    if (notif.object)
    {
        NSString* contactID = notif.object;
        if (![contactID isEqualToString:_contact.contactID])
        {
            // Ignore
            return;
        }
    }
    
    [self refreshContactDetails];
}

- (void)refreshContactDetails
{
    [self refreshContactDisplayName];
    [self refreshContactPresence];
    [self refreshContactThumbnail];
    
    [self.tableView reloadData];
}

- (NSString*)firstMatrixId
{
    NSString* matrixId = nil;
    
    if (_contact.matrixIdentifiers.count > 0)
    {
        matrixId = _contact.matrixIdentifiers.firstObject;
    }
    
    return matrixId;
}


- (void)refreshContactThumbnail
{
    UIImage* image = [_contact thumbnailWithPreferedSize:contactAvatar.frame.size];
    
    if (!image)
    {
        NSString* matrixId = self.firstMatrixId;
        
        if (matrixId)
        {
            image = [AvatarGenerator generateAvatarForMatrixItem:matrixId withDisplayName:_contact.displayName];
        }
        else
        {
            image = [AvatarGenerator generateAvatarForText:_contact.displayName];
        }
    }
    
    contactAvatar.image = image;
    [contactAvatar.layer setCornerRadius:contactAvatar.frame.size.width / 2];
    [contactAvatar setClipsToBounds:YES];
}

- (void)refreshContactDisplayName
{
    self.contactNameLabel.text = _contact.displayName;
}

- (void)refreshContactPresence
{
    NSString* presenceText;
    NSString* matrixId = self.firstMatrixId;
    
    if (matrixId)
    {
        MXUser *user = nil;
        
        // Consider here all sessions reported into contact manager
        NSArray* mxSessions = [MXKContactManager sharedManager].mxSessions;
        for (MXSession *mxSession in mxSessions)
        {
            user = [mxSession userWithUserId:matrixId];
            if (user)
            {
                break;
            }
        }
        
        presenceText = [Tools presenceText:user];
    }
    
    self.contactStatusLabel.text = presenceText;
}

- (void)onThumbnailUpdate:(NSNotification *)notif
{
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]])
    {
        NSString* contactID = notif.object;
        
        if ([contactID isEqualToString:_contact.contactID])
        {
            [self refreshContactThumbnail];
        }
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionCount = 0;
    
    [actionsArray removeAllObjects];
    [directChatsArray removeAllObjects];
    
    actionsIndex = directChatsIndex = -1;
    
    if (!self.mainSession)
    {
        return 0;
    }
    
    NSString *matrixId = self.firstMatrixId;
    
    if (matrixId.length)
    {
        // Check whether the contact is not the user himself
        if (![matrixId isEqualToString:self.mainSession.myUser.userId])
        {
            if (self.enableVoipCall)
            {
                // Offer voip call options
                [actionsArray addObject:@(ContactDetailsActionStartVoiceCall)];
                [actionsArray addObject:@(ContactDetailsActionStartVideoCall)];
            }
            
            // Check whether the option Ignore may be presented
            if (![self.mainSession isUserIgnored:matrixId])
            {
                [actionsArray addObject:@(ContactDetailsActionIgnore)];
            }
            else
            {
                [actionsArray addObject:@(ContactDetailsActionUnignore)];
            }
            
            actionsIndex = sectionCount++;
        }
        
        directChatsIndex = sectionCount++;
    }
    // Else check whether the contact has been instantiated with an email or a matrix id
    else if ((!_contact.isMatrixContact && _contact.emailAddresses.count) || [MXTools isEmailAddress:_contact.displayName])
    {
        directChatsIndex = sectionCount++;
    }
    else if ([MXTools isMatrixUserIdentifier:_contact.displayName])
    {
        matrixId = _contact.displayName;
        directChatsIndex = sectionCount++;
    }
    
    if (matrixId.length)
    {
        // Retrieve the existing direct chats
        NSArray *directRoomIds = self.mainSession.directRooms[matrixId];
        
        // Check whether the room is still existing
        for (NSString* directRoomId in directRoomIds)
        {
            if ([self.mainSession roomWithRoomId:directRoomId])
            {
                [directChatsArray addObject:directRoomId];
            }
        }
    }
    
    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == actionsIndex)
    {
        return actionsArray.count;
    }
    else if (section == directChatsIndex)
    {
        return (directChatsArray.count + 1);
    }
    
    return 0;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == directChatsIndex)
    {
        return NSLocalizedStringFromTable(@"room_participants_action_section_direct_chats", @"Vector", nil);
    }
    
    return nil;
}

- (NSString*)actionButtonTitle:(ContactDetailsAction)action
{
    NSString *title;
    
    switch (action)
    {
        case ContactDetailsActionIgnore:
            title = NSLocalizedStringFromTable(@"room_participants_action_ignore", @"Vector", nil);
            break;
        case ContactDetailsActionUnignore:
            title = NSLocalizedStringFromTable(@"room_participants_action_unignore", @"Vector", nil);
            break;
        case ContactDetailsActionStartChat:
            title = NSLocalizedStringFromTable(@"room_participants_action_start_chat", @"Vector", nil);
            break;
        case ContactDetailsActionStartVoiceCall:
            title = NSLocalizedStringFromTable(@"room_participants_action_start_voice_call", @"Vector", nil);
            break;
        case ContactDetailsActionStartVideoCall:
            title = NSLocalizedStringFromTable(@"room_participants_action_start_video_call", @"Vector", nil);
            break;
        default:
            break;
    }
    
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == actionsIndex)
    {
        TableViewCellWithButton *cellWithButton = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithButton defaultReuseIdentifier] forIndexPath:indexPath];
        
        if (indexPath.row < actionsArray.count)
        {
            NSNumber *actionNumber = [actionsArray objectAtIndex:indexPath.row];
            
            NSString *title = [self actionButtonTitle:actionNumber.unsignedIntegerValue];
            
            [cellWithButton.mxkButton setTitle:title forState:UIControlStateNormal];
            [cellWithButton.mxkButton setTitle:title forState:UIControlStateHighlighted];
            
            [cellWithButton.mxkButton setTitleColor:kVectorTextColorBlack forState:UIControlStateNormal];
            [cellWithButton.mxkButton setTitleColor:kVectorTextColorBlack forState:UIControlStateHighlighted];
            
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
            roomCell.avatarImageView.backgroundColor = [UIColor clearColor];
            roomCell.titleLabel.text = NSLocalizedStringFromTable(@"room_participants_action_start_new_chat", @"Vector", nil);
        }
        
        cell = roomCell;
    }
    else
    {
        // Create a fake cell to prevent app from crashing
        cell = [[UITableViewCell alloc] init];
    }
    
    return cell;
}

#pragma mark - TableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == directChatsIndex)
    {
        return [RoomTableViewCell cellHeight];
    }
    
    return TABLEVIEW_ROW_CELL_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == actionsIndex)
    {
        return TABLEVIEW_SECTION_HEADER_HEIGHT_WHEN_HIDDEN;
    }
    
    return TABLEVIEW_SECTION_HEADER_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if (indexPath.section == directChatsIndex)
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
            button.tag = ContactDetailsActionStartChat;
            
            [self onActionButtonPressed:button];
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
}

#pragma mark - button management

- (BOOL)hasPendingAction
{
    return nil != pendingMaskSpinnerView;
}

- (void)addPendingActionMask
{
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

- (void)removePendingActionMask
{
    if (pendingMaskSpinnerView)
    {
        [pendingMaskSpinnerView removeFromSuperview];
        pendingMaskSpinnerView = nil;
        [self.tableView reloadData];
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
            case ContactDetailsActionIgnore:
            {
                // Prompt user to ignore content from this user
                __weak __typeof(self) weakSelf = self;
                [currentAlert dismiss:NO];
                currentAlert = [[MXKAlert alloc] initWithTitle:[NSBundle mxk_localizedStringForKey:@"room_member_ignore_prompt"]  message:nil style:MXKAlertStyleAlert];
                
                [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"yes"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->currentAlert = nil;
                    
                    // Add the user to the blacklist: ignored users
                    [strongSelf addPendingActionMask];
                    [strongSelf.mainSession ignoreUsers:@[strongSelf.firstMatrixId]
                                                success:^{
                                                    
                                                    [strongSelf removePendingActionMask];
                                                    
                                                } failure:^(NSError *error) {
                                                    
                                                    [strongSelf removePendingActionMask];
                                                    NSLog(@"[ContactDetailsViewController] Ignore %@ failed", strongSelf.firstMatrixId);
                                                    
                                                    // Notify MatrixKit user
                                                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                    
                                                }];
                    
                }];
                
                currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"no"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->currentAlert = nil;
                }];
                
                [currentAlert showInViewController:self];
                break;
            }
            case ContactDetailsActionUnignore:
            {
                // Remove the member from the ignored user list.
                [self addPendingActionMask];
                __weak __typeof(self) weakSelf = self;
                [self.mainSession unIgnoreUsers:@[self.firstMatrixId]
                                        success:^{
                                            
                                            __strong __typeof(weakSelf)strongSelf = weakSelf;
                                            [strongSelf removePendingActionMask];
                                            
                                        } failure:^(NSError *error) {
                                            
                                            __strong __typeof(weakSelf)strongSelf = weakSelf;
                                            [strongSelf removePendingActionMask];
                                            NSLog(@"[ContactDetailsViewController] Unignore %@ failed", self.firstMatrixId);
                                            
                                            // Notify MatrixKit user
                                            [[AppDelegate theDelegate] showErrorAsAlert:error];
                                            
                                        }];
                break;
            }
            case ContactDetailsActionStartChat:
            {
                [self addPendingActionMask];
                
                if (_contact.matrixIdentifiers.count)
                {
                    [[AppDelegate theDelegate] createDirectChatWithUserId:self.firstMatrixId completion:^{
                        
                        [self removePendingActionMask];
                    }];
                }
                else
                {
                    // Prepare the invited participant data
                    NSArray *inviteArray;
                    NSArray *invite3PIDArray;
                    NSString *participantId;
                    
                    if (_contact.emailAddresses.count)
                    {
                        // This is a local contact, consider the first email by default.
                        // TODO: Prompt the user to select the right email.
                        MXKEmail *email = _contact.emailAddresses.firstObject;
                        participantId = email.emailAddress;
                    }
                    else
                    {
                        // This is the text filled by the user.
                        participantId = _contact.displayName;
                    }
                    
                    // Is it an email or a Matrix user ID?
                    if ([MXTools isEmailAddress:participantId])
                    {
                        // The identity server must be defined
                        if (!self.mainSession.matrixRestClient.identityServer)
                        {
                            MXError *error = [[MXError alloc] initWithErrorCode:kMXSDKErrCodeStringMissingParameters error:@"No supplied identity server URL"];
                            NSLog(@"[ContactDetailsViewController] Invite %@ failed", participantId);
                            // Alert user
                            [[AppDelegate theDelegate] showErrorAsAlert:[error createNSError]];
                            
                            return;
                        }
                        
                        // The hostname of the identity server must not have the protocol part
                        NSString *identityServer = self.mainSession.matrixRestClient.identityServer;
                        if ([identityServer hasPrefix:@"http://"] || [identityServer hasPrefix:@"https://"])
                        {
                            identityServer = [identityServer substringFromIndex:[identityServer rangeOfString:@"://"].location + 3];
                        }
                        
                        MXInvite3PID *invite3PID = [[MXInvite3PID alloc] init];
                        invite3PID.identityServer = identityServer;
                        invite3PID.medium = kMX3PIDMediumEmail;
                        invite3PID.address = participantId;
                        
                        invite3PIDArray = @[invite3PID];
                    }
                    else //if ([MXTools isMatrixUserIdentifier:participantId])
                    {
                        inviteArray = @[participantId];
                    }
                    
                    // Create a new room
                    roomCreationRequest = [self.mainSession createRoom:nil
                                                            visibility:kMXRoomDirectoryVisibilityPrivate
                                                             roomAlias:nil
                                                                 topic:nil
                                                                invite:inviteArray
                                                            invite3PID:invite3PIDArray
                                                              isDirect:YES
                                                                preset:kMXRoomPresetTrustedPrivateChat
                                                               success:^(MXRoom *room) {
                                                                   
                                                                   roomCreationRequest = nil;
                                                                   
                                                                   [self removePendingActionMask];
                                                                   
                                                                   [[AppDelegate theDelegate] showRoom:room.state.roomId andEventId:nil withMatrixSession:self.mainSession];
                                                                   
                                                               }
                                                               failure:^(NSError *error) {
                                                                   
                                                                   NSLog(@"[ContactDetailsViewController] Create room failed");
                                                                   
                                                                   roomCreationRequest = nil;
                                                                   
                                                                   [self removePendingActionMask];
                                                                   
                                                                   // Notify user
                                                                   [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                   
                                                               }];
                }
                break;
            }
            case ContactDetailsActionStartVoiceCall:
            case ContactDetailsActionStartVideoCall:
            {
                BOOL isVideoCall = (button.tag == ContactDetailsActionStartVideoCall);
                [self addPendingActionMask];
                
                NSString *matrixId = self.firstMatrixId;
                
                MXRoom* directRoom = [self.mainSession directJoinedRoomWithUserId:matrixId];
                
                // Place the call directly if the room exists
                if (directRoom)
                {
                    [directRoom placeCallWithVideo:isVideoCall success:nil failure:nil];
                    [self removePendingActionMask];
                }
                else
                {
                    // Create a new room
                    roomCreationRequest = [self.mainSession createRoom:nil
                                                            visibility:kMXRoomDirectoryVisibilityPrivate
                                                             roomAlias:nil
                                                                 topic:nil
                                                                invite:@[matrixId]
                                                            invite3PID:nil
                                                              isDirect:YES
                                                                preset:kMXRoomPresetTrustedPrivateChat
                                                               success:^(MXRoom *room) {
                                                                   
                                                                   roomCreationRequest = nil;
                                                                   
                                                                   // Delay the call in order to be sure that the room is ready
                                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                                       [room placeCallWithVideo:isVideoCall success:nil failure:nil];
                                                                       [self removePendingActionMask];
                                                                   });
                                                                   
                                                               } failure:^(NSError *error) {
                                                                   
                                                                   NSLog(@"[ContactDetailsViewController] Create room failed");
                                                                   
                                                                   roomCreationRequest = nil;
                                                                   
                                                                   [self removePendingActionMask];
                                                                   
                                                                   // Notify user
                                                                   [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                   
                                                               }];
                }
                break;
            }
            default:
                break;
        }
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer
{
    UIView *view = tapGestureRecognizer.view;
    
    if (view == self.contactNameLabelMask && _contact.displayName)
    {
        if ([self.contactNameLabel.text isEqualToString:_contact.displayName])
        {
            // Display contact's matrix id
            NSString *matrixId = self.firstMatrixId;
            if (matrixId.length)
            {
                self.contactNameLabel.text = matrixId;
            }
        }
        else
        {
            // Restore display name
            self.contactNameLabel.text = _contact.displayName;
        }
    }
    else if (view == contactAvatar || view == self.contactAvatarMask)
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
        if (self.firstMatrixId)
        {
            MXUser *user = [self.mainSession userWithUserId:self.firstMatrixId];
            avatarURL = [self.mainSession.matrixRestClient urlOfContent:user.avatarUrl];
        }

        // TODO: Display the orignal contact avatar when the contast is not a Matrix user

        [avatarFullScreenView setImageURL:avatarURL
                                 withType:nil
                      andImageOrientation:UIImageOrientationUp
                             previewImage:contactAvatar.image];

        [avatarFullScreenView showFullScreen];
    }
}

@end
