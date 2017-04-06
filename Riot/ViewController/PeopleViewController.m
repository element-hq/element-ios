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

#import "PeopleViewController.h"

#import "UIViewController+RiotSearch.h"

#import "RageShakeManager.h"

#import "AppDelegate.h"

#import "RecentTableViewCell.h"
#import "InviteRecentTableViewCell.h"

#define CONTACTS_TABLEVC_DEFAULT_SECTION_HEADER_HEIGHT 30.0
#define CONTACTS_TABLEVC_LOCALCONTACTS_SECTION_HEADER_HEIGHT 65.0

@interface PeopleViewController ()
{
    RecentsDataSource *directRoomsSource;
    NSInteger          directRoomsSectionNumber;
    
//    // Search processing
//    dispatch_queue_t searchProcessingQueue;
//    NSUInteger searchProcessingCount;
//    NSString *searchProcessingText;
//    NSMutableArray<MXKContact*> *searchProcessingLocalContacts;
//    NSMutableArray<MXKContact*> *searchProcessingMatrixContacts;
//    
//    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
//    id kAppDelegateDidTapStatusBarNotificationObserver;
//    
//    BOOL forceSearchResultRefresh;
//    
//    // This dictionary tells for each display name whether it appears several times.
//    NSMutableDictionary <NSString*,NSNumber*> *isMultiUseNameByDisplayName;
//    
//    // Shrinked sections.
//    NSInteger shrinkedSectionsBitMask;
//    
    UIView *localContactsCheckboxContainer;
    UIImageView *localContactsCheckbox;
}

@end

@implementation PeopleViewController

#pragma mark - Class methods

//+ (UINib *)nib
//{
//    return [UINib nibWithNibName:NSStringFromClass([PeopleViewController class])
//                          bundle:[NSBundle bundleForClass:[PeopleViewController class]]];
//}
//
//+ (instancetype)contactsTableViewController
//{
//    return [[[self class] alloc] initWithNibName:NSStringFromClass([PeopleViewController class])
//                                          bundle:[NSBundle bundleForClass:[PeopleViewController class]]];
//}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    directRoomsSectionNumber = 0;
    
    self.screenName = @"People";
    
    self.contactCellAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.accessibilityIdentifier = @"PeopleVCView";
    self.tableView.accessibilityIdentifier = @"PeopleVCTableView";
    
    [self.tableView registerClass:RecentTableViewCell.class forCellReuseIdentifier:RecentTableViewCell.defaultReuseIdentifier];
    [self.tableView registerClass:InviteRecentTableViewCell.class forCellReuseIdentifier:InviteRecentTableViewCell.defaultReuseIdentifier];
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 50)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)destroy
{
    localContactsCheckboxContainer = nil;
    localContactsCheckbox = nil;
    
    [super destroy];
}

- (void)addMatrixSession:(MXSession *)mxSession
{
    [super addMatrixSession:mxSession];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [AppDelegate theDelegate].masterTabBarController.navigationItem.title = NSLocalizedStringFromTable(@"title_people", @"Vector", nil);
    
    // Take the lead on the shared data source.
    directRoomsSource.areSectionsShrinkable = NO;
    [directRoomsSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModePeople];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

#pragma mark -

- (void)displayDirectRooms:(RecentsDataSource*)directRoomsDataSource;
{
    // Cancel registration on existing dataSource if any
    if (directRoomsSource)
    {
        directRoomsSource.delegate = nil;
        
        // Remove associated matrix sessions
        NSArray *mxSessions = self.mxSessions;
        for (MXSession *mxSession in mxSessions)
        {
            [self removeMatrixSession:mxSession];
        }
    }
    
    directRoomsSource = directRoomsDataSource;
    directRoomsSource.delegate = self;
    
    // Report all matrix sessions at view controller level to update UI according to sessions state
    NSArray *mxSessions = directRoomsSource.mxSessions;
    for (MXSession *mxSession in mxSessions)
    {
        [self addMatrixSession:mxSession];
    }
    
    [self refreshTableView];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    id<MXKRecentCellDataStoring> cellDataStoring = (id<MXKRecentCellDataStoring> )cellData;
    
    if (NSNotFound == [cellDataStoring.recentsDataSource.mxSession.invitedRooms indexOfObject:cellDataStoring.roomSummary.room])
    {
        return RecentTableViewCell.class;
    }
    else
    {
        return InviteRecentTableViewCell.class;
    }
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    id<MXKRecentCellDataStoring> cellDataStoring = (id<MXKRecentCellDataStoring> )cellData;
    
    if (NSNotFound == [cellDataStoring.recentsDataSource.mxSession.invitedRooms indexOfObject:cellDataStoring.roomSummary.room])
    {
        return RecentTableViewCell.defaultReuseIdentifier;
    }
    else
    {
        return InviteRecentTableViewCell.defaultReuseIdentifier;
    }
}

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    if (dataSource == directRoomsSource)
    {
        // Retrieve the new number of sections related to direct rooms
        NSInteger sectionNb = [directRoomsSource numberOfSectionsInTableView:self.tableView];
        
        if (directRoomsSectionNumber == sectionNb)
        {
            // Refresh the sections related to the direct rooms in the table view
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, directRoomsSectionNumber)];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
        }
        else if (directRoomsSectionNumber < sectionNb)
        {
            // Refresh the sections related to the direct rooms in the table view
            [self.tableView beginUpdates];
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, directRoomsSectionNumber)];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
            indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(directRoomsSectionNumber, (sectionNb - directRoomsSectionNumber))];
            [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
        }
        else
        {
            // Refresh the sections related to the direct rooms in the table view
            [self.tableView beginUpdates];
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, sectionNb)];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
            indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(sectionNb, (directRoomsSectionNumber - sectionNb))];
            [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
        }
        
        directRoomsSectionNumber = sectionNb;
    }
}

- (void)dataSource:(MXKDataSource *)dataSource didAddMatrixSession:(MXSession *)mxSession
{
    [self addMatrixSession:mxSession];
}

- (void)dataSource:(MXKDataSource *)dataSource didRemoveMatrixSession:(MXSession *)mxSession
{
    [self removeMatrixSession:mxSession];
}

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo
{
    // Handle here user actions on recents for Riot app
    if ([actionIdentifier isEqualToString:kInviteRecentTableViewCellPreviewButtonPressed])
    {
        // Retrieve the invited room
        MXRoom *invitedRoom = userInfo[kInviteRecentTableViewCellRoomKey];
        
        // Display room preview by selecting it.
        [[AppDelegate theDelegate].masterTabBarController selectRoomWithId:invitedRoom.state.roomId andEventId:nil inMatrixSession:invitedRoom.mxSession];
    }
    else if ([actionIdentifier isEqualToString:kInviteRecentTableViewCellDeclineButtonPressed])
    {
        // Retrieve the invited room
        MXRoom *invitedRoom = userInfo[kInviteRecentTableViewCellRoomKey];
        
        [self setEditing:NO];
        
        // Decline the invitation
        [invitedRoom leave:^{
            
            [self refreshTableView];
            
        } failure:^(NSError *error) {
            
            NSLog(@"[PeopleViewController] Failed to reject an invited room (%@)", invitedRoom.state.roomId);
            
        }];
    }
}

#pragma mark -

- (void)searchWithPattern:(NSString *)searchText forceReset:(BOOL)forceRefresh complete:(void (^)())complete
{
//    // Update search results.
//    searchText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//    
//    searchProcessingCount++;
//    [self startActivityIndicator];
//    
//    dispatch_async(searchProcessingQueue, ^{
//        
//        if (!searchText.length)
//        {
//            searchProcessingLocalContacts = nil;
//            searchProcessingMatrixContacts = nil;
//            
//            // Disclose by default the sections if a search was in progress.
//            if (searchProcessingText.length)
//            {
//                shrinkedSectionsBitMask = 0;
//            }
//        }
//        else if (forceRefresh || !searchProcessingText.length || [searchText hasPrefix:searchProcessingText] == NO)
//        {
//            // Retrieve all the local contacts
//            searchProcessingLocalContacts = [self unfilteredLocalContactsArray];
//            
//            // Retrieve all known matrix users
//            searchProcessingMatrixContacts = [self unfilteredMatrixContactsArray];
//            
//            // Disclose the sections
//            shrinkedSectionsBitMask = 0;
//        }
//        
//        for (NSUInteger index = 0; index < searchProcessingLocalContacts.count;)
//        {
//            MXKContact* contact = searchProcessingLocalContacts[index];
//            
//            if (![contact hasPrefix:searchText])
//            {
//                [searchProcessingLocalContacts removeObjectAtIndex:index];
//            }
//            else
//            {
//                // Next
//                index++;
//            }
//        }
//        
//        for (NSUInteger index = 0; index < searchProcessingMatrixContacts.count;)
//        {
//            MXKContact* contact = searchProcessingMatrixContacts[index];
//            
//            if (![contact hasPrefix:searchText])
//            {
//                [searchProcessingMatrixContacts removeObjectAtIndex:index];
//            }
//            else
//            {
//                // Next
//                index++;
//            }
//        }
//        
//        // Sort the refreshed list of the invitable contacts
//        [[MXKContactManager sharedManager] sortAlphabeticallyContacts:searchProcessingLocalContacts];
//        [[MXKContactManager sharedManager] sortContactsByLastActiveInformation:searchProcessingMatrixContacts];
//        
//        searchProcessingText = searchText;
//        
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            
//            // Sanity check: check whether self has been destroyed.
//            if (!searchProcessingQueue)
//            {
//                return;
//            }
//            
//            // Render the search result only if there is no other search in progress.
//            searchProcessingCount --;
//            
//            if (!searchProcessingCount)
//            {
//                if (!forceSearchResultRefresh)
//                {
//                    [self stopActivityIndicator];
//                    
//                    // Scroll the resulting list to the top only when the search pattern has been modified.
//                    BOOL shouldScrollToTop = (currentSearchText != searchProcessingText);
//                    
//                    // Update the filtered contacts.
//                    currentSearchText = searchProcessingText;
//                    filteredLocalContacts = searchProcessingLocalContacts;
//                    filteredMatrixContacts = searchProcessingMatrixContacts;
//                    
//                    if (!self.forceMatrixIdInDisplayName)
//                    {
//                        [isMultiUseNameByDisplayName removeAllObjects];
//                        for (MXKContact* contact in filteredMatrixContacts)
//                        {
//                            isMultiUseNameByDisplayName[contact.displayName] = (isMultiUseNameByDisplayName[contact.displayName] ? @(YES) : @(NO));
//                        }
//                    }
//                    
//                    // Refresh display
//                    [self refreshTableView];
//                    
//                    if (shouldScrollToTop)
//                    {
//                        // Scroll to the top
//                        [self.tableView setContentOffset:CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top) animated:NO];
//                    }
//                    
//                    if (complete)
//                    {
//                        complete();
//                    }
//                }
//                else
//                {
//                    // Launch a new search
//                    forceSearchResultRefresh = NO;
//                    [self searchWithPattern:searchProcessingText forceReset:YES complete:complete];
//                }
//            }
//        });
//        
//    });
}

- (void)refreshTableView
{
    [self.tableView reloadData];
    
    // Update the current number of sections related to the direct rooms
    directRoomsSectionNumber = [directRoomsSource numberOfSectionsInTableView:self.tableView];
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Retrieve the number of sections related to direct rooms
    NSInteger count = [directRoomsSource numberOfSectionsInTableView:self.tableView];
    
    // Prepare contacts lists
    [super numberOfSectionsInTableView:tableView];
    
    // Ignore search input
    searchInputSection = -1;
    
    // Keep visible the header for the contact sections, even if their are empty.
    filteredLocalContactsSection = count++;
    filteredMatrixContactsSection = count++;
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section < filteredLocalContactsSection)
    {
        count = [directRoomsSource tableView:tableView numberOfRowsInSection:section];
    }
    else if (section == filteredLocalContactsSection)
    {
        count = filteredLocalContacts.count;
    }
    else if (section == filteredMatrixContactsSection)
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
    if (indexPath.section < filteredLocalContactsSection)
    {
        return [directRoomsSource tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section < filteredLocalContactsSection)
    {
        return [directRoomsSource tableView:tableView canEditRowAtIndexPath:indexPath];
    }
    return NO;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == filteredLocalContactsSection)
    {
        return CONTACTS_TABLEVC_LOCALCONTACTS_SECTION_HEADER_HEIGHT;
    }
    
    return CONTACTS_TABLEVC_DEFAULT_SECTION_HEADER_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* sectionHeader;
    
    CGFloat height = [self tableView:tableView heightForHeaderInSection:section];
    if (height != 0)
    {
        sectionHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, height)];
        sectionHeader.backgroundColor = kRiotColorLightGrey;
        
        CGRect frame = sectionHeader.frame;
        frame.origin.x = 20;
        frame.origin.y = 5;
        frame.size.width = sectionHeader.frame.size.width - 10;
        frame.size.height = 20;
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
        headerLabel.font = [UIFont boldSystemFontOfSize:15.0];
        headerLabel.backgroundColor = [UIColor clearColor];
        [sectionHeader addSubview:headerLabel];
        
        if (section < filteredLocalContactsSection)
        {
            if (section == (filteredLocalContactsSection - 1))
            {
                headerLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"people_conversation_section", @"Vector", nil), [directRoomsSource tableView:self.tableView numberOfRowsInSection:section]];
            }
            else
            {
                headerLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"people_invites_section", @"Vector", nil), [directRoomsSource tableView:self.tableView numberOfRowsInSection:section]];
            }
        }
        else if (section == filteredLocalContactsSection)
        {
            headerLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"people_address_book_section", @"Vector", nil), filteredLocalContacts.count];
        }
        else if (section == filteredMatrixContactsSection)
        {
            if (currentSearchText.length)
            {
                headerLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"people_matrix_users_section", @"Vector", nil), filteredMatrixContacts.count];
            }
            else
            {
                headerLabel.text = NSLocalizedStringFromTable(@"people_matrix_users_default_section", @"Vector", nil);
            }
        }
        
        if (section == filteredLocalContactsSection)
        {
            NSLayoutConstraint *leadingConstraint, *trailingConstraint, *topConstraint, *bottomConstraint;
            NSLayoutConstraint *widthConstraint, *heightConstraint, *centerYConstraint;
            
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
                checkboxLabel.textColor = kRiotTextColorBlack;
                checkboxLabel.font = [UIFont systemFontOfSize:16.0];
                checkboxLabel.text = NSLocalizedStringFromTable(@"people_address_book_matrix_users_toggle", @"Vector", nil);
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
    if (indexPath.section < filteredLocalContactsSection)
    {
        return [directRoomsSource cellHeightAtIndexPath:indexPath];
    }
    
    return 74.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section < filteredLocalContactsSection)
    {
        // Open the room
        id<MXKRecentCellDataStoring> cellData = [directRoomsSource cellDataAtIndexPath:indexPath];
        
        [[AppDelegate theDelegate].masterTabBarController selectRoomWithId:cellData.roomSummary.roomId andEventId:nil inMatrixSession:cellData.roomSummary.room.mxSession];
    }
    else
    {
        NSInteger row = indexPath.row;
        MXKContact *mxkContact;
        
        if (indexPath.section == filteredLocalContactsSection)
        {
            mxkContact = filteredLocalContacts[row];
        }
        else if (indexPath.section == filteredMatrixContactsSection)
        {
            mxkContact = filteredMatrixContacts[row];
        }
        
        if (mxkContact)
        {
            [[AppDelegate theDelegate].masterTabBarController selectContact:mxkContact];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISearchBar delegate

//- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
//{
//    [self searchWithPattern:searchText forceReset:NO complete:nil];
//}
//
//- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
//{
//    // "Done" key has been pressed.
//    
//    // Check whether the current search input is a valid email or a Matrix user ID
//    if (currentSearchText.length && ([MXTools isEmailAddress:currentSearchText] || [MXTools isMatrixUserIdentifier:currentSearchText]))
//    {
//        // Select the contact related to the search input, rather than having to hit +
//        if (searchInputSection != -1)
//        {
//            [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:searchInputSection]];
//            return;
//        }
//        
//    }
//    
//    // Dismiss keyboard
//    [searchBar resignFirstResponder];
//}
//
//- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
//{
//    searchBar.text = nil;
//    
//    // Reset filtering
//    [self searchWithPattern:nil forceReset:NO complete:nil];
//    
//    // Leave search
//    [searchBar resignFirstResponder];
//    
//    [self withdrawViewControllerAnimated:YES completion:nil];
//}

@end
