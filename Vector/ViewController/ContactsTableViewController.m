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

#import "RageShakeManager.h"

#import "AppDelegate.h"

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
}

@end

@implementation ContactsTableViewController

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
    
    ignoredContactsByEmail = [NSMutableDictionary dictionary];
    ignoredContactsByMatrixId = [NSMutableDictionary dictionary];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Add each matrix session by default.
    NSArray *sessions = [AppDelegate theDelegate].mxSessions;
    for (MXSession *mxSession in sessions)
    {
        [self addMatrixSession:mxSession];
    }
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
    
    ignoredContactsByEmail = nil;
    ignoredContactsByMatrixId = nil;
    
    userContact = nil;
    
    if (currentAlert)
    {
        [currentAlert dismiss:NO];
        currentAlert = nil;
    }
    
    searchProcessingQueue = nil;
    searchProcessingLocalContacts = nil;
    searchProcessingMatrixContacts = nil;
    
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
    
    if (currentAlert)
    {
        [currentAlert dismiss:NO];
        currentAlert = nil;
    }
    
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

- (void)searchWithPattern:(NSString *)searchText forceRefresh:(BOOL)forceRefresh
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
        }
        else if (forceRefresh || !searchProcessingText.length || [searchText hasPrefix:searchProcessingText] == NO)
        {
            // Retrieve all the local contacts
            searchProcessingMatrixContacts = [self unfilteredLocalContactsArray];
            
            // Retrieve all known matrix users
            searchProcessingMatrixContacts = [self unfilteredMatrixContactsArray];
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
                    filteredMatrixContacts = searchProcessingMatrixContacts;
                    
                    // Refresh display
                    [self refreshTableView];
                    
                    // Force scroll to top
                    [self.tableView setContentOffset:CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top) animated:YES];
                }
                else
                {
                    // Launch a new search
                    forceSearchResultRefresh = NO;
                    [self searchWithPattern:searchProcessingText forceRefresh:YES];
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
    [self searchWithPattern:currentSearchText forceRefresh:YES];
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
            if ([ignoredContactsByMatrixId objectForKey:identifiers.firstObject])
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
                if ([ignoredContactsByEmail objectForKey:email.emailAddress])
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
                if ([ignoredContactsByMatrixId objectForKey:userId] == nil)
                {
                    MXKContact *splitContact = [[MXKContact alloc] initMatrixContactWithDisplayName:contact.displayName andMatrixID:userId];
                    [unfilteredMatrixContacts addObject:splitContact];
                }
            }
        }
        else if (identifiers.count)
        {
            NSString *userId = identifiers.firstObject;
            if ([ignoredContactsByMatrixId objectForKey:userId] == nil)
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
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == searchInputSection)
    {
        count = 1;
    }
    else if (section == filteredLocalContactsSection)
    {
        count = filteredLocalContacts.count;
    }
    else if (section == filteredMatrixContactsSection)
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
            contactCell.showMatrixIdInDisplayName = YES;
        }
    }
    
    if (contact)
    {
        [contactCell render:contact];
        
        // The search displays contacts to invite. Add a plus icon to the cell
        // in order to make it more understandable for the end user
        if (indexPath.section == filteredLocalContactsSection || indexPath.section == filteredMatrixContactsSection)
        {
            contactCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus_icon"]];
        }
        else if (indexPath.section == searchInputSection)
        {
            // This is the text entered by the user
            // Check whether the search input is a valid email or a Matrix user ID before adding the plus icon.
            if (![MXTools isEmailAddress:currentSearchText] && ![MXTools isMatrixUserIdentifier:currentSearchText])
            {
                contactCell.contentView.alpha = 0.5;
                contactCell.userInteractionEnabled = NO;
            }
            else
            {
                contactCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus_icon"]];
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
        
        if (section == filteredLocalContactsSection)
        {
            headerLabel.text = NSLocalizedStringFromTable(@"contacts_address_book_section", @"Vector", nil);
        }
        else if (section == filteredMatrixContactsSection)
        {
            headerLabel.text = NSLocalizedStringFromTable(@"contacts_matrix_users_section", @"Vector", nil);
        }
        
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
    // Do nothing by default - `ContactsTableViewController-inherited` instance must override this method.
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
