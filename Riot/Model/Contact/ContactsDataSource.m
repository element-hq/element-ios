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

#import "ContactsDataSource.h"
#import "ContactTableViewCell.h"

#import "RiotDesignValues.h"

#define CONTACTSDATASOURCE_LOCALCONTACTS_BITWISE 0x01
#define CONTACTSDATASOURCE_KNOWNCONTACTS_BITWISE 0x02

#define CONTACTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT 30.0
#define CONTACTSDATASOURCE_LOCALCONTACTS_SECTION_HEADER_HEIGHT 65.0

@interface ContactsDataSource ()
{
    // Search processing
    dispatch_queue_t searchProcessingQueue;
    NSUInteger searchProcessingCount;
    NSString *searchProcessingText;
    NSMutableArray<MXKContact*> *searchProcessingLocalContacts;
    NSMutableArray<MXKContact*> *searchProcessingMatrixContacts;
    
    BOOL forceSearchResultRefresh;
    
    // This dictionary tells for each display name whether it appears several times.
    NSMutableDictionary <NSString*,NSNumber*> *isMultiUseNameByDisplayName;
    
    // Shrinked sections.
    NSInteger shrinkedSectionsBitMask;
    
    UIView *localContactsCheckboxContainer;
    UIImageView *localContactsCheckbox;
}

@end

@implementation ContactsDataSource

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // Prepare search session
        searchProcessingQueue = dispatch_queue_create("ContactsDataSource", DISPATCH_QUEUE_SERIAL);
        searchProcessingCount = 0;
        searchProcessingText = nil;
        searchProcessingLocalContacts = nil;
        searchProcessingMatrixContacts = nil;
        
        _ignoredContactsByEmail = [NSMutableDictionary dictionary];
        _ignoredContactsByMatrixId = [NSMutableDictionary dictionary];
        
        isMultiUseNameByDisplayName = [NSMutableDictionary dictionary];
        
        _forceMatrixIdInDisplayName = NO;
        
        _areSectionsShrinkable = NO;
        shrinkedSectionsBitMask = 0;
        
        hideNonMatrixEnabledContacts = NO;
        
        _displaySearchInputInContactsList = NO;
        
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
    }
    return self;
}

- (void)destroy
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKContactManagerDidUpdateMatrixContactsNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKContactManagerDidUpdateLocalContactsNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification object:nil];
    
    filteredLocalContacts = nil;
    filteredMatrixContacts = nil;
    
    _ignoredContactsByEmail = nil;
    _ignoredContactsByMatrixId = nil;
    
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

#pragma mark -

- (void)forceRefresh
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

- (void)setForceMatrixIdInDisplayName:(BOOL)forceMatrixIdInDisplayName
{
    if (_forceMatrixIdInDisplayName != forceMatrixIdInDisplayName)
    {
        _forceMatrixIdInDisplayName = forceMatrixIdInDisplayName;
        
        [self forceRefresh];
    }
}

- (void)searchWithPattern:(NSString *)searchText forceReset:(BOOL)forceRefresh
{
    // Update search results.
    searchText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    searchProcessingCount++;
    
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
                    
                    // And inform the delegate about the update
                    [self.delegate dataSource:self didCellChange:nil];
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

- (void)setDisplaySearchInputInContactsList:(BOOL)displaySearchInputInContactsList
{
    if (_displaySearchInputInContactsList != displaySearchInputInContactsList)
    {
        _displaySearchInputInContactsList = displaySearchInputInContactsList;
        
        [self forceRefresh];
    }
}

- (MXKContact*)searchInputContact
{
    // Check whether the current search input is a valid email or a Matrix user ID
    if (currentSearchText.length && ([MXTools isEmailAddress:currentSearchText] || [MXTools isMatrixUserIdentifier:currentSearchText]))
    {
        return [[MXKContact alloc] initMatrixContactWithDisplayName:currentSearchText andMatrixID:nil];
    }
    
    return nil;
}

#pragma mark - Internals

- (void)onContactManagerDidUpdate:(NSNotification *)notif
{
    [self forceRefresh];
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
            else
            {
                // The contact has here a phone number.
                // Ignore this contact if the phone number is not linked to a matrix id because the invitation by SMS is not supported yet.
                MXKPhoneNumber *phoneNumber = contact.phoneNumbers.firstObject;
                if (!phoneNumber.matrixID)
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
        if (_displaySearchInputInContactsList)
        {
            searchInputSection = count++;
        }
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
    else if (section == filteredLocalContactsSection && !(shrinkedSectionsBitMask & CONTACTSDATASOURCE_LOCALCONTACTS_BITWISE))
    {
        count = filteredLocalContacts.count;
    }
    else if (section == filteredMatrixContactsSection && !(shrinkedSectionsBitMask & CONTACTSDATASOURCE_KNOWNCONTACTS_BITWISE))
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
        cell.textLabel.textColor = kRiotTextColorGray;
        cell.textLabel.font = [UIFont systemFontOfSize:15.0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    // Prepare a contact cell here
    MXKContact *contact;
    BOOL showMatrixIdInDisplayName = NO;
    
    if (indexPath.section == searchInputSection)
    {
        // Show what the user is typing in a cell. So that he can click on it
        contact = [[MXKContact alloc] initMatrixContactWithDisplayName:currentSearchText andMatrixID:nil];
    }
    else if (indexPath.section == filteredLocalContactsSection)
    {
        if (indexPath.row < filteredLocalContacts.count)
        {
            contact = filteredLocalContacts[indexPath.row];
            showMatrixIdInDisplayName = YES;
        }
    }
    else if (indexPath.section == filteredMatrixContactsSection)
    {
        if (indexPath.row < filteredMatrixContacts.count)
        {
            contact = filteredMatrixContacts[indexPath.row];
            
            showMatrixIdInDisplayName = self.forceMatrixIdInDisplayName ? YES : [isMultiUseNameByDisplayName[contact.displayName] isEqualToNumber:@(YES)];
        }
    }
    
    if (contact)
    {
        ContactTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:[ContactTableViewCell defaultReuseIdentifier]];
        if (!contactCell)
        {
            contactCell = [[ContactTableViewCell alloc] init];
        }
        
        // Make the cell display the contact
        [contactCell render:contact];
        
        contactCell.selectionStyle = UITableViewCellSelectionStyleDefault;
        contactCell.showMatrixIdInDisplayName = showMatrixIdInDisplayName;
        
        // The search displays contacts to invite.
        if (indexPath.section == filteredLocalContactsSection || indexPath.section == filteredMatrixContactsSection)
        {
            // Add the right accessory view if any
            contactCell.accessoryType = self.contactCellAccessoryType;
            if (self.contactCellAccessoryImage)
            {
                contactCell.accessoryView = [[UIImageView alloc] initWithImage:self.contactCellAccessoryImage];
            }
            
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
                if (self.contactCellAccessoryImage)
                {
                    contactCell.accessoryView = [[UIImageView alloc] initWithImage:self.contactCellAccessoryImage];
                }
            }
        }
        
        return contactCell;
    }
    
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark -

-(MXKContact *)contactAtIndexPath:(NSIndexPath*)indexPath
{
    NSInteger row = indexPath.row;
    MXKContact *mxkContact;
    
    if (indexPath.section == searchInputSection)
    {
        mxkContact = [[MXKContact alloc] initMatrixContactWithDisplayName:currentSearchText andMatrixID:nil];
    }
    else if (indexPath.section == filteredLocalContactsSection && row < filteredLocalContacts.count)
    {
        mxkContact = filteredLocalContacts[row];
    }
    else if (indexPath.section == filteredMatrixContactsSection && row < filteredMatrixContacts.count)
    {
        mxkContact = filteredMatrixContacts[row];
    }
    
    return mxkContact;
}

- (NSIndexPath*)cellIndexPathWithContact:(MXKContact*)contact
{
    NSIndexPath *indexPath = nil;
    
    NSUInteger index = [filteredLocalContacts indexOfObject:contact];
    if (index != NSNotFound)
    {
        indexPath = [NSIndexPath indexPathForRow:index inSection:filteredLocalContactsSection];
    }
    else
    {
        index = [filteredMatrixContacts indexOfObject:contact];
        if (index != NSNotFound)
        {
            indexPath = [NSIndexPath indexPathForRow:index inSection:filteredMatrixContactsSection];
        }
    }
    return indexPath;
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section
{
    if (section == filteredLocalContactsSection || section == filteredMatrixContactsSection)
    {
        if (section == filteredLocalContactsSection && !(shrinkedSectionsBitMask & CONTACTSDATASOURCE_LOCALCONTACTS_BITWISE))
        {
            return CONTACTSDATASOURCE_LOCALCONTACTS_SECTION_HEADER_HEIGHT;
        }
        
        return CONTACTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT;
    }
    return 0;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    NSString* sectionTitle = nil;
    NSUInteger count = 0;
    
    if (section == filteredLocalContactsSection)
    {
        count = filteredLocalContacts.count;
        
        if (count)
        {
            sectionTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"contacts_address_book_section", @"Vector", nil), count];
        }
        else
        {
            sectionTitle = NSLocalizedStringFromTable(@"contacts_address_book_section_default", @"Vector", nil);
        }
    }
    else //if (section == filteredMatrixContactsSection)
    {
        sectionTitle = NSLocalizedStringFromTable(@"contacts_matrix_users_section_default", @"Vector", nil);
        
        if (currentSearchText.length)
        {
            count = filteredMatrixContacts.count;
            
            if (count)
            {
                sectionTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"contacts_matrix_users_section", @"Vector", nil), count];
            }
        }
    }
    
    return sectionTitle;
}

- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame
{
    UIView* sectionHeader;
    
    NSInteger sectionBitwise = 0;
    
    sectionHeader = [[UIView alloc] initWithFrame:frame];
    sectionHeader.backgroundColor = kRiotColorLightGrey;
    
    frame.origin.x = 20;
    frame.origin.y = 5;
    frame.size.width = sectionHeader.frame.size.width - 10;
    frame.size.height = 20;
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
    headerLabel.text = [self titleForHeaderInSection:section];
    headerLabel.font = [UIFont boldSystemFontOfSize:15.0];
    headerLabel.backgroundColor = [UIColor clearColor];
    [sectionHeader addSubview:headerLabel];
    
    if (_areSectionsShrinkable)
    {
        if (section == filteredLocalContactsSection)
        {
            sectionBitwise = CONTACTSDATASOURCE_LOCALCONTACTS_BITWISE;
        }
        else //if (section == filteredMatrixContactsSection)
        {
            if (currentSearchText.length)
            {
                // This section is collapsable only if it is not empty
                if (filteredMatrixContacts.count)
                {
                    sectionBitwise = CONTACTSDATASOURCE_KNOWNCONTACTS_BITWISE;
                }
            }
        }
    }
    
    if (sectionBitwise)
    {
        // Add shrink button
        UIButton *shrinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        frame = sectionHeader.frame;
        frame.origin.x = frame.origin.y = 0;
        frame.size.height = CONTACTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT;
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
    
    if (section == filteredLocalContactsSection && !(shrinkedSectionsBitMask & CONTACTSDATASOURCE_LOCALCONTACTS_BITWISE))
    {
        NSLayoutConstraint *leadingConstraint, *trailingConstraint, *topConstraint, *bottomConstraint;
        NSLayoutConstraint *widthConstraint, *heightConstraint, *centerYConstraint;
        
        if (!localContactsCheckboxContainer)
        {
            CGFloat containerWidth = sectionHeader.frame.size.width;
            
            localContactsCheckboxContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CONTACTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT, containerWidth, sectionHeader.frame.size.height - CONTACTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT)];
            localContactsCheckboxContainer.backgroundColor = [UIColor clearColor];
            localContactsCheckboxContainer.translatesAutoresizingMaskIntoConstraints = NO;
            
            // Add Checkbox and Label
            localContactsCheckbox = [[UIImageView alloc] initWithFrame:CGRectMake(23, 5, 22, 22)];
            localContactsCheckbox.translatesAutoresizingMaskIntoConstraints = NO;
            [localContactsCheckboxContainer addSubview:localContactsCheckbox];
            
            UILabel *checkboxLabel = [[UILabel alloc] initWithFrame:CGRectMake(54, 5, containerWidth - 64, 30)];
            checkboxLabel.translatesAutoresizingMaskIntoConstraints = NO;
            checkboxLabel.textColor = kRiotTextColorBlack;
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
            heightConstraint = [NSLayoutConstraint constraintWithItem:checkboxMask
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:nil
                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                           multiplier:1
                                                             constant:36];
            
            centerYConstraint = [NSLayoutConstraint constraintWithItem:checkboxMask
                                                             attribute:NSLayoutAttributeCenterY
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:localContactsCheckbox
                                                             attribute:NSLayoutAttributeCenterY
                                                            multiplier:1
                                                              constant:0.0f];
            
            leadingConstraint = [NSLayoutConstraint constraintWithItem:checkboxMask
                                                             attribute:NSLayoutAttributeLeading
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:localContactsCheckbox
                                                             attribute:NSLayoutAttributeLeading
                                                            multiplier:1
                                                              constant:-7];
            
            trailingConstraint = [NSLayoutConstraint constraintWithItem:checkboxMask
                                                              attribute:NSLayoutAttributeTrailing
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:checkboxLabel
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1
                                                               constant:0];
            
            [NSLayoutConstraint activateConstraints:@[heightConstraint, centerYConstraint, leadingConstraint, trailingConstraint]];
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
                                                      constant:CONTACTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT];
        bottomConstraint = [NSLayoutConstraint constraintWithItem:localContactsCheckboxContainer
                                                        attribute:NSLayoutAttributeBottom
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:sectionHeader
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1
                                                         constant:0];
        
        [NSLayoutConstraint activateConstraints:@[leadingConstraint, widthConstraint, topConstraint, bottomConstraint]];
    }
    
    return sectionHeader;
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
        
        // Inform the delegate about the update
        [self.delegate dataSource:self didCellChange:nil];
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
        [self.delegate dataSource:self didCellChange:nil];
    }
    else
    {
        // Refresh the search result by launching a new search session.
        [self searchWithPattern:currentSearchText forceReset:YES];
    }
}

@end
