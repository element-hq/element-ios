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

#import "AppDelegate.h"

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
    
    ContactsTableViewController *contactsPickerViewController;
    
    // Display a gradient view above the screen.
    CAGradientLayer* tableViewMaskLayer;
    
    // Display a button to invite new member.
    UIImageView* addParticipantButtonImageView;
    NSLayoutConstraint *addParticipantButtonImageViewBottomConstraint;
    
    UIAlertController *currentAlert;
    
    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
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
    
    [NSLayoutConstraint activateConstraints:@[_searchBarTopConstraint, _tableViewBottomConstraint]];
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"group_participants_title", @"Vector", nil);
    
    _searchBarView.placeholder = NSLocalizedStringFromTable(@"group_participants_filter_group_members", @"Vector", nil);
    _searchBarView.returnKeyType = UIReturnKeyDone;
    _searchBarView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    // Search bar header is hidden when no group is provided
    _searchBarHeader.hidden = (self.group == nil);
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self.tableView registerClass:ContactTableViewCell.class forCellReuseIdentifier:@"ParticipantTableViewCellId"];
    
    // @TODO: Add programmatically the button to add participant.
    //[self addAddParticipantButton];
    
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
    
    [self refreshSearchBarItemsColor:_searchBarView];
    
    _searchBarHeaderBorder.backgroundColor = kRiotAuxiliaryColor;
    
    // Check the table view style to select its bg color.
    self.tableView.backgroundColor = ((self.tableView.style == UITableViewStylePlain) ? kRiotPrimaryBgColor : kRiotSecondaryBgColor);
    self.view.backgroundColor = self.tableView.backgroundColor;
    
    // Update the gradient view above the screen
    CGFloat white = 1.0;
    [kRiotPrimaryBgColor getWhite:&white alpha:nil];
    CGColorRef opaqueWhiteColor = [UIColor colorWithWhite:white alpha:1.0].CGColor;
    CGColorRef transparentWhiteColor = [UIColor colorWithWhite:white alpha:0].CGColor;
    tableViewMaskLayer.colors = [NSArray arrayWithObjects:(__bridge id)transparentWhiteColor, (__bridge id)transparentWhiteColor, (__bridge id)opaqueWhiteColor, nil];
    
    if (self.tableView.dataSource)
    {
        [self.tableView reloadData];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return kRiotDesignStatusBarStyle;
}

// This method is called when the viewcontroller is added or removed from a container view controller.
- (void)didMoveToParentViewController:(nullable UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
}

- (void)destroy
{
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
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
    
    [super destroy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking
    [[AppDelegate theDelegate] trackScreen:@"GroupDetailsPeople"];
    
    if (contactsPickerViewController)
    {
        [contactsPickerViewController destroy];
        contactsPickerViewController = nil;
    }
    
    if (_group)
    {
        // Force refresh
        [self refreshDisplayWithGroup:[self.mxSession groupWithGroupId:_group.groupId]];
        
        // Trigger a refresh on the group members and the invited users.
        [self.mxSession updateGroupUsers:_group success:nil failure:^(NSError *error) {
            
            NSLog(@"[GroupParticipantsViewController] viewWillAppear: group members update failed %@", _group.groupId);
            
        }];
        [self.mxSession updateGroupInvitedUsers:_group success:nil failure:^(NSError *error) {
            
            NSLog(@"[GroupParticipantsViewController] viewWillAppear: invited users update failed %@", _group.groupId);
            
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
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
                                 
                                 tableViewMaskLayer.bounds = newBounds;
                                 
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
    
    _mxSession = mxSession;
    
    [self addMatrixSession:mxSession];
    
    [self refreshDisplayWithGroup:group];
}

#pragma mark -

- (void)registerOnGroupChangeNotifications
{
    [self cancelRegistrationOnGroupChangeNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateGroupUsers:) name:kMXSessionDidUpdateGroupUsersNotification object:self.mxSession];
}

- (void)cancelRegistrationOnGroupChangeNotifications
{
    // Remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didUpdateGroupUsers:(NSNotification *)notif
{
    [self refreshDisplayWithGroup:[self.mxSession groupWithGroupId:_group.groupId]];
}

- (void)refreshDisplayWithGroup:(MXGroup *)group
{
    _group = group;
    
    if (_group)
    {
        _searchBarHeader.hidden = NO;
        
        [self registerOnGroupChangeNotifications];
    }
    else
    {
        // Search bar header is hidden when no group is provided
        _searchBarHeader.hidden = YES;
        
        [self cancelRegistrationOnGroupChangeNotifications];
    }
    
    // Refresh the members list.
    [self refreshParticipantsList];
    
    [self refreshTableView];
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
                         
                         addParticipantButtonImageViewBottomConstraint.constant = keyboardHeight + 9;
                         
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
    
    // Consider the grayscale components of the kRiotPrimaryBgColor.
    CGFloat white = 1.0;
    [kRiotPrimaryBgColor getWhite:&white alpha:nil];
    
    CGColorRef opaqueWhiteColor = [UIColor colorWithWhite:white alpha:1.0].CGColor;
    CGColorRef transparentWhiteColor = [UIColor colorWithWhite:white alpha:0].CGColor;
    
    tableViewMaskLayer.colors = [NSArray arrayWithObjects:(__bridge id)transparentWhiteColor, (__bridge id)transparentWhiteColor, (__bridge id)opaqueWhiteColor, nil];
    
    // display a gradient to the rencents bottom (20% of the bottom of the screen)
    tableViewMaskLayer.locations = [NSArray arrayWithObjects:
                                    [NSNumber numberWithFloat:0],
                                    [NSNumber numberWithFloat:0.85],
                                    [NSNumber numberWithFloat:1.0], nil];
    
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
    addParticipantButtonImageView.image = [UIImage imageNamed:@"add_group_participant"];
    
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
    contactsPickerViewController = [ContactsTableViewController contactsTableViewController];
    
    // Set delegate to handle action on member (start chat, mention)
    contactsPickerViewController.contactsTableViewControllerDelegate = self;
    
    // Prepare its data source
    ContactsDataSource *contactsDataSource = [[ContactsDataSource alloc] initWithMatrixSession:self.mxSession];
    contactsDataSource.areSectionsShrinkable = YES;
    contactsDataSource.displaySearchInputInContactsList = YES;
    contactsDataSource.forceMatrixIdInDisplayName = YES;
    // Add a plus icon to the contact cell in the contacts picker, in order to make it more understandable for the end user.
    contactsDataSource.contactCellAccessoryImage = [UIImage imageNamed:@"plus_icon"];
    
    // List all the participants matrix user id to ignore them during the contacts search.
    for (Contact *contact in actualParticipants)
    {
        [contactsDataSource.ignoredContactsByMatrixId setObject:contact forKey:contact.mxGroupUser.userId];
    }
    for (Contact *contact in invitedParticipants)
    {
        [contactsDataSource.ignoredContactsByMatrixId setObject:contact forKey:contact.mxGroupUser.userId];
    }
    
    [contactsPickerViewController showSearch:YES];
    contactsPickerViewController.searchBar.placeholder = NSLocalizedStringFromTable(@"group_participants_invite_another_user", @"Vector", nil);
    
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
}

- (void)reloadSearchResult
{
    if (currentSearchText.length)
    {
        NSString *searchText = currentSearchText;
        currentSearchText = nil;
        
        [self searchBar:_searchBarView textDidChange:searchText];
    }
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
    [self reloadSearchResult];
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
        
        pendingMaskSpinnerView.alpha = 1;
        
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
    // Check whether the view controller is displayed inside a segmented one.
    if (self.parentViewController.navigationController)
    {
        // Hide back button title
        self.parentViewController.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        
        [self.parentViewController.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        // Hide back button title
        self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        
        [self.navigationController pushViewController:viewController animated:YES];
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
            
            // Update member badge
            if (contact.mxGroupUser.isPrivileged)
            {
                participantCell.thumbnailBadgeView.image = [UIImage imageNamed:@"admin_icon"];
                participantCell.thumbnailBadgeView.hidden = NO;
            }
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = kRiotPrimaryBgColor;
    
    // Update the selected background view
    if (kRiotSelectedBgColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = kRiotSelectedBgColor;
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
    CGFloat height = 0.0;
    
    if (section == invitedSection)
    {
        height = 30.0;
    }
    
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* sectionHeader;
    
    if (section == invitedSection)
    {
        sectionHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 30)];
        sectionHeader.backgroundColor = kRiotSecondaryBgColor;
        
        CGRect frame = sectionHeader.frame;
        frame.origin.x = 20;
        frame.origin.y = 5;
        frame.size.width = sectionHeader.frame.size.width - 10;
        frame.size.height -= 10;
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
        headerLabel.textColor = kRiotPrimaryTextColor;
        headerLabel.font = [UIFont boldSystemFontOfSize:15.0];
        headerLabel.backgroundColor = [UIColor clearColor];
        
        headerLabel.text = NSLocalizedStringFromTable(@"group_participants_invited_section", @"Vector", nil);
        
        [sectionHeader addSubview:headerLabel];
    }
    
    return sectionHeader;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 74.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
        
        leaveAction.backgroundColor = [MXKTools convertImageToPatternColor:@"remove_icon_blue" backgroundColor:kRiotSecondaryBgColor patternSize:CGSizeMake(74, 74) resourceSize:CGSizeMake(24, 24)];
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
            currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"group_participants_leave_prompt_title", @"Vector", nil)
                                                               message:NSLocalizedStringFromTable(@"group_participants_leave_prompt_msg", @"Vector", nil)
                                                        preferredStyle:UIAlertControllerStyleAlert];
            
            [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                               }
                                                               
                                                           }]];
            
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"leave", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                                   
                                                                   [self addPendingActionMask];
                                                                   [self.mxSession leaveGroup:_group.groupId success:^{
                                                                       
                                                                       [self withdrawViewControllerAnimated:YES completion:nil];
                                                                       
                                                                   } failure:^(NSError *error) {
                                                                       
                                                                       [self removePendingActionMask];
                                                                       NSLog(@"[GroupParticipantsVC] Leave group %@ failed", _group.groupId);
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
            NSString *promptMsg = [NSString stringWithFormat:NSLocalizedStringFromTable(@"group_participants_remove_prompt_msg", @"Vector", nil), (contact.mxGroupUser.displayname.length ? contact.mxGroupUser.displayname : memberUserId)];
            currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"group_participants_remove_prompt_title", @"Vector", nil)
                                                               message:promptMsg
                                                        preferredStyle:UIAlertControllerStyleAlert];
            
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
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                                   
                                                                   NSLog(@"[GroupParticipantsVC] Kick %@ failed", memberUserId);
                                                                   // Alert user
                                                                   [[AppDelegate theDelegate] showErrorAsAlert:[NSError errorWithDomain:@"GroupDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:[NSBundle mxk_localizedStringForKey:@"not_supported_yet"]}]];
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
    NSString *promptMsg = [NSString stringWithFormat:NSLocalizedStringFromTable(@"group_participants_invite_prompt_msg", @"Vector", nil), contact.displayName];
    currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"group_participants_invite_prompt_title", @"Vector", nil)
                                                       message:promptMsg
                                                preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"invite", @"Vector", nil)
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
                                                               
                                                               NSLog(@"[GroupParticipantsVC] Invite %@ failed", participantId);
                                                               [[AppDelegate theDelegate] showErrorAsAlert:[NSError errorWithDomain:@"GroupDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:[NSBundle mxk_localizedStringForKey:@"not_supported_yet"]}]];
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
    searchBar.barTintColor = searchBar.tintColor = kRiotColorBlue;
    searchBar.tintColor = kRiotColorBlue;
    
    // FIXME: this all seems incredibly fragile and tied to gutwrenching the current UISearchBar internals.
    
    // text color
    UITextField *searchBarTextField = [searchBar valueForKey:@"_searchField"];
    searchBarTextField.textColor = kRiotSecondaryTextColor;
    
    // Magnifying glass icon.
    UIImageView *leftImageView = (UIImageView *)searchBarTextField.leftView;
    leftImageView.image = [leftImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    leftImageView.tintColor = kRiotColorBlue;
    
    // remove the gray background color
    UIView *effectBackgroundTop =  [searchBarTextField valueForKey:@"_effectBackgroundTop"];
    UIView *effectBackgroundBottom =  [searchBarTextField valueForKey:@"_effectBackgroundBottom"];
    effectBackgroundTop.hidden = YES;
    effectBackgroundBottom.hidden = YES;
    
    // place holder
    searchBarTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:searchBarTextField.placeholder
                                                                               attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                                                                            NSUnderlineColorAttributeName: kRiotColorBlue,
                                                                                            NSForegroundColorAttributeName: kRiotColorBlue}];
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
