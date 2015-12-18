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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MXPublicRoom *publicRoom = dataSource.filteredRooms[indexPath.row];
    [[AppDelegate theDelegate] showRoom:publicRoom.roomId withMatrixSession:dataSource.mxSession];
}

@end
