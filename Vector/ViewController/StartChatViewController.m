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

#import "StartChatViewController.h"

#import "VectorDesignValues.h"

#import "RageShakeManager.h"

#import "AppDelegate.h"

#import "AvatarGenerator.h"

@interface StartChatViewController ()
{
    // Section indexes
    NSInteger participantsSection;
    NSInteger invitableSection;
    
    // The current list of participants.
    NSMutableArray<MXKContact*> *participants;
    
    // The contact used to describe the current user.
    MXKContact *userContact;
    
    // Navigation bar items
    UIBarButtonItem *cancelBarButtonItem;
    UIBarButtonItem *createBarButtonItem;
    
    // HTTP Request
    MXHTTPOperation *roomCreationRequest;
    
    // Search session
    NSString *currentSearchText;
    UIView* searchBarSeparator;
    
    // Search results
    NSMutableArray<MXKContact*> *invitableContacts;
    
    // Contact instances by matrix user id, or email address.
    NSMutableDictionary<NSString*, MXKContact*> *participantsById;
    
    // This dictionary tells for each display name whether it appears several times in participants list
    NSMutableDictionary <NSString*, NSNumber*> *isMultiUseNameByDisplayName;
    
    MXKAlert *currentAlert;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;
}

@end

@implementation StartChatViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([StartChatViewController class])
                          bundle:[NSBundle bundleForClass:[StartChatViewController class]]];
}

+ (instancetype)roomParticipantsViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([StartChatViewController class])
                                          bundle:[NSBundle bundleForClass:[StartChatViewController class]]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    _isAddParticipantSearchBarEditing = NO;
    
    // Prepare room participants
    participants = [NSMutableArray array];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Check whether the view controller has been pushed via storyboard
    if (!_tableView)
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
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"room_creation_title", @"Vector", nil);
    
    cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onButtonPressed:)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
    
    createBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"start", @"Vector", nil) style:UIBarButtonItemStylePlain target:self action:@selector(onButtonPressed:)];
    self.navigationItem.rightBarButtonItem = createBarButtonItem;
    
    // Add each matrix session, to update the view controller appearance according to mx sessions state
    NSArray *sessions = [AppDelegate theDelegate].mxSessions;
    for (MXSession *mxSession in sessions)
    {
        [self addMatrixSession:mxSession];
    }
    
    _searchBarView.placeholder = NSLocalizedStringFromTable(@"room_participants_invite_another_user", @"Vector", nil);
    _searchBarView.returnKeyType = UIReturnKeyDone;
    _searchBarView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self refreshSearchBarItemsColor:_searchBarView];
    
    _searchBarHeaderBorder.backgroundColor = kVectorColorSilver;
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    // FIXME: Handle multi accounts
    NSString *displayName = NSLocalizedStringFromTable(@"you", @"Vector", nil);
    userContact = [[MXKContact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:self.mainSession.myUser.userId];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)destroy
{
    if (roomCreationRequest)
    {
        [roomCreationRequest cancel];
        roomCreationRequest = nil;
    }
    
    cancelBarButtonItem = nil;
    createBarButtonItem = nil;
    
    invitableContacts = nil;
    
    participantsById = nil;
    
    isMultiUseNameByDisplayName = nil;
    
    participants = nil;
    userContact = nil;
    
    if (currentAlert)
    {
        [currentAlert dismiss:NO];
        currentAlert = nil;
    }
    
    [super destroy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:@"StartChat"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
    
    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.tableView setContentOffset:CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top) animated:YES];
        
    }];
    
    // Register on contact update
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableView) name:kMXKContactManagerDidUpdateMatrixContactsNotification object:nil];
    
    // Active the search session if the current participant list is empty
    if (!participants.count)
    {
        self.isAddParticipantSearchBarEditing = YES;
    }
    else
    {
        // Refresh display
        [self refreshTableView];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (currentAlert)
    {
        [currentAlert dismiss:NO];
        currentAlert = nil;
    }
 
    // cancel any pending search
    [self searchBarCancelButtonClicked:_searchBarView];
    
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKContactManagerDidUpdateMatrixContactsNotification object:nil];
}

#pragma mark -

- (void)setIsAddParticipantSearchBarEditing:(BOOL)isAddParticipantsSearchBarEditing
{
    if (_isAddParticipantSearchBarEditing != isAddParticipantsSearchBarEditing)
    {
        if (isAddParticipantsSearchBarEditing)
        {
            self.navigationItem.rightBarButtonItem = nil;
        }
        else
        {
            self.navigationItem.rightBarButtonItem = createBarButtonItem;
            
            [self refreshParticipants];
        }
        
        _isAddParticipantSearchBarEditing = isAddParticipantsSearchBarEditing;
        
        // Switch the display between search result and participants list
        [self refreshTableView];
    }
}

#pragma mark - Internals

- (void)refreshTableView
{
    [self.tableView reloadData];
}

- (void)refreshParticipants
{
    // Refer all participants in one dictionary.
    participantsById = [NSMutableDictionary dictionary];
    isMultiUseNameByDisplayName = [NSMutableDictionary dictionary];
    
    for (MXKContact* contact in participants)
    {
        if (contact.matrixIdentifiers.count)
        {
            // Here the contact can only have one identifer
            [participantsById setObject:contact forKey:contact.matrixIdentifiers.firstObject];
        }
        else
        {
            [participantsById setObject:contact forKey:contact.displayName];
            
        }
        isMultiUseNameByDisplayName[contact.displayName] = (isMultiUseNameByDisplayName[contact.displayName] ? @(YES) : @(NO));
    }
    
    [participantsById setObject:userContact forKey:self.mainSession.myUser.userId];
}

- (void)sortInvitableContacts
{
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
    
    // Sort invitable contacts list
    [invitableContacts sortUsingComparator:comparator];
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    
    invitableSection = participantsSection = -1;
    
    if (_isAddParticipantSearchBarEditing)
    {
        invitableSection = count++;
    }
    else
    {
        participantsSection = count++;
    }
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == invitableSection)
    {
        if (!currentSearchText.length)
        {
            // Display by default all the contacts who share a private room with the current user
            invitableContacts = [NSMutableArray arrayWithArray:[[MXKContactManager sharedManager] privateMatrixContacts:self.mainSession]];
            
            // Sort the refreshed list of the invitable contacts
            [self sortInvitableContacts];
        }
        
        count = invitableContacts.count;
    }
    else if (section == participantsSection)
    {
        count = participants.count + 1;
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactTableViewCell* participantCell = [tableView dequeueReusableCellWithIdentifier:[ContactTableViewCell defaultReuseIdentifier]];
    
    if (!participantCell)
    {
        participantCell = [[ContactTableViewCell alloc] init];
    }
    else
    {
        // Restore default values
        participantCell.accessoryView = nil;
        participantCell.contentView.alpha = 1;
        participantCell.userInteractionEnabled = YES;
    }
    
    MXKContact *contact;
    
    if (indexPath.section == participantsSection)
    {
        if (indexPath.row == 0)
        {
            // oneself dedicated cell
            contact = userContact;
        }
        else
        {
            NSInteger index = indexPath.row - 1;
            
            if (index < participants.count)
            {
                contact = participants[index];
                
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
            }
        }
        
        participantCell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else if (indexPath.section == invitableSection)
    {
        if (indexPath.row < invitableContacts.count)
        {
            contact = invitableContacts[indexPath.row];
            
            participantCell.selectionStyle = UITableViewCellSelectionStyleDefault;
            
            // Append the matrix identifier (if any) to the display name.
            NSArray *identifiers = contact.matrixIdentifiers;
            if (identifiers.count)
            {
                NSString *participantId = identifiers.firstObject;
                
                // Check whether the display name is not already the matrix id
                if (![contact.displayName isEqualToString:participantId])
                {
                    NSString *displayName = [NSString stringWithFormat:@"%@ (%@)", contact.displayName, participantId];
                    
                    contact = [[MXKContact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:participantId];
                }
            }
        }
    }
    
    if (contact)
    {
        [participantCell render:contact];
        
        // The search displays contacts to invite. Add a plus icon to the cell
        // in order to make it more understandable for the end user
        if (indexPath.section == invitableSection)
        {
            if (currentSearchText.length && indexPath.row == 0)
            {
                // This contact corresponds to the text entered by the user
                
                // Check whether this input is a valid email or a Matrix user ID before adding the plus icon.
                if (![MXTools isEmailAddress:currentSearchText] && ![MXTools isMatrixUserIdentifier:currentSearchText])
                {
                    participantCell.contentView.alpha = 0.5;
                    participantCell.userInteractionEnabled = NO;
                }
                else
                {
                    participantCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus_icon"]];
                }
            }
            else
            {
                participantCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus_icon"]];
            }
        }
    }
    
    return participantCell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == participantsSection && indexPath.row != 0)
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 74.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    if (indexPath.section == invitableSection)
    {
        if (row < invitableContacts.count)
        {
            MXKContact *mxkContact = invitableContacts[row];
            
            // Update here the mutable list of participants
            [participants addObject:mxkContact];
            
            // Refresh display by leaving search session
            [self searchBarCancelButtonClicked:_searchBarView];
            
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* actions;
    
    // add the swipe to delete only on participants sections
    if (indexPath.section == participantsSection && indexPath.row != 0)
    {
        actions = [[NSMutableArray alloc] init];
        
        // Patch: Force the width of the button by adding whitespace characters into the title string.
        UITableViewRowAction *leaveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"        "  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            
            [self onDeleteAt:indexPath];
        
        }];
        
        leaveAction.backgroundColor = [MXKTools convertImageToPatternColor:@"remove_icon" backgroundColor:kVectorColorLightGrey patternSize:CGSizeMake(74, 74) resourceSize:CGSizeMake(25, 24)];
        [actions insertObject:leaveAction atIndex:0];
    }
    
    return actions;
}

#pragma mark - Actions

- (void)onDeleteAt:(NSIndexPath*)path
{
    NSInteger row = path.row;
    row --;
    
    if (row < participants.count)
    {
        [participants removeObjectAtIndex:row];
        
        [self refreshParticipants];
        
        [self refreshTableView];
    }
}

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == createBarButtonItem)
    {
        // Disable button to prevent multiple request
        createBarButtonItem.enabled = NO;
        [self startActivityIndicator];
        
        // Prepare the invited participant data
        NSMutableArray *inviteArray = [NSMutableArray array];
        NSMutableArray *invite3PIDArray = [NSMutableArray array];
        
        // Check whether some users must be invited
        for (MXKContact *contact in participants)
        {
            NSArray *identifiers = contact.matrixIdentifiers;
            if (identifiers.count)
            {
                [inviteArray addObject:identifiers.firstObject];
            }
            else
            {
                // This is a text entered by the user, or a local email contact
                NSString *participantId = contact.displayName;
                
                // Is it an email or a Matrix user ID?
                if ([MXTools isEmailAddress:participantId])
                {
                    // The identity server must be defined
                    if (!self.mainSession.matrixRestClient.identityServer)
                    {
                        MXError *error = [[MXError alloc] initWithErrorCode:kMXSDKErrCodeStringMissingParameters error:@"No supplied identity server URL"];
                        NSLog(@"[StartChatViewController] Invite %@ failed", participantId);
                        // Alert user
                        [[AppDelegate theDelegate] showErrorAsAlert:[error createNSError]];
                        
                        continue;
                    }
                    
                    // The hostname of the identity server must not have the protocol part
                    NSString *identityServer = self.mainSession.matrixRestClient.identityServer;
                    if ([identityServer hasPrefix:@"http://"] || [identityServer hasPrefix:@"https://"])
                    {
                        identityServer = [identityServer substringFromIndex:[identityServer rangeOfString:@"://"].location + 3];
                    }
                    
                    MXInvite3PID *invite3PID = [[MXInvite3PID alloc] init];
                    invite3PID.identityServer = identityServer;
                    invite3PID.medium = @"email";
                    invite3PID.address = participantId;
                    
                    [invite3PIDArray addObject:invite3PID];
                }
                else
                {
                    [inviteArray addObject:participantId];
                }
            }
        }
        
        // Is it a direct chat?
        BOOL isDirect = ((inviteArray.count + invite3PIDArray.count == 1) ? YES : NO);
        
        // In case of a direct chat with only one user id, we open the first available direct chat
        // or creates a new one (if it doesn't exist).
        if (isDirect && inviteArray.count)
        {
            [[AppDelegate theDelegate] startDirectChatWithUserId:inviteArray.firstObject completion:^{
                
                [self stopActivityIndicator];
                
            }];
        }
        else
        {
            // Ensure direct chat are created with equal ops on both sides (the trusted_private_chat preset)
            MXRoomPreset preset = (isDirect ? kMXRoomPresetTrustedPrivateChat : nil);
            
            // Create new room
            roomCreationRequest = [self.mainSession createRoom:nil
                                                    visibility:kMXRoomDirectoryVisibilityPrivate
                                                     roomAlias:nil
                                                         topic:nil
                                                        invite:(inviteArray.count ? inviteArray : nil)
                                                    invite3PID:(invite3PIDArray.count ? invite3PIDArray : nil)
                                                      isDirect:isDirect
                                                        preset:preset
                                                       success:^(MXRoom *room) {
                                                           
                                                           roomCreationRequest = nil;
                                                           
                                                           [self stopActivityIndicator];
                                                           
                                                           [[AppDelegate theDelegate] showRoom:room.state.roomId andEventId:nil withMatrixSession:self.mainSession];
                                                           
                                                       } failure:^(NSError *error) {
                                                           
                                                           createBarButtonItem.enabled = YES;
                                                           
                                                           roomCreationRequest = nil;
                                                           [self stopActivityIndicator];
                                                           
                                                           NSLog(@"[StartChatViewController] Create room failed");
                                                           
                                                           // Alert user
                                                           [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                           
                                                       }];
        }
    }
    else if (sender == self.navigationItem.leftBarButtonItem)
    {
        // Cancel has been pressed
        if (_isAddParticipantSearchBarEditing && participants.count)
        {
            // Cancel the search process
            [self searchBarCancelButtonClicked:_searchBarView];
        }
        else
        {
            // Cancel the new chat creation
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

#pragma mark - UISearchBar delegate

- (void)refreshSearchBarItemsColor:(UISearchBar *)searchBar
{
    // bar tint color
    searchBar.barTintColor = searchBar.tintColor = kVectorColorGreen;
    searchBar.tintColor = kVectorColorGreen;
    
    // FIXME: this all seems incredibly fragile and tied to gutwrenching the current UISearchBar internals.

    // text color
    UITextField *searchBarTextField = [searchBar valueForKey:@"_searchField"];
    searchBarTextField.textColor = kVectorTextColorGray;
    
    // Magnifying glass icon.
    UIImageView *leftImageView = (UIImageView *)searchBarTextField.leftView;
    leftImageView.image = [leftImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    leftImageView.tintColor = kVectorColorGreen;
    
    // remove the gray background color
    UIView *effectBackgroundTop =  [searchBarTextField valueForKey:@"_effectBackgroundTop"];
    UIView *effectBackgroundBottom =  [searchBarTextField valueForKey:@"_effectBackgroundBottom"];
    effectBackgroundTop.hidden = YES;
    effectBackgroundBottom.hidden = YES;
        
    // place holder
    searchBarTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:searchBarTextField.placeholder
                                                                               attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                                                                            NSUnderlineColorAttributeName: kVectorColorGreen,
                                                                                            NSForegroundColorAttributeName: kVectorColorGreen}];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Update search results.
    NSMutableArray<MXKContact*> *contacts;
    
    searchText = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (currentSearchText.length && [searchText hasPrefix:currentSearchText])
    {
        contacts = invitableContacts;
    }
    else if (searchText.length)
    {
        // Retrieve all known matrix users
        NSArray *matrixContacts = [NSMutableArray arrayWithArray:[MXKContactManager sharedManager].matrixContacts];
        
        // Retrieve all known email addresses from local contacts
        NSArray *localEmailContacts = [MXKContactManager sharedManager].localEmailContacts;
        
        contacts = [NSMutableArray arrayWithCapacity:(matrixContacts.count + localEmailContacts.count)];
        
        // Add first email contacts
        for (MXKContact* contact in localEmailContacts)
        {
            // Remove the current emails listed in participants.
            if ([participantsById objectForKey:contact.displayName] == nil)
            {
                [contacts addObject:contact];
            }
        }
        
        // Matrix ids: split contacts with several ids, and remove the current participants.
        for (MXKContact* contact in matrixContacts)
        {
            NSArray *identifiers = contact.matrixIdentifiers;
            if (identifiers.count > 1)
            {
                for (NSString *userId in identifiers)
                {
                    if ([participantsById objectForKey:userId] == nil)
                    {
                        MXKContact *splitContact = [[MXKContact alloc] initMatrixContactWithDisplayName:contact.displayName andMatrixID:userId];
                        [contacts addObject:splitContact];
                    }
                }
            }
            else if (identifiers.count)
            {
                NSString *userId = identifiers.firstObject;
                if ([participantsById objectForKey:userId] == nil)
                {
                    [contacts addObject:contact];
                }
            }
        }
    }
    
    currentSearchText = searchText;
    
    // Check whether the search input is a valid email or a Matrix user ID
    BOOL isValidInput = ([MXTools isEmailAddress:currentSearchText] || [MXTools isMatrixUserIdentifier:currentSearchText]);
    
    // Update invitable contacts list:
    invitableContacts = [NSMutableArray array];
    
    for (MXKContact* contact in contacts)
    {
        if ([contact hasPrefix:currentSearchText])
        {
            // Ignore the contact if it corresponds to the search input
            if (!isValidInput || [contact.displayName isEqualToString:currentSearchText] == NO)
            {
                [invitableContacts addObject:contact];
            }
        }
    }
    
    // Sort the refreshed list of the invitable contacts
    [self sortInvitableContacts];
    
    if (currentSearchText.length)
    {
        // Show what the user is typing in a cell. So that he can click on it
        MXKContact *contact = [[MXKContact alloc] initMatrixContactWithDisplayName:searchText andMatrixID:nil];
        [invitableContacts insertObject:contact atIndex:0];
    }
    
    // Refresh display
    [self refreshTableView];
    
    // Force scroll to top
    [self.tableView setContentOffset:CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top) animated:YES];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    self.isAddParticipantSearchBarEditing = YES;
    searchBar.showsCancelButton = NO;
    
    // Handle here local contacts
#ifdef MX_USE_CONTACTS_SERVER_SYNC
    if (![MXKAppSettings standardAppSettings].syncLocalContacts)
    {
        // If not requested yet, ask user permission to sync their local contacts
        if (![MXKAppSettings standardAppSettings].syncLocalContacts && ![MXKAppSettings standardAppSettings].syncLocalContactsPermissionRequested)
        {
            [MXKAppSettings standardAppSettings].syncLocalContactsPermissionRequested = YES;
            
            [MXKContactManager requestUserConfirmationForLocalContactsSyncInViewController:self completionHandler:^(BOOL granted) {
                if (granted)
                {
                    // Allow local contacts sync in order to add address book emails in search result
                    [MXKAppSettings standardAppSettings].syncLocalContacts = YES;
                }
            }];
        }
    }
#else
    // If not requested yet, ask user permission to access their local contacts
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    {
        // Try to load the local contacts list
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[MXKContactManager sharedManager] loadLocalContacts];
            
        });
    }
#endif
    
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // "Done" key has been pressed.
    
    // Check whether the current search input is a valid email or a Matrix user ID
    if (currentSearchText.length && ([MXTools isEmailAddress:currentSearchText] || [MXTools isMatrixUserIdentifier:currentSearchText]))
    {
        // Select the contact related to the search input, rather than having to hit +
        MXKContact *contact = invitableContacts[0];

        // Sanity check
        if (contact)
        {
            [participants addObject:contact];
            
            // Cancel the search process
            [self searchBarCancelButtonClicked:searchBar];
            return;
        }
        
    }
    
    // Dismiss keyboard
    [_searchBarView resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = currentSearchText = nil;
    invitableContacts = nil;
    self.isAddParticipantSearchBarEditing = NO;
    
    // Leave search
    [searchBar resignFirstResponder];
}

@end
