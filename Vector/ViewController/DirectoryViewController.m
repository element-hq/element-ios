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

#import "VectorDesignValues.h"

#import "RageShakeManager.h"

@interface DirectoryViewController ()
{
    PublicRoomsDirectoryDataSource *dataSource;
}

@end

@implementation DirectoryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];

    self.title = NSLocalizedStringFromTable(@"directory_title", @"Vector", nil);

    self.tableView.delegate = self;

    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Release the current selected room (if any) except if the Room ViewController is still visible (see splitViewController.isCollapsed condition)
    if (self.splitViewController && self.splitViewController.isCollapsed)
    {
        [[AppDelegate theDelegate].homeViewController closeSelectedRoom];
    }
    else
    {
        // In case of split view controller where the primary and secondary view controllers are displayed side-by-side onscreen,
        // the selected room (if any) is highlighted.
        [self refreshCurrentSelectedCell:YES];
    }
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

    // Check whether the user has already joined the selected public room
    if ([dataSource.mxSession roomWithRoomId:publicRoom.roomId])
    {
        [self openRoomWithId:publicRoom.roomId inMatrixSession:dataSource.mxSession];
    }
    else
    {
        // Join the room before opening it
        [self startActivityIndicator];
        [dataSource.mxSession joinRoom:publicRoom.roomId success:^(MXRoom *room) {

            [self stopActivityIndicator];

            [self openRoomWithId:publicRoom.roomId inMatrixSession:dataSource.mxSession];

        } failure:^(NSError *error) {

            [self stopActivityIndicator];

            NSLog(@"[DirectoryVC] Failed to join public room (%@)", publicRoom.displayname);

            // Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    }
}

#pragma mark - Private methods

- (void)openRoomWithId:(NSString*)roomId inMatrixSession:(MXSession*)mxSession
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[AppDelegate theDelegate].homeViewController selectRoomWithId:roomId andEventId:nil inMatrixSession:mxSession];
    });
}

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    HomeViewController *homeViewController = [AppDelegate theDelegate].homeViewController;

    // Update here the index of the current selected cell (if any) - Useful in landscape mode with split view controller.
    NSIndexPath *currentSelectedCellIndexPath = nil;
    if (homeViewController.currentRoomViewController)
    {
        // Look for the rank of this selected room in displayed recents
        currentSelectedCellIndexPath = [dataSource cellIndexPathWithRoomId:homeViewController.selectedRoomId andMatrixSession:homeViewController.selectedRoomSession];
    }

    if (currentSelectedCellIndexPath)
    {
        // Select the right row
        [self.tableView selectRowAtIndexPath:currentSelectedCellIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];

        if (forceVisible)
        {
            // Scroll table view to make the selected row appear at second position
            NSInteger topCellIndexPathRow = currentSelectedCellIndexPath.row ? currentSelectedCellIndexPath.row - 1: currentSelectedCellIndexPath.row;
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:topCellIndexPathRow inSection:currentSelectedCellIndexPath.section];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    }
    else
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath)
        {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

@end
