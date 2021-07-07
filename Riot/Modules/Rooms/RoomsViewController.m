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

#import "RecentsDataSource.h"

#import "Riot-Swift.h"

@interface RoomsViewController ()
{
    RecentsDataSource *recentsDataSource;
}

@end

@implementation RoomsViewController

+ (instancetype)instantiate
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    RoomsViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"RoomsViewController"];
    return viewController;
}

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
    
    // Tag the recents table with the its recents data source mode.
    // This will be used by the shared RecentsDataSource instance for sanity checks (see UITableViewDataSource methods).
    self.recentsTableView.tag = RecentsDataSourceModeRooms;
    
    // Add the (+) button programmatically
    plusButtonImageView = [self vc_addFABWithImage:[UIImage imageNamed:@"rooms_floating_action"]
                                            target:self
                                            action:@selector(onPlusButtonPressed)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [AppDelegate theDelegate].masterTabBarController.navigationItem.title = NSLocalizedStringFromTable(@"title_rooms", @"Vector", nil);
    [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor = ThemeService.shared.theme.tintColor;
    
    if ([self.dataSource isKindOfClass:RecentsDataSource.class])
    {
        // Take the lead on the shared data source.
        recentsDataSource = (RecentsDataSource*)self.dataSource;
        recentsDataSource.areSectionsShrinkable = NO;
        [recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModeRooms];
    }
}

- (void)destroy
{
    [super destroy];
}

#pragma mark - Override RecentsViewController

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    // Check whether the recents data source is correctly configured.
    if (recentsDataSource.recentsDataSourceMode != RecentsDataSourceModeRooms)
    {
        return;
    }
    
    [super refreshCurrentSelectedCell:forceVisible];
}

- (void)onPlusButtonPressed
{
    [self showRoomDirectory];
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // Hide the header to merge Invites and Rooms into a single list.
    return 0.0;
}

#pragma mark - 

- (void)scrollToNextRoomWithMissedNotifications
{
    // Check whether the recents data source is correctly configured.
    if (recentsDataSource.recentsDataSourceMode == RecentsDataSourceModeRooms)
    {
        [self scrollToTheTopTheNextRoomWithMissedNotificationsInSection:recentsDataSource.conversationSection];
    }
}

#pragma mark - Empty view management

- (void)updateEmptyView
{
    [self.emptyView fillWith:[self emptyViewArtwork]
                       title:NSLocalizedStringFromTable(@"rooms_empty_view_title", @"Vector", nil)
             informationText:NSLocalizedStringFromTable(@"rooms_empty_view_information", @"Vector", nil)];
}

- (UIImage*)emptyViewArtwork
{
    if (ThemeService.shared.isCurrentThemeDark)
    {
        return [UIImage imageNamed:@"rooms_empty_screen_artwork_dark"];
    }
    else
    {
        return [UIImage imageNamed:@"rooms_empty_screen_artwork"];
    }
}

- (BOOL)shouldShowEmptyView
{
    // Do not present empty screen while searching
    if (recentsDataSource.searchPatternsList.count)
    {
        return NO;
    }
    
    // Otherwise check the number of items to display
    return [self totalItemCounts] == 0;
}

// Total items to display on the screen
- (NSUInteger)totalItemCounts
{
    return recentsDataSource.conversationCellDataArray.count
    + recentsDataSource.invitesCellDataArray.count;
}

@end
