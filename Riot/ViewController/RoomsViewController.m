/*
 Copyright 2017 Vector Creations Ltd

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

#import "RoomsViewController.h"

#import "AppDelegate.h"

#import "RecentsDataSource.h"

@interface RoomsViewController ()
{
    RecentsDataSource *recentsDataSource;

    // The animated view displayed at the table view bottom when paginating the room directory
    UIView* footerSpinnerView;
}
@end

@implementation RoomsViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    self.screenName = @"Rooms";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.accessibilityIdentifier = @"RoomsVCView";
    self.recentsTableView.accessibilityIdentifier = @"RoomsVCTableView";
    
    // Add room creation button programmatically
    [self addRoomCreationButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [AppDelegate theDelegate].masterTabBarController.navigationItem.title = NSLocalizedStringFromTable(@"title_rooms", @"Vector", nil);
    
    if ([self.dataSource isKindOfClass:RecentsDataSource.class])
    {
        // Take the lead on the shared data source.
        recentsDataSource = (RecentsDataSource*)self.dataSource;
        recentsDataSource.areSectionsShrinkable = NO;
        [recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModeRooms];
    }
}

- (void)dealloc
{
    
}

- (void)destroy
{
    [super destroy];
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (recentsDataSource.recentsDataSourceMode == RecentsDataSourceModeRooms && indexPath.section == recentsDataSource.directorySection)
    {
        [self openPublicRoomAtIndexPath:indexPath];
    }
    else
    {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (recentsDataSource.recentsDataSourceMode == RecentsDataSourceModeRooms)
    {
        // Trigger inconspicuous pagination on directy when user scrolls down
        if ((scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.frame.size.height) < 300)
        {
            [self triggerDirectoryPagination];
        }
    }
    else
    {
        [super scrollViewDidScroll:scrollView];
    }
}

#pragma mark - Private methods

- (void)openPublicRoomAtIndexPath:(NSIndexPath *)indexPath
{
    MXPublicRoom *publicRoom = [recentsDataSource.publicRoomsDirectoryDataSource roomAtIndexPath:indexPath];

    // Check whether the user has already joined the selected public room
    if ([recentsDataSource.publicRoomsDirectoryDataSource.mxSession roomWithRoomId:publicRoom.roomId])
    {
        // Open the public room
        [[AppDelegate theDelegate].masterTabBarController selectRoomWithId:publicRoom.roomId andEventId:nil inMatrixSession:recentsDataSource.publicRoomsDirectoryDataSource.mxSession];
    }
    else
    {
        // Preview the public room
        if (publicRoom.worldReadable)
        {
            RoomPreviewData *roomPreviewData = [[RoomPreviewData alloc] initWithRoomId:publicRoom.roomId andSession:recentsDataSource.publicRoomsDirectoryDataSource.mxSession];

            [self startActivityIndicator];

            // Try to get more information about the room before opening its preview
            [roomPreviewData peekInRoom:^(BOOL succeeded) {

                [self stopActivityIndicator];

                [[AppDelegate theDelegate].masterTabBarController showRoomPreview:roomPreviewData];
            }];
        }
        else
        {
            RoomPreviewData *roomPreviewData = [[RoomPreviewData alloc] initWithPublicRoom:publicRoom andSession:recentsDataSource.publicRoomsDirectoryDataSource.mxSession];
            [[AppDelegate theDelegate].masterTabBarController showRoomPreview:roomPreviewData];
        }
    }
}

- (void)triggerDirectoryPagination
{
    if (recentsDataSource.publicRoomsDirectoryDataSource.hasReachedPaginationEnd || footerSpinnerView)
    {
        // We got all public rooms or we are already paginating
        // Do nothing
        return;
    }

    [self addSpinnerFooterView];

    [recentsDataSource.publicRoomsDirectoryDataSource paginate:^(NSUInteger roomsAdded) {

        // The table view is automatically filled
        [self removeSpinnerFooterView];

    } failure:^(NSError *error) {

        [self removeSpinnerFooterView];
    }];
}

- (void)addSpinnerFooterView
{
    if (!footerSpinnerView)
    {
        UIActivityIndicatorView* spinner  = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinner.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
        CGRect frame = spinner.frame;
        frame.size.height = 80; // 80 * 0.75 = 60
        spinner.bounds = frame;

        spinner.color = [UIColor darkGrayColor];
        spinner.hidesWhenStopped = NO;
        spinner.backgroundColor = [UIColor clearColor];
        [spinner startAnimating];

        // No need to manage constraints here, iOS defines them
        self.recentsTableView.tableFooterView = footerSpinnerView = spinner;
    }
}

- (void)removeSpinnerFooterView
{
    if (footerSpinnerView)
    {
        footerSpinnerView = nil;

        // Hide line separators of empty cells
        self.recentsTableView.tableFooterView = [[UIView alloc] init];;
    }
}

@end
