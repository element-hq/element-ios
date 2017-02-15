/*
 Copyright 2017 OpenMarket Ltd
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

#import "ContactsTableViewController.h"

#import "UIViewController+VectorSearch.h"

#import "RageShakeManager.h"

#import "AppDelegate.h"

#define CONTACTS_TABLEVC_LOCALCONTACTS_BITWISE 0x01
#define CONTACTS_TABLEVC_KNOWNCONTACTS_BITWISE 0x02

#define CONTACTS_TABLEVC_DEFAULT_SECTION_HEADER_HEIGHT 30.0
#define CONTACTS_TABLEVC_LOCALCONTACTS_SECTION_HEADER_HEIGHT 65.0

@interface ContactsTableViewController ()
{
    // Search processing
    dispatch_queue_t searchProcessingQueue;
    NSUInteger searchProcessingCount;
    NSString *searchProcessingText;
    NSMutableArray<MXKContact*> *searchProcessingLocalContacts;
    NSMutableArray<MXKContact*> *searchProcessingMatrixContacts;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;
    
    BOOL forceSearchResultRefresh;
    
    // This dictionary tells for each display name whether it appears several times.
    NSMutableDictionary <NSString*,NSNumber*> *isMultiUseNameByDisplayName;
    
    // Shrinked sections.
    NSInteger shrinkedSectionsBitMask;
    
    UIView *localContactsCheckboxContainer;
    UIImageView *localContactsCheckbox;
}

@end

@implementation ContactsTableViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([ContactsTableViewController class])
                          bundle:[NSBundle bundleForClass:[ContactsTableViewController class]]];
}

+ (instancetype)contactsTableViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([ContactsTableViewController class])
                                          bundle:[NSBundle bundleForClass:[ContactsTableViewController class]]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // Prepare search session
    searchProcessingQueue = dispatch_queue_create("ContactsTableViewController", DISPATCH_QUEUE_SERIAL);
    searchProcessingCount = 0;
    searchProcessingText = nil;
    searchProcessingLocalContacts = nil;
    searchProcessingMatrixContacts = nil;
    
    _ignoredContactsByEmail = [NSMutableDictionary dictionary];
    _ignoredContactsByMatrixId = [NSMutableDictionary dictionary];
    
    isMultiUseNameByDisplayName = [NSMutableDictionary dictionary];
    
    _forceMatrixIdInDisplayName = NO;
    
    shrinkedSectionsBitMask = 0;
    
    hideNonMatrixEnabledContacts = NO;
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
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)destroy
{
    filteredLocalContacts = nil;
    filteredMatrixContacts = nil;
    
    _ignoredContactsByEmail = nil;
    _ignoredContactsByMatrixId = nil;
    
    userContact = nil;
    
    forceSearchResultRefresh = NO;
    
    searchProcessingQueue = nil;
    searchProcessingLocalContacts = nil;
    searchProcessingMatrixContacts = nil;
    
    isMultiUseNameByDisplayName = nil;
    
    _contactCellAccessoryImage = nil;
    
    localContactsCheckboxContainer = nil;
    localContactsCheckbox = nil;
    
    [super destroy];
}

- (void)addMatrixSession:(MXSession *)mxSession
{
    [super addMatrixSession:mxSession];
    
    // FIXME: Handle multi accounts
    NSString *displayName = NSLocalizedStringFromTable(@"you", @"Vector", nil);
    userContact = [[MXKContact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:self.mainSession.myUser.userId];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:@"ContactsTable"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
    
    // Observe kAppDelegateDidTapStatusBarNotification.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.tableView setContentOffset:CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top) animated:YES];
        
    }];
    
    // Register on contact update notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactManagerDidUpdate:) name:kMXKContactManagerDidUpdateMatrixContactsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactManagerDidUpdate:) name:kMXKContactManagerDidUpdateLocalContactsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactManagerDidUpdate:) name:kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification object:nil];
    
    // Check whether the access to the local contacts has not been already asked.
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    {
        // Allow by default the local contacts sync in order to discover matrix users.
        // This setting change will trigger the loading of the local contacts, which will automatically
        // ask user permission to access their local contacts.
        [MXKAppSettings standardAppSettings].syncLocalContacts = YES;
    }
    else
    {
        // Refresh the matrix identifiers for all the local contacts.
        [[MXKContactManager sharedManager] updateMatrixIDsForAllLocalContacts];
    }
    
    // Scroll to the top the current table content if any
    [self.tableView setContentOffset:CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top) animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKContactManagerDidUpdateMatrixContactsNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKContactManagerDidUpdateLocalContactsNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification object:nil];
}

#pragma mark -

- (void)setForceMatrixIdInDisplayName:(BOOL)forceMatrixIdInDisplayName
{
    if (_forceMatrixIdInDisplayName != forceMatrixIdInDisplayName)
    {
        _forceMatrixIdInDisplayName = forceMatrixIdInDisplayName;
        
        if (self.tableView)
        {
            [self refreshTableView];
        }
    }
}

- (void)searchWithPattern:(NSString *)searchText forceReset:(BOOL)forceRefresh complete:(void (^)())complete
{
    // Update search results.
    searchText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    searchProcessingCount++;
    [self startActivityIndicator];
    
    dispatch_async(searchProcessingQueue, ^{
        
        if (!searchText.length)
        {
            searchProcessingLocalContacts = nil;
            searchProcessingMatrixContacts = nil;
            
            // Disclose by default the sections if a search was in progress.
            if (searchProcessingText.length)
            {
                shrinkedSectionsBitMask = 0;
            }
        }
        else if (forceRefresh || !searchProcessingText.length || [searchText hasPrefix:searchProcessingText] == NO)
        {
            // Retrieve all the local contacts
            searchProcessingLocalContacts = [self unfilteredLocalContactsArray];
            
            // Retrieve all known matrix users
            searchProcessingMatrixContacts = [self unfilteredMatrixContactsArray];
            
            // Disclose the sections
            shrinkedSectionsBitMask = 0;
        }
        
        for (NSUInteger index = 0; index < searchProcessingLocalContacts.count;)
        {
            MXKContact* contact = searchProcessingLocalContacts[index];
            
            if (![contact hasPrefix:searchText])
            {
                [searchProcessingLocalContacts removeObjectAtIndex:index];
            }
            else
            {
                // Next
                index++;
            }
        }
        
        for (NSUInteger index = 0; index < searchProcessingMatrixContacts.count;)
        {
            MXKContact* contact = searchProcessingMatrixContacts[index];
            
            if (![contact hasPrefix:searchText])
            {
                [searchProcessingMatrixContacts removeObjectAtIndex:index];
            }
            else
            {
                // Next
                index++;
            }
        }
        
        // Sort the refreshed list of the invitable contacts
        [[MXKContactManager sharedManager] sortAlphabeticallyContacts:searchProcessingLocalContacts];
        [[MXKContactManager sharedManager] sortContactsByLastActiveInformation:searchProcessingMatrixContacts];
        
        searchProcessingText = searchText;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            // Sanity check: check whether self has been destroyed.
            if (!searchProcessingQueue)
            {
                return;
            }
            
            // Render the search result only if there is no other search in progress.
            searchProcessingCount --;
            
            if (!searchProcessingCount)
            {
                if (!forceSearchResultRefresh)
                {
                    [self stopActivityIndicator];
                    
                    // Scroll the resulting list to the top only when the search pattern has been modified.
                    BOOL shouldScrollToTop = (currentSearchText != searchProcessingText);
                    
                    // Update the filtered contacts.
                    currentSearchText = searchProcessingText;
                    filteredLocalContacts = searchProcessingLocalContacts;
                    filteredMatrixContacts = searchProcessingMatrixContacts;
                    
                    if (!self.forceMatrixIdInDisplayName)
                    {
                        [isMultiUseNameByDisplayName removeAllObjects];
                        for (MXKContact* contact in filteredMatrixContacts)
                        {
                            isMultiUseNameByDisplayName[contact.displayName] = (isMultiUseNameByDisplayName[contact.displayName] ? @(YES) : @(NO));
                        }
                    }
                    
                    // Refresh display
                    [self refreshTableView];
                    
                    if (shouldScrollToTop)
                    {
                        // Scroll to the top
                        [self.tableView setContentOffset:CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top) animated:NO];
                    }
                    
                    if (complete)
                    {
                        complete();
                    }
                }
                else
                {
                    // Launch a new search
                    forceSearchResultRefresh = NO;
                    [self searchWithPattern:searchProcessingText forceReset:YES complete:complete];
                }
            }
        });
        
    });
}

- (void)refreshTableView
{
    [self.tableView reloadData];
}

#pragma mark - Internals

- (void)onContactManagerDidUpdate:(NSNotification *)notif
{
    // Check whether a search is in progress
    if (searchProcessingCount)
    {
        forceSearchResultRefresh = YES;
        return;
    }
    
    // Refresh the search result
    [self searchWithPattern:currentSearchText forceReset:YES complete:nil];
}

- (NSMutableArray<MXKContact*>*)unfilteredLocalContactsArray
{
    // Retrieve all the contacts obtained by splitting each local contact by contact method. This list is ordered alphabetically.
    NSMutableArray *unfilteredLocalContacts = [NSMutableArray arrayWithArray:[MXKContactManager sharedManager].localContactsSplitByContactMethod];
    
    // Remove the ignored contacts
    // + Check whether the non-matrix-enabled contacts must be ignored
    for (NSUInteger index = 0; index < unfilteredLocalContacts.count;)
    {
        MXKContact* contact = unfilteredLocalContacts[index];
        
        NSArray *identifiers = contact.matrixIdentifiers;
        if (identifiers.count)
        {
            if ([_ignoredContactsByMatrixId objectForKey:identifiers.firstObject])
            {
                [unfilteredLocalContacts removeObjectAtIndex:index];
                continue;
            }
        }
        else if (hideNonMatrixEnabledContacts)
        {
            // Ignore non-matrix-enabled contact
            [unfilteredLocalContacts removeObjectAtIndex:index];
            continue;
        }
        else
        {
            NSArray *emails = contact.emailAddresses;
            if (emails.count)
            {
                // Here the contact has only one email address.
                MXKEmail *email = emails.firstObject;
                
                // Trick: ignore @facebook.com email addresses from the results - facebook have discontinued that service...
                if ([_ignoredContactsByEmail objectForKey:email.emailAddress] || [email.emailAddress hasSuffix:@"@facebook.com"])
                {
                    [unfilteredLocalContacts removeObjectAtIndex:index];
                    continue;
                }
            }
        }
        
        index++;
    }
    
    return unfilteredLocalContacts;
}

- (NSMutableArray<MXKContact*>*)unfilteredMatrixContactsArray
{
    NSArray *matrixContacts = [MXKContactManager sharedManager].matrixContacts;
    NSMutableArray *unfilteredMatrixContacts = [NSMutableArray arrayWithCapacity:matrixContacts.count];
    
    // Matrix ids: split contacts with several ids, and remove the current participants.
    for (MXKContact* contact in matrixContacts)
    {
        NSArray *identifiers = contact.matrixIdentifiers;
        if (identifiers.count > 1)
        {
            for (NSString *userId in identifiers)
            {
                if ([_ignoredContactsByMatrixId objectForKey:userId] == nil)
                {
                    MXKContact *splitContact = [[MXKContact alloc] initMatrixContactWithDisplayName:contact.displayName andMatrixID:userId];
                    [unfilteredMatrixContacts addObject:splitContact];
                }
            }
        }
        else if (identifiers.count)
        {
            NSString *userId = identifiers.firstObject;
            if ([_ignoredContactsByMatrixId objectForKey:userId] == nil)
            {
                [unfilteredMatrixContacts addObject:contact];
            }
        }
    }
    
    return unfilteredMatrixContacts;
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    
    searchInputSection = filteredLocalContactsSection = filteredMatrixContactsSection = -1;
    
    if (currentSearchText.length)
    {
        searchInputSection = count++;
    }
    else
    {
        // Display by default the full address book ordered alphabetically, mixing Matrix enabled and non-Matrix enabled users.
        if (!filteredLocalContacts)
        {
            filteredLocalContacts = [self unfilteredLocalContactsArray];
        }
    }
    
    // Keep visible the header for the both contact sections, even if their are empty.
    filteredLocalContactsSection = count++;
    filteredMatrixContactsSection = count++;
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == searchInputSection)
    {
        count = 1;
    }
    else if (section == filteredLocalContactsSection && !(shrinkedSectionsBitMask & CONTACTS_TABLEVC_LOCALCONTACTS_BITWISE))
    {
        count = filteredLocalContacts.count;
    }
    else if (section == filteredMatrixContactsSection && !(shrinkedSectionsBitMask & CONTACTS_TABLEVC_KNOWNCONTACTS_BITWISE))
    {
        if (currentSearchText.length)
        {
            count = filteredMatrixContacts.count;
        }
        else
        {
            // Display a message to invite the user to use the search field.
            count = 1;
        }
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Consider first the case of the known contacts section when no search is in progress.
    if (!currentSearchText.length && indexPath.section == filteredMatrixContactsSection && indexPath.row == 0)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"defaultKnownContactCell"];
        if (!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"defaultKnownContactCell"];
        }
        
        cell.textLabel.text = NSLocalizedStringFromTable(@"contacts_matrix_users_search_prompt", @"Vector", nil);
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.textColor = kVectorTextColorGray;
        cell.textLabel.font = [UIFont systemFontOfSize:15.0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    // Prepare a contact cell here
    ContactTableViewCell* contactCell = [tableView dequeueReusableCellWithIdentifier:[ContactTableViewCell defaultReuseIdentifier]];
    
    if (!contactCell)
    {
        contactCell = [[ContactTableViewCell alloc] init];
    }
    else
    {
        // Restore default values
        contactCell.accessoryView = nil;
        contactCell.contentView.alpha = 1;
        contactCell.userInteractionEnabled = YES;
        contactCell.accessoryType = UITableViewCellAccessoryNone;
        contactCell.accessoryView = nil;
    }
    
    MXKContact *contact;
    
    if (indexPath.section == searchInputSection)
    {
        // Show what the user is typing in a cell. So that he can click on it
        contact = [[MXKContact alloc] initMatrixContactWithDisplayName:currentSearchText andMatrixID:nil];
        
        contactCell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else if (indexPath.section == filteredLocalContactsSection)
    {
        if (indexPath.row < filteredLocalContacts.count)
        {
            contact = filteredLocalContacts[indexPath.row];
            
            contactCell.selectionStyle = UITableViewCellSelectionStyleDefault;
            contactCell.showMatrixIdInDisplayName = YES;
        }
    }
    else if (indexPath.section == filteredMatrixContactsSection)
    {
        if (indexPath.row < filteredMatrixContacts.count)
        {
            contact = filteredMatrixContacts[indexPath.row];
            
            contactCell.selectionStyle = UITableViewCellSelectionStyleDefault;
            contactCell.showMatrixIdInDisplayName = self.forceMatrixIdInDisplayName ? YES : [isMultiUseNameByDisplayName[contact.displayName] isEqualToNumber:@(YES)];
        }
    }
    
    if (contact)
    {
        [contactCell render:contact];
        
        // The search displays contacts to invite. 
        if (indexPath.section == filteredLocalContactsSection || indexPath.section == filteredMatrixContactsSection)
        {
            // Add the right accessory view if any
            contactCell.accessoryType = self.contactCellAccessoryType;
            contactCell.accessoryView = [[UIImageView alloc] initWithImage:self.contactCellAccessoryImage];
        }
        else if (indexPath.section == searchInputSection)
        {
            // This is the text entered by the user
            // Check whether the search input is a valid email or a Matrix user ID before adding the accessory view.
            if (![MXTools isEmailAddress:currentSearchText] && ![MXTools isMatrixUserIdentifier:currentSearchText])
            {
                contactCell.contentView.alpha = 0.5;
                contactCell.userInteractionEnabled = NO;
            }
            else
            {
                // Add the right accessory view if any
                contactCell.accessoryType = self.contactCellAccessoryType;
                contactCell.accessoryView = [[UIImageView alloc] initWithImage:self.contactCellAccessoryImage];
            }
        }
    }
    
    return contactCell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == filteredLocalContactsSection || section == filteredMatrixContactsSection)
    {
        if (section == filteredLocalContactsSection && !(shrinkedSectionsBitMask & CONTACTS_TABLEVC_LOCALCONTACTS_BITWISE))
        {
            return CONTACTS_TABLEVC_LOCALCONTACTS_SECTION_HEADER_HEIGHT;
        }
        
        return CONTACTS_TABLEVC_DEFAULT_SECTION_HEADER_HEIGHT;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* sectionHeader;
    
    CGFloat height = [self tableView:tableView heightForHeaderInSection:section];
    if (height != 0)
    {
        NSInteger sectionBitwise = -1;
        
        sectionHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, height)];
        sectionHeader.backgroundColor = kVectorColorLightGrey;
        
        CGRect frame = sectionHeader.frame;
        frame.origin.x = 20;
        frame.origin.y = 5;
        frame.size.width = sectionHeader.frame.size.width - 10;
        frame.size.height = 20;
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
        headerLabel.font = [UIFont boldSystemFontOfSize:15.0];
        headerLabel.backgroundColor = [UIColor clearColor];
        [sectionHeader addSubview:headerLabel];
        
        if (section == filteredLocalContactsSection)
        {
            headerLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"contacts_address_book_section", @"Vector", nil), filteredLocalContacts.count];
            
            sectionBitwise = CONTACTS_TABLEVC_LOCALCONTACTS_BITWISE;
        }
        else //if (section == filteredMatrixContactsSection)
        {
            if (currentSearchText.length)
            {
                headerLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"contacts_matrix_users_section", @"Vector", nil), filteredMatrixContacts.count];
                
                // This section is collapsable only if it is not empty
                if (filteredMatrixContacts.count)
                {
                    sectionBitwise = CONTACTS_TABLEVC_KNOWNCONTACTS_BITWISE;
                }
            }
            else
            {
                headerLabel.text = NSLocalizedStringFromTable(@"contacts_matrix_users_default_section", @"Vector", nil);
            }
        }
        
        if (sectionBitwise != -1)
        {
            // Add shrink button
            UIButton *shrinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
            frame = sectionHeader.frame;
            frame.origin.x = frame.origin.y = 0;
            frame.size.height = CONTACTS_TABLEVC_DEFAULT_SECTION_HEADER_HEIGHT;
            shrinkButton.frame = frame;
            shrinkButton.backgroundColor = [UIColor clearColor];
            [shrinkButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            shrinkButton.tag = sectionBitwise;
            [sectionHeader addSubview:shrinkButton];
            sectionHeader.userInteractionEnabled = YES;
            
            // Add shrink icon
            UIImage *chevron;
            if (shrinkedSectionsBitMask & sectionBitwise)
            {
                chevron = [UIImage imageNamed:@"disclosure_icon"];
            }
            else
            {
                chevron = [UIImage imageNamed:@"shrink_icon"];
            }
            UIImageView *chevronView = [[UIImageView alloc] initWithImage:chevron];
            chevronView.contentMode = UIViewContentModeCenter;
            frame = chevronView.frame;
            frame.origin.x = shrinkButton.frame.size.width - frame.size.width - 16;
            frame.origin.y = (shrinkButton.frame.size.height - frame.size.height) / 2;
            chevronView.frame = frame;
            [sectionHeader addSubview:chevronView];
            chevronView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
        }
        
        if (section == filteredLocalContactsSection && !(shrinkedSectionsBitMask & CONTACTS_TABLEVC_LOCALCONTACTS_BITWISE))
        {
            NSLayoutConstraint *leadingConstraint, *trailingConstraint, *topConstraint, *bottomConstraint;
            NSLayoutConstraint *widthConstraint, *heightConstraint, *centerYConstraint, *centerXConstraint;
            
            if (!localContactsCheckboxContainer)
            {
                CGFloat containerWidth = sectionHeader.frame.size.width;
                
                localContactsCheckboxContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CONTACTS_TABLEVC_DEFAULT_SECTION_HEADER_HEIGHT, containerWidth, sectionHeader.frame.size.height - CONTACTS_TABLEVC_DEFAULT_SECTION_HEADER_HEIGHT)];
                localContactsCheckboxContainer.backgroundColor = [UIColor clearColor];
                localContactsCheckboxContainer.translatesAutoresizingMaskIntoConstraints = NO;
                
                // Add Checkbox and Label
                localContactsCheckbox = [[UIImageView alloc] initWithFrame:CGRectMake(23, 5, 22, 22)];
                localContactsCheckbox.translatesAutoresizingMaskIntoConstraints = NO;
                [localContactsCheckboxContainer addSubview:localContactsCheckbox];
                
                UILabel *checkboxLabel = [[UILabel alloc] initWithFrame:CGRectMake(54, 5, containerWidth - 64, 30)];
                checkboxLabel.translatesAutoresizingMaskIntoConstraints = NO;
                checkboxLabel.textColor = kVectorTextColorBlack;
                checkboxLabel.font = [UIFont systemFontOfSize:16.0];
                checkboxLabel.text = NSLocalizedStringFromTable(@"contacts_address_book_matrix_users_toggle", @"Vector", nil);
                [localContactsCheckboxContainer addSubview:checkboxLabel];
                
                UIView *checkboxMask = [[UIView alloc] initWithFrame:CGRectMake(16, -2, 36, 36)];
                checkboxMask.translatesAutoresizingMaskIntoConstraints = NO;
                [localContactsCheckboxContainer addSubview:checkboxMask];
                // Listen to check box tap
                checkboxMask.userInteractionEnabled = YES;
                UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCheckBoxTap:)];
                [tapGesture setNumberOfTouchesRequired:1];
                [tapGesture setNumberOfTapsRequired:1];
                [tapGesture setDelegate:self];
                [checkboxMask addGestureRecognizer:tapGesture];
                
                // Add switch constraints
                leadingConstraint = [NSLayoutConstraint constraintWithItem:localContactsCheckbox
                                                                 attribute:NSLayoutAttributeLeading
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:localContactsCheckboxContainer
                                                                 attribute:NSLayoutAttributeLeading
                                                                multiplier:1
                                                                  constant:23];
                
                topConstraint = [NSLayoutConstraint constraintWithItem:localContactsCheckbox
                                                             attribute:NSLayoutAttributeTop
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:localContactsCheckboxContainer
                                                             attribute:NSLayoutAttributeTop
                                                            multiplier:1
                                                              constant:5];
                
                widthConstraint = [NSLayoutConstraint constraintWithItem:localContactsCheckbox
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:nil
                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1
                                                                constant:22];
                heightConstraint = [NSLayoutConstraint constraintWithItem:localContactsCheckbox
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1
                                                                 constant:22];
                
                [NSLayoutConstraint activateConstraints:@[leadingConstraint, topConstraint, widthConstraint, heightConstraint]];
                
                
                // Add Label constraints
                centerYConstraint = [NSLayoutConstraint constraintWithItem:checkboxLabel
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:localContactsCheckbox
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1
                                                                  constant:0.0f];
                heightConstraint = [NSLayoutConstraint constraintWithItem:checkboxLabel
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1
                                                                 constant:30];
                leadingConstraint = [NSLayoutConstraint constraintWithItem:checkboxLabel
                                                                 attribute:NSLayoutAttributeLeading
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:localContactsCheckbox
                                                                 attribute:NSLayoutAttributeTrailing
                                                                multiplier:1
                                                                  constant:10];
                trailingConstraint = [NSLayoutConstraint constraintWithItem:checkboxLabel
                                                                  attribute:NSLayoutAttributeTrailing
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:localContactsCheckboxContainer
                                                                  attribute:NSLayoutAttributeTrailing
                                                                 multiplier:1
                                                                   constant:-10];
                
                [NSLayoutConstraint activateConstraints:@[centerYConstraint, heightConstraint, leadingConstraint, trailingConstraint]];
                
                // Add check box mask constraints
                widthConstraint = [NSLayoutConstraint constraintWithItem:checkboxMask
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:nil
                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1
                                                                constant:36];
                
                heightConstraint = [NSLayoutConstraint constraintWithItem:checkboxMask
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1
                                                                 constant:36];
                
                centerXConstraint = [NSLayoutConstraint constraintWithItem:checkboxMask
                                                                 attribute:NSLayoutAttributeCenterX
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:localContactsCheckbox
                                                                 attribute:NSLayoutAttributeCenterX
                                                                multiplier:1
                                                                  constant:0.0f];
                
                centerYConstraint = [NSLayoutConstraint constraintWithItem:checkboxMask
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:localContactsCheckbox
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1
                                                                  constant:0.0f];
                
                [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint, centerXConstraint, centerYConstraint]];
            }
            
            // Set the right value of the tick box
            localContactsCheckbox.image = hideNonMatrixEnabledContacts ? [UIImage imageNamed:@"selection_tick"] : [UIImage imageNamed:@"selection_untick"];
            
            // Add the check box container
            [sectionHeader addSubview:localContactsCheckboxContainer];
            leadingConstraint = [NSLayoutConstraint constraintWithItem:localContactsCheckboxContainer
                                                             attribute:NSLayoutAttributeLeading
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:sectionHeader
                                                             attribute:NSLayoutAttributeLeading
                                                            multiplier:1
                                                              constant:0];
            widthConstraint = [NSLayoutConstraint constraintWithItem:localContactsCheckboxContainer
                                                           attribute:NSLayoutAttributeWidth
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:sectionHeader
                                                           attribute:NSLayoutAttributeWidth
                                                          multiplier:1
                                                            constant:0];
            topConstraint = [NSLayoutConstraint constraintWithItem:localContactsCheckboxContainer
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:sectionHeader
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1
                                                          constant:CONTACTS_TABLEVC_DEFAULT_SECTION_HEADER_HEIGHT];
            bottomConstraint = [NSLayoutConstraint constraintWithItem:localContactsCheckboxContainer
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:sectionHeader
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1
                                                             constant:0];
            
            [NSLayoutConstraint activateConstraints:@[leadingConstraint, widthConstraint, topConstraint, bottomConstraint]];
        }
    }
    return sectionHeader;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!currentSearchText.length && indexPath.section == filteredMatrixContactsSection && indexPath.row == 0)
    {
        return 50;
    }
    
    return 74.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.contactsTableViewControllerDelegate)
    {
        NSInteger row = indexPath.row;
        MXKContact *mxkContact;
        
        if (indexPath.section == searchInputSection)
        {
            mxkContact = [[MXKContact alloc] initMatrixContactWithDisplayName:currentSearchText andMatrixID:nil];
        }
        else if (indexPath.section == filteredLocalContactsSection)
        {
            mxkContact = filteredLocalContacts[row];
        }
        else if (indexPath.section == filteredMatrixContactsSection)
        {
            mxkContact = filteredMatrixContacts[row];
        }
        
        if (mxkContact)
        {
            [self.contactsTableViewControllerDelegate contactsTableViewController:self didSelectContact:mxkContact];
        }
    }
    // Else do nothing by default - `ContactsTableViewController-inherited` instance must override this method.
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISearchBar delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self searchWithPattern:searchText forceReset:NO complete:nil];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // "Done" key has been pressed.
    
    // Check whether the current search input is a valid email or a Matrix user ID
    if (currentSearchText.length && ([MXTools isEmailAddress:currentSearchText] || [MXTools isMatrixUserIdentifier:currentSearchText]))
    {
        // Select the contact related to the search input, rather than having to hit +
        if (searchInputSection != -1)
        {
            [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:searchInputSection]];
            return;
        }
        
    }
    
    // Dismiss keyboard
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = nil;
    
    // Reset filtering
    [self searchWithPattern:nil forceReset:NO complete:nil];
    
    // Leave search
    [searchBar resignFirstResponder];
    
    [self withdrawViewControllerAnimated:YES completion:nil];
}

#pragma mark - Action

- (IBAction)onButtonPressed:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *shrinkButton = (UIButton*)sender;
        NSInteger selectedSectionBit = shrinkButton.tag;
        
        if (shrinkedSectionsBitMask & selectedSectionBit)
        {
            // Disclose the section
            shrinkedSectionsBitMask &= ~selectedSectionBit;
        }
        else
        {
            // Shrink this section
            shrinkedSectionsBitMask |= selectedSectionBit;
        }
        
        // Refresh
        [self refreshTableView];
    }
}
    
#pragma mark - Action
    
- (IBAction)onCheckBoxTap:(UITapGestureRecognizer*)sender
{
    // Update local contacts filter
    hideNonMatrixEnabledContacts = !hideNonMatrixEnabledContacts;
    
    // Check whether a search is in progress
    if (searchProcessingCount)
    {
        forceSearchResultRefresh = YES;
        return;
    }
    
    // Refresh the search result
    if (hideNonMatrixEnabledContacts)
    {
        // Remove the non-matrix-enabled contacts from the current filtered local contacts
        for (NSUInteger index = 0; index < filteredLocalContacts.count;)
        {
            MXKContact* contact = filteredLocalContacts[index];
            
            NSArray *identifiers = contact.matrixIdentifiers;
            if (!identifiers.count)
            {
                [filteredLocalContacts removeObjectAtIndex:index];
                continue;
            }
            
            index++;
        }
        
        // Refresh display
        [self refreshTableView];
    }
    else
    {
        // Refresh the search result by launching a new search session.
        [self searchWithPattern:currentSearchText forceReset:YES complete:nil];
    }
}

@end
