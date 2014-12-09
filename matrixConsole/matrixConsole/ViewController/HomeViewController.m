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

#import "HomeViewController.h"

#import "MatrixHandler.h"
#import "AppDelegate.h"

@interface HomeViewController () {
    NSArray *publicRooms;
    
    // List of public room names to highlight in displayed list
    NSArray* highlightedPublicRooms;
    
    // Search in public room
    UISearchBar     *recentsSearchBar;
    NSMutableArray  *filteredPublicRooms;
    BOOL             searchBarShouldEndEditing;
    UIView          *savedTableHeaderView;
}

@property (weak, nonatomic) IBOutlet UITableView *publicRoomsTable;
@property (weak, nonatomic) IBOutlet UILabel *roomCreationLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomAliasLabel;
@property (weak, nonatomic) IBOutlet UILabel *participantsLabel;
@property (weak, nonatomic) IBOutlet UITextField *roomNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *roomAliasTextField;
@property (weak, nonatomic) IBOutlet UITextField *participantsTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *roomVisibilityControl;
@property (weak, nonatomic) IBOutlet UIButton *createRoomBtn;
- (IBAction)onButtonPressed:(id)sender;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    _roomCreationLabel.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    _createRoomBtn.enabled = NO;
    _createRoomBtn.alpha = 0.5;
    
    // Init
    publicRooms = nil;
    highlightedPublicRooms = @[@"#matrix:matrix.org"]; // Add here a room name to highlight its display in public room list
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    publicRooms = nil;
    highlightedPublicRooms = nil;
    
    recentsSearchBar = nil;
    filteredPublicRooms = nil;
    savedTableHeaderView = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Ensure to display room creation section
    [self.tableView scrollRectToVisible:_roomCreationLabel.frame animated:NO];
    
    if ([[MatrixHandler sharedHandler] isLogged]) {
        // Update alias placeholder
        _roomAliasTextField.placeholder = [NSString stringWithFormat:@"(e.g. #foo:%@)", [MatrixHandler sharedHandler].homeServer];
        // Refresh listed public rooms
        [self refreshPublicRooms];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTextFieldChange:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Leave potential search session
    if (recentsSearchBar) {
        [self searchBarCancelButtonClicked:recentsSearchBar];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
}

#pragma mark - Internals

- (void)refreshPublicRooms {
    // Retrieve public rooms
    [[MatrixHandler sharedHandler].mxRestClient publicRooms:^(NSArray *rooms){
        publicRooms = [rooms sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            
            MXPublicRoom *firstRoom =  (MXPublicRoom*)a;
            MXPublicRoom *secondRoom = (MXPublicRoom*)b;
            
            return [firstRoom.displayname compare:secondRoom.displayname options:NSCaseInsensitiveSearch];
        }];
        [_publicRoomsTable reloadData];
    }
                                                    failure:^(NSError *error){
                                                        NSLog(@"GET public rooms failed: %@", error);
                                                        //Alert user
                                                        [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                    }];
    
}

- (void)search:(id)sender {
    if (!recentsSearchBar) {
        // Check whether there are data in which search
        if (publicRooms.count) {
            // Create search bar
            recentsSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
            recentsSearchBar.showsCancelButton = YES;
            recentsSearchBar.returnKeyType = UIReturnKeyDone;
            recentsSearchBar.delegate = self;
            [recentsSearchBar becomeFirstResponder];
            // Hide table header during search session
            savedTableHeaderView = self.tableView.tableHeaderView;
            self.tableView.tableHeaderView = nil;
            // Reload table in order to display search bar as section header
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            [self.tableView reloadData];
            
        }
    } else {
        [self searchBarCancelButtonClicked: recentsSearchBar];
    }
}

- (void)dismissKeyboard {
    // Hide the keyboard
    [_roomNameTextField resignFirstResponder];
    [_roomAliasTextField resignFirstResponder];
    [_participantsTextField resignFirstResponder];
}

- (NSString*)alias {
    // Extract alias name from alias text field
    NSString *alias = _roomAliasTextField.text;
    if (alias.length > 1) {
        // Remove '#' character
        alias = [alias substringFromIndex:1];
        // Remove homeserver
        NSString *suffix = [NSString stringWithFormat:@":%@",[MatrixHandler sharedHandler].homeServer];
        NSRange range = [alias rangeOfString:suffix];
        alias = [alias stringByReplacingCharactersInRange:range withString:@""];
    }
    
    if (! alias.length) {
        alias = nil;
    }
    
    return alias;
}

- (NSArray*)participantsList {
    NSMutableArray *participants = [NSMutableArray array];
    
    if (_participantsTextField.text.length) {
        NSArray *components = [_participantsTextField.text componentsSeparatedByString:@";"];
        
        for (NSString *component in components) {
            // Remove white space from both ends
            NSString *user = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (user.length > 1 && [user hasPrefix:@"@"]) {
                [participants addObject:user];
            }
        }
    }
    
    if (participants.count == 0) {
        participants = nil;
    }
    
    return participants;
}

#pragma mark - UITextField delegate

- (void)onTextFieldChange:(NSNotification *)notif {
    NSString *roomName = _roomNameTextField.text;
    NSString *roomAlias = _roomAliasTextField.text;
    NSString *participants = _participantsTextField.text;
    
    if (roomName.length || roomAlias.length || participants.length) {
        _createRoomBtn.enabled = YES;
        _createRoomBtn.alpha = 1;
    } else {
        _createRoomBtn.enabled = NO;
        _createRoomBtn.alpha = 0.5;
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == _roomAliasTextField) {
        textField.text = self.alias;
        textField.placeholder = @"foo";
    } else if (textField == _participantsTextField) {
        if (textField.text.length == 0) {
            textField.text = @"@";
        }
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == _roomAliasTextField) {
        // Compute the new alias with this string change
        NSString * alias = textField.text;
        if (alias.length) {
            // add homeserver as suffix
            textField.text = [NSString stringWithFormat:@"#%@:%@", alias, [MatrixHandler sharedHandler].homeServer];
        }
        
        textField.placeholder = [NSString stringWithFormat:@"(e.g. #foo:%@)", [MatrixHandler sharedHandler].homeServer];
    } else if (textField == _participantsTextField) {
        NSArray *participants = self.participantsList;
        textField.text = [participants componentsJoinedByString:@"; "];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // Auto complete participant IDs
    if (textField == _participantsTextField) {
        // Auto completion is active only when the change concerns the end of the current string
        if (range.location == textField.text.length) {
            NSString *participants = [textField.text stringByReplacingCharactersInRange:range withString:string];
            
            if ([string isEqualToString:@";"]) {
                // Add '@' character
                participants = [participants stringByAppendingString:@" @"];
            } else if ([string isEqualToString:@":"]) {
                // Add homeserver
                if ([MatrixHandler sharedHandler].homeServer) {
                    participants = [participants stringByAppendingString:[MatrixHandler sharedHandler].homeServer];
                }
            }
            
            textField.text = participants;
            
            // Update Create button status
            [self onTextFieldChange:nil];
            return NO;
        }
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*) textField {
    // "Done" key has been pressed
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender {
    [self dismissKeyboard];
    
    if (sender == _createRoomBtn) {
        // Disable button to prevent multiple request
        _createRoomBtn.enabled = NO;
        
        NSString *roomName = _roomNameTextField.text;
        if (! roomName.length) {
            roomName = nil;
        }
        
        // Create new room
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        [mxHandler.mxRestClient createRoom:roomName
         visibility:(_roomVisibilityControl.selectedSegmentIndex == 0) ? kMXRoomVisibilityPublic : kMXRoomVisibilityPrivate
         room_alias_name:self.alias
         topic:nil
         success:^(MXCreateRoomResponse *response) {
             // Check whether some users must be invited
             NSArray *invitedUsers = self.participantsList;
             for (NSString *userId in invitedUsers) {
                 [mxHandler.mxRestClient inviteUser:userId toRoom:response.roomId success:^{
                     NSLog(@"%@ has been invited (roomId: %@)", userId, response.roomId);
                 } failure:^(NSError *error) {
                     NSLog(@"%@ invitation failed (roomId: %@): %@", userId, response.roomId, error);
                     //Alert user
                     [[AppDelegate theDelegate] showErrorAsAlert:error];
                 }];
             }
             
             // Reset text fields
             _roomNameTextField.text = nil;
             _roomAliasTextField.text = nil;
             _participantsTextField.text = nil;
             // Open created room
             [[AppDelegate theDelegate].masterTabBarController showRoom:response.roomId];
         } failure:^(NSError *error) {
             _createRoomBtn.enabled = YES;
             NSLog(@"Create room (%@ %@ (%@)) failed: %@", _roomNameTextField.text, self.alias, (_roomVisibilityControl.selectedSegmentIndex == 0) ? @"Public":@"Private", error);
             //Alert user
             [[AppDelegate theDelegate] showErrorAsAlert:error];
         }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (filteredPublicRooms) {
        return filteredPublicRooms.count;
    }
    return publicRooms.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (recentsSearchBar) {
        return (recentsSearchBar.frame.size.height + 40);
    }
    return 40;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *sectionHeader = [[UIView alloc] initWithFrame:[tableView rectForHeaderInSection:section]];
    sectionHeader.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    UILabel *sectionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, sectionHeader.frame.size.width, 40)];
    sectionLabel.font = [UIFont boldSystemFontOfSize:16];
    sectionLabel.backgroundColor = [UIColor clearColor];
    [sectionHeader addSubview:sectionLabel];
    
    if (publicRooms) {
        NSString *homeserver = [MatrixHandler sharedHandler].homeServerURL;
        if (homeserver.length) {
            sectionLabel.text = [NSString stringWithFormat:@" Public Rooms (at %@):", homeserver];
        } else {
            sectionLabel.text = @" Public Rooms:";
        }
        
        UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [searchButton setImage:[UIImage imageNamed:@"icon_search"] forState:UIControlStateNormal];
        [searchButton setImage:[UIImage imageNamed:@"icon_search"] forState:UIControlStateHighlighted];
        [searchButton addTarget:self action:@selector(search:) forControlEvents:UIControlEventTouchUpInside];
        searchButton.frame = CGRectMake(sectionLabel.frame.size.width - 45, 0, 40, 40);
        [sectionHeader addSubview:searchButton];
        sectionHeader.userInteractionEnabled = YES;
        if (recentsSearchBar) {
            CGRect frame = recentsSearchBar.frame;
            frame.origin.y = 40;
            recentsSearchBar.frame = frame;
            [sectionHeader addSubview:recentsSearchBar];
        }
    } else {
        sectionLabel.text = @" No Public Rooms";
    }
    
    return sectionHeader;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Cell is larger for public room with topic
    MXPublicRoom *publicRoom;
    if (filteredPublicRooms) {
        publicRoom = [filteredPublicRooms objectAtIndex:indexPath.row];
    } else {
        publicRoom = [publicRooms objectAtIndex:indexPath.row];
    }
    
    if (publicRoom.topic) {
        return 60;
    }
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    MXPublicRoom *publicRoom;
    if (filteredPublicRooms) {
        publicRoom = [filteredPublicRooms objectAtIndex:indexPath.row];
    } else {
        publicRoom = [publicRooms objectAtIndex:indexPath.row];
    }
    
    // Check whether this public room has topic
    if (publicRoom.topic) {
        cell = [_publicRoomsTable dequeueReusableCellWithIdentifier:@"PublicRoomCellSubtitle" forIndexPath:indexPath];
        cell.detailTextLabel.text = publicRoom.topic;
    } else {
        cell = [_publicRoomsTable dequeueReusableCellWithIdentifier:@"PublicRoomCellBasic" forIndexPath:indexPath];
    }
    
    // Set room display name
    cell.textLabel.text = [publicRoom displayname];
    
    // Highlight?
    if (cell.textLabel.text && [highlightedPublicRooms indexOfObject:cell.textLabel.text] != NSNotFound) {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:17];
    } else {
        cell.textLabel.font = [UIFont systemFontOfSize:19];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:16];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MXPublicRoom *publicRoom;
    if (filteredPublicRooms) {
        publicRoom = [filteredPublicRooms objectAtIndex:indexPath.row];
    } else {
        publicRoom = [publicRooms objectAtIndex:indexPath.row];
    }
    
    // Check whether the user has already joined the selected public room
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    if ([mxHandler.mxSession roomWithRoomId:publicRoom.roomId]) {
        // Open selected room
        [[AppDelegate theDelegate].masterTabBarController showRoom:publicRoom.roomId];
    } else {
        // Join the selected room
        UIActivityIndicatorView *loadingWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        if (selectedCell) {
            CGPoint center = CGPointMake(selectedCell.frame.size.width / 2, selectedCell.frame.size.height / 2);
            loadingWheel.center = center;
            [selectedCell addSubview:loadingWheel];
        }
        [loadingWheel startAnimating];
        [mxHandler.mxSession joinRoom:publicRoom.roomId success:^(MXRoom *room) {
            // Show joined room
            [loadingWheel stopAnimating];
            [loadingWheel removeFromSuperview];
            [[AppDelegate theDelegate].masterTabBarController showRoom:publicRoom.roomId];
        } failure:^(NSError *error) {
            NSLog(@"Failed to join public room (%@) failed: %@", publicRoom.displayname, error);
            //Alert user
            [loadingWheel stopAnimating];
            [loadingWheel removeFromSuperview];
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    searchBarShouldEndEditing = NO;
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return searchBarShouldEndEditing;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    // Update filtered list
    if (searchText.length) {
        if (filteredPublicRooms) {
            [filteredPublicRooms removeAllObjects];
        } else {
            filteredPublicRooms = [NSMutableArray arrayWithCapacity:publicRooms.count];
        }
        for (MXPublicRoom *publicRoom in publicRooms) {
            if ([[publicRoom displayname] rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [filteredPublicRooms addObject:publicRoom];
            }
        }
    } else {
        filteredPublicRooms = nil;
    }
    // Refresh display
    [self.tableView reloadData];
    if (filteredPublicRooms.count) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    // "Done" key has been pressed
    searchBarShouldEndEditing = YES;
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    // Leave search
    searchBarShouldEndEditing = YES;
    [searchBar resignFirstResponder];
    recentsSearchBar = nil;
    filteredPublicRooms = nil;
    // Restore table header and refresh table display
    self.tableView.tableHeaderView = savedTableHeaderView;
    [self.tableView reloadData];
}

@end
