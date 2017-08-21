/*
 Copyright 2017 Aram Sargsyan
 
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

#import "ShareViewController.h"
#import "SegmentedViewController.h"
#import "RoomsListViewController.h"
#import "FallbackViewController.h"
#import "ShareRecentsDataSource.h"
#import "ShareExtensionManager.h"


@interface ShareViewController ()

// The current user account
@property (nonatomic) MXKAccount *userAccount;
@property (nonatomic) id removedAccountObserver;

@property (nonatomic) NSArray <MXRoom *> *rooms;

@property (weak, nonatomic) IBOutlet UIView *masterContainerView;
@property (weak, nonatomic) IBOutlet UILabel *tittleLabel;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (nonatomic) SegmentedViewController *segmentedViewController;


@end


@implementation ShareViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self prepareSession];
    
    [self configureViews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Add observer to handle removed accounts
    self.removedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidRemoveAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self checkUserAccount];
    }];
    
    [self checkUserAccount];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Remove listener
    if (self.removedAccountObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self.removedAccountObserver];
        self.removedAccountObserver = nil;
    }
    
    [self.userAccount pauseInBackgroundTask];
}

#pragma mark - Private

- (void)prepareSession
{
    // Apply the application group
    [MXKAppSettings standardAppSettings].applicationGroup = @"group.im.vector";
    
    // We consider for now the first enabled account.
    // TODO: Handle multiple accounts
    self.userAccount = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    if (self.userAccount)
    {
        NSLog(@"[ShareViewController] openSession for %@ account", self.userAccount.mxCredentials.userId);
        // Use MXFileStore as MXStore to permanently store events.
        [self.userAccount openSessionWithStore:[[MXFileStore alloc] init]];
        
        [self addMatrixSession:self.userAccount.mxSession];
    }
}

- (void)checkUserAccount
{
    // Force account manager to reload account from the local storage.
    [[MXKAccountManager sharedManager] forceReloadAccounts];
    
    if (self.userAccount)
    {
        // Check whether the used account is still the first active one
        MXKAccount *firstAccount = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        
        // Compare the access token
        if (!firstAccount || ![self.userAccount.mxCredentials.accessToken isEqualToString:firstAccount.mxCredentials.accessToken])
        {
            // Remove this account
            [self removeMatrixSession:self.userAccount.mxSession];
            [self.userAccount closeSession:YES];
            self.userAccount = nil;
        }
    }
    
    if (self.userAccount)
    {
        // Resume the matrix session
        [self.userAccount resume];
    }
    else
    {
        // Prepare a new session if a new account is available.
        [self prepareSession];
        
        [self configureViews];
    }
}

- (void)configureViews
{
    self.masterContainerView.layer.cornerRadius = 7;
    
    // Empty the content view
    NSArray *subviews = self.contentView.subviews;
    for (UIView *subview in subviews)
    {
        [subview removeFromSuperview];
    }
    
    // Release the current segmented view controller if any
    if (self.segmentedViewController)
    {
        // Release correctly all the existing data source and view controllers.
        [self.segmentedViewController destroy];
        self.segmentedViewController = nil;
    }
    
    if (self.mainSession)
    {
        self.tittleLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"send_to", @"Vector", nil), @""];
        [self configureSegmentedViewController];
    }
    else
    {
        NSDictionary *infoDictionary = [NSBundle mainBundle].infoDictionary;
        NSString *bundleDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
        self.tittleLabel.text = bundleDisplayName;
        [self configureFallbackViewController];
    }
}

- (void)configureSegmentedViewController
{
    self.segmentedViewController = [SegmentedViewController segmentedViewController];
    
    NSArray *titles = @[NSLocalizedStringFromTable(@"title_rooms", @"Vector", nil) , NSLocalizedStringFromTable(@"title_people", @"Vector", nil)];
    
    void (^failureBlock)() = ^void() {
        [self dismissViewControllerAnimated:YES completion:^{
            [[ShareExtensionManager sharedManager] terminateExtensionCanceled:NO];
        }];
    };
    
    ShareRecentsDataSource *roomsDataSource = [[ShareRecentsDataSource alloc] initWithMatrixSession:self.mainSession dataSourceMode:RecentsDataSourceModeRooms];
    RoomsListViewController *roomsViewController = [RoomsListViewController recentListViewController];
    roomsViewController.failureBlock = failureBlock;
    [roomsViewController displayList:roomsDataSource];
    
    ShareRecentsDataSource *peopleDataSource = [[ShareRecentsDataSource alloc] initWithMatrixSession:self.mainSession dataSourceMode:RecentsDataSourceModePeople];
    RoomsListViewController *peopleViewController = [RoomsListViewController recentListViewController];
    peopleViewController.failureBlock = failureBlock;
    [peopleViewController displayList:peopleDataSource];
    
    [self.segmentedViewController initWithTitles:titles viewControllers:@[roomsViewController, peopleViewController] defaultSelected:0];
    
    [self addChildViewController:self.segmentedViewController];
    [self.contentView addSubview:self.segmentedViewController.view];
    [self.segmentedViewController didMoveToParentViewController:self];
    
    [self autoPinSubviewEdges:self.segmentedViewController.view toSuperviewEdges:self.contentView];
}

- (void)configureFallbackViewController
{
    FallbackViewController *fallbackVC = [FallbackViewController new];
    [self addChildViewController:fallbackVC];
    [self.contentView addSubview:fallbackVC.view];
    [fallbackVC didMoveToParentViewController:self];
    
    [self autoPinSubviewEdges:fallbackVC.view toSuperviewEdges:self.contentView];
}

- (void)autoPinSubviewEdges:(UIView *)subview toSuperviewEdges:(UIView *)superview
{
    subview.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    widthConstraint.active = YES;
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
    heightConstraint.active = YES;
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    centerXConstraint.active = YES;
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    centerYConstraint.active = YES;
}

#pragma mark - Actions

- (IBAction)close:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[ShareExtensionManager sharedManager] terminateExtensionCanceled:YES];
    }];
}


@end
