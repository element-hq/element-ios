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

#import "GeneratedInterface-Swift.h"

@interface PeopleViewController () <SpaceMembersCoordinatorBridgePresenterDelegate>
{
    NSInteger          directRoomsSectionNumber;
    RecentsDataSource *recentsDataSource;
}

@property(nonatomic) SpaceMembersCoordinatorBridgePresenter *spaceMembersCoordinatorBridgePresenter;
@property (nonatomic, strong) MXThrottler *tableViewPaginationThrottler;

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
    
    self.screenTimer = [[AnalyticsScreenTimer alloc] initWithScreen:AnalyticsScreenPeople];
    self.tableViewPaginationThrottler = [[MXThrottler alloc] initWithMinimumDelay:0.1];
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
    plusButtonImageView = [self vc_addFABWithImage:AssetImages.peopleFloatingAction.image
                                            target:self
                                            action:@selector(onPlusButtonPressed)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [AppDelegate theDelegate].masterTabBarController.navigationItem.title = [VectorL10n titlePeople];
    [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor = ThemeService.shared.theme.tintColor;
    
    if ([self.dataSource isKindOfClass:RecentsDataSource.class])
    {
        // Take the lead on the shared data source.
        recentsDataSource = (RecentsDataSource*)self.dataSource;
        recentsDataSource.areSectionsShrinkable = NO;
        [recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModePeople];
    }
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([super respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)])
    {
        [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
    
    [self.tableViewPaginationThrottler throttle:^{
        NSInteger section = indexPath.section;
        NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:section];
        if (tableView.numberOfSections > section
            && indexPath.row == numberOfRowsInSection - 1)
        {
            [self->recentsDataSource paginateInSection:section];
        }
    }];
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
    if (self.dataSource.currentSpace != nil)
    {
        self.spaceMembersCoordinatorBridgePresenter = [[SpaceMembersCoordinatorBridgePresenter alloc] initWithUserSessionsService:[UserSessionsService shared] session:self.mainSession spaceId:self.dataSource.currentSpace.spaceId];
        self.spaceMembersCoordinatorBridgePresenter.delegate = self;
        [self.spaceMembersCoordinatorBridgePresenter presentFrom:self animated:YES];
    }
    else
    {
        [self performSegueWithIdentifier:@"presentStartChat" sender:self];
    }
}

#pragma mark -

- (void)scrollToNextRoomWithMissedNotifications
{
    // Check whether the recents data source is correctly configured.
    if (recentsDataSource.recentsDataSourceMode == RecentsDataSourceModePeople)
    {
        [self scrollToTheTopTheNextRoomWithMissedNotificationsInSection:recentsDataSource.peopleSection];
    }
}

#pragma mark - Empty view management

- (void)updateEmptyView
{
    [self.emptyView fillWith:[self emptyViewArtwork]
                       title:[VectorL10n peopleEmptyViewTitle]
             informationText:[VectorL10n peopleEmptyViewInformation]];
}

- (UIImage*)emptyViewArtwork
{
    if (ThemeService.shared.isCurrentThemeDark)
    {
        return AssetImages.peopleEmptyScreenArtworkDark.image;
    }
    else
    {
        return AssetImages.peopleEmptyScreenArtwork.image;
    }
}

#pragma mark - SpaceMembersCoordinatorBridgePresenterDelegate

- (void)spaceMembersCoordinatorBridgePresenterDelegateDidComplete:(SpaceMembersCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        self.spaceMembersCoordinatorBridgePresenter = nil;
    }];
}

@end
