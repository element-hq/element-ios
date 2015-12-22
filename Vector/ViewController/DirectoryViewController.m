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

#import "DirectoryViewController.h"

#import "PublicRoomsDirectoryDataSource.h"

#import "AppDelegate.h"

@interface DirectoryViewController ()
{
    PublicRoomsDirectoryDataSource *dataSource;
}

@end

@implementation DirectoryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedStringFromTable(@"directory_title", @"Vector", nil);

    self.tableView.delegate = self;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView reloadData];
}

- (void)displayWitDataSource:(PublicRoomsDirectoryDataSource *)dataSource2
{
    // Let the data source provide cells
    dataSource = dataSource2;
    self.tableView.dataSource = dataSource;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MXPublicRoom *publicRoom = dataSource.filteredRooms[indexPath.row];

    // In the master-detail case, try to come back smoothly to the "classic" display
    // (list of rooms on left in the master and the selected rooom on right in the detail)
    // Unfortunately, animation is not possible since we cannot know when it finishes.
    [self.navigationController popViewControllerAnimated:NO];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[AppDelegate theDelegate].homeViewController selectRoomWithId:publicRoom.roomId inMatrixSession:dataSource.mxSession];
    });
}

@end
