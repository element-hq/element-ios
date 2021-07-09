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

#import "PeopleViewController.h"

#import "UIViewController+RiotSearch.h"

#import "RageShakeManager.h"

#import "RecentsDataSource.h"
#import "RecentTableViewCell.h"
#import "InviteRecentTableViewCell.h"

#import "Riot-Swift.h"

@interface PeopleViewController ()
{
    NSInteger          directRoomsSectionNumber;
    RecentsDataSource *recentsDataSource;
}

@end

@implementation PeopleViewController

+ (instancetype)instantiate
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    PeopleViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"PeopleViewController"];
    return viewController;
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    directRoomsSectionNumber = 0;
    
    self.screenName = @"People";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.accessibilityIdentifier = @"PeopleVCView";
    self.recentsTableView.accessibilityIdentifier = @"PeopleVCTableView";
    
    // Tag the recents table with the its recents data source mode.
    // This will be used by the shared RecentsDataSource instance for sanity checks (see UITableViewDataSource methods).
    self.recentsTableView.tag = RecentsDataSourceModePeople;
    
    // Add the (+) button programmatically
    plusButtonImageView = [self vc_addFABWithImage:[UIImage imageNamed:@"people_floating_action"]
                                            target:self
                                            action:@selector(onPlusButtonPressed)];
    
    // Register table view cell for contacts.
    [self.recentsTableView registerClass:ContactTableViewCell.class forCellReuseIdentifier:ContactTableViewCell.defaultReuseIdentifier];
    
    // Change the table data source. It must be the people view controller itself.
    self.recentsTableView.dataSource = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [AppDelegate theDelegate].masterTabBarController.navigationItem.title = NSLocalizedStringFromTable(@"title_people", @"Vector", nil);
    [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor = ThemeService.shared.theme.tintColor;
    
    if (recentsDataSource)
    {
        // Take the lead on the shared data source.
        recentsDataSource.areSectionsShrinkable = NO;
        [recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModePeople];
    }
}

#pragma mark - 

- (void)displayList:(MXKRecentsDataSource *)listDataSource
{
    [super displayList:listDataSource];
    
    // Change the table data source. It must be the people view controller itself.
    self.recentsTableView.dataSource = self;
    
    // Keep a ref on the recents data source
    if ([listDataSource isKindOfClass:RecentsDataSource.class])
    {
        recentsDataSource = (RecentsDataSource*)listDataSource;
    }
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:MXKContact.class])
    {
        return ContactTableViewCell.class;
    }
    
    return [super cellViewClassForCellData:cellData];
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Retrieve the current number of sections related to the direct rooms.
    // Sanity check: check whether the recents data source is correctly configured.
    directRoomsSectionNumber = 0;
    
    if (recentsDataSource.recentsDataSourceMode == RecentsDataSourceModePeople)
    {
        directRoomsSectionNumber = [self.dataSource numberOfSectionsInTableView:self.recentsTableView];
    }
    
    return directRoomsSectionNumber;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // FIXME: Should this need to check the section?
    if (section >= directRoomsSectionNumber)
    {
        return 0;
    }
    
    return [self.dataSource tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // FIXME: Should this need to check the section?
    if (indexPath.section >= directRoomsSectionNumber)
    {
        // Return a fake cell to prevent app from crashing.
        return [[UITableViewCell alloc] init];
    }
    
    return [self.dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // FIXME: Should this need to check the section?
    if (indexPath.section >= directRoomsSectionNumber)
    {
        return NO;
    }
    
    return [self.dataSource tableView:tableView canEditRowAtIndexPath:indexPath];
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // FIXME: Should this need to check the section?
    if (indexPath.section >= directRoomsSectionNumber)
    {
        return 0.0;
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // FIXME: Should this need to check the section?
    if (indexPath.section >= directRoomsSectionNumber)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        return;
    }
    
    return [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - Override RecentsViewController

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    // Check whether the recents data source is correctly configured.
    if (recentsDataSource.recentsDataSourceMode != RecentsDataSourceModePeople)
    {
        return;
    }
    
    [super refreshCurrentSelectedCell:forceVisible];
}

- (void)onPlusButtonPressed
{
    [self performSegueWithIdentifier:@"presentStartChat" sender:self];
}

#pragma mark -

- (void)scrollToNextRoomWithMissedNotifications
{
    // Check whether the recents data source is correctly configured.
    if (recentsDataSource.recentsDataSourceMode == RecentsDataSourceModePeople)
    {
        [self scrollToTheTopTheNextRoomWithMissedNotificationsInSection:recentsDataSource.conversationSection];
    }
}

#pragma mark - Empty view management

- (void)updateEmptyView
{
    [self.emptyView fillWith:[self emptyViewArtwork]
                       title:NSLocalizedStringFromTable(@"people_empty_view_title", @"Vector", nil)
             informationText:NSLocalizedStringFromTable(@"people_empty_view_information", @"Vector", nil)];
}

- (UIImage*)emptyViewArtwork
{
    if (ThemeService.shared.isCurrentThemeDark)
    {
        return [UIImage imageNamed:@"people_empty_screen_artwork_dark"];
    }
    else
    {
        return [UIImage imageNamed:@"people_empty_screen_artwork"];
    }
}

- (BOOL)shouldShowEmptyView
{
    // Do not present empty screen while searching
    if (recentsDataSource.searchPatternsList.count)
    {
        return NO;
    }
    
    return [self totalItemCounts] == 0;
}

// Total items to display on the screen
- (NSUInteger)totalItemCounts
{
    return recentsDataSource.invitesCellDataArray.count
    + recentsDataSource.conversationCellDataArray.count
    + recentsDataSource.peopleCellDataArray.count;
}

@end
