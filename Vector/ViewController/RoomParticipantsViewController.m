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

#import "RoomParticipantsViewController.h"

#import "RageShakeManager.h"

#import "AppDelegate.h"

@interface RoomParticipantsViewController ()
{
    NSMutableArray *participants;
    
    // Add participants
    NSInteger addParticipantsSection;
    MXKTableViewCellWithSearchBar *addParticipantsSearchBarCell;
    NSString *addParticipantsSearchText;
    
    // Search result
    NSInteger searchResultSection;
    NSMutableArray *filteredParticipants;
    
    // Participants
    NSInteger participantsSection;
    NSMutableDictionary *participantsByIds;
}

@end

@implementation RoomParticipantsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Setup `MXKViewControllerHandling` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"room_participants_title", @"Vector", nil);
    
    // Add each matrix session, to update the view controller appearance according to mx sessions state
    NSArray *sessions = [AppDelegate theDelegate].masterTabBarController.mxSessions;
    for (MXSession *mxSession in sessions)
    {
        [self addMatrixSession:mxSession];
    }
    
    addParticipantsSearchBarCell = [[MXKTableViewCellWithSearchBar alloc] init];
    addParticipantsSearchBarCell.mxkSearchBar.searchBarStyle = UISearchBarStyleMinimal;
    //    addParticipantsSearchBarCell.mxkSearchBar.barTintColor = [UIColor whiteColor]; // set barTint in case of UISearchBarStyleDefault (= UISearchBarStyleProminent)
    addParticipantsSearchBarCell.mxkSearchBar.returnKeyType = UIReturnKeyDone;
    addParticipantsSearchBarCell.mxkSearchBar.delegate = self;
    _isAddParticipantSearchBarEditing = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)destroy
{
    addParticipantsSearchBarCell = nil;
    filteredParticipants = nil;
    participantsByIds = nil;
    
    participants = nil;
    
    [super destroy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Refresh display
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

#pragma mark -

- (void)setRoomParticipants:(NSArray *)roomParticipants
{
    participants = [NSMutableArray arrayWithArray:roomParticipants];
}

- (NSArray*)roomParticipants
{
    return participants;
}

- (void)setIsAddParticipantSearchBarEditing:(BOOL)isAddParticipantsSearchBarEditing
{
    if (_isAddParticipantSearchBarEditing != isAddParticipantsSearchBarEditing)
    {
        _isAddParticipantSearchBarEditing = isAddParticipantsSearchBarEditing;
        
        // Switch the display between search result and participants list
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange (1, 1)];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    addParticipantsSection = searchResultSection = participantsSection = -1;
    
    if (_isAddParticipantSearchBarEditing)
    {
        // Only "add participant" section is displayed
        addParticipantsSection = count++;
        searchResultSection = count++;
    }
    else
    {
        addParticipantsSection = count++;
        participantsSection = count++;
    }
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == addParticipantsSection)
    {
        count = 2;
    }
    else if (section == searchResultSection)
    {
        count = filteredParticipants.count;
    }
    else if (section == participantsSection)
    {
        count = self.roomParticipants.count;
        if (self.userMatrixId)
        {
            count++;
        }
    }
    
    return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == addParticipantsSection)
    {
        return NSLocalizedStringFromTable(@"room_participants_add_participant", @"Vector", nil);
    }
    else if (section == participantsSection)
    {
        NSInteger count = self.roomParticipants.count;
        if (self.userMatrixId)
        {
            count++;
        }
        
        if (count > 1)
        {
            return [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_participants_multi_participants", @"Vector", nil), count];
        }
        else
        {
            return NSLocalizedStringFromTable(@"room_participants_one_participant", @"Vector", nil);
        }
        
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == addParticipantsSection)
    {
        if (indexPath.row == 0)
        {
            cell = addParticipantsSearchBarCell;
            if (_isAddParticipantSearchBarEditing)
            {
                [addParticipantsSearchBarCell.mxkSearchBar becomeFirstResponder];
            }
        }
        else if (indexPath.row == 1)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"addParticipantsSeparator"];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"addParticipantsSeparator"];
                UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 8, cell.frame.size.width, 2)];
                separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                separator.backgroundColor = [UIColor blackColor];
                [cell.contentView addSubview:separator];
            }
        }
    }
    else if (indexPath.section == searchResultSection)
    {
        if (indexPath.row < filteredParticipants.count)
        {
            MXKContactTableCell* filteredParticipantCell = [tableView dequeueReusableCellWithIdentifier:[MXKContactTableCell defaultReuseIdentifier]];
            if (!filteredParticipantCell)
            {
                filteredParticipantCell = [[MXKContactTableCell alloc] init];
            }
            
            [filteredParticipantCell render:filteredParticipants[indexPath.row]];
            
            // Show 'add' icon.
            filteredParticipantCell.contactAccessoryViewType = MXKContactTableCellAccessoryCustom;
            filteredParticipantCell.contactAccessoryViewHeightConstraint.constant = 30;
            filteredParticipantCell.contactAccessoryView.image = [UIImage imageNamed:@"add"];
            filteredParticipantCell.contactAccessoryView.hidden = NO;
            filteredParticipantCell.selectionStyle = UITableViewCellSelectionStyleDefault;
            
            cell = filteredParticipantCell;
        }
    }
    else if (indexPath.section == participantsSection)
    {
        MXKContactTableCell *participantCell = [tableView dequeueReusableCellWithIdentifier:[MXKContactTableCell defaultReuseIdentifier]];
        if (!participantCell)
        {
            participantCell = [[MXKContactTableCell alloc] init];
        }
        
        if (self.userMatrixId && indexPath.row == 0)
        {
            MXKContact *contact = [participantsByIds objectForKey:self.userMatrixId];
            if (! contact)
            {
                contact = [[MXKContact alloc] initMatrixContactWithDisplayName:NSLocalizedStringFromTable(@"you", @"Vector", nil) andMatrixID:self.userMatrixId];
                if (!participantsByIds)
                {
                    participantsByIds = [NSMutableDictionary dictionary];
                }
                [participantsByIds setObject:contact forKey:self.userMatrixId];
            }
            
            [participantCell render:contact];
            
            // Hide accessory view.
            participantCell.contactAccessoryViewType = MXKContactTableCellAccessoryCustom;
            participantCell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else
        {
            NSInteger index = indexPath.row;
            
            if (self.userMatrixId)
            {
                index --;
            }
            
            if (index < participants.count)
            {
                NSString *userId = participants[index];
                MXKContact *contact = [participantsByIds objectForKey:userId];
                if (!contact)
                {
                    // Create this missing contact
                    // Look for the corresponding MXUser
                    NSArray *sessions = self.mxSessions;
                    MXUser *mxUser;
                    for (MXSession *session in sessions)
                    {
                        mxUser = [session userWithUserId:userId];
                        if (mxUser)
                        {
                            contact = [[MXKContact alloc] initMatrixContactWithDisplayName:((mxUser.displayname.length > 0) ? mxUser.displayname : userId) andMatrixID:userId];
                            break;
                        }
                    }
                    
                    if (contact)
                    {
                        if (!participantsByIds)
                        {
                            participantsByIds = [NSMutableDictionary dictionary];
                        }
                        [participantsByIds setObject:contact forKey:userId];
                    }
                    
                }
                
                if (contact)
                {
                    [participantCell render:contact];
                }
                
                // Show 'remove' icon.
                participantCell.contactAccessoryViewType = MXKContactTableCellAccessoryCustom;
                participantCell.contactAccessoryViewHeightConstraint.constant = 30;
                participantCell.contactAccessoryView.image = [UIImage imageNamed:@"remove"];
                participantCell.contactAccessoryView.hidden = NO;
                participantCell.selectionStyle = UITableViewCellSelectionStyleDefault;
            }
        }
        
        cell = participantCell;
    }
    
    return cell;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == addParticipantsSection && indexPath.row == 1)
    {
        return 10;
    }
    return 44;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]])
    {
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
        tableViewHeaderFooterView.textLabel.text = [tableViewHeaderFooterView.textLabel.text capitalizedString];
        tableViewHeaderFooterView.textLabel.font = [UIFont boldSystemFontOfSize:17];
        tableViewHeaderFooterView.textLabel.textColor = [UIColor blackColor];
    }
}

//- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    return 1;
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    
    if (indexPath.section == searchResultSection)
    {
        if (index < filteredParticipants.count)
        {
            MXKContact *contact = filteredParticipants[index];
            
            NSArray *identifiers = contact.matrixIdentifiers;
            if (identifiers.count)
            {
                [participants addObject:identifiers.firstObject];
                
                // Handle a mapping contact by userId for selected participants
                if (!participantsByIds)
                {
                    participantsByIds = [NSMutableDictionary dictionary];
                }
                [participantsByIds setObject:contact forKey:identifiers.firstObject];
            }
            
//            [filteredParticipants removeObjectAtIndex:index];
//            // Refresh display
//            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            
            // Leave search session
            [self searchBarCancelButtonClicked:addParticipantsSearchBarCell.mxkSearchBar];
        }
    }
    else if (indexPath.section == participantsSection)
    { 
        if (self.userMatrixId)
        {
            index --;
        }
        
        if (index < participants.count)
        {
            [participantsByIds removeObjectForKey:participants[index]];
            [participants removeObjectAtIndex:index];
            
            // Refresh display
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

#pragma mark - UISearchBar delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSInteger previousFilteredCount = filteredParticipants.count;
    
    NSMutableArray *mxUsers;
    if (addParticipantsSearchText.length && [searchText hasPrefix:addParticipantsSearchText])
    {
        mxUsers = filteredParticipants;
    }
    else
    {
        // Retrieve all known matrix users
        NSArray *matrixContacts = [NSMutableArray arrayWithArray:[MXKContactManager sharedManager].matrixContacts];
        mxUsers = [NSMutableArray arrayWithCapacity:matrixContacts.count];
        
        // Split contacts with several ids, and remove the current participants.
        for (MXKContact* contact in matrixContacts)
        {
            NSArray *identifiers = contact.matrixIdentifiers;
            if (identifiers.count > 1)
            {
                for (NSString *userId in identifiers)
                {
                    if (!participants || [participants indexOfObject:userId] == NSNotFound)
                    {
                        if (![userId isEqualToString:self.userMatrixId])
                        {
                            MXKContact *splitContact = [[MXKContact alloc] initMatrixContactWithDisplayName:contact.displayName andMatrixID:userId];
                            [mxUsers addObject:splitContact];
                        }
                    }
                }
            }
            else if (identifiers.count)
            {
                NSString *userId = identifiers.firstObject;
                if (!participants || [participants indexOfObject:userId] == NSNotFound)
                {
                    if (![userId isEqualToString:self.userMatrixId])
                    {
                        [mxUsers addObject:contact];
                    }
                }
            }
        }
    }
    addParticipantsSearchText = searchText;
    
    filteredParticipants = [NSMutableArray array];
    NSMutableArray *indexArray = [NSMutableArray array];
    NSInteger index = 0;
    
    for (MXKContact* contact in mxUsers)
    {
        if ([contact matchedWithPatterns:@[addParticipantsSearchText]])
        {
            [filteredParticipants addObject:contact];
            [indexArray addObject:[NSIndexPath indexPathForRow:index++ inSection:0]];
        }
    }
    
    if (previousFilteredCount || filteredParticipants.count)
    {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange (searchResultSection, 1)];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    self.isAddParticipantSearchBarEditing = YES;
    searchBar.showsCancelButton = YES;
    
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // "Done" key has been pressed
    self.isAddParticipantSearchBarEditing = NO;
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = addParticipantsSearchText = nil;
    filteredParticipants = nil;
    self.isAddParticipantSearchBarEditing = NO;
    
    // Leave search
    [searchBar resignFirstResponder];
}

@end
