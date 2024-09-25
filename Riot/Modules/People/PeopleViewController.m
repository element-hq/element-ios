/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "PeopleViewController.h"

#import "UIViewController+RiotSearch.h"

#import "RageShakeManager.h"

#import "RecentsDataSource.h"
#import "RecentTableViewCell.h"
#import "InviteRecentTableViewCell.h"

#import "GeneratedInterface-Swift.h"

@interface PeopleViewController () <SpaceMembersCoordinatorBridgePresenterDelegate, MasterTabBarItemDisplayProtocol>
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
    
    self.screenTracker = [[AnalyticsScreenTracker alloc] initWithScreen:AnalyticsScreenPeople];
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
    
    UIImage *fabImage = self.dataSource.currentSpace == nil ? AssetImages.peopleFloatingAction.image : AssetImages.addMemberFloatingAction.image;
    // Add the (+) button programmatically
    plusButtonImageView = [self vc_addFABWithImage:fabImage
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
    [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor = ThemeService.shared.theme.tintColor;
    
    if ([self.dataSource isKindOfClass:RecentsDataSource.class])
    {
        // Take the lead on the shared data source.
        recentsDataSource = (RecentsDataSource*)self.dataSource;
        
        if (recentsDataSource.recentsDataSourceMode != RecentsDataSourceModePeople)
        {
            // Take the lead on the shared data source.
            [recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModePeople];
            
            // Reset filtering on the shared data source when switching tabs
            [recentsDataSource searchWithPatterns:nil];
            [self.recentsSearchBar setText:nil];
        }
    }
}

#pragma mark - UITableView delegate

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
        [self scrollToTheTopTheNextRoomWithMissedNotificationsInSection:[recentsDataSource.sections sectionIndexForSectionType:RecentsDataSourceSectionTypePeople]];
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

#pragma mark - MasterTabBarItemDisplayProtocol

- (NSString *)masterTabBarItemTitle
{
    return [VectorL10n titlePeople];
}

@end
