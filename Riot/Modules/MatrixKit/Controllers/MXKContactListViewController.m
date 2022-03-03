/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "MXKContactListViewController.h"

#import "MXKSectionedContacts.h"

#import "NSBundle+MatrixKit.h"

#import "MXKSwiftHeader.h"

@interface MXKContactListViewController ()
{
    // YES -> only matrix users
    // NO -> display local contacts
    BOOL displayMatrixUsers;
    
    // screenshot of the local contacts
    NSArray* localContactsArray;
    MXKSectionedContacts* sectionedLocalContacts;
    
    // screenshot of the matrix users
    NSArray* matrixContactsArray;
    MXKSectionedContacts* sectionedMatrixContacts;
    
    // Search
    UIBarButtonItem *searchButton;
    UISearchBar     *contactsSearchBar;
    NSMutableArray  *filteredContacts;
    MXKSectionedContacts* sectionedFilteredContacts;
    BOOL             searchBarShouldEndEditing;
    BOOL             ignoreSearchRequest;
    NSString* latestSearchedPattern;
    
    NSArray* collationTitles;
    
    // mask view while processing a request
    UIActivityIndicatorView * pendingMaskSpinnerView;
}

@end

@implementation MXKContactListViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKContactListViewController class])
                          bundle:[NSBundle bundleForClass:[MXKContactListViewController class]]];
}

+ (instancetype)contactListViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([MXKContactListViewController class])
                                          bundle:[NSBundle bundleForClass:[MXKContactListViewController class]]];
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    _enableBarButtonSearch = YES;
    
    // get the system collation titles
    collationTitles = [[UILocalizedIndexedCollation currentCollation] sectionTitles];
}

- (void)dealloc
{
    searchButton = nil;
}

- (void)destroy
{
    [self removePendingActionMask];
    
    [super destroy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Check whether the view controller has been pushed via storyboard
    if (!_contactsControls)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    // global init
    displayMatrixUsers = (0 == self.contactsControls.selectedSegmentIndex);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactsRefresh:) name:kMXKContactManagerDidUpdateMatrixContactsNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactsRefresh:) name:kMXKContactManagerDidUpdateLocalContactsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactsRefresh:) name:kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification object:nil];
    
    if (!_contactTableViewCellClass)
    {
        // Set default table view cell class
        self.contactTableViewCellClass = [MXKContactTableCell class];
    }
    
    // Localize string
    [_contactsControls setTitle:[VectorL10n contactMxUsers] forSegmentAtIndex:0];
    [_contactsControls setTitle:[VectorL10n contactLocalContacts] forSegmentAtIndex:1];
    
    // Apply search option in navigation bar
    self.enableBarButtonSearch = _enableBarButtonSearch;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Restore search mechanism (if enabled)
    ignoreSearchRequest = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // The user may still press search button whereas the view disappears
    ignoreSearchRequest = YES;
    
    // Leave potential search session
    if (contactsSearchBar)
    {
        [self searchBarCancelButtonClicked:contactsSearchBar];
    }
}

- (void)scrollToTop
{
    // stop any scrolling effect
    [UIView setAnimationsEnabled:NO];
    // before scrolling to the tableview top
    self.tableView.contentOffset = CGPointMake(-self.tableView.adjustedContentInset.left, -self.tableView.adjustedContentInset.top);
    [UIView setAnimationsEnabled:YES];
}

#pragma mark -

-(void)setContactTableViewCellClass:(Class)contactTableViewCellClass
{
    // Sanity check: accept only MXKContactTableCell classes or sub-classes
    NSParameterAssert([contactTableViewCellClass isSubclassOfClass:MXKContactTableCell.class]);
    
    _contactTableViewCellClass = contactTableViewCellClass;
    [self.tableView registerClass:contactTableViewCellClass forCellReuseIdentifier:[contactTableViewCellClass defaultReuseIdentifier]];
}

- (void)setEnableBarButtonSearch:(BOOL)enableBarButtonSearch
{
    _enableBarButtonSearch = enableBarButtonSearch;
    
    if (enableBarButtonSearch)
    {
        if (!searchButton)
        {
            searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(search:)];
        }
        
        // Add it in right bar items
        NSArray *rightBarButtonItems = self.navigationItem.rightBarButtonItems;
        self.navigationItem.rightBarButtonItems = rightBarButtonItems ? [rightBarButtonItems arrayByAddingObject:searchButton] : @[searchButton];
    }
    else
    {
        NSMutableArray *rightBarButtonItems = [NSMutableArray arrayWithArray: self.navigationItem.rightBarButtonItems];
        [rightBarButtonItems removeObject:searchButton];
        self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    }
}

#pragma mark - Internals

- (void)updateSectionedLocalContacts:(BOOL)force
{
    [self stopActivityIndicator];
    
    MXKContactManager* sharedManager = [MXKContactManager sharedManager];
    
    if (force || !localContactsArray)
    {
        localContactsArray = sharedManager.localContacts;
        sectionedLocalContacts = [sharedManager getSectionedContacts:localContactsArray];
    }
}

- (void)updateSectionedMatrixContacts:(BOOL)force
{
    [self stopActivityIndicator];
    
    MXKContactManager* sharedManager = [MXKContactManager sharedManager];
    
    if (force || !matrixContactsArray)
    {
        matrixContactsArray = sharedManager.matrixContacts;
        sectionedMatrixContacts = [sharedManager getSectionedContacts:matrixContactsArray];
    }
}

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

#pragma mark - UITableView dataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionNb;
    
    // search in progress
    if (contactsSearchBar)
    {
        sectionNb = sectionedFilteredContacts.sectionedContacts.count;
        if (!sectionNb)
        {
            // Keep at least one section to display the search bar
            sectionNb = 1;
        }
    }
    else if (displayMatrixUsers)
    {
        [self updateSectionedMatrixContacts:NO];
        sectionNb = sectionedMatrixContacts.sectionedContacts.count;
        
    }
    else
    {
        [self updateSectionedLocalContacts:NO];
        sectionNb = sectionedLocalContacts.sectionedContacts.count;
    }
    
    return sectionNb;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    MXKSectionedContacts* sectionedContacts = contactsSearchBar ? sectionedFilteredContacts : (displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts);
    
    if (section < sectionedContacts.sectionedContacts.count)
    {
        return [sectionedContacts.sectionedContacts[section] count];
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section
{
    if (contactsSearchBar)
    {
        // Hide section titles during search session
        return nil;
    }
    
    MXKSectionedContacts* sectionedContacts = displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts;
    if (section < sectionedContacts.sectionTitles.count)
    {
        return (NSString*)[sectionedContacts.sectionTitles objectAtIndex:section];
    }
    
    return nil;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)aTableView
{
    // do not display the collation during a search
    if (contactsSearchBar)
    {
        return nil;
    }
    
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)aTableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    MXKSectionedContacts* sectionedContacts = displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts;
    NSInteger section = [sectionedContacts.sectionTitles indexOfObject:title];
    
    // undefined title -> jump to the first valid non empty section
    if (NSNotFound == section)
    {
        NSInteger systemCollationIndex = [collationTitles indexOfObject:title];
        
        // find in the system collation
        if (NSNotFound != systemCollationIndex)
        {
            systemCollationIndex--;
            
            while ((systemCollationIndex >= 0) && (NSNotFound == section))
            {
                NSString* systemTitle = [collationTitles objectAtIndex:systemCollationIndex];
                section = [sectionedContacts.sectionTitles indexOfObject:systemTitle];
                systemCollationIndex--;
            }
        }
    }
    
    return section;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MXKContactTableCell* cell = [tableView dequeueReusableCellWithIdentifier:[_contactTableViewCellClass defaultReuseIdentifier] forIndexPath:indexPath];
    cell.thumbnailDisplayBoxType = MXKTableViewCellDisplayBoxTypeCircle;
    
    MXKSectionedContacts* sectionedContacts = contactsSearchBar ? sectionedFilteredContacts : (displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts);
    
    MXKContact* contact = nil;
    
    if (indexPath.section < sectionedContacts.sectionedContacts.count)
    {
        NSArray *thisSection = [sectionedContacts.sectionedContacts objectAtIndex:indexPath.section];
        
        if (indexPath.row < thisSection.count)
        {
            contact = [thisSection objectAtIndex:indexPath.row];
        }
    }
    
    if (contact)
    {
        cell.contactAccessoryViewType = MXKContactTableCellAccessoryMatrixIcon;
        [cell render:contact];
        cell.delegate = self;
    }
    
    return cell;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MXKSectionedContacts* sectionedContacts = contactsSearchBar ? sectionedFilteredContacts : (displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts);
    
    MXKContact* contact = nil;
    
    if (indexPath.section < sectionedContacts.sectionedContacts.count)
    {
        NSArray *thisSection = [sectionedContacts.sectionedContacts objectAtIndex:indexPath.section];
        
        if (indexPath.row < thisSection.count)
        {
            contact = [thisSection objectAtIndex:indexPath.row];
        }
    }
    
    return [((Class<MXKCellRendering>)_contactTableViewCellClass) heightForCellData:contact withMaximumWidth:tableView.frame.size.width];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // In case of search, the section titles are hidden and the search bar is displayed in first section header.
    if (contactsSearchBar)
    {
        if (section == 0)
        {
            return contactsSearchBar.frame.size.height;
        }
        return 0;
    }
    
    // Default section header height
    return 22;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (contactsSearchBar && section == 0)
    {
        return contactsSearchBar;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MXKSectionedContacts* sectionedContacts = contactsSearchBar ? sectionedFilteredContacts : (displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts);
    
    MXKContact* contact = nil;
    
    if (indexPath.section < sectionedContacts.sectionedContacts.count)
    {
        NSArray *thisSection = [sectionedContacts.sectionedContacts objectAtIndex:indexPath.section];
        
        if (indexPath.row < thisSection.count)
        {
            contact = [thisSection objectAtIndex:indexPath.row];
        }
    }
    
    if (self.delegate) {
        [self.delegate contactListViewController:self didSelectContact:contact.contactID];
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    // Release here resources, and restore reusable cells
    if ([cell respondsToSelector:@selector(didEndDisplay)])
    {
        [(id<MXKCellRendering>)cell didEndDisplay];
    }
}

#pragma mark - Actions

- (void)onContactsRefresh:(NSNotification *)notif
{
    if ([notif.name isEqualToString:kMXKContactManagerDidUpdateMatrixContactsNotification])
    {
        [self updateSectionedMatrixContacts:YES];
    }
    else if ([notif.name isEqualToString:kMXKContactManagerDidUpdateLocalContactsNotification])
    {
        [self updateSectionedLocalContacts:YES];
    }
    else //if ([notif.name isEqualToString:kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification])
    {
        // Consider here only global notifications, ignore notifications related to a specific contact.
        if (notif.object)
        {
            return;
        }
        
        [self updateSectionedLocalContacts:YES];
    }
    
    if (contactsSearchBar)
    {
        latestSearchedPattern = nil;
        [self searchBar:contactsSearchBar textDidChange:contactsSearchBar.text];
    }
    else
    {
        [self.tableView reloadData];
    }
}

- (IBAction)onSegmentValueChange:(id)sender
{
    if (sender == self.contactsControls)
    {
        displayMatrixUsers = (0 == self.contactsControls.selectedSegmentIndex);
        
        // Leave potential search session
        if (contactsSearchBar)
        {
            [self searchBarCancelButtonClicked:contactsSearchBar];
        }
        
        [self.tableView reloadData];
    }
}

#pragma mark Search management

- (void)search:(id)sender
{
    // The user may have pressed search button whereas the view controller was disappearing
    if (ignoreSearchRequest)
    {
        return;
    }
    
    if (!contactsSearchBar)
    {
        MXKSectionedContacts* sectionedContacts = displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts;
        
        // Check whether there are data in which search
        if (sectionedContacts.sectionedContacts.count > 0)
        {
            // Create search bar
            contactsSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
            contactsSearchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            contactsSearchBar.showsCancelButton = YES;
            contactsSearchBar.returnKeyType = UIReturnKeyDone;
            contactsSearchBar.delegate = self;
            searchBarShouldEndEditing = NO;
            
            // init the table content
            latestSearchedPattern = @"";
            filteredContacts = [(displayMatrixUsers ? matrixContactsArray : localContactsArray) mutableCopy];
            sectionedFilteredContacts = [[MXKContactManager sharedManager] getSectionedContacts:filteredContacts];
            
            [self.tableView reloadData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->contactsSearchBar becomeFirstResponder];
            });
        }
    }
    else
    {
        [self searchBarCancelButtonClicked:contactsSearchBar];
    }
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    searchBarShouldEndEditing = NO;
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    return searchBarShouldEndEditing;
}

- (NSArray*)patternsFromText:(NSString*)text
{
    NSArray* items = [text componentsSeparatedByString:@" "];
    
    if (items.count <= 1)
    {
        return items;
    }
    
    NSMutableArray* patterns = [[NSMutableArray alloc] init];
    
    for (NSString* item in items)
    {
        if (item.length > 0)
        {
            [patterns addObject:item];
        }
    }
    
    return patterns;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ((contactsSearchBar == searchBar) && (![latestSearchedPattern isEqualToString:searchText]))
    {
        latestSearchedPattern = searchText;
        
        // contacts
        NSArray* contacts = displayMatrixUsers ? matrixContactsArray : localContactsArray;
        
        // Update filtered list
        if (searchText.length && contacts.count)
        {
            filteredContacts = [[NSMutableArray alloc] init];
            
            NSArray* patterns = [self patternsFromText:searchText];
            for(MXKContact* contact in contacts)
            {
                if ([contact matchedWithPatterns:patterns])
                {
                    [filteredContacts addObject:contact];
                }
            }
        }
        else
        {
            filteredContacts = [contacts mutableCopy];
        }
        
        sectionedFilteredContacts = [[MXKContactManager sharedManager] getSectionedContacts:filteredContacts];
        
        // Refresh display
        [self.tableView reloadData];
        [self scrollToTop];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if (contactsSearchBar == searchBar)
    {
        // "Done" key has been pressed
        searchBarShouldEndEditing = YES;
        [contactsSearchBar resignFirstResponder];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if (contactsSearchBar == searchBar)
    {
        // Leave search
        searchBarShouldEndEditing = YES;
        [contactsSearchBar resignFirstResponder];
        [contactsSearchBar removeFromSuperview];
        contactsSearchBar = nil;
        filteredContacts = nil;
        sectionedFilteredContacts = nil;
        latestSearchedPattern = nil;
        [self.tableView reloadData];
        [self scrollToTop];
    }
}

#pragma mark - MXKCellRendering delegate

- (void)cell:(id<MXKCellRendering>)cell didRecognizeAction:(NSString*)actionIdentifier userInfo:(NSDictionary *)userInfo
{
    if ([actionIdentifier isEqualToString:kMXKContactCellTapOnThumbnailView])
    { 
        if (self.delegate) {
            [self.delegate contactListViewController:self didTapContactThumbnail:userInfo[kMXKContactCellContactIdKey]];
        }
    }
}

- (BOOL)cell:(id<MXKCellRendering>)cell shouldDoAction:(NSString *)actionIdentifier userInfo:(NSDictionary *)userInfo defaultValue:(BOOL)defaultValue
{
    // No such action yet on contacts
    return defaultValue;
}

@end
