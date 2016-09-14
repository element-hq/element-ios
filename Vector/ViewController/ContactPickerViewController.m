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

#import "ContactPickerViewController.h"

#import "AppDelegate.h"

#import "ContactTableViewCell.h"

#import "VectorDesignValues.h"

#import "RageShakeManager.h"

@interface ContactPickerViewController()
{
    NSMutableArray *matrixContacts;
    
    NSMutableArray *filteredContacts;
    
    NSString *currentSearchText;
    
    // This dictionary tells for each display name whether it appears several times.
    NSMutableDictionary <NSString*,NSNumber*> *isMultiUseNameByDisplayName;
    NSMutableDictionary <NSString*,NSNumber*> *backupIsMultiUseNameByDisplayName;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;
}

@end

@implementation ContactPickerViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([ContactPickerViewController class])
                          bundle:[NSBundle bundleForClass:[ContactPickerViewController class]]];
}

+ (instancetype)contactPickerViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([ContactPickerViewController class])
                                          bundle:[NSBundle bundleForClass:[ContactPickerViewController class]]];
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Check whether the view controller has been pushed via storyboard
    if (!_contactsTableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];

    [self.contactsTableView registerNib:ContactTableViewCell.nib forCellReuseIdentifier:ContactTableViewCell.defaultReuseIdentifier];

    // Hide line separators of empty cells
    self.contactsTableView.tableFooterView = [[UIView alloc] init];
    
    self.noResultsLabel.text = [NSBundle mxk_localizedStringForKey:@"search_no_results"];
    self.noResultsLabel.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:@"PeopleGlobalSearch"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
    
    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.contactsTableView setContentOffset:CGPointMake(-self.contactsTableView.contentInset.left, -self.contactsTableView.contentInset.top) animated:YES];
        
    }];
    
    // Register on contact update
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshContactsList) name:kMXKContactManagerDidUpdateMatrixContactsNotification object:nil];
    
    [self refreshContactsList];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKContactManagerDidUpdateMatrixContactsNotification object:nil];
    
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }
}

- (void)destroy
{
    matrixContacts = nil;
    filteredContacts = nil;
    
    isMultiUseNameByDisplayName = nil;
    backupIsMultiUseNameByDisplayName = nil;
    
    [super destroy];
}

#pragma mark -

- (void)refreshContactsList
{
    // Retrieve all known matrix users
    NSArray *contacts = [NSArray arrayWithArray:[MXKContactManager sharedManager].matrixContacts];
    
    // Retrieve all known email addresses from local contacts
    NSArray *localEmailContacts = [MXKContactManager sharedManager].localEmailContacts;
    
    matrixContacts = [NSMutableArray arrayWithCapacity:(contacts.count + localEmailContacts.count)];
    
    // Add first email contacts
    if (localEmailContacts.count)
    {
        [matrixContacts addObjectsFromArray:localEmailContacts];
    }
    
    if (contacts.count)
    {
        [matrixContacts addObjectsFromArray:contacts];
    }
    
    // Sort invitable contacts by displaying local email first
    // ...and then alphabetically.
    NSComparator comparator = ^NSComparisonResult(MXKContact *contactA, MXKContact *contactB) {
        
        BOOL isLocalEmailA = !contactA.matrixIdentifiers.count;
        BOOL isLocalEmailB = !contactB.matrixIdentifiers.count;
        
        if (!isLocalEmailA && isLocalEmailB)
        {
            return NSOrderedDescending;
        }
        if (isLocalEmailA && !isLocalEmailB)
        {
            return NSOrderedAscending;
        }
        
        return [contactA.sortingDisplayName compare:contactB.sortingDisplayName options:NSCaseInsensitiveSearch];
    };
    
    [matrixContacts sortUsingComparator:comparator];
    
    // Reset
    isMultiUseNameByDisplayName = [NSMutableDictionary dictionary];
    backupIsMultiUseNameByDisplayName = nil;
    
    if (currentSearchText.length)
    {
        filteredContacts = [NSMutableArray array];
        
        for (MXKContact* contact in matrixContacts)
        {
            if ([contact matchedWithPatterns:@[currentSearchText]])
            {
                [filteredContacts addObject:contact];
                
                isMultiUseNameByDisplayName[contact.displayName] = (isMultiUseNameByDisplayName[contact.displayName] ? @(YES) : @(NO));
            }
        }
    }
    else
    {
        for (MXKContact* contact in matrixContacts)
        {
            isMultiUseNameByDisplayName[contact.displayName] = (isMultiUseNameByDisplayName[contact.displayName] ? @(YES) : @(NO));
        }
        backupIsMultiUseNameByDisplayName = isMultiUseNameByDisplayName;
    }
    
    // Refresh display
    [self.contactsTableView reloadData];
}

- (void)searchWithPattern:(NSString *)searchText
{
    NSArray *contacts;
    
    // Update search results
    if (currentSearchText.length && [searchText hasPrefix:currentSearchText])
    {
        contacts = filteredContacts;
    }
    else
    {
        contacts = matrixContacts;
    }
    
    currentSearchText = searchText;
    
    if (currentSearchText.length)
    {
        // Check whether the search input is a valid email or a Matrix user ID
        BOOL isValidInput = ([MXTools isEmailAddress:currentSearchText] || [MXTools isMatrixUserIdentifier:currentSearchText]);

        filteredContacts = [NSMutableArray array];
        isMultiUseNameByDisplayName = [NSMutableDictionary dictionary];
        
        for (MXKContact* contact in contacts)
        {
            if ([contact matchedWithPatterns:@[currentSearchText]])
            {
                // Ignore the contact if it corresponds to the search input
                if (!isValidInput || [contact.displayName isEqualToString:currentSearchText] == NO)
                {
                    [filteredContacts addObject:contact];
                    
                    isMultiUseNameByDisplayName[contact.displayName] = (isMultiUseNameByDisplayName[contact.displayName] ? @(YES) : @(NO));
                }
            }
        }
        
        // Show what the user is typing in a cell. So that he can click on it
        MXKContact *contact = [[MXKContact alloc] initMatrixContactWithDisplayName:currentSearchText andMatrixID:nil];
        [filteredContacts insertObject:contact atIndex:0];
    }
    else
    {
        filteredContacts = nil;
        
        if (backupIsMultiUseNameByDisplayName)
        {
            isMultiUseNameByDisplayName = backupIsMultiUseNameByDisplayName;
        }
        else
        {
            for (MXKContact* contact in matrixContacts)
            {
                isMultiUseNameByDisplayName[contact.displayName] = (isMultiUseNameByDisplayName[contact.displayName] ? @(YES) : @(NO));
            }
            backupIsMultiUseNameByDisplayName = isMultiUseNameByDisplayName;
        }
    }
    
    // Refresh display
    [self.contactsTableView reloadData];
}

#pragma mark - UITableView data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    // Display something only when search is in progress (Hide the full contacts list by default).
    if (filteredContacts)
    {
        count = filteredContacts.count;
        _noResultsLabel.hidden = (count != 0);
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactTableViewCell* participantCell = [tableView dequeueReusableCellWithIdentifier:[ContactTableViewCell defaultReuseIdentifier]];
    MXKContact *contact;
    
    if (indexPath.row < filteredContacts.count)
    {
        contact = filteredContacts[indexPath.row];
    }
    
    if (contact)
    {
        participantCell.contentView.alpha = 1.0;
        participantCell.userInteractionEnabled = YES;
        
        if (currentSearchText.length && indexPath.row == 0)
        {
            // This is the text entered by the user
            // Check whether the search input is a valid email or a Matrix user ID before adding the plus icon.
            if (![MXTools isEmailAddress:currentSearchText] && ![MXTools isMatrixUserIdentifier:currentSearchText])
            {
                participantCell.contentView.alpha = 0.5;
                participantCell.userInteractionEnabled = NO;
            }
        }
        
        // Disambiguate the display name when it appears several times.
        if (contact.displayName && [isMultiUseNameByDisplayName[contact.displayName] isEqualToNumber:@(YES)])
        {
            NSArray *identifiers = contact.matrixIdentifiers;
            if (identifiers.count)
            {
                NSString *participantId = identifiers.firstObject;
                NSString *displayName = [NSString stringWithFormat:@"%@ (%@)", contact.displayName, participantId];
                
                contact = [[MXKContact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:participantId];
            }
        }
        
        [participantCell render:contact];
    }
    
    return participantCell;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 74.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MXKContact *selectedContact;
    
    if (indexPath.row < filteredContacts.count)
    {
        selectedContact = filteredContacts[indexPath.row];
    }
    
    if (_delegate && selectedContact)
    {
        [self.delegate contactPickerViewController:self didSelectContact:selectedContact];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
