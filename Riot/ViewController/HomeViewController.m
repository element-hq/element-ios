/*
 Copyright 2015 OpenMarket Ltd
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

#import "HomeViewController.h"

#import "AppDelegate.h"

#import "RecentsDataSource.h"

@implementation HomeViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    self.screenName = @"Home";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.accessibilityIdentifier = @"HomeVCView";
    self.recentsTableView.accessibilityIdentifier = @"HomeVCTableView";
    
    // TODO: Implement the new home screen.
    // Hide the table view FTM.
    self.recentsTableView.hidden = YES;
    UIImageView *sheltieWaiting = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sheltie-waiting-porch.jpg"]];
    sheltieWaiting.frame = self.view.frame;
    sheltieWaiting.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    sheltieWaiting.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:sheltieWaiting];

    // Add room creation button programmatically
    [self addRoomCreationButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [AppDelegate theDelegate].masterTabBarController.navigationItem.title = NSLocalizedStringFromTable(@"title_home", @"Vector", nil);
    
    if ([self.dataSource isKindOfClass:RecentsDataSource.class])
    {
        // Take the lead on the shared data source.
        RecentsDataSource *recentsDataSource = (RecentsDataSource*)self.dataSource;
        recentsDataSource.areSectionsShrinkable = YES;
        [recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModeHome];
    }
}

- (void)dealloc
{
    
}

- (void)destroy
{
    [super destroy];
}

#pragma mark - Override RecentsViewController

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    // Check whether the recents data source is correctly configured.
    if ([self.dataSource isKindOfClass:RecentsDataSource.class])
    {
        RecentsDataSource *recentsDataSource = (RecentsDataSource*)self.dataSource;
        if (recentsDataSource.recentsDataSourceMode != RecentsDataSourceModeHome)
        {
            return;
        }
    }
    
    [super refreshCurrentSelectedCell:forceVisible];
}

- (void)onRoomCreationButtonPressed
{
    __weak typeof(self) weakSelf = self;
    
    [currentAlert dismiss:NO];
    
    currentAlert = [[MXKAlert alloc] initWithTitle:nil message:nil style:MXKAlertStyleActionSheet];
    
    [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_recents_start_chat_with", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf->currentAlert = nil;
        
        [strongSelf performSegueWithIdentifier:@"presentStartChat" sender:strongSelf];
    }];
    
    [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_recents_create_empty_room", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf->currentAlert = nil;
        
        [strongSelf createAnEmptyRoom];
    }];

    [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_recents_join_room", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf->currentAlert = nil;

        [strongSelf joinARoom];
    }];

    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleCancel handler:^(MXKAlert *alert) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf->currentAlert = nil;
    }];
    
    currentAlert.sourceView = createNewRoomImageView;
    
    currentAlert.mxkAccessibilityIdentifier = @"HomeVCCreateRoomAlert";
    [currentAlert showInViewController:self];
}

@end
