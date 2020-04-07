/*
 Copyright 2016 OpenMarket Ltd
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

#import "StartChatViewController.h"

#import "AppDelegate.h"
#import "Riot-Swift.h"
#import "MXSession+Riot.h"

@interface StartChatViewController () <UITableViewDataSource, UISearchBarDelegate, ContactsTableViewControllerDelegate>
{
    // The contact used to describe the current user.
    MXKContact *userContact;
    
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

@property (weak, nonatomic) IBOutlet UIView *searchBarHeader;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBarView;
@property (weak, nonatomic) IBOutlet UIView *searchBarHeaderBorder;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewBottomConstraint;

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
    
    self.screenName = @"StartChat";
    
    _isAddParticipantSearchBarEditing = NO;
    
    // Prepare room participants
    participants = [NSMutableArray array];
    
    // Assign itself as delegate
    self.contactsTableViewControllerDelegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
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
                                                                        toItem:self.contactsTableView
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0f
                                                                      constant:0.0f];
    
    [NSLayoutConstraint activateConstraints:@[_searchBarTopConstraint, _tableViewBottomConstraint]];
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"room_creation_title", @"Vector", nil);
    
    // Add each matrix session by default.
    NSArray *sessions = [AppDelegate theDelegate].mxSessions;
    for (MXSession *mxSession in sessions)
    {
        [self addMatrixSession:mxSession];
    }

    // Prepare its data source
    ContactsDataSource *dataSource = [[ContactsDataSource alloc] initWithMatrixSession:self.mainSession]; // TO TEST
    dataSource.areSectionsShrinkable = YES;
    dataSource.displaySearchInputInContactsList = YES;
    dataSource.forceMatrixIdInDisplayName = YES;
    // Add a plus icon to the contact cell when a search session is in progress,
    // in order to make it more understandable for the end user.
    dataSource.contactCellAccessoryImage = [UIImage imageNamed:@"plus_icon"];

    [self displayList:dataSource];

    cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onButtonPressed:)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
    
    createBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"start", @"Vector", nil) style:UIBarButtonItemStylePlain target:self action:@selector(onButtonPressed:)];
    self.navigationItem.rightBarButtonItem = createBarButtonItem;
    
    _searchBarView.placeholder = NSLocalizedStringFromTable(@"room_creation_invite_another_user", @"Vector", nil);
    _searchBarView.returnKeyType = UIReturnKeyDone;
    _searchBarView.autocapitalizationType = UITextAutocapitalizationTypeNone;    
    [self refreshSearchBarItemsColor:_searchBarView];
    
    // Hide line separators of empty cells
    self.contactsTableView.tableFooterView = [[UIView alloc] init];
    
    [self.contactsTableView registerClass:ContactTableViewCell.class forCellReuseIdentifier:@"ParticipantTableViewCellId"];
    
    // Redirect table data source
    self.contactsTableView.dataSource = self;
}

- (void)userInterfaceThemeDidChange
{
    [super userInterfaceThemeDidChange];
    
    [self refreshSearchBarItemsColor:_searchBarView];
    
    _searchBarHeaderBorder.backgroundColor = ThemeService.shared.theme.headerBorderColor;
    
    // Check the table view style to select its bg color.
    self.contactsTableView.backgroundColor = ((self.contactsTableView.style == UITableViewStylePlain) ? ThemeService.shared.theme.backgroundColor : ThemeService.shared.theme.headerBackgroundColor);
    self.view.backgroundColor = self.contactsTableView.backgroundColor;
    self.contactsTableView.separatorColor = ThemeService.shared.theme.lineBreakColor;
    
    if (self.contactsTableView.dataSource)
    {
        [self.contactsTableView reloadData];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
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
    
    // FIXME: Handle multi accounts
    NSString *displayName = NSLocalizedStringFromTable(@"you", @"Vector", nil);
    userContact = [[MXKContact alloc] initMatrixContactWithDisplayName:displayName andMatrixID:self.mainSession.myUser.userId];
    
    [self refreshParticipants];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Active the search session if the current participant list is empty
    if (!participants.count)
    {
        self.isAddParticipantSearchBarEditing = YES;
    }
    else
    {
        // Refresh display
        [self refreshContactsTable];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

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
        [self refreshContactsTable];
    }
}

#pragma mark - Internals

- (void)refreshParticipants
{
    // Refer all participants in ignored contacts dictionary.
    isMultiUseNameByDisplayName = [NSMutableDictionary dictionary];
    [contactsDataSource.ignoredContactsByMatrixId removeAllObjects];
    [contactsDataSource.ignoredContactsByEmail removeAllObjects];
    
    for (MXKContact* contact in participants)
    {
        NSArray *identifiers = contact.matrixIdentifiers;
        if (identifiers.count)
        {
            // Here the contact can only have one identifier
            contactsDataSource.ignoredContactsByMatrixId[identifiers.firstObject] = contact;
        }
        else
        {
            NSArray *emails = contact.emailAddresses;
            if (emails.count)
            {
                // Here the contact can only have one email
                MXKEmail *email = emails.firstObject;
                contactsDataSource.ignoredContactsByEmail[email.emailAddress] = contact;
            }
        }
        isMultiUseNameByDisplayName[contact.displayName] = (isMultiUseNameByDisplayName[contact.displayName] ? @(YES) : @(NO));
    }
    
    if (userContact)
    {
        contactsDataSource.ignoredContactsByMatrixId[self.mainSession.myUser.userId] = userContact;
    }
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    
    if (_isAddParticipantSearchBarEditing)
    {
        participantsSection = -1;
        count = [contactsDataSource numberOfSectionsInTableView:tableView];
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
    
    if (_isAddParticipantSearchBarEditing)
    {
        count = [contactsDataSource tableView:tableView numberOfRowsInSection:section];
    }
    else if (section == participantsSection)
    {
        count = participants.count + 1;
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (_isAddParticipantSearchBarEditing)
    {
        cell = [contactsDataSource tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    else if (indexPath.section == participantsSection)
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
        // Return a fake cell to prevent app from crashing.
        cell = [[UITableViewCell alloc] init];
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    // Update the selected background view
    if (ThemeService.shared.theme.selectedBackgroundColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = ThemeService.shared.theme.selectedBackgroundColor;
    }
    else
    {
        if (tableView.style == UITableViewStylePlain)
        {
            cell.selectedBackgroundView = nil;
        }
        else
        {
            cell.selectedBackgroundView.backgroundColor = nil;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0.0;
    
    if (_isAddParticipantSearchBarEditing)
    {
        height = [contactsDataSource heightForHeaderInSection:section];
    }
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isAddParticipantSearchBarEditing)
    {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    
    return 74;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isAddParticipantSearchBarEditing)
    {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
    else
    {
        // Do nothing
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
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
        
        leaveAction.backgroundColor = [MXKTools convertImageToPatternColor:@"remove_icon" backgroundColor:ThemeService.shared.theme.headerBackgroundColor patternSize:CGSizeMake(74, 74) resourceSize:CGSizeMake(24, 24)];
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
        
        [self refreshContactsTable];
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
                        NSLog(@"[StartChatViewController] Invite %@ failed", participantId);
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
                    invite3PID.medium = kMX3PIDMediumEmail;
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

            MXWeakify(self);
            void (^onFailure)(NSError *) = ^(NSError *error){
                MXStrongifyAndReturnIfNil(self);

                self->createBarButtonItem.enabled = YES;

                self->roomCreationRequest = nil;
                [self stopActivityIndicator];

                NSLog(@"[StartChatViewController] Create room failed");

                // Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            };

            [self.mainSession canEnableE2EByDefaultInNewRoomWithUsers:inviteArray success:^(BOOL canEnableE2E) {
                MXStrongifyAndReturnIfNil(self);

                // Create new room
                MXRoomCreationParameters *roomCreationParameters = [MXRoomCreationParameters new];
                roomCreationParameters.visibility = kMXRoomDirectoryVisibilityPrivate;
                roomCreationParameters.inviteArray = inviteArray.count ? inviteArray : nil;
                roomCreationParameters.invite3PIDArray = invite3PIDArray.count ? invite3PIDArray : nil;
                roomCreationParameters.isDirect = isDirect;
                roomCreationParameters.preset = preset;

                if (canEnableE2E && roomCreationParameters.invite3PIDArray == nil)
                {
                    roomCreationParameters.initialStateEvents = @[
                                                                  [MXRoomCreationParameters initialStateEventForEncryptionWithAlgorithm:kMXCryptoMegolmAlgorithm
                                                                   ]];
                }

                self->roomCreationRequest = [self.mainSession createRoomWithParameters:roomCreationParameters success:^(MXRoom *room) {

                    self->roomCreationRequest = nil;

                    [self stopActivityIndicator];

                    [[AppDelegate theDelegate] showRoom:room.roomId andEventId:nil withMatrixSession:self.mainSession];

                } failure:onFailure];

            } failure:onFailure];
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
    searchBar.barTintColor = searchBar.tintColor = ThemeService.shared.theme.tintColor;
    searchBar.tintColor = ThemeService.shared.theme.tintColor;
    
    // FIXME: this all seems incredibly fragile and tied to gutwrenching the current UISearchBar internals.

    // text color
    UITextField *searchBarTextField = searchBar.vc_searchTextField;
    searchBarTextField.textColor = ThemeService.shared.theme.textSecondaryColor;
    
    // Magnifying glass icon.
    UIImageView *leftImageView = (UIImageView *)searchBarTextField.leftView;
    leftImageView.image = [leftImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    leftImageView.tintColor = ThemeService.shared.theme.tintColor;
    
    // remove the gray background color
    UIView *effectBackgroundTop =  [searchBarTextField valueForKey:@"_effectBackgroundTop"];
    UIView *effectBackgroundBottom =  [searchBarTextField valueForKey:@"_effectBackgroundBottom"];
    effectBackgroundTop.hidden = YES;
    effectBackgroundBottom.hidden = YES;
        
    // place holder
    if (searchBarTextField.placeholder)
    {
        searchBarTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:searchBarTextField.placeholder
                                                                                   attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                                                                                NSUnderlineColorAttributeName: ThemeService.shared.theme.tintColor,
                                                                                                NSForegroundColorAttributeName: ThemeService.shared.theme.tintColor}];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [contactsDataSource searchWithPattern:searchText forceReset:NO];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{    
    self.isAddParticipantSearchBarEditing = YES;
    searchBar.showsCancelButton = NO;
    
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = nil;
    self.isAddParticipantSearchBarEditing = NO;
    
    // Reset filtering
    [contactsDataSource searchWithPattern:nil forceReset:NO];
    
    // Leave search
    [searchBar resignFirstResponder];
}

#pragma mark - ContactsTableViewControllerDelegate

- (void)contactsTableViewController:(ContactsTableViewController *)contactsTableViewController didSelectContact:(MXKContact*)contact
{
    // If contact has only an email the identity server must be defined
    if (!self.mainSession.matrixRestClient.identityServer && contact.matrixIdentifiers.count == 0)
    {
        NSString *participantId;
        
        if (contact.emailAddresses.count)
        {
            MXKEmail *email = contact.emailAddresses.firstObject;
            participantId = email.emailAddress;
        }
        else
        {
            // This is the text filled by the user.
            participantId = contact.displayName;
        }
        
        if ([MXTools isEmailAddress:participantId])
        {
            NSLog(@"[StartChatViewController] No identity server is configured, do not add participant with email");
            
            [contactsTableViewController refreshCurrentSelectedCell:YES];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSBundle mxk_localizedStringForKey:@"error"]
                                                                           message:NSLocalizedStringFromTable(@"room_creation_error_invite_user_by_email_without_identity_server", @"Vector", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            
            return;
        }
    }
    
    if (contact)
    {
        // Update here the mutable list of participants
        [participants addObject:contact];
    }
    
    // Refresh display by leaving search session
    [self searchBarCancelButtonClicked:_searchBarView];
}

@end
