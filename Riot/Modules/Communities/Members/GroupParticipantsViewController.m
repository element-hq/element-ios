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

#import "GroupParticipantsViewController.h"

#import "GeneratedInterface-Swift.h"

#import "Contact.h"
#import "ContactTableViewCell.h"

#import "RageShakeManager.h"

@interface GroupParticipantsViewController ()
{
    // Search result
    NSString *currentSearchText;
    NSMutableArray<Contact*> *filteredActualParticipants;
    NSMutableArray<Contact*> *filteredInvitedParticipants;
    
    // Mask view while processing a request
    UIActivityIndicatorView *pendingMaskSpinnerView;
    
    // The current pushed view controller
    UIViewController *pushedViewController;
    
    // Display a gradient view above the screen.
    CAGradientLayer* tableViewMaskLayer;
    
    // Display a button to invite new member.
    UIImageView* addParticipantButtonImageView;
    NSLayoutConstraint *addParticipantButtonImageViewBottomConstraint;
    
    UIAlertController *currentAlert;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
}

@end

@implementation GroupParticipantsViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)groupParticipantsViewController
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
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Check whether the view controller has been pushed via storyboard
    if (!self.tableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    // Adjust Top and Bottom constraints to take into account potential navBar and tabBar.
    [NSLayoutConstraint deactivateConstraints:@[_searchBarTopConstraint, _tableViewBottomConstraint]];
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"
    _searchBarTopConstraint = [NSLayoutConstraint constraintWithItem:self.topLayoutGuide
                                                           attribute:NSLayoutAttributeBottom
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.searchBarHeader
                                                           attribute:NSLayoutAttributeTop
                                                          multiplier:1.0f
                                                            constant:0.0f];
    
    _tableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.tableView
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0f
                                                               constant:0.0f];
    #pragma clang diagnostic pop
    
    [NSLayoutConstraint activateConstraints:@[_searchBarTopConstraint, _tableViewBottomConstraint]];
    
    _searchBarView.placeholder = [VectorL10n groupParticipantsFilterMembers];
    _searchBarView.returnKeyType = UIReturnKeyDone;
    _searchBarView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    // Search bar header is hidden when no group is provided
    _searchBarHeader.hidden = (self.group == nil);
    
    // Enable self-sizing cells and section headers.
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 74;
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 30;
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self.tableView registerClass:ContactTableViewCell.class forCellReuseIdentifier:@"ParticipantTableViewCellId"];
    [self.tableView registerNib:MXKTableViewHeaderFooterWithLabel.nib forHeaderFooterViewReuseIdentifier:MXKTableViewHeaderFooterWithLabel.defaultReuseIdentifier];
    
    // @TODO: Add programmatically the button to add participant.
    //[self addAddParticipantButton];
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];
    
    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    [self refreshSearchBarItemsColor:_searchBarView];
    
    _searchBarHeaderBorder.backgroundColor = ThemeService.shared.theme.headerBorderColor;
    
    // Check the table view style to select its bg color.
    self.tableView.backgroundColor = ((self.tableView.style == UITableViewStylePlain) ? ThemeService.shared.theme.backgroundColor : ThemeService.shared.theme.headerBackgroundColor);
    self.view.backgroundColor = self.tableView.backgroundColor;
    self.tableView.separatorColor = ThemeService.shared.theme.lineBreakColor;
    
    // Update the gradient view above the screen
    CGFloat white = 1.0;
    [ThemeService.shared.theme.backgroundColor getWhite:&white alpha:nil];
    CGColorRef opaqueWhiteColor = [UIColor colorWithWhite:white alpha:1.0].CGColor;
    CGColorRef transparentWhiteColor = [UIColor colorWithWhite:white alpha:0].CGColor;
    tableViewMaskLayer.colors = @[(__bridge id) transparentWhiteColor, (__bridge id) transparentWhiteColor, (__bridge id) opaqueWhiteColor];
    
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

// This method is called when the viewcontroller is added or removed from a container view controller.
- (void)didMoveToParentViewController:(nullable UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
}

- (void)destroy
{
    // Release the potential pushed view controller
    [self releasePushedViewController];
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    _group = nil;
    _mxSession = nil;
    
    filteredActualParticipants = nil;
    filteredInvitedParticipants = nil;
    
    actualParticipants = nil;
    invitedParticipants = nil;
    
    [self removePendingActionMask];
    
    // Note: all observers are removed during super call.
    [super destroy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Release the potential pushed view controller
    [self releasePushedViewController];
    
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
            [self refreshDisplayWithGroup:self->_group];
        };
        
        // Trigger a refresh on the group members and the invited users.
        [self.mxSession updateGroupUsers:_group success:(isPreview ? success : nil) failure:^(NSError *error) {
            
            MXLogDebug(@"[GroupParticipantsViewController] viewWillAppear: group members update failed %@", self->_group.groupId);
            
        }];
        [self.mxSession updateGroupInvitedUsers:_group success:(isPreview ? success : nil) failure:^(NSError *error) {
            
            MXLogDebug(@"[GroupParticipantsViewController] viewWillAppear: invited users update failed %@", self->_group.groupId);
            
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self cancelRegistrationOnGroupChangeNotifications];
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    // cancel any pending search
    [self searchBarCancelButtonClicked:_searchBarView];
}

- (void)withdrawViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    // Check whether the current view controller is displayed inside a segmented view controller in order to withdraw the right item
    if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
    {
        [((SegmentedViewController*)self.parentViewController) withdrawViewControllerAnimated:animated completion:completion];
    }
    else
    {
        [super withdrawViewControllerAnimated:animated completion:completion];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Sanity check
    if (tableViewMaskLayer)
    {
        CGRect currentBounds = tableViewMaskLayer.bounds;
        CGRect newBounds = CGRectIntegral(self.view.frame);
        
        newBounds.size.height -= self.keyboardHeight;
        
        // Check if there is an update
        if (!CGSizeEqualToSize(currentBounds.size, newBounds.size))
        {
            newBounds.origin = CGPointZero;
            
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 
                                 self->tableViewMaskLayer.bounds = newBounds;
                                 
                             }
                             completion:^(BOOL finished){
                             }];
            
        }
        
        // Hide the addParticipants button on landscape when keyboard is visible
        BOOL isLandscapeOriented = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
        addParticipantButtonImageView.hidden = tableViewMaskLayer.hidden = (isLandscapeOriented && self.keyboardHeight);
    }
}

- (void)setGroup:(MXGroup*)group withMatrixSession:(MXSession*)mxSession
{
    // Cancel any pending search
    [self searchBarCancelButtonClicked:_searchBarView];
    
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateGroupUsers:) name:kMXSessionDidUpdateGroupUsersNotification object:_mxSession];
    }
}

- (void)cancelRegistrationOnGroupChangeNotifications
{
    // Remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidUpdateGroupUsersNotification object:_mxSession];
}

- (void)didUpdateGroupUsers:(NSNotification *)notif
{
    MXGroup *group = notif.userInfo[kMXSessionNotificationGroupKey];
    if (group && [group.groupId isEqualToString:_group.groupId])
    {
        // Update the current displayed group instance with the one stored in the session
        [self refreshDisplayWithGroup:group];
    }
}

- (void)refreshDisplayWithGroup:(MXGroup *)group
{
    _group = group;
    
    if (_group)
    {
        _searchBarHeader.hidden = NO;
    }
    else
    {
        // Search bar header is hidden when no group is provided
        _searchBarHeader.hidden = YES;
    }
    
    // Refresh the members list.
    [self refreshParticipantsList];
}

- (void)startActivityIndicator
{
    // Check whether the current view controller is displayed inside a segmented view controller in order to run the right activity view
    if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
    {
        [((SegmentedViewController*)self.parentViewController) startActivityIndicator];
        
        // Force stop the activity view of the view controller
        [self.activityIndicator stopAnimating];
    }
    else
    {
        [super startActivityIndicator];
    }
}

- (void)stopActivityIndicator
{
    // Check whether the current view controller is displayed inside a segmented view controller in order to stop the right activity view
    if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
    {
        [((SegmentedViewController*)self.parentViewController) stopActivityIndicator];
        
        // Force stop the activity view of the view controller
        [self.activityIndicator stopAnimating];
    }
    else
    {
        [super stopActivityIndicator];
    }
}

- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    super.keyboardHeight = keyboardHeight;
    
    // Update addParticipants button position with animation
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         self->addParticipantButtonImageViewBottomConstraint.constant = keyboardHeight + 9;
                         
                         // Force to render the view
                         [self.view layoutIfNeeded];
                         
                     }
                     completion:^(BOOL finished){
                     }];
}

#pragma mark - Internals

- (void)refreshTableView
{
    [self.tableView reloadData];
}

- (void)addAddParticipantButton
{
    // Add blur mask programmatically
    tableViewMaskLayer = [CAGradientLayer layer];
    
    // Consider the grayscale components of the ThemeService.shared.theme.backgroundColor.
    CGFloat white = 1.0;
    [ThemeService.shared.theme.backgroundColor getWhite:&white alpha:nil];
    
    CGColorRef opaqueWhiteColor = [UIColor colorWithWhite:white alpha:1.0].CGColor;
    CGColorRef transparentWhiteColor = [UIColor colorWithWhite:white alpha:0].CGColor;
    
    tableViewMaskLayer.colors = @[(__bridge id) transparentWhiteColor, (__bridge id) transparentWhiteColor, (__bridge id) opaqueWhiteColor];
    
    // display a gradient to the rencents bottom (20% of the bottom of the screen)
    tableViewMaskLayer.locations = @[@0.0F,
            @0.85F,
            @1.0F];
    
    tableViewMaskLayer.bounds = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    tableViewMaskLayer.anchorPoint = CGPointZero;
    
    // CAConstraint is not supported on IOS.
    // it seems only being supported on Mac OS.
    // so viewDidLayoutSubviews will refresh the layout bounds.
    [self.view.layer addSublayer:tableViewMaskLayer];
    
    // Add + button
    addParticipantButtonImageView = [[UIImageView alloc] init];
    [addParticipantButtonImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:addParticipantButtonImageView];
    
    addParticipantButtonImageView.backgroundColor = [UIColor clearColor];
    addParticipantButtonImageView.contentMode = UIViewContentModeCenter;
    addParticipantButtonImageView.image = AssetImages.addGroupParticipant.image;
    
    CGFloat side = 78.0f;
    NSLayoutConstraint* widthConstraint = [NSLayoutConstraint constraintWithItem:addParticipantButtonImageView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1
                                                                        constant:side];
    
    NSLayoutConstraint* heightConstraint = [NSLayoutConstraint constraintWithItem:addParticipantButtonImageView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1
                                                                         constant:side];
    
    NSLayoutConstraint* centerXConstraint = [NSLayoutConstraint constraintWithItem:addParticipantButtonImageView
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1
                                                                          constant:0];
    
    addParticipantButtonImageViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                                 attribute:NSLayoutAttributeBottom
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:addParticipantButtonImageView
                                                                                 attribute:NSLayoutAttributeBottom
                                                                                multiplier:1
                                                                                  constant:self.keyboardHeight + 9];
    
    // Available on iOS 8 and later
    [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint, centerXConstraint, addParticipantButtonImageViewBottomConstraint]];
    
    addParticipantButtonImageView.userInteractionEnabled = YES;
    
    // Handle tap gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onAddParticipantButtonPressed)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [addParticipantButtonImageView addGestureRecognizer:tap];
}

- (void)onAddParticipantButtonPressed
{
    // Push the contacts picker.
    ContactsTableViewController *contactsPickerViewController = [ContactsTableViewController contactsTableViewController];
    
    // Set delegate to handle action on member (start chat, mention)
    contactsPickerViewController.contactsTableViewControllerDelegate = self;
    
    // Prepare its data source
    ContactsDataSource *contactsDataSource = [[ContactsDataSource alloc] initWithMatrixSession:self.mxSession];
    contactsDataSource.areSectionsShrinkable = YES;
    contactsDataSource.displaySearchInputInContactsList = YES;
    contactsDataSource.forceMatrixIdInDisplayName = YES;
    // Add a plus icon to the contact cell in the contacts picker, in order to make it more understandable for the end user.
    contactsDataSource.contactCellAccessoryImage = [AssetImages.plusIcon.image vc_tintedImageUsingColor:ThemeService.shared.theme.textPrimaryColor];
    
    // List all the participants matrix user id to ignore them during the contacts search.
    for (Contact *contact in actualParticipants)
    {
        contactsDataSource.ignoredContactsByMatrixId[contact.mxGroupUser.userId] = contact;
    }
    for (Contact *contact in invitedParticipants)
    {
        contactsDataSource.ignoredContactsByMatrixId[contact.mxGroupUser.userId] = contact;
    }
    
    [contactsPickerViewController showSearch:YES];
    contactsPickerViewController.searchBar.placeholder = [VectorL10n groupParticipantsInviteAnotherUser];
    
    // Apply the search pattern if any
    if (currentSearchText)
    {
        contactsPickerViewController.searchBar.text = currentSearchText;
        [contactsDataSource searchWithPattern:currentSearchText forceReset:YES];
    }
    
    [contactsPickerViewController displayList:contactsDataSource];
    
    [self pushViewController:contactsPickerViewController];
}

- (void)refreshParticipantsList
{
    if (_group)
    {
        actualParticipants = [[NSMutableArray alloc] initWithCapacity:_group.users.chunk.count];
        for (MXGroupUser *groupUser in _group.users.chunk)
        {
            Contact *contact = [[Contact alloc] initMatrixContactWithDisplayName:groupUser.displayname andMatrixID:groupUser.userId];
            contact.mxGroupUser = groupUser;
            
            [actualParticipants addObject:contact];
        }
        
        invitedParticipants = [[NSMutableArray alloc] initWithCapacity:_group.invitedUsers.chunk.count];
        for (MXGroupUser *groupUser in _group.invitedUsers.chunk)
        {
            Contact *contact = [[Contact alloc] initMatrixContactWithDisplayName:groupUser.displayname andMatrixID:groupUser.userId];
            contact.mxGroupUser = groupUser;
            
            [invitedParticipants addObject:contact];
        }
    }
    else
    {
        actualParticipants = nil;
        invitedParticipants = nil;
    }
    
    [self finalizeParticipantsList];
}

- (void)finalizeParticipantsList
{
    // Sort group participants by power and then alphabetically.
    NSComparator comparator = ^NSComparisonResult(Contact *userA, Contact *userB) {
        
        if (userA.mxGroupUser.isPrivileged && userB.mxGroupUser.isPrivileged)
        {
            return [userA.mxGroupUser.displayname compare:userB.mxGroupUser.displayname options:NSCaseInsensitiveSearch];
        }
        if (userA.mxGroupUser.isPrivileged)
        {
            return NSOrderedAscending;
        }
        if (userB.mxGroupUser.isPrivileged)
        {
            return NSOrderedDescending;
        }
        
        return [userA.mxGroupUser.displayname compare:userB.mxGroupUser.displayname options:NSCaseInsensitiveSearch];
    };
    
    // Sort each participants list in alphabetical order
    [actualParticipants sortUsingComparator:comparator];
    [invitedParticipants sortUsingComparator:comparator];
    
    // Reload search result if any
    if (currentSearchText.length)
    {
        NSString *searchText = currentSearchText;
        currentSearchText = nil;
        
        [self searchBar:_searchBarView textDidChange:searchText];
    }
    else
    {
        [self refreshTableView];
    }
}

- (void)addPendingActionMask
{
    // Remove potential existing mask
    [self removePendingActionMask];
    
    // Add a spinner above the tableview to avoid that the user tap on any other button
    pendingMaskSpinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    pendingMaskSpinnerView.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.5];
    pendingMaskSpinnerView.frame = self.tableView.frame;
    pendingMaskSpinnerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    
    // append it
    [self.tableView.superview addSubview:pendingMaskSpinnerView];
    
    // animate it
    [pendingMaskSpinnerView startAnimating];
    
    // Show the spinner after a delay so that if it is removed in a short future,
    // it is not displayed to the end user.
    pendingMaskSpinnerView.alpha = 0;
    [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        
        self->pendingMaskSpinnerView.alpha = 1;
        
    } completion:^(BOOL finished) {
    }];
}

- (void)removePendingActionMask
{
    if (pendingMaskSpinnerView)
    {
        [pendingMaskSpinnerView removeFromSuperview];
        pendingMaskSpinnerView = nil;
    }
}

- (void)pushViewController:(UIViewController*)viewController
{
    // Keep ref on pushed view controller
    pushedViewController = viewController;
    
    // Check whether the view controller is displayed inside a segmented one.
    if (self.parentViewController.navigationController)
    {
        // Hide back button title
        [self.parentViewController vc_removeBackTitle];

        [self.parentViewController.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        // Hide back button title
        [self vc_removeBackTitle];

        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)releasePushedViewController
{
    if (pushedViewController)
    {
        if ([pushedViewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *navigationController = (UINavigationController*)pushedViewController;
            for (id subViewController in navigationController.viewControllers)
            {
                if ([subViewController respondsToSelector:@selector(destroy)])
                {
                    [subViewController destroy];
                }
            }
        }
        else if ([pushedViewController respondsToSelector:@selector(destroy)])
        {
            [(id)pushedViewController destroy];
        }
        
        pushedViewController = nil;
    }
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    
    participantsSection = invitedSection = -1;
    
    if (currentSearchText.length)
    {
        if (filteredActualParticipants.count)
        {
            participantsSection = count++;
        }
        
        if (filteredInvitedParticipants.count)
        {
            invitedSection = count++;
        }
    }
    else
    {
        if (actualParticipants.count)
        {
            participantsSection = count++;
        }
        
        if (invitedParticipants.count)
        {
            invitedSection = count++;
        }
    }
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == participantsSection)
    {
        if (currentSearchText.length)
        {
            count = filteredActualParticipants.count;
        }
        else
        {
            count = actualParticipants.count;
        }
    }
    else if (section == invitedSection)
    {
        if (currentSearchText.length)
        {
            count = filteredInvitedParticipants.count;
        }
        else
        {
            count = invitedParticipants.count;
        }
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == participantsSection || indexPath.section == invitedSection)
    {
        ContactTableViewCell* participantCell = [tableView dequeueReusableCellWithIdentifier:@"ParticipantTableViewCellId" forIndexPath:indexPath];
        participantCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        Contact *contact;
        NSArray *participants;
        
        if (indexPath.section == participantsSection)
        {
            if (currentSearchText.length)
            {
                participants = filteredActualParticipants;
            }
            else
            {
                participants = actualParticipants;
            }
        }
        else
        {
            if (currentSearchText.length)
            {
                participants = filteredInvitedParticipants;
            }
            else
            {
                participants = invitedParticipants;
            }
        }
        
        if (indexPath.row < participants.count)
        {
            contact = participants[indexPath.row];
        }
        
        if (contact)
        {
            [participantCell render:contact];
            
            NSString *powerLevelText;
            
            // Update power level label
            if (contact.mxGroupUser.isPrivileged)
            {
                powerLevelText = [VectorL10n roomMemberPowerLevelShortAdmin];
            }
            
            participantCell.powerLevelLabel.text = powerLevelText;
        }
        
        cell = participantCell;
    }
    else
    {
        // Return a fake cell to prevent app from crashing.
        cell = [[UITableViewCell alloc] init];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == participantsSection || indexPath.section == invitedSection)
    {
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    // iOS8 requires this method to enable editing (see editActionsForRowAtIndexPath).
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView.estimatedRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    if (section == invitedSection)
    {
        return tableView.estimatedSectionHeaderHeight;
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
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
    
    // Refresh here the estimated row height
    tableView.estimatedRowHeight = cell.frame.size.height;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(nonnull UIView *)view forSection:(NSInteger)section
{
    // Refresh here the estimated header height
    tableView.estimatedSectionHeaderHeight = view.frame.size.height;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    MXKTableViewHeaderFooterWithLabel *sectionHeader;
    
    if (section == invitedSection)
    {
        sectionHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MXKTableViewHeaderFooterWithLabel.defaultReuseIdentifier];
        sectionHeader.mxkContentView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
        sectionHeader.mxkLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
        sectionHeader.mxkLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        
        sectionHeader.mxkLabel.text = [VectorL10n groupParticipantsInvitedSection];
    }
    
    return sectionHeader;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Contact *contact;
    NSArray *participants;
    
    if (indexPath.section == participantsSection)
    {
        if (currentSearchText.length)
        {
            participants = filteredActualParticipants;
        }
        else
        {
            participants = actualParticipants;
        }
    }
    else if (indexPath.section == invitedSection)
    {
        if (currentSearchText.length)
        {
            participants = filteredInvitedParticipants;
        }
        else
        {
            participants = invitedParticipants;
        }
    }
    
    if (indexPath.row < participants.count)
    {
        contact = participants[indexPath.row];
    }
    
    if (contact)
    {
        ContactDetailsViewController *contactDetailsViewController = [ContactDetailsViewController instantiate];
        contactDetailsViewController.enableVoipCall = NO;
        contactDetailsViewController.contact = contact;
        
        [self pushViewController:contactDetailsViewController];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* actions;
    
    // add the swipe to delete only on participants sections
    if (indexPath.section == participantsSection || indexPath.section == invitedSection)
    {
        actions = [[NSMutableArray alloc] init];
        
        // Patch: Force the width of the button by adding whitespace characters into the title string.
        UITableViewRowAction *leaveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"        "  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self onDeleteAt:indexPath];
            
        }];
        
        leaveAction.backgroundColor = [MXKTools convertImageToPatternColor:@"remove_icon_blue" backgroundColor:ThemeService.shared.theme.headerBackgroundColor patternSize:CGSizeMake(74, 74) resourceSize:CGSizeMake(24, 24)];
        [actions insertObject:leaveAction atIndex:0];
    }
    
    return actions;
}

#pragma mark - ContactsTableViewControllerDelegate

- (void)contactsTableViewController:(ContactsTableViewController *)contactsTableViewController didSelectContact:(MXKContact*)contact
{
    [self didSelectInvitableContact:contact];
}

#pragma mark - Actions

- (void)onDeleteAt:(NSIndexPath*)path
{
    if (path.section == participantsSection || path.section == invitedSection)
    {
        __weak typeof(self) weakSelf = self;
        
        if (currentAlert)
        {
            [currentAlert dismissViewControllerAnimated:NO completion:nil];
            currentAlert = nil;
        }
        
        NSMutableArray *participants;
        Contact *contact;
        
        if (path.section == participantsSection)
        {
            if (currentSearchText.length)
            {
                participants = filteredActualParticipants;
            }
            else
            {
                participants = actualParticipants;
            }
        }
        else
        {
            if (currentSearchText.length)
            {
                participants = filteredInvitedParticipants;
            }
            else
            {
                participants = invitedParticipants;
            }
        }
        
        if (path.row < participants.count)
        {
            contact = participants[path.row];
        }
        
        if (contact && [contact.mxGroupUser.userId isEqualToString:self.mxSession.myUser.userId])
        {
            // Leave this group?
            currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n groupParticipantsLeavePromptTitle]
                                                               message:[VectorL10n groupParticipantsLeavePromptMsg]
                                                        preferredStyle:UIAlertControllerStyleAlert];
            
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                               }
                                                               
                                                           }]];
            
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n leave]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                                   
                                                                   [self addPendingActionMask];
                                                                   [self.mxSession leaveGroup:self->_group.groupId success:^{
                                                                       
                                                                       [self withdrawViewControllerAnimated:YES completion:nil];
                                                                       
                                                                   } failure:^(NSError *error) {
                                                                       
                                                                       [self removePendingActionMask];
                                                                       MXLogDebug(@"[GroupParticipantsVC] Leave group %@ failed", self->_group.groupId);
                                                                       // Alert user
                                                                       [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                       
                                                                   }];
                                                               }
                                                               
                                                           }]];
            
            [currentAlert mxk_setAccessibilityIdentifier:@"GroupParticipantsVCLeaveAlert"];
            [self presentViewController:currentAlert animated:YES completion:nil];
        }
        else if (contact)
        {
            NSString *memberUserId = contact.mxGroupUser.userId;
            
            // Kick ?
            NSString *promptMsg = [VectorL10n groupParticipantsRemovePromptMsg:(contact.mxGroupUser.displayname.length ? contact.mxGroupUser.displayname : memberUserId)];
            currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n groupParticipantsRemovePromptTitle]
                                                               message:promptMsg
                                                        preferredStyle:UIAlertControllerStyleAlert];
            
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                               }
                                                               
                                                           }]];
            
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n remove]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                                   
                                                                   MXLogDebug(@"[GroupParticipantsVC] Kick %@ failed", memberUserId);
                                                                   // Alert user
                                                                   [[AppDelegate theDelegate] showErrorAsAlert:[NSError errorWithDomain:@"GroupDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:[VectorL10n notSupportedYet]}]];
                                                               }
                                                               
                                                           }]];
            
            [currentAlert mxk_setAccessibilityIdentifier:@"GroupParticipantsVCKickAlert"];
            [self presentViewController:currentAlert animated:YES completion:nil];
        }
    }
}

#pragma mark -

- (void)didSelectInvitableContact:(MXKContact*)contact
{
    __weak typeof(self) weakSelf = self;
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    // Invite ?
    NSString *promptMsg = [VectorL10n groupParticipantsInvitePromptMsg:contact.displayName];
    currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n groupParticipantsInvitePromptTitle]
                                                       message:promptMsg
                                                preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n invite]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           NSArray *identifiers = contact.matrixIdentifiers;
                                                           NSString *participantId;
                                                           
                                                           if (identifiers.count)
                                                           {
                                                               participantId = identifiers.firstObject;
                                                               
                                                               MXLogDebug(@"[GroupParticipantsVC] Invite %@ failed", participantId);
                                                               [[AppDelegate theDelegate] showErrorAsAlert:[NSError errorWithDomain:@"GroupDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:[VectorL10n notSupportedYet]}]];
                                                           }
                                                       }
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier:@"GroupParticipantsVCInviteAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

#pragma mark - UISearchBar delegate

- (void)refreshSearchBarItemsColor:(UISearchBar *)searchBar
{
    // bar tint color
    searchBar.barTintColor = searchBar.tintColor = ThemeService.shared.theme.tintColor;
    searchBar.tintColor = ThemeService.shared.theme.tintColor;
    
    // FIXME: this all seems incredibly fragile and tied to gutwrenching the current UISearchBar internals.
    
    // text color
    UITextField *searchBarTextField = searchBar.vc_searchTextField;
    searchBarTextField.textColor = ThemeService.shared.theme.textSecondaryColor;
    
    // Magnifying glass icon.
    UIImageView *leftImageView = (UIImageView *)searchBarTextField.leftView;
    leftImageView.image = [leftImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    leftImageView.tintColor = ThemeService.shared.theme.tintColor;
    
    // remove the gray background color
    UIView *effectBackgroundTop =  [searchBarTextField valueForKey:@"_effectBackgroundTop"];
    UIView *effectBackgroundBottom =  [searchBarTextField valueForKey:@"_effectBackgroundBottom"];
    effectBackgroundTop.hidden = YES;
    effectBackgroundBottom.hidden = YES;
    
    // place holder
    searchBarTextField.textColor = ThemeService.shared.theme.placeholderTextColor;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Update search results.
    NSUInteger index;
    MXKContact *contact;
    
    searchText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (!currentSearchText.length || [searchText hasPrefix:currentSearchText] == NO)
    {
        // Copy participants and invited participants
        filteredActualParticipants = [NSMutableArray arrayWithArray:actualParticipants];
        filteredInvitedParticipants = [NSMutableArray arrayWithArray:invitedParticipants];
    }
    
    currentSearchText = searchText;
    
    // Filter group participants
    if (currentSearchText.length)
    {
        for (index = 0; index < filteredActualParticipants.count;)
        {
            contact = filteredActualParticipants[index];
            if (![contact matchedWithPatterns:@[currentSearchText]])
            {
                [filteredActualParticipants removeObjectAtIndex:index];
            }
            else
            {
                index++;
            }
        }
        
        for (index = 0; index < filteredInvitedParticipants.count;)
        {
            contact = filteredInvitedParticipants[index];
            if (![contact matchedWithPatterns:@[currentSearchText]])
            {
                [filteredInvitedParticipants removeObjectAtIndex:index];
            }
            else
            {
                index++;
            }
        }
    }
    else
    {
        filteredActualParticipants = nil;
        filteredInvitedParticipants = nil;
    }
    
    // Refresh display
    [self refreshTableView];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
    
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // "Done" key has been pressed.
    
    // Dismiss keyboard
    [_searchBarView resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if (currentSearchText)
    {
        currentSearchText = nil;
        filteredActualParticipants = nil;
        filteredInvitedParticipants = nil;
        
        [self refreshTableView];
    }
    
    searchBar.text = nil;
    // Leave search
    [searchBar resignFirstResponder];
}

@end
