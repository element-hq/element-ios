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

#import "GBDeviceInfo_iOS.h"

@interface ContactDetailsViewController ()
{
    RoomMemberTitleView* contactTitleView;
    MXKImageView *contactAvatar;
    
    /**
     Observe UIApplicationWillChangeStatusBarOrientationNotification to hide/show bubbles bg.
     */
    id UIApplicationWillChangeStatusBarOrientationNotificationObserver;
    
    /**
     The observer of the presence for matrix user.
     */
    id mxPresenceObserver;
    
    /**
     List of the allowed actions on this member.
     */
    NSMutableArray<NSNumber*> *actionsArray;
    
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
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
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
    
    // Force refresh
    self.contact = _contact;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (mxPresenceObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxPresenceObserver];
        mxPresenceObserver = nil;
    }
    
    // Restore navigation bar display
    [self hideNavigationBarBorder:NO];
    
    self.bottomImageView.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKContactThumbnailUpdateNotification object:nil];
}

- (void)destroy
{
    [super destroy];
    
    if (UIApplicationWillChangeStatusBarOrientationNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationWillChangeStatusBarOrientationNotificationObserver];
        UIApplicationWillChangeStatusBarOrientationNotificationObserver = nil;
    }
    
    [contactTitleView removeFromSuperview];
    contactTitleView = nil;
    
    actionsArray = nil;
    
    [self removePendingActionMask];
    
    [currentAlert dismiss:NO];
    currentAlert = nil;
}

- (void)viewDidLayoutSubviews
{
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
    // Remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (mxPresenceObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxPresenceObserver];
        mxPresenceObserver = nil;
    }
    
    _contact = contact;
    
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
    
    if (!_contact.isMatrixContact)
    {
        // Refresh matrix info of the contact
        [[MXKContactManager sharedManager] updateMatrixIDsForLocalContact:_contact];
    }
    
    [self refreshContactDisplayName];
    [self refreshContactPresence];
    [self refreshContactThumbnail];
}

#pragma mark -

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
            image = [AvatarGenerator generateRoomMemberAvatar:matrixId displayName:_contact.displayName];
        }
        else
        {
            image = [UIImage imageNamed:@"placeholder"];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    [actionsArray removeAllObjects];
    
    if (_contact.isMatrixContact)
    {
        // Consider the case of the user himself
        if ([_contact.matrixIdentifiers indexOfObject:self.mainSession.myUser.userId] != NSNotFound)
        {
            [actionsArray addObject:@(ContactDetailsActionStartChat)];
        }
        else
        {
            [actionsArray addObject:@(ContactDetailsActionStartChat)];
            
            if (self.enableVoipCall)
            {
                // Offer voip call options
                [actionsArray addObject:@(ContactDetailsActionStartVoiceCall)];
                [actionsArray addObject:@(ContactDetailsActionStartVideoCall)];
            }
            
            // Check whether the option Ignore may be presented
            if (![self.mainSession isUserIgnored:self.firstMatrixId])
            {
                [actionsArray addObject:@(ContactDetailsActionIgnore)];
            }
            else
            {
                [actionsArray addObject:@(ContactDetailsActionUnignore)];
            }
        }
    }
    
    return actionsArray.count;
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
    NSInteger row = indexPath.row;
    
    TableViewCellWithButton *cell  = [[TableViewCellWithButton alloc] init];
    
    if (row < actionsArray.count)
    {
        NSNumber *actionNumber = [actionsArray objectAtIndex:row];
        
        NSString *title = [self actionButtonTitle:actionNumber.unsignedIntegerValue];
        
        [cell.mxkButton setTitle:title forState:UIControlStateNormal];
        [cell.mxkButton setTitle:title forState:UIControlStateHighlighted];
        
        [cell.mxkButton setTitleColor:kVectorTextColorBlack forState:UIControlStateNormal];
        [cell.mxkButton setTitleColor:kVectorTextColorBlack forState:UIControlStateHighlighted];
        
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
                    [strongSelf.mainSession ignoreUsers:@[[strongSelf firstMatrixId]]
                                                success:^{
                                                    
                                                    [strongSelf removePendingActionMask];
                                                    
                                                } failure:^(NSError *error) {
                                                    
                                                    [strongSelf removePendingActionMask];
                                                    NSLog(@"[ContactDetailsViewController] Ignore %@ failed: %@", [strongSelf firstMatrixId], error);
                                                    
                                                    // Notify MatrixKit user
                                                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                                                    
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
                                            NSLog(@"[ContactDetailsViewController] Unignore %@ failed: %@", self.firstMatrixId, error);
                                            
                                            // Notify MatrixKit user
                                            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                                            
                                        }];
                break;
            }
            case ContactDetailsActionStartChat:
            {
                [self addPendingActionMask];
                
                [[AppDelegate theDelegate] startPrivateOneToOneRoomWithUserId:self.firstMatrixId completion:^{
                    
                    [self removePendingActionMask];
                }];
                break;
            }
            case ContactDetailsActionStartVoiceCall:
            case ContactDetailsActionStartVideoCall:
            {
                BOOL isVideoCall = (button.tag == ContactDetailsActionStartVideoCall);
                [self addPendingActionMask];
                
                NSString *matrixId = self.firstMatrixId;
                MXRoom* oneToOneRoom = [self.mainSession privateOneToOneRoomWithUserId:matrixId];
                
                // Place the call directly if the room exists
                if (oneToOneRoom)
                {
                    [self.mainSession.callManager placeCallInRoom:oneToOneRoom.state.roomId withVideo:isVideoCall];
                    [self removePendingActionMask];
                }
                else
                {
                    // Create a new room
                    [self.mainSession createRoom:nil
                                      visibility:kMXRoomDirectoryVisibilityPrivate
                                       roomAlias:nil
                                           topic:nil
                                         success:^(MXRoom *room) {
                                             
                                             // Add the user
                                             [room inviteUser:matrixId success:^{
                                                 
                                                 // Delay the call in order to be sure that the room is ready
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [self.mainSession.callManager placeCallInRoom:room.state.roomId withVideo:isVideoCall];
                                                     [self removePendingActionMask];
                                                 });
                                                 
                                             } failure:^(NSError *error) {
                                                 
                                                 NSLog(@"[ContactDetailsViewController] %@ invitation failed (roomId: %@): %@", matrixId, room.state.roomId, error);
                                                 
                                                 [self removePendingActionMask];
                                                 
                                                 // Notify MatrixKit user
                                                 [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                                                 
                                             }];
                                             
                                         } failure:^(NSError *error) {
                                             
                                             NSLog(@"[ContactDetailsViewController] Create room failed: %@", error);
                                             
                                             [self removePendingActionMask];
                                             
                                             // Notify MatrixKit user
                                             [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                                             
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
}

@end
