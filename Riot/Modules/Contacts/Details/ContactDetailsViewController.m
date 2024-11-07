/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "ContactDetailsViewController.h"

#import "GeneratedInterface-Swift.h"
#import "MXSession+Riot.h"

#import "RoomMemberTitleView.h"

#import "AvatarGenerator.h"
#import "Tools.h"

#import "TableViewCellWithButton.h"
#import "RoomTableViewCell.h"

#import "TableViewCellWithButton.h"

#import "GBDeviceInfo_iOS.h"

#define TABLEVIEW_ROW_CELL_HEIGHT         46
#define TABLEVIEW_SECTION_HEADER_HEIGHT   28
#define TABLEVIEW_SECTION_HEADER_HEIGHT_WHEN_HIDDEN 0.01f

@interface ContactDetailsViewController () <RoomMemberTitleViewDelegate>
{
    RoomMemberTitleView* contactTitleView;
    
    // HTTP Request
    MXHTTPOperation *roomCreationRequest;
    
    /**
     Observe UIApplicationWillChangeStatusBarOrientationNotification to hide/show bubbles bg.
     */
    __weak id UIApplicationWillChangeStatusBarOrientationNotificationObserver;
    
    /**
     The observer of the presence for matrix user.
     */
    __weak id mxPresenceObserver;
    
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
    UIAlertController *currentAlert;
    
    /**
     Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
     */
    __weak id kThemeServiceDidChangeThemeNotificationObserver;
    
    /**
     The current visibility of the status bar in this view controller.
     */
    BOOL isStatusBarHidden;
}
@end

@implementation ContactDetailsViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)instantiate
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
    // Do any additional setup after loading the view, typically from a nib.
    
    // Check whether the view controller has been pushed via storyboard
    if (!_tableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    actionsArray = [[NSMutableArray alloc] init];
    directChatsArray = [[NSMutableArray alloc] init];
    
    contactTitleView = [RoomMemberTitleView roomMemberTitleView];
    contactTitleView.delegate = self;
    
    self.contactAvatar.contentMode = UIViewContentModeScaleAspectFill;
    self.contactAvatar.defaultBackgroundColor = [UIColor clearColor];
        
    // Define directly the navigation titleView with the custom title view instance. Do not use anymore a container.
    self.navigationItem.titleView = contactTitleView;    
    
    // Display leftBarButtonItems or leftBarButtonItem to the right of the Back button
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.contactNameLabelMask addGestureRecognizer:tap];
    self.contactNameLabelMask.userInteractionEnabled = YES;

    // Add tap to show the contact avatar in fullscreen
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.contactAvatarMask addGestureRecognizer:tap];
    self.contactAvatarMask.userInteractionEnabled = YES;
    
    // Need to listen to the tap gesture in the title view too.
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [contactTitleView.memberAvatarMask addGestureRecognizer:tap];
    contactTitleView.memberAvatarMask.userInteractionEnabled = YES;
    
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
    
    MXWeakify(self);
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    self.headerView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    self.contactNameLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.contactStatusLabel.textColor = ThemeService.shared.theme.tintColor;
    
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
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    
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
    
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    currentAlert = nil;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Check whether the title view has been created and rendered.
    if (contactTitleView && contactTitleView.superview)
    {
        // Adjust the header height by taking into account the actual position of the member avatar in title view
        // This position depends automatically on the screen orientation.
        CGPoint memberAvatarOriginInTitleView = contactTitleView.memberAvatarMask.frame.origin;
        CGPoint memberAvatarActualPosition = [contactTitleView convertPoint:memberAvatarOriginInTitleView toView:self.view];
        
        CGFloat avatarHeaderHeight = memberAvatarActualPosition.y + self.contactAvatar.frame.size.height;
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
    
    MXWeakify(self);
    
    // Observe contact presence change
    mxPresenceObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKContactManagerMatrixUserPresenceChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
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
    // Check whether the view is loaded
    if (!self.isViewLoaded)
    {
        return;
    }
    
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
    UIImage* image = [_contact thumbnailWithPreferedSize:self.contactAvatar.frame.size];
    
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
    
    self.contactAvatar.image = image;
    [self.contactAvatar.layer setCornerRadius:self.contactAvatar.frame.size.width / 2];
    [self.contactAvatar setClipsToBounds:YES];
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
    
    // Main Navigation bar opacity must follow
    self.navigationController.navigationBar.translucent = isHidden;
    mainNavigationController.navigationBar.translucent = isHidden;
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
        return [VectorL10n roomParticipantsActionSectionDirectChats];
    }
    
    return nil;
}

- (NSString*)actionButtonTitle:(ContactDetailsAction)action
{
    NSString *title;
    
    switch (action)
    {
        case ContactDetailsActionIgnore:
            title = [VectorL10n roomParticipantsActionIgnore];
            break;
        case ContactDetailsActionUnignore:
            title = [VectorL10n roomParticipantsActionUnignore];
            break;
        case ContactDetailsActionStartChat:
            title = [VectorL10n roomParticipantsActionStartNewChat];
            break;
        case ContactDetailsActionStartVoiceCall:
            title = [VectorL10n roomParticipantsActionStartVoiceCall];
            break;
        case ContactDetailsActionStartVideoCall:
            title = [VectorL10n roomParticipantsActionStartVideoCall];
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
            NSNumber *actionNumber = actionsArray[indexPath.row];
            
            NSString *title = [self actionButtonTitle:actionNumber.unsignedIntegerValue];
            
            [cellWithButton.mxkButton setTitle:title forState:UIControlStateNormal];
            [cellWithButton.mxkButton setTitle:title forState:UIControlStateHighlighted];
            
            [cellWithButton.mxkButton setTitleColor:ThemeService.shared.theme.textPrimaryColor forState:UIControlStateNormal];
            [cellWithButton.mxkButton setTitleColor:ThemeService.shared.theme.textPrimaryColor forState:UIControlStateHighlighted];
            
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
            roomCell.avatarImageView.image = AssetImages.startChat.image;
            roomCell.avatarImageView.defaultBackgroundColor = [UIColor clearColor];
            roomCell.titleLabel.text = [VectorL10n roomParticipantsActionStartNewChat];
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
            Analytics.shared.viewRoomTrigger = AnalyticsViewRoomTriggerSearchContactDetail;
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
                [currentAlert dismissViewControllerAnimated:NO completion:nil];
                currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n roomMemberIgnorePrompt] message:nil preferredStyle:UIAlertControllerStyleAlert];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n yes]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                       
                                                                       // Add the user to the blacklist: ignored users
                                                                       [self addPendingActionMask];
                                                                       [self.mainSession ignoreUsers:@[self.firstMatrixId]
                                                                                                   success:^{
                                                                                                       
                                                                                                       [self removePendingActionMask];
                                                                                                       
                                                                                                   } failure:^(NSError *error) {
                                                                                                       
                                                                                                       [self removePendingActionMask];
                                                                                                       MXLogDebug(@"[ContactDetailsViewController] Ignore %@ failed", self.firstMatrixId);
                                                                                                       
                                                                                                       // Notify MatrixKit user
                                                                                                       [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                                                       
                                                                                                   }];
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n no]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert mxk_setAccessibilityIdentifier:@"ContactDetailsVCIgnoreAlert"];
                [self presentViewController:currentAlert animated:YES completion:nil];
                break;
            }
            case ContactDetailsActionUnignore:
            {
                // Remove the member from the ignored user list.
                [self addPendingActionMask];
                __weak __typeof(self) weakSelf = self;
                [self.mainSession unIgnoreUsers:@[self.firstMatrixId]
                                        success:^{
                                            
                                            __strong __typeof(weakSelf)self = weakSelf;
                                            [self removePendingActionMask];
                                            
                                        } failure:^(NSError *error) {
                                            
                                            __strong __typeof(weakSelf)self = weakSelf;
                                            [self removePendingActionMask];
                                            MXLogDebug(@"[ContactDetailsViewController] Unignore %@ failed", self.firstMatrixId);
                                            
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
                    [[AppDelegate theDelegate] showNewDirectChat:self.firstMatrixId withMatrixSession:self.mainSession completion:^{
                        
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
                            [self removePendingActionMask];
                            
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:[VectorL10n error]
                                                                                           message:[VectorL10n roomParticipantsStartNewChatErrorUsingUserEmailWithoutIdentityServer]
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                            [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok] style:UIAlertActionStyleDefault handler:nil]];
                            [self presentViewController:alert animated:YES completion:nil];
                            
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

                    MXWeakify(self);
                    void (^onFailure)(NSError *) = ^(NSError *error){
                        MXStrongifyAndReturnIfNil(self);

                        MXLogDebug(@"[ContactDetailsViewController] Create room failed");

                        self->roomCreationRequest = nil;

                        [self removePendingActionMask];

                        // Notify user
                        [[AppDelegate theDelegate] showErrorAsAlert:error];
                    };


                    // Create a new room
                    [self.mainSession vc_canEnableE2EByDefaultInNewRoomWithUsers:inviteArray success:^(BOOL canEnableE2E) {
                        MXStrongifyAndReturnIfNil(self);

                        MXRoomCreationParameters *roomCreationParameters = [MXRoomCreationParameters new];
                        roomCreationParameters.visibility = kMXRoomDirectoryVisibilityPrivate;
                        roomCreationParameters.inviteArray = inviteArray;
                        roomCreationParameters.invite3PIDArray = invite3PIDArray;
                        roomCreationParameters.isDirect = YES;
                        roomCreationParameters.preset = kMXRoomPresetTrustedPrivateChat;

                        if (canEnableE2E && roomCreationParameters.invite3PIDArray == nil)
                        {
                            roomCreationParameters.initialStateEvents = @[
                                                                          [MXRoomCreationParameters initialStateEventForEncryptionWithAlgorithm:kMXCryptoMegolmAlgorithm
                                                                           ]];
                        }


                        self->roomCreationRequest = [self.mainSession createRoomWithParameters:roomCreationParameters success:^(MXRoom *room) {

                            self->roomCreationRequest = nil;

                            [self removePendingActionMask];
                            
                            Analytics.shared.viewRoomTrigger = AnalyticsViewRoomTriggerCreated;
                            [[AppDelegate theDelegate] showRoom:room.roomId andEventId:nil withMatrixSession:self.mainSession];

                        } failure:onFailure];

                    } failure:onFailure];
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
                    MXRoomCreationParameters *roomCreationParameters = [MXRoomCreationParameters parametersForDirectRoomWithUser:matrixId];
                    roomCreationRequest = [self.mainSession createRoomWithParameters:roomCreationParameters success:^(MXRoom *room) {

                        self->roomCreationRequest = nil;

                        // Delay the call in order to be sure that the room is ready
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [room placeCallWithVideo:isVideoCall success:nil failure:nil];
                            [self removePendingActionMask];
                        });

                    } failure:^(NSError *error) {

                        MXLogDebug(@"[ContactDetailsViewController] Create room failed");

                        self->roomCreationRequest = nil;

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
    else if (view == contactTitleView.memberAvatarMask || view == self.contactAvatarMask)
    {
        // Show the avatar in full screen
        __block MXKImageView * avatarFullScreenView = [[MXKImageView alloc] initWithFrame:CGRectZero];
        avatarFullScreenView.stretchable = YES;

        MXWeakify(self);
        [avatarFullScreenView setRightButtonTitle:[VectorL10n ok] handler:^(MXKImageView* imageView, NSString* buttonTitle) {
            
            MXStrongifyAndReturnIfNil(self);
            [avatarFullScreenView dismissSelection];
            [avatarFullScreenView removeFromSuperview];

            avatarFullScreenView = nil;
            
            self->isStatusBarHidden = NO;
            // Trigger status bar update
            [self setNeedsStatusBarAppearanceUpdate];
        }];

        NSString *avatarURL = nil;
        if (self.firstMatrixId)
        {
            MXUser *user = [self.mainSession userWithUserId:self.firstMatrixId];
            avatarURL = user.avatarUrl;
        }

        // TODO: Display the orignal contact avatar when the contast is not a Matrix user

        [avatarFullScreenView setImageURI:avatarURL
                                 withType:nil
                      andImageOrientation:UIImageOrientationUp
                             previewImage:self.contactAvatar.image
                             mediaManager:self.mainSession.mediaManager];

        [avatarFullScreenView showFullScreen];
        isStatusBarHidden = YES;
        
        // Trigger status bar update
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

#pragma mark - RoomMemberTitleViewDelegate

- (void)roomMemberTitleViewDidLayoutSubview:(RoomMemberTitleView*)titleView
{
    [self viewDidLayoutSubviews];
}

@end
