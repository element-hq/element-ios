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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return publicRooms.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *sectionHeader = [[UILabel alloc] initWithFrame:[tableView rectForHeaderInSection:section]];
    sectionHeader.font = [UIFont boldSystemFontOfSize:16];
    sectionHeader.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    
    if (publicRooms) {
        NSString *homeserver = [MatrixHandler sharedHandler].homeServerURL;
        if (homeserver.length) {
            sectionHeader.text = [NSString stringWithFormat:@" Public Rooms (at %@):", homeserver];
        } else {
            sectionHeader.text = @" Public Rooms:";
        }
    } else {
        sectionHeader.text = @" No Public Rooms";
    }
    
    return sectionHeader;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Cell is larger for public room with topic
    MXPublicRoom *publicRoom = [publicRooms objectAtIndex:indexPath.row];
    if (publicRoom.topic) {
        return 60;
    }
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MXPublicRoom *publicRoom = [publicRooms objectAtIndex:indexPath.row];
    UITableViewCell *cell;
    
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
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
    // Check whether the user has already joined the selected public room
    MXPublicRoom *publicRoom = [publicRooms objectAtIndex:indexPath.row];
    if ([mxHandler.mxData getRoomData:publicRoom.room_id]) {
        // Open selected room
        [[AppDelegate theDelegate].masterTabBarController showRoom:publicRoom.room_id];
    } else {
        // Join the selected room
        [mxHandler.mxSession join:publicRoom.room_id success:^{
            // Show joined room
            [[AppDelegate theDelegate].masterTabBarController showRoom:publicRoom.room_id];
        } failure:^(NSError *error) {
            NSLog(@"Failed to join public room (%@) failed: %@", publicRoom.displayname, error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Internals

- (void)refreshPublicRooms {
    // Retrieve public rooms
    [[MatrixHandler sharedHandler].mxHomeServer publicRooms:^(NSArray *rooms){
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
        // Compute the new phone number with this string change
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
                participants = [participants stringByAppendingString:[MatrixHandler sharedHandler].homeServer];
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

#pragma mark - 

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
        [[MatrixHandler sharedHandler].mxSession
         createRoom:roomName
         visibility:(_roomVisibilityControl.selectedSegmentIndex == 0) ? kMXRoomVisibilityPublic : kMXRoomVisibilityPrivate
         room_alias_name:self.alias
         topic:nil
         invite:self.participantsList
         success:^(MXCreateRoomResponse *response) {
             // Reset text fields
             _roomNameTextField.text = nil;
             _roomAliasTextField.text = nil;
             _participantsTextField.text = nil;
             // Open created room
             [[AppDelegate theDelegate].masterTabBarController showRoom:response.room_id];
         } failure:^(NSError *error) {
             _createRoomBtn.enabled = YES;
             NSLog(@"Create room (%@ %@ %@ (%@)) failed: %@", _roomNameTextField.text, self.alias, self.participantsList, (_roomVisibilityControl.selectedSegmentIndex == 0) ? @"Public":@"Private", error);
             //Alert user
             [[AppDelegate theDelegate] showErrorAsAlert:error];
         }];
    }
}

@end
