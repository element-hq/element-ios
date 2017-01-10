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

#import "AppDelegate.h"

@interface StartChatViewController ()
{
    // Section indexes
    NSInteger participantsSection;
    
    // The current list of participants.
    NSMutableArray<MXKContact*> *participants;
    
    // Navigation bar items
    UIBarButtonItem *cancelBarButtonItem;
    UIBarButtonItem *createBarButtonItem;
    
    // HTTP Request
    MXHTTPOperation *roomCreationRequest;
    
    // This dictionary tells for each display name whether it appears several times in participants list
    NSMutableDictionary <NSString*, NSNumber*> *isMultiUseNameByDisplayName;
}

@end

@implementation StartChatViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([StartChatViewController class])
                          bundle:[NSBundle bundleForClass:[StartChatViewController class]]];
}

+ (instancetype)startChatViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([StartChatViewController class])
                                          bundle:[NSBundle bundleForClass:[StartChatViewController class]]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    _isAddParticipantSearchBarEditing = NO;
    
    // Prepare room participants
    participants = [NSMutableArray array];
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
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"room_creation_title", @"Vector", nil);
    
    cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onButtonPressed:)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
    
    createBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"start", @"Vector", nil) style:UIBarButtonItemStylePlain target:self action:@selector(onButtonPressed:)];
    self.navigationItem.rightBarButtonItem = createBarButtonItem;
    
    _searchBarView.placeholder = NSLocalizedStringFromTable(@"room_participants_invite_another_user", @"Vector", nil);
    _searchBarView.returnKeyType = UIReturnKeyDone;
    _searchBarView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self refreshSearchBarItemsColor:_searchBarView];
    
    _searchBarHeaderBorder.backgroundColor = kVectorColorSilver;
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self.tableView registerClass:ContactTableViewCell.class forCellReuseIdentifier:@"ParticipantTableViewCellId"];
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
    
    isMultiUseNameByDisplayName = nil;
    
    participants = nil;
    
    [super destroy];
}

- (void)addMatrixSession:(MXSession *)mxSession
{
    [super addMatrixSession:mxSession];
    
    [self refreshParticipants];
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
 
    // cancel any pending search
    [self searchBarCancelButtonClicked:_searchBarView];
}

#pragma mark -

- (void)setIsAddParticipantSearchBarEditing:(BOOL)isAddParticipantSearchBarEditing
{
    if (_isAddParticipantSearchBarEditing != isAddParticipantSearchBarEditing)
    {
        if (isAddParticipantSearchBarEditing)
        {
            self.navigationItem.rightBarButtonItem = nil;
        }
        else
        {
            self.navigationItem.rightBarButtonItem = createBarButtonItem;
            
            [self refreshParticipants];
        }
        
        _isAddParticipantSearchBarEditing = isAddParticipantSearchBarEditing;
        
        // Switch the display between search result and participants list
        [self refreshTableView];
    }
}

#pragma mark - Internals

- (void)refreshParticipants
{
    // Refer all participants in ignored contacts dictionary.
    isMultiUseNameByDisplayName = [NSMutableDictionary dictionary];
    
    for (MXKContact* contact in participants)
    {
        NSArray *identifiers = contact.matrixIdentifiers;
        if (identifiers.count)
        {
            // Here the contact can only have one identifier
            [ignoredContactsByMatrixId setObject:contact forKey:identifiers.firstObject];
        }
        else
        {
            NSArray *emails = contact.emailAddresses;
            if (emails.count)
            {
                // Here the contact can only have one email
                MXKEmail *email = emails.firstObject;
                [ignoredContactsByEmail setObject:contact forKey:email.emailAddress];
            }
        }
        isMultiUseNameByDisplayName[contact.displayName] = (isMultiUseNameByDisplayName[contact.displayName] ? @(YES) : @(NO));
    }
    
    if (userContact)
    {
        [ignoredContactsByMatrixId setObject:userContact forKey:self.mainSession.myUser.userId];
    }
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    
    if (_isAddParticipantSearchBarEditing)
    {
        participantsSection = -1;
        count = [super numberOfSectionsInTableView:self.tableView];
    }
    else
    {
        searchInputSection = filteredLocalContactsSection = filteredMatrixContactsSection = -1;
        participantsSection = count++;
    }
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == participantsSection)
    {
        count = participants.count + 1;
    }
    else
    {
        count = [super tableView:self.tableView numberOfRowsInSection:section];
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == participantsSection)
    {
        ContactTableViewCell* participantCell = [tableView dequeueReusableCellWithIdentifier:@"ParticipantTableViewCellId" forIndexPath:indexPath];
        
        MXKContact *contact;
        
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
                if (contact.displayName)
                {
                    participantCell.showMatrixIdInDisplayName = [isMultiUseNameByDisplayName[contact.displayName] isEqualToNumber:@(YES)];
                }
            }
        }
        
        participantCell.selectionStyle = UITableViewCellSelectionStyleNone;
        [participantCell render:contact];
        
        cell = participantCell;
    }
    else
    {
        cell = [super tableView:self.tableView cellForRowAtIndexPath:indexPath];
    }
    
    return cell;
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0.0;
    
    if (section != participantsSection)
    {
        height = [super tableView:self.tableView heightForHeaderInSection:section];
    }
    
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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
        // Update here the mutable list of participants
        [participants addObject:mxkContact];
        
        // Refresh display by leaving search session
        [self searchBarCancelButtonClicked:_searchBarView];
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
                // This is a text entered by the user, or a local contact
                NSString *participantId;
                
                if (contact.emailAddresses.count)
                {
                    // This is a local contact, consider the first email by default.
                    // TODO: Prompt the user to select the right email.
                    MXKEmail *email = contact.emailAddresses.firstObject;
                    participantId = email.emailAddress;
                }
                else
                {
                    // This is the text filled by the user.
                    participantId = contact.displayName;
                }
                
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
    [self searchWithPattern:searchText forceRefresh:NO];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    // Check whether the access to the local contacts has not been already asked.
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    {
        // Allow by default the local contacts sync in order to discover matrix users.
        // This setting change will trigger the loading of the local contacts, which will automatically
        // ask user permission to access their local contacts.
        [MXKAppSettings standardAppSettings].syncLocalContacts = YES;
    }
    
    self.isAddParticipantSearchBarEditing = YES;
    searchBar.showsCancelButton = NO;
    
    return YES;
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
    [_searchBarView resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = nil;
    self.isAddParticipantSearchBarEditing = NO;
    
    // Reset filtering
    [self searchWithPattern:nil forceRefresh:NO];
    
    // Leave search
    [searchBar resignFirstResponder];
}

@end
