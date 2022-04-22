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

#import "RecentsDataSource.h"
#import "GeneratedInterface-Swift.h"

@interface FavouritesViewController () <MasterTabBarItemDisplayProtocol>
{    
    RecentsDataSource *recentsDataSource;
}

@property (nonatomic, strong) MXThrottler *tableViewPaginationThrottler;

@end

@implementation FavouritesViewController

+ (instancetype)instantiate
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    FavouritesViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"FavouritesViewController"];
    return viewController;
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    self.enableDragging = YES;
    
    self.screenTracker = [[AnalyticsScreenTracker alloc] initWithScreen:AnalyticsScreenFavourites];
    self.tableViewPaginationThrottler = [[MXThrottler alloc] initWithMinimumDelay:0.1];
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
    [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor = ThemeService.shared.theme.tintColor;
    
    if (recentsDataSource.recentsDataSourceMode != RecentsDataSourceModeFavourites)
    {
        // Take the lead on the shared data source.
        [recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModeFavourites];
        
        // Reset filtering on the shared data source when switching tabs
        [recentsDataSource searchWithPatterns:nil];
        [self.recentsSearchBar setText:nil];
    }
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
        [self scrollToTheTopTheNextRoomWithMissedNotificationsInSection:[recentsDataSource.sections sectionIndexForSectionType:RecentsDataSourceSectionTypeFavorites]];
    }
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // Hide the unique header
    return 0.0f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([super respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)])
    {
        [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
    
    [self.tableViewPaginationThrottler throttle:^{
        NSInteger section = indexPath.section;
        if (tableView.numberOfSections <= section)
        {
            return;
        }
        
        NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
        if (indexPath.row == numberOfRowsInSection - 1)
        {
            [self->recentsDataSource paginateInSection:section];
        }
    }];
}

#pragma mark - Empty view management

- (void)updateEmptyView
{
    [self.emptyView fillWith:[self emptyViewArtwork]
                       title:[VectorL10n favouritesEmptyViewTitle]
             informationText:[VectorL10n favouritesEmptyViewInformation]];
}

- (UIImage*)emptyViewArtwork
{
    if (ThemeService.shared.isCurrentThemeDark)
    {
        return AssetImages.favouritesEmptyScreenArtworkDark.image;
    }
    else
    {
        return AssetImages.favouritesEmptyScreenArtwork.image;
    }
}

#pragma mark - MasterTabBarItemDisplayProtocol

- (NSString *)masterTabBarItemTitle
{
    return [VectorL10n titleFavourites];
}

@end
