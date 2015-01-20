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

@implementation ContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    sectionedContacts = nil;
        
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

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    if (sectionedContacts.sectionTitles.count <= section) {
        return nil;
    }
    else {
        return (NSString*)[sectionedContacts.sectionTitles objectAtIndex:section];
    }
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
    
    // set the thumbnail
    if (contact.thumbnail) {
        cell.thumbnail.image = contact.thumbnail;
    } else {
        cell.thumbnail.image = [UIImage imageNamed:@"default-profile"];
    }
    
    cell.thumbnail.layer.cornerRadius = cell.thumbnail.frame.size.width / 2;
    cell.thumbnail.clipsToBounds = YES;
    
    // and the displayname
    cell.contactDisplayName.text = contact.displayName;
        
    return cell;
}

#pragma mark - Actions

- (void)onContactsRefresh:(NSNotification *)notif {
    sectionedContacts = nil;
    [self.tableView reloadData];
}

@end
