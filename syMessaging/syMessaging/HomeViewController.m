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

@interface HomeViewController ()

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPublicRoom:)];
//    self.navigationItem.rightBarButtonItem = addButton;
    
    // Do any additional setup after loading the view, typically from a nib.
    _publicRooms = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([[MatrixHandler sharedHandler] isLogged]) {
        [self refreshPublicRooms];
    }
}

- (void)addPublicRoom:(id)sender {
    // TODO
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_publicRooms){
        return _publicRooms.count;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (_publicRooms) {
        NSString *homeserver = [[MatrixHandler sharedHandler] homeServerURL];
        if (homeserver.length) {
            return [NSString stringWithFormat:@"Public Rooms (at %@)", homeserver];
        }
        return @"Public Rooms";
    }
    return @"No Public Rooms";
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [_publicRoomsTable dequeueReusableCellWithIdentifier:@"PublicRoomCell" forIndexPath:indexPath];
    
    MXPublicRoom *publicRoom = [_publicRooms objectAtIndex:indexPath.row];
    cell.textLabel.text = [publicRoom displayname];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Join the selected room
    MXPublicRoom *publicRoom = [_publicRooms objectAtIndex:indexPath.row];
    [[[MatrixHandler sharedHandler] mxSession] join:publicRoom.room_id success:^{
        // Show joined room
        [[AppDelegate theDelegate].masterTabBarController showRoomDetails:publicRoom.room_id];
    } failure:^(NSError *error) {
        NSLog(@"Failed to join public room (%@) failed: %@", publicRoom.displayname, error);
        //Alert user
        [[AppDelegate theDelegate] showErrorAsAlert:error];
    }];
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Internals

- (void)refreshPublicRooms
{
    // Retrieve public rooms
    [[[MatrixHandler sharedHandler] homeServer] publicRooms:^(NSArray *rooms){
        _publicRooms = rooms;
        [_publicRoomsTable reloadData];
    }
                                                    failure:^(NSError *error){
                                                        NSLog(@"GET public rooms failed: %@", error);
                                                        //Alert user
                                                        [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                    }];
    
}

@end
