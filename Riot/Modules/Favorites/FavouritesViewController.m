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

#import "FavouritesViewController.h"

#import "AppDelegate.h"

#import "RecentsDataSource.h"

@interface FavouritesViewController ()
{    
    RecentsDataSource *recentsDataSource;
}

@end

@implementation FavouritesViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    self.screenName = @"Favourites";
    
    self.enableDragging = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.accessibilityIdentifier = @"FavouritesVCView";
    self.recentsTableView.accessibilityIdentifier = @"FavouritesVCTableView";
    
    // Tag the recents table with the its recents data source mode.
    // This will be used by the shared RecentsDataSource instance for sanity checks (see UITableViewDataSource methods).
    self.recentsTableView.tag = RecentsDataSourceModeFavourites;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [AppDelegate theDelegate].masterTabBarController.navigationItem.title = NSLocalizedStringFromTable(@"title_favourites", @"Vector", nil);
    [AppDelegate theDelegate].masterTabBarController.navigationController.navigationBar.tintColor = kRiotColorIndigo;
    [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor = kRiotColorIndigo;
    
    if (recentsDataSource)
    {
        // Take the lead on the shared data source.
        recentsDataSource.areSectionsShrinkable = NO;
        [recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModeFavourites];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([AppDelegate theDelegate].masterTabBarController.tabBar.tintColor == kRiotColorIndigo)
    {
        // Restore default tintColor
        [AppDelegate theDelegate].masterTabBarController.navigationController.navigationBar.tintColor = kRiotColorGreen;
        [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor = kRiotColorGreen;
    }
}

- (void)dealloc
{
    
}

- (void)destroy
{
    [super destroy];
}

#pragma mark -

- (void)displayList:(MXKRecentsDataSource *)listDataSource
{
    [super displayList:listDataSource];
    
    // Keep a ref on the recents data source
    if ([listDataSource isKindOfClass:RecentsDataSource.class])
    {
        recentsDataSource = (RecentsDataSource*)listDataSource;
    }
}

#pragma mark - Override RecentsViewController

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    // Check whether the recents data source is correctly configured.
    if (recentsDataSource.recentsDataSourceMode != RecentsDataSourceModeFavourites)
    {
        return;
    }
    
    [super refreshCurrentSelectedCell:forceVisible];
}

#pragma mark -

- (void)scrollToNextRoomWithMissedNotifications
{
    // Check whether the recents data source is correctly configured.
    if (recentsDataSource.recentsDataSourceMode == RecentsDataSourceModeFavourites)
    {
        [self scrollToTheTopTheNextRoomWithMissedNotificationsInSection:recentsDataSource.favoritesSection];
    }
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // Hide the unique header
    return 0.0f;
}

@end
