/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "ContactsViewController.h"

// SDK api
#import "MatrixSDKHandler.h"

// application info
#import "AppDelegate.h"

// contacts management
#import "ContactManager.h"
#import "MXCContact.h"
#import "MXCEmail.h"
#import "MXCPhoneNumber.h"

// contact cell
#import "ContactTableCell.h"

// alert
#import "MXCAlert.h"

// settings
#import "AppSettings.h"

//
#import "ContactDetailsViewController.h"

NSString *const kInvitationMessage = @"I'd like to chat with you with matrix. Please, visit the website http://matrix.org to have more information.";

@interface ContactsViewController () {
    // YES -> only matrix users
    // NO -> display local contacts
    BOOL displayMatrixUsers;
    
    // screenshot of the local contacts
    NSMutableArray* localContacts;
    SectionedContacts* sectionedLocalContacts;
    
    // screenshot of the matrix users
    NSMutableDictionary* matrixUserByMatrixID;
    SectionedContacts* sectionedMatrixContacts;
    
    // tap on thumbnail to display contact info
    MXCContact* selectedContact;
    
    // Search
    UISearchBar     *contactsSearchBar;
    NSMutableArray  *filteredContacts;
    SectionedContacts* sectionedFilteredContacts;
    BOOL             searchBarShouldEndEditing;
    NSString* latestSearchedPattern;
}

@property (strong, nonatomic) MXCAlert *startChatMenu;
@property (strong, nonatomic) MXCAlert *allowContactSyncAlert;
@property (weak, nonatomic) IBOutlet UITableView* tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl* contactsControls;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@end

@implementation ContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // get the system collation titles
    collationTitles = [[UILocalizedIndexedCollation currentCollation]sectionTitles];
    
    // global init
    displayMatrixUsers = (0 == self.contactsControls.selectedSegmentIndex);
    matrixUserByMatrixID = [[NSMutableDictionary alloc] init];
    
    // event listener
    [[MatrixSDKHandler sharedHandler]  addObserver:self forKeyPath:@"status" options:0 context:nil];

    // add the search icon on the right
    // need to add more buttons ?
    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(search:)];
    self.navigationItem.rightBarButtonItems = @[searchButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactsRefresh:) name:kContactManagerContactsListRefreshNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // required to reduce the tableview height while searching
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Leave potential search session
    if (contactsSearchBar) {
        [self searchBarCancelButtonClicked:contactsSearchBar];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

- (void)startActivityIndicator {
    [_activityIndicator.layer setCornerRadius:5];
    _activityIndicator.hidden = NO;
    [_activityIndicator startAnimating];
}

- (void)stopActivityIndicator {
    [_activityIndicator stopAnimating];
    _activityIndicator.hidden = YES;
}

- (void)scrollToTop {
    // stop any scrolling effect
    [UIView setAnimationsEnabled:NO];
    // before scrolling to the tableview top
    self.tableView.contentOffset = CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top);
    [UIView setAnimationsEnabled:YES];
}

// should be called when resetting the application
// the contact manager warn there is a contacts list update
// but the Matrix SDK handler has no more userID -> so assume there is a reset 
- (void)reset {
    // Leave potential search session
    if (contactsSearchBar) {
        [self searchBarCancelButtonClicked:contactsSearchBar];
    }
    
    localContacts = nil;
    sectionedLocalContacts = nil;
    
    matrixUserByMatrixID = [[NSMutableDictionary alloc] init];;
    sectionedMatrixContacts = nil;
    
    [self.contactsControls setSelectedSegmentIndex:0];
    [self.tableView reloadData];
}

#pragma mark - Keyboard handling

- (void)onKeyboardWillShow:(NSNotification *)notif {
    // get the keyboard size
    NSValue *rectVal = notif.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect endRect = rectVal.CGRectValue;
    
    // IOS 8 triggers some unexpected keyboard events
    if ((endRect.size.height == 0) || (endRect.size.width == 0)) {
        return;
    }
    
    CGFloat keyboardHeight = (endRect.origin.y == 0) ? endRect.size.width : endRect.size.height;
    
    // the tableview bottom inset must also be updated
    UIEdgeInsets insets = self.tableView.contentInset;
    insets.bottom = keyboardHeight;
    
    // get the animation info
    NSNumber *curveValue = [[notif userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    
    // the duration is ignored but it is better to define it
    double animationDuration = [[[notif userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | (animationCurve << 16) animations:^{
        // reduce the tableview height
        self.tableView.contentInset = insets;
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
    }];
}

- (void)onKeyboardWillHide:(NSNotification *)notif {
    // get the keyboard size
    NSValue *rectVal = notif.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect endRect = rectVal.CGRectValue;
    
    rectVal = notif.userInfo[UIKeyboardFrameBeginUserInfoKey];
    CGRect beginRect = rectVal.CGRectValue;
    
    UIEdgeInsets insets = self.tableView.contentInset;
    insets.bottom = 0;
    
    // do not animate if the both rect are the same
    // but ensure that the fields are properly resetted
    // e.g. when the user swipes to hide the keyboard
    // this method is called with invalid rects
    // animationDuration is ignored because of the animation curve
    // use it to be sure that it will be broken with any new IOS update
    if (CGRectEqualToRect(endRect, beginRect)) {
        
        self.tableView.contentInset = insets;
        [self.view layoutIfNeeded];
        
    } else {
        // get the animation info
        NSNumber *curveValue = [[notif userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
        UIViewAnimationCurve animationCurve = curveValue.intValue;
        
        // the duration is ignored but it is better to define it
        double animationDuration = [[[notif userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        // animate the keyboard closing
        [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | (animationCurve << 16) animations:^{
            self.tableView.contentInset = insets;
            [self.view layoutIfNeeded];
            
        } completion:^(BOOL finished) {
        }];
    }
}

#pragma mark - UITableView delegate

- (void)updateSectionedLocalContacts {
    [self stopActivityIndicator];
    
    ContactManager* sharedManager = [ContactManager sharedManager];
    
    if (!localContacts) {
        localContacts = sharedManager.contacts;
    }
    
    if (!sectionedLocalContacts) {
        sectionedLocalContacts = [sharedManager getSectionedContacts:sharedManager.contacts];
    }
}

- (void)updateSectionedMatrixContacts {
    // Check whether mxSession is available in matrix handler
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    if (!mxHandler.mxSession) {
        [self startActivityIndicator];
        sectionedMatrixContacts = nil;
    } else {
        [self stopActivityIndicator];
        
        NSArray* usersIDs = [mxHandler oneToOneRoomMemberIDs];
        // return a MatrixIDs list of 1:1 room members
        
        NSMutableArray* knownUserIDs = [[matrixUserByMatrixID allKeys] mutableCopy];
        
        // list the contacts IDs
        // avoid delete and create the same ones
        // it could save thumbnail downloads
        for(NSString* userID in usersIDs) {
            //
            MXUser* user = [mxHandler.mxSession userWithUserId:userID];
            
            // sanity check
            if (user) {
                // managed UserID
                [knownUserIDs removeObject:userID];
                
                MXCContact* contact = [matrixUserByMatrixID objectForKey:userID];
                
                // already defined
                if (contact) {
                    contact.displayName = (user.displayname.length > 0) ? user.displayname : user.userId;
                } else {
                    contact = [[MXCContact alloc] initWithDisplayName:((user.displayname.length > 0) ? user.displayname : user.userId) matrixID:user.userId];
                    [matrixUserByMatrixID setValue:contact forKey:userID];
                }
            }
        }
        
        // some userIDs don't exist anymore
        for (NSString* userID in knownUserIDs) {
            [matrixUserByMatrixID removeObjectForKey:userID];
        }
        
        sectionedMatrixContacts = [[ContactManager sharedManager] getSectionedContacts:[matrixUserByMatrixID allValues]];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // search in progress
    if (contactsSearchBar) {
        return sectionedFilteredContacts.sectionedContacts.count;
    }
    else if (displayMatrixUsers) {
        [self updateSectionedMatrixContacts];
        return sectionedMatrixContacts.sectionedContacts.count;
        
    } else {
        [self updateSectionedLocalContacts];
        return sectionedLocalContacts.sectionedContacts.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    SectionedContacts* sectionedContacts = contactsSearchBar ? sectionedFilteredContacts : (displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts);
    
    return [[sectionedContacts.sectionedContacts objectAtIndex:section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    SectionedContacts* sectionedContacts = contactsSearchBar ? sectionedFilteredContacts : (displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts);
    
    if (sectionedContacts.sectionTitles.count <= section) {
        return nil;
    }
    else {
        return (NSString*)[sectionedContacts.sectionTitles objectAtIndex:section];
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)aTableView {
    // do not display the collation during a search
    if (contactsSearchBar) {
        return nil;
    } else {
        [self.tableView setSectionIndexColor:[AppDelegate theDelegate].masterTabBarController.tabBar.tintColor];
        [self.tableView setSectionIndexBackgroundColor:[UIColor clearColor]];
        
        return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
    }
}

- (NSInteger)tableView:(UITableView *)aTableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    SectionedContacts* sectionedContacts = contactsSearchBar ? sectionedFilteredContacts : (displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts);
    NSUInteger section = [sectionedContacts.sectionTitles indexOfObject:title];
    
    // undefined title -> jump to the first valid non empty section
    if (NSNotFound == section) {
        NSUInteger systemCollationIndex = [collationTitles indexOfObject:title];
        
        // find in the system collation
        if (NSNotFound != systemCollationIndex) {
            systemCollationIndex--;
            
            while ((systemCollationIndex == 0) && (NSNotFound == section)) {
                NSString* systemTitle = [collationTitles objectAtIndex:systemCollationIndex];
                section = [sectionedContacts.sectionTitles indexOfObject:systemTitle];
                systemCollationIndex--;
            }
        }
    }

    return section;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    ContactTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell" forIndexPath:indexPath];
    SectionedContacts* sectionedContacts = contactsSearchBar ? sectionedFilteredContacts : (displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts);
    
    MXCContact* contact = nil;
    
    if (indexPath.section < sectionedContacts.sectionedContacts.count) {
        NSArray *thisSection = [sectionedContacts.sectionedContacts objectAtIndex:indexPath.section];
        
        if (indexPath.row < thisSection.count) {
            contact = [thisSection objectAtIndex:indexPath.row];
        }
    }
    
    // tap on matrix user thumbnail -> open a detailled sheet
    UITapGestureRecognizer* tapGesture = nil;
    
    // check if it is already defined
    // gesture in storyboard does not seem to work properly
    // it always triggers a tap event on the first cell
    for (UIGestureRecognizer* gesture in cell.thumbnailView.gestureRecognizers) {
        
        if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
            tapGesture = (UITapGestureRecognizer*)gesture;
            break;
        }
    }

    // add it if it is not yet defined
    if (!tapGesture) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onContactThumbnailTap:)];
        [tap setNumberOfTouchesRequired:1];
        [tap setNumberOfTapsRequired:1];
        [tap setDelegate:self];
        [cell.thumbnailView addGestureRecognizer:tap];
    }
    
    cell.contact = contact;
                
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SectionedContacts* sectionedContacts = contactsSearchBar ? sectionedFilteredContacts : (displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts);
    MXCContact* contact = nil;
    
    if (indexPath.section < sectionedContacts.sectionedContacts.count) {
        NSArray *thisSection = [sectionedContacts.sectionedContacts objectAtIndex:indexPath.section];
        
        if (indexPath.row < thisSection.count) {
            contact = [thisSection objectAtIndex:indexPath.row];
        }
    }
    
    __weak typeof(self) weakSelf = self;
    NSArray* matrixIDs = contact.matrixIdentifiers;

    // matrix user ?
    if (matrixIDs.count) {
        
        MatrixSDKHandler* mxHandler = [MatrixSDKHandler sharedHandler];
        
        // display only if the mxSession is available in matrix SDK handler
        if (mxHandler.mxSession) {
            // only 1 matrix ID
            if (matrixIDs.count == 1) {
                NSString* matrixID = [matrixIDs objectAtIndex:0];

                self.startChatMenu = [[MXCAlert alloc] initWithTitle:[NSString stringWithFormat:@"Chat with %@", matrixID]  message:nil style:MXCAlertStyleAlert];
                
                [self.startChatMenu addActionWithTitle:@"Cancel" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
                    weakSelf.startChatMenu = nil;
                }];
                
                [self.startChatMenu addActionWithTitle:@"OK" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
                    weakSelf.startChatMenu = nil;
                    
                    [mxHandler startPrivateOneToOneRoomWithUserId:matrixID];
                }];
            } else {
                self.startChatMenu = [[MXCAlert alloc] initWithTitle:[NSString stringWithFormat:@"Chat with "]  message:nil style:MXCAlertStyleActionSheet];
                
                for(NSString* matrixID in matrixIDs) {
                    [self.startChatMenu addActionWithTitle:matrixID style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
                        weakSelf.startChatMenu = nil;
                        
                        [mxHandler startPrivateOneToOneRoomWithUserId:matrixID];
                    }];
                }
                
                [self.startChatMenu addActionWithTitle:@"Cancel" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
                    weakSelf.startChatMenu = nil;
                }];
                
                UIView *sourceView = [tableView cellForRowAtIndexPath:indexPath];
                self.startChatMenu.sourceView = sourceView ? sourceView : tableView;
            }
            
            [self.startChatMenu showInViewController:self];
        }
    } else {
        // invite to use matrix
        if (([MFMessageComposeViewController canSendText] ? contact.emailAddresses.count : 0) + (contact.phoneNumbers.count > 0)) {
        
            self.startChatMenu = [[MXCAlert alloc] initWithTitle:[NSString stringWithFormat:@"Invite this user to use matrix with"]  message:nil style:MXCAlertStyleActionSheet];
            
            // check if the target can send SMSes
            if ([MFMessageComposeViewController canSendText]) {
                // list phonenumbers
                for(MXCPhoneNumber* phonenumber in contact.phoneNumbers) {
                    
                    [self.startChatMenu addActionWithTitle:phonenumber.textNumber style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
                        weakSelf.startChatMenu = nil;
                        
                        // launch SMS composer
                        MFMessageComposeViewController *messageComposer = [[MFMessageComposeViewController alloc] init];
                        
                        if (messageComposer)
                        {
                            messageComposer.messageComposeDelegate = weakSelf;
                            messageComposer.body =kInvitationMessage;
                            messageComposer.recipients = [NSArray arrayWithObject:phonenumber.textNumber];

                            dispatch_async(dispatch_get_main_queue(), ^{
                                [weakSelf presentViewController:messageComposer animated:YES completion:nil];
                            });
                        }
                    }];
                }
            }
            
            // list emails
            for(MXCEmail* email in contact.emailAddresses) {
                
                [self.startChatMenu addActionWithTitle:email.emailAddress style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
                    weakSelf.startChatMenu = nil;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSString* subject = [ @"Matrix.org is magic" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        NSString* body = [kInvitationMessage stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@", email.emailAddress, subject, body]]];
                    });
                }];
            }
            
            [self.startChatMenu addActionWithTitle:@"Cancel" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
                weakSelf.startChatMenu = nil;
            }];
            
            UIView *sourceView = [tableView cellForRowAtIndexPath:indexPath];
            self.startChatMenu.sourceView = sourceView ? sourceView : tableView;
            [self.startChatMenu showInViewController:self];
        }
    }
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([@"status" isEqualToString:keyPath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (displayMatrixUsers) {
                if (contactsSearchBar) {
                    [self updateSectionedMatrixContacts];
                    latestSearchedPattern = nil;
                    [self searchBar:contactsSearchBar textDidChange:contactsSearchBar.text];
                } else {
                    [self.tableView reloadData];
                }
            }
        });
    }
}

#pragma mark - Actions

- (void)onContactsRefresh:(NSNotification *)notif {
    localContacts = nil;
    sectionedLocalContacts = nil;
    
    // there is an user id
    if ([[MatrixSDKHandler sharedHandler] userId]) {
        [self updateSectionedLocalContacts];
        //
        if (!displayMatrixUsers) {
            if (contactsSearchBar) {
                latestSearchedPattern = nil;
                [self searchBar:contactsSearchBar textDidChange:contactsSearchBar.text];
            } else {
                [self.tableView reloadData];
            }
        }
    } else {
        // the client could have been logged out
        [self reset];
    }
}

- (IBAction)onSegmentValueChange:(id)sender {
    if (sender == self.contactsControls) {
        displayMatrixUsers = (0 == self.contactsControls.selectedSegmentIndex);
        
        if (contactsSearchBar) {
            if (displayMatrixUsers) {
                [self updateSectionedMatrixContacts];
            } else {
                [self updateSectionedLocalContacts];
            }
            
            latestSearchedPattern = nil;
            [self searchBar:contactsSearchBar textDidChange:contactsSearchBar.text];
        } else {
            [self.tableView reloadData];
        }
    
        if (!displayMatrixUsers) {
            AppSettings* appSettings = [AppSettings sharedSettings];
            
            if (!appSettings.syncLocalContacts) {
                __weak typeof(self) weakSelf = self;
                
                self.allowContactSyncAlert = [[MXCAlert alloc] initWithTitle:@"Allow local contacts synchronization ?"  message:nil style:MXCAlertStyleAlert];
                
                [self.allowContactSyncAlert addActionWithTitle:@"No" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
                    weakSelf.allowContactSyncAlert = nil;
                }];
                
                [self.allowContactSyncAlert addActionWithTitle:@"Yes" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
                        weakSelf.allowContactSyncAlert = nil;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        appSettings.syncLocalContacts = YES;
                        [weakSelf.tableView reloadData];
                    });
                }];
                
                [self.allowContactSyncAlert showInViewController:self];
            }
        }
    }
}

- (IBAction)onContactThumbnailTap:(id)sender {
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UIView* tappedView = ((UITapGestureRecognizer*)sender).view;
        
        // search the parentce cell
        while (tappedView && ![tappedView isKindOfClass:[ContactTableCell class]]) {
            tappedView = tappedView.superview;
        }
        
        // find it ?
        if ([tappedView isKindOfClass:[ContactTableCell class]]) {
            MXCContact* contact = ((ContactTableCell*)tappedView).contact;
            
            // open detailled sheet if there
            if (contact.matrixIdentifiers.count > 0) {
                selectedContact = ((ContactTableCell*)tappedView).contact;
                [self performSegueWithIdentifier:@"showContactDetails" sender:self];
            }
        }
        
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showContactDetails"]) {
        ContactDetailsViewController *contactDetailsViewController = segue.destinationViewController;
        contactDetailsViewController.contact = selectedContact;
        selectedContact = nil;
    }
}

#pragma mark MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Search management

- (void)search:(id)sender {
    if (!contactsSearchBar) {
        SectionedContacts* sectionedContacts = displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts;
        
        // Check whether there are data in which search
        if (sectionedContacts.sectionedContacts.count > 0) {
            // Create search bar
            contactsSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
            contactsSearchBar.showsCancelButton = YES;
            contactsSearchBar.returnKeyType = UIReturnKeyDone;
            contactsSearchBar.delegate = self;
            contactsSearchBar.tintColor = [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor;
            searchBarShouldEndEditing = NO;
            
            // init the table content
            latestSearchedPattern = @"";
            filteredContacts = [(displayMatrixUsers ? [matrixUserByMatrixID allValues] : localContacts) mutableCopy];
            sectionedFilteredContacts = [[ContactManager sharedManager] getSectionedContacts:filteredContacts];
            
            self.tableView.tableHeaderView = contactsSearchBar;
            [self.tableView reloadData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [contactsSearchBar becomeFirstResponder];
            });
        }
    } else {
        [self searchBarCancelButtonClicked:contactsSearchBar];
    }
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    searchBarShouldEndEditing = NO;
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return searchBarShouldEndEditing;
}

- (NSArray*)patternsFromText:(NSString*)text {
    NSArray* items = [text componentsSeparatedByString:@" "];
    
    if (items.count <= 1) {
        return items;
    }
    
    NSMutableArray* patterns = [[NSMutableArray alloc] init];
    
    for (NSString* item in items) {
        if (item.length > 0) {
            [patterns addObject:item];
        }
    }
    
    return patterns;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ((contactsSearchBar == searchBar) && (![latestSearchedPattern isEqualToString:searchText])) {
        latestSearchedPattern = searchText;
        
        // contacts
        NSArray* contacts = displayMatrixUsers ? [matrixUserByMatrixID allValues] : localContacts;
        
        // Update filtered list
        if (searchText.length && contacts.count) {
            
            filteredContacts = [[NSMutableArray alloc] init];
            
            NSArray* patterns = [self patternsFromText:searchText];
            for(MXCContact* contact in contacts) {
                if ([contact matchedWithPatterns:patterns]) {
                    [filteredContacts addObject:contact];
                }
            }
        } else {
            filteredContacts = [contacts mutableCopy];
        }
        
        sectionedFilteredContacts = [[ContactManager sharedManager] getSectionedContacts:filteredContacts];
        
        // Refresh display
        [self.tableView reloadData];
        [self scrollToTop];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if (contactsSearchBar == searchBar) {
        // "Done" key has been pressed
        searchBarShouldEndEditing = YES;
        [contactsSearchBar resignFirstResponder];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    if (contactsSearchBar == searchBar) {
        // Leave search
        searchBarShouldEndEditing = YES;
        [contactsSearchBar resignFirstResponder];
        contactsSearchBar = nil;
        filteredContacts = nil;
        sectionedFilteredContacts = nil;
        latestSearchedPattern = nil;
        self.tableView.tableHeaderView = nil;
        [self.tableView reloadData];
        [self scrollToTop];
    }
}

@end
