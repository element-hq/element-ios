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

#import "ContactManager.h"
#import "ConsoleContact.h"

#import "ContactTableCell.h"

#import "CustomAlert.h"

#import "MatrixHandler.h"
#import "AppDelegate.h"

@interface ContactsViewController ()
@property (strong, nonatomic) CustomAlert *startChatMenu;
@end

@implementation ContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    sectionedContacts = nil;
    
    // get the system collation titles
    collationTitles = [[UILocalizedIndexedCollation currentCollation]sectionTitles];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactsRefresh:) name:kContactManagerRefreshNotification object:nil];
}

#pragma mark - UITableView delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!sectionedContacts) {
        ContactManager* sharedManager = [ContactManager sharedManager];
        
        sectionedContacts = [sharedManager getSectionedContacts:sharedManager.contacts];
    }
    
    return sectionedContacts.sectionedContacts.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[sectionedContacts.sectionedContacts objectAtIndex:section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    if (sectionedContacts.sectionTitles.count <= section) {
        return nil;
    }
    else {
        return (NSString*)[sectionedContacts.sectionTitles objectAtIndex:section];
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)aTableView
{
    NSMutableArray* titles = [[NSMutableArray alloc] initWithCapacity:10];
    
    [titles addObjectsFromArray:[[UILocalizedIndexedCollation currentCollation] sectionIndexTitles]];
    
    // force the background color
    if ([self.tableView respondsToSelector:@selector(setSectionIndexBackgroundColor:)]) {
        [self.tableView setSectionIndexBackgroundColor:[UIColor clearColor]];
    }
    
    return titles;
}

- (NSInteger)tableView:(UITableView *)aTableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    NSUInteger section;
    
    @synchronized(self)
    {
        section = [sectionedContacts.sectionTitles indexOfObject:title];
    }
    
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
    
    ConsoleContact* contact = nil;
    
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
    
    ConsoleContact* contact = nil;
    
    if (indexPath.section < sectionedContacts.sectionedContacts.count) {
        NSArray *thisSection = [sectionedContacts.sectionedContacts objectAtIndex:indexPath.section];
        
        if (indexPath.row < thisSection.count) {
            contact = [thisSection objectAtIndex:indexPath.row];
        }
    }
    
    NSArray* matrixIDs = contact.matrixIdentifiers;
    
    if (matrixIDs.count) {
        // Display action menu: Add attachments, Invite user...
        __weak typeof(self) weakSelf = self;
        
        NSString* matrixID = [matrixIDs objectAtIndex:0];
        

        self.startChatMenu = [[CustomAlert alloc] initWithTitle:[NSString stringWithFormat:@"Start chat with %@", matrixID]  message:nil style:CustomAlertStyleAlert];
        
        [self.startChatMenu addActionWithTitle:@"Cancel" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
            weakSelf.startChatMenu = nil;
        }];
        
        [self.startChatMenu addActionWithTitle:@"OK" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
            weakSelf.startChatMenu = nil;
            
            MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
            
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
    }
}

#pragma mark - Actions

- (void)onContactsRefresh:(NSNotification *)notif {
    sectionedContacts = nil;
    [self.tableView reloadData];
}

@end
