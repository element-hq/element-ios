/*
 Copyright 2017 OpenMarket Ltd
 
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

#define CONTACTS_TABLEVC_LOCALCONTACTS_BIT     0x01
#define CONTACTS_TABLEVC_KNOWNCONTACTS_BIT     0x02

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
    
    // Report all the contacts by matrix id.
    NSMutableDictionary <NSString*, MXKContact*> *contactsByMatrixId;
    
    // Shrinked sections.
    BOOL enableSectionShrinking;
    NSInteger shrinkedSectionsBitMask;
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
    searchProcessingQueue = dispatch_queue_create("StartChatViewController", DISPATCH_QUEUE_SERIAL);
    searchProcessingCount = 0;
    searchProcessingText = nil;
    searchProcessingLocalContacts = nil;
    searchProcessingMatrixContacts = nil;
    
    _ignoredContactsByEmail = [NSMutableDictionary dictionary];
    _ignoredContactsByMatrixId = [NSMutableDictionary dictionary];
    
    isMultiUseNameByDisplayName = [NSMutableDictionary dictionary];
    contactsByMatrixId = [NSMutableDictionary dictionary];
    
    _forceMatrixIdInDisplayName = NO;
    
    enableSectionShrinking = NO;
    shrinkedSectionsBitMask = 0;
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
    
    searchProcessingQueue = nil;
    searchProcessingLocalContacts = nil;
    searchProcessingMatrixContacts = nil;
    
    isMultiUseNameByDisplayName = nil;
    contactsByMatrixId = nil;
    
    _contactCellAccessoryImage = nil;
    
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
    
    // Check whether the access to the local contacts has not been already asked.
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    {
        // Allow by default the local contacts sync in order to discover matrix users.
        // This setting change will trigger the loading of the local contacts, which will automatically
        // ask user permission to access their local contacts.
        [MXKAppSettings standardAppSettings].syncLocalContacts = YES;
    }
    
    // Observe kAppDelegateDidTapStatusBarNotification.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.tableView setContentOffset:CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top) animated:YES];
        
    }];
    
    // Register on contact update notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactManagerDidUpdate:) name:kMXKContactManagerDidUpdateMatrixContactsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactManagerDidUpdate:) name:kMXKContactManagerDidUpdateLocalContactsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactManagerDidUpdate:) name:kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification object:nil];
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

- (void)searchWithPattern:(NSString *)searchText forceReset:(BOOL)forceRefresh
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
            
            // Disclose the sections
            shrinkedSectionsBitMask = 0;
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
        
        // List all the filtered local Matrix-enabled contacts by their matrix id to remove a contact
        // from the "Known Contacts" section if a local contact matches with his Matrix identifier.
        [contactsByMatrixId removeAllObjects];
        
        for (NSUInteger index = 0; index < searchProcessingLocalContacts.count;)
        {
            MXKContact* contact = searchProcessingLocalContacts[index];
            
            if (![contact hasPrefix:searchText])
            {
                [searchProcessingLocalContacts removeObjectAtIndex:index];
            }
            else
            {
                NSArray *identifiers = contact.matrixIdentifiers;
                if (identifiers.count)
                {
                    // Here the contact can only have one identifier
                    contactsByMatrixId[identifiers.firstObject] = contact;
                }
                
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
            
            // Render the search result only if there is no other search in progress.
            searchProcessingCount --;
            
            if (!searchProcessingCount)
            {
                if (!forceSearchResultRefresh)
                {
                    [self stopActivityIndicator];
                    
                    // Update the filtered contacts.
                    currentSearchText = searchProcessingText;
                    filteredLocalContacts = searchProcessingLocalContacts;
                    
                    // Check whether some Matrix-enabled contacts are listed in the local contact.
                    if (contactsByMatrixId.count)
                    {
                        // Remove a contact from the "Known Contacts" section if a local contact matches with his Matrix identifier.
                        filteredMatrixContacts = [NSMutableArray arrayWithArray:searchProcessingMatrixContacts];
                        for (NSUInteger index = 0; index < filteredMatrixContacts.count;)
                        {
                            MXKContact* contact = filteredMatrixContacts[index];
                            
                            // Here the contact can only have one identifier
                            NSArray *identifiers = contact.matrixIdentifiers;
                            if (identifiers.count && contactsByMatrixId[identifiers.firstObject])
                            {
                                [filteredMatrixContacts removeObjectAtIndex:index];
                            }
                            else
                            {
                                // Next
                                index++;
                            }
                        }
                    }
                    else
                    {
                        filteredMatrixContacts = searchProcessingMatrixContacts;
                    }
                    
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
                    
                    // Force scroll to top
                    [self.tableView setContentOffset:CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top) animated:NO];
                }
                else
                {
                    // Launch a new search
                    forceSearchResultRefresh = NO;
                    [self searchWithPattern:searchProcessingText forceReset:YES];
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
    [self searchWithPattern:currentSearchText forceReset:YES];
}

- (NSMutableArray<MXKContact*>*)unfilteredLocalContactsArray
{
    // Retrieve all the contacts obtained by splitting each local contact by contact method. This list is ordered alphabetically.
    NSMutableArray *unfilteredLocalContacts = [NSMutableArray arrayWithArray:[MXKContactManager sharedManager].localContactsSplitByContactMethod];
    
    // Remove the ignored contacts
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
        else
        {
            NSArray *emails = contact.emailAddresses;
            if (emails.count)
            {
                MXKEmail *email = emails.firstObject;
                if ([_ignoredContactsByEmail objectForKey:email.emailAddress])
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
        
        if (filteredLocalContacts.count)
        {
            filteredLocalContactsSection = count++;
        }
        
        if (filteredMatrixContacts.count)
        {
            filteredMatrixContactsSection = count++;
        }
    }
    else
    {
        // Display by default the full address book ordered alphabetically, mixing Matrix enabled and non-Matrix enabled users.
        if (!filteredLocalContacts)
        {
            filteredLocalContacts = [self unfilteredLocalContactsArray];
        }
        
        if (filteredLocalContacts.count)
        {
            filteredLocalContactsSection = count++;
        }
    }
    
    // Enable the section shrinking only when all the contacts sections are displayed.
    enableSectionShrinking = (filteredLocalContactsSection != -1 && filteredMatrixContactsSection != -1);
    if (enableSectionShrinking == NO)
    {
        // Disclose the section
        shrinkedSectionsBitMask = 0;
    }
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == searchInputSection)
    {
        count = 1;
    }
    else if (section == filteredLocalContactsSection && !(shrinkedSectionsBitMask & CONTACTS_TABLEVC_LOCALCONTACTS_BIT))
    {
        count = filteredLocalContacts.count;
    }
    else if (section == filteredMatrixContactsSection && !(shrinkedSectionsBitMask & CONTACTS_TABLEVC_KNOWNCONTACTS_BIT))
    {
        count = filteredMatrixContacts.count;
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
        return 30.0;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* sectionHeader;
    
    if (section == filteredLocalContactsSection || section == filteredMatrixContactsSection)
    {
        NSInteger sectionBit = -1;
        
        sectionHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 30)];
        sectionHeader.backgroundColor = kVectorColorLightGrey;
        
        CGRect frame = sectionHeader.frame;
        frame.origin.x = 20;
        frame.origin.y = 5;
        frame.size.width = sectionHeader.frame.size.width - 10;
        frame.size.height -= 10;
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
        headerLabel.font = [UIFont boldSystemFontOfSize:15.0];
        headerLabel.backgroundColor = [UIColor clearColor];
        [sectionHeader addSubview:headerLabel];
        
        if (section == filteredLocalContactsSection)
        {
            headerLabel.text = NSLocalizedStringFromTable(@"contacts_address_book_section", @"Vector", nil);
            sectionBit = CONTACTS_TABLEVC_LOCALCONTACTS_BIT;
        }
        else //if (section == filteredMatrixContactsSection)
        {
            headerLabel.text = NSLocalizedStringFromTable(@"contacts_matrix_users_section", @"Vector", nil);
            sectionBit = CONTACTS_TABLEVC_KNOWNCONTACTS_BIT;
        }
        
        if (enableSectionShrinking)
        {
            // Add shrink button
            UIButton *shrinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
            frame = sectionHeader.frame;
            frame.origin.x = frame.origin.y = 0;
            shrinkButton.frame = frame;
            shrinkButton.backgroundColor = [UIColor clearColor];
            [shrinkButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            shrinkButton.tag = sectionBit;
            [sectionHeader addSubview:shrinkButton];
            sectionHeader.userInteractionEnabled = YES;
            
            // Add shrink icon
            UIImage *chevron;
            if (shrinkedSectionsBitMask & sectionBit)
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
            frame.origin.x = sectionHeader.frame.size.width - frame.size.width - 16;
            frame.origin.y = (sectionHeader.frame.size.height - frame.size.height) / 2;
            chevronView.frame = frame;
            [sectionHeader addSubview:chevronView];
            chevronView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
        }
    }
    return sectionHeader;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    [self searchWithPattern:searchText forceReset:NO];
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
    [self searchWithPattern:nil forceReset:NO];
    
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

@end
