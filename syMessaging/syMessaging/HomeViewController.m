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

@interface HomeViewController ()

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Retrieve public rooms
    _publicRooms = nil;
    [[[MatrixHandler sharedHandler] homeServer] publicRooms:^(NSArray *rooms) {
        _publicRooms = rooms;
        [_publicRoomsTable reloadData];
    }
                                                    failure:^(MXError *error){
                                                        //TODO
                                                    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_publicRooms){
        return _publicRooms.count;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [_publicRoomsTable dequeueReusableCellWithIdentifier:@"PublicRoomCell" forIndexPath:indexPath];
    
    MXPublicRoom *publicRoom = [_publicRooms objectAtIndex:indexPath.row];
    if ([publicRoom name]) {
        cell.textLabel.text = [publicRoom name];
    }
    else if ([publicRoom topic]) {
        cell.textLabel.text = [publicRoom topic];
    }
    
    return cell;
}

@end
