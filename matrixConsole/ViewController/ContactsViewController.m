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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactsRefresh:) name:kContactManagerContactsListRefreshNotification object:nil];
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


#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (displayMatrixUsers) {
        // check if the user is already known
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        
        if ((mxHandler.status != MatrixSDKHandlerStatusServerSyncDone) && (mxHandler.status != MatrixSDKHandlerStatusStoreDataReady)) {
            [self startActivityIndicator];
            return 0;
        } else {
            [self stopActivityIndicator];

            //NSArray* users = [mxHandler.mxSession users];
            NSArray* usersIDs = [mxHandler oneToOneRoomMemberMatrixIDs];
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
            
            return sectionedMatrixContacts.sectionedContacts.count;
        }
        
    } else {
        [self stopActivityIndicator];
        
        ContactManager* sharedManager = [ContactManager sharedManager];
        
        if (!localContacts) {
            localContacts = sharedManager.contacts;
        }
        
        if (!sectionedLocalContacts) {
            sectionedLocalContacts = [sharedManager getSectionedContacts:sharedManager.contacts];
        }
        
        return sectionedLocalContacts.sectionedContacts.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (displayMatrixUsers) {
        return [[sectionedMatrixContacts.sectionedContacts objectAtIndex:section] count];
    } else {
        return [[sectionedLocalContacts.sectionedContacts objectAtIndex:section] count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    SectionedContacts* sectionedContacts = displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts;
    
    if (sectionedContacts.sectionTitles.count <= section) {
        return nil;
    }
    else {
        return (NSString*)[sectionedContacts.sectionTitles objectAtIndex:section];
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)aTableView {
    [self.tableView setSectionIndexColor:[AppDelegate theDelegate].masterTabBarController.tabBar.tintColor];
    [self.tableView setSectionIndexBackgroundColor:[UIColor clearColor]];
    
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)aTableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    SectionedContacts* sectionedContacts = displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts;
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
    SectionedContacts* sectionedContacts = displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts;
    
    MXCContact* contact = nil;
    
    if (indexPath.section < sectionedContacts.sectionedContacts.count) {
        NSArray *thisSection = [sectionedContacts.sectionedContacts objectAtIndex:indexPath.section];
        
        if (indexPath.row < thisSection.count) {
            contact = [thisSection objectAtIndex:indexPath.row];
        }
    }
    
    cell.contact = contact;
                
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SectionedContacts* sectionedContacts = displayMatrixUsers ? sectionedMatrixContacts : sectionedLocalContacts;
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
        // Display action menu: Add attachments, Invite user...
        
        NSString* matrixID = [matrixIDs objectAtIndex:0];

        self.startChatMenu = [[MXCAlert alloc] initWithTitle:[NSString stringWithFormat:@"Start chat with %@", matrixID]  message:nil style:MXCAlertStyleAlert];
        
        [self.startChatMenu addActionWithTitle:@"Cancel" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
            weakSelf.startChatMenu = nil;
        }];
        
        [self.startChatMenu addActionWithTitle:@"OK" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
            weakSelf.startChatMenu = nil;
            
            MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
            
            // else create new room
            [mxHandler.mxRestClient createRoom:nil
                                    visibility:kMXRoomVisibilityPrivate
                                     roomAlias:nil
                                         topic:nil
                                       success:^(MXCreateRoomResponse *response) {
                                           // add the user
                                           [mxHandler.mxRestClient inviteUser:matrixID toRoom:response.roomId success:^{
                                           } failure:^(NSError *error) {
                                               NSLog(@"%@ invitation failed (roomId: %@): %@", matrixID, response.roomId, error);
                                               //Alert user
                                               [[AppDelegate theDelegate] showErrorAsAlert:error];
                                           }];
                                           
                                           // Open created room
                                           [[AppDelegate theDelegate].masterTabBarController showRoom:response.roomId];
                                           
                                       } failure:^(NSError *error) {
                                           NSLog(@"Create room failed: %@", error);
                                           //Alert user
                                           [[AppDelegate theDelegate] showErrorAsAlert:error];
                                       }];
                
        }];
        
        [self.startChatMenu showInViewController:self];
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
            
            [self.startChatMenu showInViewController:self];
        }
    }
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([@"status" isEqualToString:keyPath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (displayMatrixUsers) {
                [self.tableView reloadData];
            }
        });
    }
}

#pragma mark - Actions

- (void)onContactsRefresh:(NSNotification *)notif {
    localContacts = nil;
    sectionedLocalContacts = nil;
    [self.tableView reloadData];
}

- (IBAction)onSegmentValueChange:(id)sender {
    if (sender == self.contactsControls) {
        displayMatrixUsers = (0 == self.contactsControls.selectedSegmentIndex);
        [self.tableView reloadData];
        
        if (!displayMatrixUsers) {
            AppSettings* appSettings = [AppSettings sharedSettings];
            
            if (!appSettings.requestedLocalContactsSync) {
                __weak typeof(self) weakSelf = self;
                
                self.allowContactSyncAlert = [[MXCAlert alloc] initWithTitle:@"Allow local contacts synchronization ?"  message:nil style:MXCAlertStyleAlert];
                
                [self.allowContactSyncAlert addActionWithTitle:@"NO" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
                    weakSelf.allowContactSyncAlert = nil;
                }];
                
                [self.allowContactSyncAlert addActionWithTitle:@"YES" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
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
#pragma mark MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
