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

#import <Contacts/Contacts.h>
#import "ContactsDataSource.h"
#import "ContactTableViewCell.h"
#import "SectionHeaderView.h"
#import "LocalContactsSectionHeaderContainerView.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#define CONTACTSDATASOURCE_LOCALCONTACTS_BITWISE 0x01
#define CONTACTSDATASOURCE_USERDIRECTORY_BITWISE 0x02

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

    // The current request to the homeserver user directory
    MXHTTPOperation *hsUserDirectoryOperation;
    
    BOOL forceSearchResultRefresh;
    
    // This dictionary tells for each display name whether it appears several times.
    NSMutableDictionary <NSString*,NSNumber*> *isMultiUseNameByDisplayName;
    
    // Shrinked sections.
    NSInteger shrinkedSectionsBitMask;
    
    LocalContactsSectionHeaderContainerView *localContactsCheckboxContainer;
    UILabel *checkboxLabel;
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
    }
    return self;
}

- (instancetype)initWithMatrixSession:(MXSession *)mxSession
{
    self = [super initWithMatrixSession:mxSession];
    if (self) {
        // Only show local contacts when contact sync is enabled and the identity server terms of service have been accepted.
        _showLocalContacts = MXKAppSettings.standardAppSettings.syncLocalContacts && self.mxSession.identityService.areAllTermsAgreed;
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
    checkboxLabel = nil;
    localContactsCheckbox = nil;

    [hsUserDirectoryOperation cancel];
    hsUserDirectoryOperation = nil;
    
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
    // If possible, always start a new search by asking the homeserver user directory
    BOOL hsUserDirectory = (self.mxSession.state != MXSessionStateHomeserverNotReachable);
    [self searchWithPattern:searchText forceReset:forceRefresh hsUserDirectory:hsUserDirectory];
}

- (void)searchWithPattern:(NSString *)searchText forceReset:(BOOL)forceRefresh hsUserDirectory:(BOOL)hsUserDirectory
{
    // Update search results.
    searchText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSMutableArray<MXKContact*> *unfilteredLocalContacts;
    NSMutableArray<MXKContact*> *unfilteredMatrixContacts;
    
    searchProcessingCount++;

    if (!searchText.length)
    {
        // Disclose by default the sections if a search was in progress.
        if (searchProcessingText.length)
        {
            shrinkedSectionsBitMask = 0;
        }
    }
    else if (forceRefresh || ![searchText isEqualToString:searchProcessingText])
    {
        // Prepare on the main thread the arrays used to initialize the search on the processing queue.
        unfilteredLocalContacts = [self unfilteredLocalContactsArray];
        if (!hsUserDirectory)
        {
            _userDirectoryState = ContactsDataSourceUserDirectoryStateOfflineLoading;
            unfilteredMatrixContacts = [self unfilteredMatrixContactsArray];
        }
        else if (![searchText isEqualToString:searchProcessingText])
        {
            _userDirectoryState = ContactsDataSourceUserDirectoryStateLoading;

            // Make a search on the homeserver user directory
            [filteredMatrixContacts removeAllObjects];
            filteredMatrixContacts = nil;

            // Cancel previous operation
            if (hsUserDirectoryOperation)
            {
                [hsUserDirectoryOperation cancel];
                hsUserDirectoryOperation = nil;
            }
            
            MXWeakify(self);

            hsUserDirectoryOperation = [self.mxSession.matrixRestClient searchUsers:searchText limit:50 success:^(MXUserSearchResponse *userSearchResponse) {
                
                MXStrongifyAndReturnIfNil(self);
                
                self->filteredMatrixContacts = [NSMutableArray arrayWithCapacity:userSearchResponse.results.count];

                // Keep the response order as the hs ordered users by relevance
                for (MXUser *mxUser in userSearchResponse.results)
                {
                    MXKContact *contact = [[MXKContact alloc] initMatrixContactWithDisplayName:mxUser.displayname andMatrixID:mxUser.userId];
                    [self->filteredMatrixContacts addObject:contact];
                }

                self->hsUserDirectoryOperation = nil;

                self->_userDirectoryState = userSearchResponse.limited ? ContactsDataSourceUserDirectoryStateLoadedButLimited : ContactsDataSourceUserDirectoryStateLoaded;

                // And inform the delegate about the update
                [self.delegate dataSource:self didCellChange:nil];

            } failure:^(NSError *error) {

                // Ignore connection cancellation error
                if ((![error.domain isEqualToString:NSURLErrorDomain] || error.code != NSURLErrorCancelled))
                {
                    // But for other errors, launch a local search
                    MXLogDebug(@"[ContactsDataSource] [MXRestClient searchUsers] returns an error. Do a search on local known contacts");
                    [self searchWithPattern:searchText forceReset:forceRefresh hsUserDirectory:NO];
                }
            }];
        }

        // Disclose the sections
        shrinkedSectionsBitMask = 0;
    }
    
    MXWeakify(self);

    dispatch_async(searchProcessingQueue, ^{
        
        MXStrongifyAndReturnIfNil(self);
        
        // Reset the current arrays if it is required
        if (!searchText.length)
        {
            self->searchProcessingLocalContacts = nil;
            self->searchProcessingMatrixContacts = nil;
        }
        else if (unfilteredLocalContacts)
        {
            self->searchProcessingLocalContacts = unfilteredLocalContacts;
            self->searchProcessingMatrixContacts = unfilteredMatrixContacts;
        }
        
        for (NSUInteger index = 0; index < self->searchProcessingLocalContacts.count;)
        {
            MXKContact* contact = self->searchProcessingLocalContacts[index];
            
            if (![contact hasPrefix:searchText])
            {
                [self->searchProcessingLocalContacts removeObjectAtIndex:index];
            }
            else
            {
                // Next
                index++;
            }
        }
        
        for (NSUInteger index = 0; index < self->searchProcessingMatrixContacts.count;)
        {
            MXKContact* contact = self->searchProcessingMatrixContacts[index];
            
            if (![contact hasPrefix:searchText])
            {
                [self->searchProcessingMatrixContacts removeObjectAtIndex:index];
            }
            else
            {
                // Next
                index++;
            }
        }
        
        // Sort the refreshed list of the invitable contacts
        [[MXKContactManager sharedManager] sortAlphabeticallyContacts:self->searchProcessingLocalContacts];
        [[MXKContactManager sharedManager] sortContactsByLastActiveInformation:self->searchProcessingMatrixContacts];
        
        self->searchProcessingText = searchText;
        
        MXWeakify(self);
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            // Sanity check: check whether self has been destroyed.
            MXStrongifyAndReturnIfNil(self);
            
            // Render the search result only if there is no other search in progress.
            self->searchProcessingCount --;
            
            if (!self->searchProcessingCount)
            {
                if (!self->forceSearchResultRefresh)
                {
                    // Update the filtered contacts.
                    self->currentSearchText = self->searchProcessingText;
                    self->filteredLocalContacts = self->searchProcessingLocalContacts;

                    if (!hsUserDirectory)
                    {
                        self->filteredMatrixContacts = self->searchProcessingMatrixContacts;
                        self->_userDirectoryState = ContactsDataSourceUserDirectoryStateOfflineLoaded;
                    }
                    
                    if (!self.forceMatrixIdInDisplayName)
                    {
                        [self->isMultiUseNameByDisplayName removeAllObjects];
                        for (MXKContact* contact in self->filteredMatrixContacts)
                        {
                            self->isMultiUseNameByDisplayName[contact.displayName] = (self->isMultiUseNameByDisplayName[contact.displayName] ? @(YES) : @(NO));
                        }
                    }
                    
                    // And inform the delegate about the update
                    [self.delegate dataSource:self didCellChange:nil];
                }
                else
                {
                    // Launch a new search
                    self->forceSearchResultRefresh = NO;
                    [self searchWithPattern:self->searchProcessingText forceReset:YES];
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
            if (_ignoredContactsByMatrixId[identifiers.firstObject])
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
                if (_ignoredContactsByEmail[email.emailAddress] || [email.emailAddress hasSuffix:@"@facebook.com"])
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
                if (_ignoredContactsByMatrixId[userId] == nil)
                {
                    MXKContact *splitContact = [[MXKContact alloc] initMatrixContactWithDisplayName:contact.displayName andMatrixID:userId];
                    [unfilteredMatrixContacts addObject:splitContact];
                }
            }
        }
        else if (identifiers.count)
        {
            NSString *userId = identifiers.firstObject;
            if (_ignoredContactsByMatrixId[userId] == nil)
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
        
        // Keep visible the header for the both contact sections, even if they're are empty.
        if (BuildSettings.allowLocalContactsAccess && self.showLocalContacts && [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized)
        {
            filteredLocalContactsSection = count++;
        }
        filteredMatrixContactsSection = count++;
    }
    else
    {
        // Display by default the full address book ordered alphabetically, mixing Matrix enabled and non-Matrix enabled users.
        if (!filteredLocalContacts)
        {
            filteredLocalContacts = [self unfilteredLocalContactsArray];
        }
        
        // Keep visible the local contact header, even if the section is empty.
        if (BuildSettings.allowLocalContactsAccess && self.showLocalContacts && [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized)
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
        count = RiotSettings.shared.allowInviteExernalUsers ? 1 : 0;
    }
    else if (section == filteredLocalContactsSection && !(shrinkedSectionsBitMask & CONTACTSDATASOURCE_LOCALCONTACTS_BITWISE))
    {
        // Display a default cell when no local contacts is available.
        count = filteredLocalContacts.count ? filteredLocalContacts.count : 1;
    }
    else if (section == filteredMatrixContactsSection && !(shrinkedSectionsBitMask & CONTACTSDATASOURCE_USERDIRECTORY_BITWISE))
    {
        // Display a default cell when no contacts is available.
        count = filteredMatrixContacts.count ? filteredMatrixContacts.count : 1;
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    else
    {
        MXKTableViewCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
        if (!tableViewCell)
        {
            tableViewCell = [[MXKTableViewCell alloc] init];
            tableViewCell.textLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
            tableViewCell.textLabel.font = [UIFont systemFontOfSize:15.0];
            tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        // Check whether a search session is in progress
        if (currentSearchText.length)
        {
            if (indexPath.section == filteredMatrixContactsSection &&
                (_userDirectoryState == ContactsDataSourceUserDirectoryStateLoading || _userDirectoryState == ContactsDataSourceUserDirectoryStateOfflineLoading))
            {
                tableViewCell.textLabel.text = [VectorL10n searchSearching];
            }
            else
            {
                tableViewCell.textLabel.text = [VectorL10n searchNoResult];
            }
        }
        else if (indexPath.section == filteredLocalContactsSection)
        {
            tableViewCell.textLabel.numberOfLines = 0;

            // Indicate to the user why there is no contacts
            switch ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts])
            {
                case CNAuthorizationStatusAuthorized:
                    if (hideNonMatrixEnabledContacts && !self.mxSession.identityService)
                    {
                        // Because we cannot make lookups with no IS
                        tableViewCell.textLabel.text = [VectorL10n contactsAddressBookNoIdentityServer];
                    }
                    else
                    {
                        // Because there is no contacts on the device
                        tableViewCell.textLabel.text = [VectorL10n contactsAddressBookNoContact];
                    }
                    break;

                case CNAuthorizationStatusNotDetermined:
                    // Because the user have not granted the permission yet
                    // (The permission request popup is displayed at the same time)
                    tableViewCell.textLabel.text = [VectorL10n contactsAddressBookPermissionRequired];
                    break;

                default:
                {
                    // Because the user didn't allow the app to access local contacts
                    tableViewCell.textLabel.text = [VectorL10n contactsAddressBookPermissionDenied:AppInfo.current.displayName];
                    break;
                }
            }
        }
        return tableViewCell;
    }
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
        // if local section is collapsed there is no cell
        if (!(shrinkedSectionsBitMask & CONTACTSDATASOURCE_LOCALCONTACTS_BITWISE)) {
            indexPath = [NSIndexPath indexPathForRow:index inSection:filteredLocalContactsSection];
        }
    }
    else
    {
        index = [filteredMatrixContacts indexOfObject:contact];
        // if matrix section is collapsed or we are not showing the matrix section(as with empty query) there is no cell
        if (index != NSNotFound && !(shrinkedSectionsBitMask & CONTACTSDATASOURCE_USERDIRECTORY_BITWISE) && filteredMatrixContactsSection != -1)
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

- (NSAttributedString *)attributedStringForHeaderTitleInSection:(NSInteger)section
{
    NSAttributedString *sectionTitle;
    NSString* title;
    NSUInteger count = 0;
    
    if (section == filteredLocalContactsSection)
    {
        count = filteredLocalContacts.count;
        title = [VectorL10n contactsAddressBookSection];
    }
    else //if (section == filteredMatrixContactsSection)
    {
        switch (_userDirectoryState)
        {
            case ContactsDataSourceUserDirectoryStateOfflineLoading:
            case ContactsDataSourceUserDirectoryStateOfflineLoaded:
                title = [VectorL10n contactsUserDirectoryOfflineSection];
                break;

            default:
                title = [VectorL10n contactsUserDirectorySection];
                break;
        }
        
        if (currentSearchText.length)
        {
            count = filteredMatrixContacts.count;
        }
    }
    
    if (count)
    {
        NSString *roomCountFormat = (_userDirectoryState == ContactsDataSourceUserDirectoryStateLoadedButLimited) ? @"   > %tu" : @"   %tu";
        NSString *roomCount = [NSString stringWithFormat:roomCountFormat, count];
        
        NSMutableAttributedString *mutableSectionTitle = [[NSMutableAttributedString alloc] initWithString:title
                                                                                         attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.headerTextPrimaryColor,
                                                                                                      NSFontAttributeName: [UIFont boldSystemFontOfSize:15.0]}];
        [mutableSectionTitle appendAttributedString:[[NSMutableAttributedString alloc] initWithString:roomCount
                                                                                    attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.headerTextSecondaryColor,
                                                                                                 NSFontAttributeName: [UIFont boldSystemFontOfSize:15.0]}]];
        
        sectionTitle = mutableSectionTitle;
    }
    else if (title)
    {
        sectionTitle = [[NSAttributedString alloc] initWithString:title
                                               attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.headerTextPrimaryColor,
                                                            NSFontAttributeName: [UIFont boldSystemFontOfSize:15.0]}];
    }
    
    return sectionTitle;
}

- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame inTableView:(UITableView *)tableView
{
    NSInteger sectionBitwise = 0;
    
    SectionHeaderView *sectionHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:SectionHeaderView.defaultReuseIdentifier];
    if (sectionHeader == nil)
    {
        sectionHeader = [[SectionHeaderView alloc] initWithReuseIdentifier:SectionHeaderView.defaultReuseIdentifier];
    }
    sectionHeader.frame = frame;
    sectionHeader.backgroundView = [UIView new];
    sectionHeader.backgroundView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    sectionHeader.topViewHeight = CONTACTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT;

    frame.size.height = CONTACTSDATASOURCE_DEFAULT_SECTION_HEADER_HEIGHT - 10;
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
    headerLabel.attributedText = [self attributedStringForHeaderTitleInSection:section];
    headerLabel.backgroundColor = [UIColor clearColor];
    sectionHeader.headerLabel = headerLabel;

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
                    sectionBitwise = CONTACTSDATASOURCE_USERDIRECTORY_BITWISE;
                }
            }
        }
    }
    
    if (sectionBitwise)
    {
        // Add shrink button
        UIButton *shrinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        shrinkButton.backgroundColor = [UIColor clearColor];
        [shrinkButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        shrinkButton.tag = sectionBitwise;
        sectionHeader.topSpanningView = shrinkButton;
        sectionHeader.userInteractionEnabled = YES;
        
        // Add shrink icon
        UIImage *chevron;
        if (shrinkedSectionsBitMask & sectionBitwise)
        {
            chevron = AssetImages.disclosureIcon.image;
        }
        else
        {
            chevron = AssetImages.shrinkIcon.image;
        }
        UIImageView *chevronView = [[UIImageView alloc] initWithImage:chevron];
        chevronView.tintColor = ThemeService.shared.theme.textSecondaryColor;
        chevronView.contentMode = UIViewContentModeCenter;
        sectionHeader.accessoryView = chevronView;
    }
    
    if (section == filteredLocalContactsSection && !(shrinkedSectionsBitMask & CONTACTSDATASOURCE_LOCALCONTACTS_BITWISE))
    {
        if (!localContactsCheckboxContainer)
        {
            localContactsCheckboxContainer = [[LocalContactsSectionHeaderContainerView alloc] initWithFrame:CGRectZero];
            localContactsCheckboxContainer.backgroundColor = [UIColor clearColor];

            // Add Checkbox and Label
            localContactsCheckbox = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
            [localContactsCheckboxContainer addSubview:localContactsCheckbox];
            localContactsCheckboxContainer.checkboxView = localContactsCheckbox;
            
            checkboxLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 30)];
            checkboxLabel.font = [UIFont systemFontOfSize:16.0];
            checkboxLabel.text = [VectorL10n contactsAddressBookMatrixUsersToggle];
            [localContactsCheckboxContainer addSubview:checkboxLabel];
            localContactsCheckboxContainer.checkboxLabel = checkboxLabel;
            
            UIView *checkboxMask = [[UIView alloc] initWithFrame:CGRectZero];
            checkboxMask.translatesAutoresizingMaskIntoConstraints = NO;
            [localContactsCheckboxContainer addSubview:checkboxMask];
            localContactsCheckboxContainer.maskView = checkboxMask;

            // Listen to check box tap
            checkboxMask.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCheckBoxTap:)];
            [tapGesture setNumberOfTouchesRequired:1];
            [tapGesture setNumberOfTapsRequired:1];
            [tapGesture setDelegate:self];
            [checkboxMask addGestureRecognizer:tapGesture];
        }
        
        // Apply UI theme
        checkboxLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
        
        // Set the right value of the tick box
        localContactsCheckbox.image = hideNonMatrixEnabledContacts ? AssetImages.selectionTick.image : AssetImages.selectionUntick.image;
        localContactsCheckbox.tintColor = ThemeService.shared.theme.tintColor;
        
        // Add the check box container
        sectionHeader.bottomView = localContactsCheckboxContainer;
    }
    
    return sectionHeader;
}

- (UIView *)viewForStickyHeaderInSection:(NSInteger)section withFrame:(CGRect)frame inTableView:(UITableView *)tableView
{
    // Return the section header used when the section is shrinked
    NSInteger savedShrinkedSectionsBitMask = shrinkedSectionsBitMask;
    shrinkedSectionsBitMask = CONTACTSDATASOURCE_LOCALCONTACTS_BITWISE | CONTACTSDATASOURCE_USERDIRECTORY_BITWISE;
    
    UIView *stickyHeader = [self viewForHeaderInSection:section withFrame:frame inTableView:tableView];
    
    shrinkedSectionsBitMask = savedShrinkedSectionsBitMask;
    
    return stickyHeader;
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
