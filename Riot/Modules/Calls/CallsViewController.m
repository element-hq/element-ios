// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

#import "CallsViewController.h"

#import "UIViewController+RiotSearch.h"

#import "RageShakeManager.h"

#import "RecentsDataSource.h"
#import "RecentTableViewCell.h"

#import "Riot-Swift.h"

@interface CallsViewController () <SpaceMembersCoordinatorBridgePresenterDelegate>
{
    NSInteger          callRoomsSectionNumber;
    RecentsDataSource *recentsDataSource;
}

@property(nonatomic) SpaceMembersCoordinatorBridgePresenter *spaceMembersCoordinatorBridgePresenter;

@end

@implementation CallsViewController

+ (instancetype)instantiate
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    CallsViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"CallsViewController"];
    return viewController;
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    callRoomsSectionNumber = 0;
    
    self.screenName = @"Calls";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.accessibilityIdentifier = @"CallsVCView";
    self.recentsTableView.accessibilityIdentifier = @"CallsVCTableView";
    
    // Tag the recents table with the its recents data source mode.
    // This will be used by the shared RecentsDataSource instance for sanity checks (see UITableViewDataSource methods).
    self.recentsTableView.tag = RecentsDataSourceModeSipCalls;
    
    // Add the (+) button programmatically
    plusButtonImageView = [self vc_addFABWithImage:[UIImage imageNamed:@"start_call"]
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
    
    [AppDelegate theDelegate].masterTabBarController.navigationItem.title = [VectorL10n titleCalls];
    [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor = ThemeService.shared.theme.tintColor;
    
    if ([self.dataSource isKindOfClass:RecentsDataSource.class])
    {
        // Take the lead on the shared data source.
        recentsDataSource = (RecentsDataSource*)self.dataSource;
        recentsDataSource.areSectionsShrinkable = NO;
        [recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModeSipCalls];
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

#pragma mark - Override RecentsViewController

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    // Check whether the recents data source is correctly configured.
    if (recentsDataSource.recentsDataSourceMode != RecentsDataSourceModeSipCalls)
    {
        return;
    }
    
    [super refreshCurrentSelectedCell:forceVisible];
}

- (void)onPlusButtonPressed
{
    [super openDialpad];
}

#pragma mark -

- (void)scrollToNextRoomWithMissedNotifications
{
    // Check whether the recents data source is correctly configured.
    if (recentsDataSource.recentsDataSourceMode == RecentsDataSourceModeSipCalls)
    {
        [self scrollToTheTopTheNextRoomWithMissedNotificationsInSection:recentsDataSource.callsSection];
    }
}

#pragma mark - Empty view management

- (void)updateEmptyView
{
    [self.emptyView fillWith:[self emptyViewArtwork]
                       title:[VectorL10n callsEmptyViewTitle]
             informationText:[VectorL10n callsEmptyViewInformation]];
}

- (UIImage*)emptyViewArtwork
{
    if (ThemeService.shared.isCurrentThemeDark)
    {
        // TODO: replace with picture calls_empty_screen_artwork_dark
        return [UIImage imageNamed:@"rooms_empty_screen_artwork_dark"];
    }
    else
    {
        // TODO: replace with picture calls_empty_screen_artwork
        return [UIImage imageNamed:@"rooms_empty_screen_artwork"];
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
