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

#import "GroupDetailsViewController.h"

#import "AppDelegate.h"

#import "MXGroup+Riot.h"

@interface GroupDetailsViewController ()
{
    /**
     mask view while processing a request
     */
    UIActivityIndicatorView * pendingMaskSpinnerView;
    
    /**
     Current alert (if any).
     */
    UIAlertController *currentAlert;
    
    /**
     Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
     */
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
    
    /**
     The current visibility of the status bar in this view controller.
     */
    BOOL isStatusBarHidden;
}
@end

@implementation GroupDetailsViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)groupDetailsViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass(self.class)
                                          bundle:[NSBundle bundleForClass:self.class]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // Keep visible the status bar by default.
    isStatusBarHidden = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Check whether the view controller has been pushed via storyboard
    if (!_tableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    self.groupAvatar.contentMode = UIViewContentModeScaleAspectFill;
    self.groupAvatar.defaultBackgroundColor = [UIColor clearColor];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.groupNameLabelMask addGestureRecognizer:tap];
    self.groupNameLabelMask.userInteractionEnabled = YES;

    // Add tap to show the group avatar in fullscreen
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.groupAvatarMask addGestureRecognizer:tap];
    self.groupAvatarMask.userInteractionEnabled = YES;
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    // Observe user interface theme change.
    kRiotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    self.defaultBarTintColor = kRiotSecondaryBgColor;
    self.barTitleColor = kRiotPrimaryTextColor;
    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    self.headerView.backgroundColor = kRiotSecondaryBgColor;
    self.groupNameLabel.textColor = kRiotPrimaryTextColor;
    self.groupDescriptionLabel.textColor = kRiotColorGreen;
    
    // Check the table view style to select its bg color.
    self.tableView.backgroundColor = ((self.tableView.style == UITableViewStylePlain) ? kRiotPrimaryBgColor : kRiotSecondaryBgColor);
    self.view.backgroundColor = self.tableView.backgroundColor;
    
    if (self.tableView.dataSource)
    {
        [self.tableView reloadData];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return kRiotDesignStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden
{
    // Return the current status bar visibility.
    return isStatusBarHidden;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:@"GroupDetails"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
    
    // Hide the bottom border of the navigation bar to display the expander header
    [self hideNavigationBarBorder:YES];
    
    // Report matrix session from AppDelegate
    NSArray *mxSessions = [AppDelegate theDelegate].mxSessions;
    for (MXSession *mxSession in mxSessions)
    {
        [self addMatrixSession:mxSession];
    }
    
    if (_group)
    {
        // Register on notifications related to the group change
        [self registerOnGroupChangeNotifications];
        
        // Force refresh
        [self refreshGroupDetails];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self cancelRegistrationOnGroupChangeNotifications];
    
    // Restore navigation bar display
    [self hideNavigationBarBorder:NO];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Restore navigation bar display
    [self hideNavigationBarBorder:NO];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(coordinator.transitionDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // Hide the bottom border of the navigation bar
        [self hideNavigationBarBorder:YES];
        
    });
}

- (void)destroy
{
    [super destroy];
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
    }
    
    [self cancelRegistrationOnGroupChangeNotifications];
    
    [self removePendingActionMask];
    
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    currentAlert = nil;
}

#pragma mark -

- (void)setGroup:(MXGroup *)group
{
    [self cancelRegistrationOnGroupChangeNotifications];
    
    _group = group;
    
    [self registerOnGroupChangeNotifications];
    
    [self refreshGroupDetails];
}

#pragma mark -

- (void)registerOnGroupChangeNotifications
{
    //@TODO
}

- (void)cancelRegistrationOnGroupChangeNotifications
{
    // Remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refreshGroupDetails
{
    [self refreshGroupDisplayName];
    [self refreshGroupThumbnail];
    
    self.groupDescriptionLabel.text = _group.summary.profile.shortDescription;
    
    [self.tableView reloadData];
}

- (void)refreshGroupThumbnail
{
    [_group setGroupAvatarImageIn:self.groupAvatar matrixSession:self.mainSession];
    
    [self.groupAvatar.layer setCornerRadius:self.groupAvatar.frame.size.width / 2];
    [self.groupAvatar setClipsToBounds:YES];
}

- (void)refreshGroupDisplayName
{
    self.groupNameLabel.text = _group.summary.profile.name;
    
    if (!self.groupNameLabel.text.length)
    {
        self.groupNameLabel.text = _group.groupId;
    }
}

#pragma mark - Hide/Show navigation bar border

- (void)hideNavigationBarBorder:(BOOL)isHidden
{
    // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
    UINavigationController *mainNavigationController = self.navigationController;
    if (self.splitViewController && self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
    {
        mainNavigationController = self.splitViewController.viewControllers.firstObject;
    }
    
    if (isHidden)
    {
        // The default shadow image is nil. When non-nil, this property represents a custom shadow image to show instead
        // of the default. For a custom shadow image to be shown, a custom background image must also be set with the
        // setBackgroundImage:forBarMetrics: method. If the default background image is used, then the default shadow
        // image will be used regardless of the value of this property.
        [mainNavigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
        [mainNavigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    }
    else
    {
        // Restore default navigationbar settings
        [mainNavigationController.navigationBar setShadowImage:nil];
        [mainNavigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    }
}

#pragma mark - TableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionCount = 0;
    
    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    // Create a fake cell to prevent app from crashing
    cell = [[UITableViewCell alloc] init];
    
    return cell;
}

#pragma mark - TableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = kRiotPrimaryBgColor;
    
    // Update the selected background view
    if (kRiotSelectedBgColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = kRiotSelectedBgColor;
    }
    else
    {
        if (tableView.style == UITableViewStylePlain)
        {
            cell.selectedBackgroundView = nil;
        }
        else
        {
            cell.selectedBackgroundView.backgroundColor = nil;
        }
    }
}

#pragma mark - button management

- (BOOL)hasPendingAction
{
    return nil != pendingMaskSpinnerView;
}

- (void)addPendingActionMask
{
    // add a spinner above the tableview to avoid that the user tap on any other button
    pendingMaskSpinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    pendingMaskSpinnerView.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    pendingMaskSpinnerView.frame = self.tableView.frame;
    pendingMaskSpinnerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    
    // append it
    [self.tableView.superview addSubview:pendingMaskSpinnerView];
    
    // animate it
    [pendingMaskSpinnerView startAnimating];
}

- (void)removePendingActionMask
{
    if (pendingMaskSpinnerView)
    {
        [pendingMaskSpinnerView removeFromSuperview];
        pendingMaskSpinnerView = nil;
        [self.tableView reloadData];
    }
}

#pragma mark - Action

- (void)handleTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer
{
    UIView *view = tapGestureRecognizer.view;
    
    if (view == self.groupNameLabelMask && _group.summary.profile.name)
    {
        if ([self.groupNameLabel.text isEqualToString:_group.summary.profile.name])
        {
            // Display group's matrix id
            self.groupNameLabel.text = _group.groupId;
        }
        else
        {
            // Restore display name
            self.groupNameLabel.text = _group.summary.profile.name;
        }
    }
    else if (view == self.groupAvatarMask)
    {
        // Show the avatar in full screen
        __block MXKImageView * avatarFullScreenView = [[MXKImageView alloc] initWithFrame:CGRectZero];
        avatarFullScreenView.stretchable = YES;

        [avatarFullScreenView setRightButtonTitle:[NSBundle mxk_localizedStringForKey:@"ok"] handler:^(MXKImageView* imageView, NSString* buttonTitle) {
            [avatarFullScreenView dismissSelection];
            [avatarFullScreenView removeFromSuperview];

            avatarFullScreenView = nil;
            
            isStatusBarHidden = NO;
            // Trigger status bar update
            [self setNeedsStatusBarAppearanceUpdate];
        }];

        NSString *avatarURL = [self.mainSession.matrixRestClient urlOfContent:_group.summary.profile.avatarUrl];
        [avatarFullScreenView setImageURL:avatarURL
                                 withType:nil
                      andImageOrientation:UIImageOrientationUp
                             previewImage:self.groupAvatar.image];

        [avatarFullScreenView showFullScreen];
        isStatusBarHidden = YES;
        
        // Trigger status bar update
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

@end
