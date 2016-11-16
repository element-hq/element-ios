/*
 Copyright 2015 OpenMarket Ltd

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

#import "RecentsDataSource.h"
#import "RecentsViewController.h"

#import "RoomDataSource.h"
#import "RoomViewController.h"

#import "DirectoryViewController.h"
#import "ContactDetailsViewController.h"
#import "SettingsViewController.h"

#import "HomeMessagesSearchViewController.h"
#import "HomeMessagesSearchDataSource.h"
#import "HomeFilesSearchViewController.h"
#import "FilesSearchCellData.h"

#import "AppDelegate.h"

#import "GBDeviceInfo_iOS.h"

@interface HomeViewController ()
{
    RecentsViewController *recentsViewController;
    RecentsDataSource *recentsDataSource;

    HomeMessagesSearchViewController *messagesSearchViewController;
    HomeMessagesSearchDataSource *messagesSearchDataSource;
    
    HomeFilesSearchViewController *filesSearchViewController;
    MXKSearchDataSource *filesSearchDataSource;
    
    ContactPickerViewController *contactsViewController;
    MXKContact *selectedContact;

    // Display a gradient view above the screen
    CAGradientLayer* tableViewMaskLayer;

    // Display a button to a new room
    UIImageView* createNewRoomImageView;
    
    MXHTTPOperation *roomCreationRequest;

    // Tell whether the authentication screen is preparing.
    BOOL isAuthViewControllerPreparing;

    // Observer that checks when the Authentification view controller has gone.
    id authViewControllerObserver;

    // The parameters to pass to the Authentification view controller.
    NSDictionary *authViewControllerRegistrationParameters;

    // Current alert (if any).
    MXKAlert *currentAlert;
}

@property(nonatomic,getter=isHidden) BOOL hidden;

@end

@implementation HomeViewController

- (void)viewDidLoad
{
    // Set up the SegmentedVC tabs before calling [super viewDidLoad]
    NSMutableArray* viewControllers = [[NSMutableArray alloc] init];
    NSMutableArray* titles = [[NSMutableArray alloc] init];

    [titles addObject: NSLocalizedStringFromTable(@"search_rooms", @"Vector", nil)];
    recentsViewController = [RecentsViewController recentListViewController];
    recentsViewController.delegate = self;
    [viewControllers addObject:recentsViewController];

    [titles addObject: NSLocalizedStringFromTable(@"search_messages", @"Vector", nil)];
    messagesSearchViewController = [HomeMessagesSearchViewController searchViewController];
    [viewControllers addObject:messagesSearchViewController];

    // Add search People tab
    [titles addObject: NSLocalizedStringFromTable(@"search_people", @"Vector", nil)];
    contactsViewController = [ContactPickerViewController contactPickerViewController];
    contactsViewController.delegate = self;
    [viewControllers addObject:contactsViewController];
    
    // add Files tab
    [titles addObject: NSLocalizedStringFromTable(@"search_files", @"Vector", nil)];
    filesSearchViewController = [HomeFilesSearchViewController searchViewController];
    [viewControllers addObject:filesSearchViewController];

    [self initWithTitles:titles viewControllers:viewControllers defaultSelected:0];

    [super viewDidLoad];
    
    // The navigation bar tint color and the rageShake Manager are handled by super (see SegmentedViewController)

    self.navigationItem.title = NSLocalizedStringFromTable(@"title_recents", @"Vector", nil);

    // Add the Vector background image when search bar is empty
    [self addBackgroundImageViewToView:self.view];
    
    // Add room creation button programatically
    [self addRoomCreationButton];
    
    // Initialize here the data sources if a matrix session has been already set.
    [self initializeDataSources];
    
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
}

- (void)dealloc
{
    [self closeSelectedRoom];
}

- (void)destroy
{
    [super destroy];

    if (currentAlert)
    {
        [currentAlert dismiss:NO];
        currentAlert = nil;
    }

    if (authViewControllerObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:authViewControllerObserver];
        authViewControllerObserver = nil;
    }

    if (roomCreationRequest)
    {
        [roomCreationRequest cancel];
        roomCreationRequest = nil;
    }
    
    if (createNewRoomImageView)
    {
        [createNewRoomImageView removeFromSuperview];
        createNewRoomImageView = nil;
        tableViewMaskLayer = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Show the home view controller content only when a user is logged in.
    self.hidden = ([MXKAccountManager sharedManager].accounts.count == 0);

    // Let's child display the loading not the home view controller
    if (self.activityIndicator)
    {
        [self.activityIndicator stopAnimating];
        self.activityIndicator = nil;
    }
    
    // Refresh the search results if a search in in progress
    if (!self.searchBarHidden)
    {
        [self updateSearch];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Check whether we're not logged in
    if (![MXKAccountManager sharedManager].accounts.count)
    {
        [self showAuthenticationScreen];
    }
    else
    {
        // Check whether the user has been already prompted to send crash reports.
        // (Check whether 'enableCrashReport' flag has been set once)
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"enableCrashReport"])
        {
            [self promptUserBeforeUsingGoogleAnalytics];
        }
        
        // Release the current selected room (if any) except if the Room ViewController is still visible (see splitViewController.isCollapsed condition)
        if (!self.splitViewController || self.splitViewController.isCollapsed)
        {
            // Release the current selected room (if any).
            [self closeSelectedRoom];
        }
        else
        {
            // In case of split view controller where the primary and secondary view controllers are displayed side-by-side onscreen,
            // the selected room (if any) is highlighted.
            [self refreshCurrentSelectedCellInChild:YES];
        }
    }
    
    // Here the actual view size is available, check the background image display if any
    if (!self.searchBarHidden)
    {
        [self checkAndShowBackgroundImage];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    // sanity check
    if (tableViewMaskLayer)
    {
        CGRect currentBounds = tableViewMaskLayer.bounds;
        CGRect newBounds = CGRectIntegral(self.view.frame);

        // check if there is an update
        if (!CGSizeEqualToSize(currentBounds.size, newBounds.size))
        {
            newBounds.origin = CGPointZero;
            tableViewMaskLayer.bounds = newBounds;
        }
    }
}

#pragma mark -

- (void)showAuthenticationScreen
{
    // Check whether an authentication screen is not already shown or preparing
    if (!self.authViewController && !isAuthViewControllerPreparing)
    {
        isAuthViewControllerPreparing = YES;
        
        [[AppDelegate theDelegate] restoreInitialDisplay:^{
            
            [self performSegueWithIdentifier:@"showAuth" sender:self];
            
        }];
    }
}

- (void)showAuthenticationScreenWithRegistrationParameters:(NSDictionary *)parameters
{
    if (self.authViewController)
    {
        NSLog(@"[HomeViewController] Universal link: Forward registration parameter to the existing AuthViewController");
        self.authViewController.externalRegistrationParameters = parameters;
    }
    else
    {
        NSLog(@"[HomeViewController] Universal link: Logout current sessions and open AuthViewController to complete the registration");

        // Keep a ref on the params
        authViewControllerRegistrationParameters = parameters;

        // And do a logout out. It will then display AuthViewController
        [[AppDelegate theDelegate] logout];
    }
}

- (void)initializeDataSources
{
    MXSession *mainSession = self.mainSession;
    
    if (mainSession)
    {
        // Init the recents data source
        recentsDataSource = [[RecentsDataSource alloc] initWithMatrixSession:mainSession];
        [recentsViewController displayList:recentsDataSource fromHomeViewController:self];
        
        // Init the search for messages
        messagesSearchDataSource = [[HomeMessagesSearchDataSource alloc] initWithMatrixSession:mainSession];
        [messagesSearchViewController displaySearch:messagesSearchDataSource];
        
        // Init the search for messages
        filesSearchDataSource = [[MXKSearchDataSource alloc] initWithMatrixSession:mainSession];
        filesSearchDataSource.roomEventFilter.containsURL = YES;
        filesSearchDataSource.shouldShowRoomDisplayName = YES;
        [filesSearchDataSource registerCellDataClass:FilesSearchCellData.class forCellIdentifier:kMXKSearchCellDataIdentifier];
        [filesSearchViewController displaySearch:filesSearchDataSource];
        
        // Check whether there are others sessions
        NSArray* mxSessions = self.mxSessions;
        if (mxSessions.count > 1)
        {
            for (MXSession *mxSession in mxSessions)
            {
                if (mxSession != mainSession)
                {
                    // Add the session to the recents data source
                    [recentsDataSource addMatrixSession:mxSession];
                    
                    // FIXME: Update messagesSearchDataSource and filesSearchDataSource
                }
            }
        }
        
        // Do not go to search mode when first opening the home
        [self hideSearch:NO];

        // Do the one time check on device id
        [self checkDeviceId];
    }
}

- (void)addMatrixSession:(MXSession *)mxSession
{
    // Check whether the controller's view is loaded into memory.
    if (recentsViewController)
    {
        // Check whether the data sources have been initialized.
        if (!recentsDataSource)
        {
            // Add first the session. The updated sessions list will be used during data sources initialization.
            [super addMatrixSession:mxSession];
            
            // Prepare data sources and return
            [self initializeDataSources];
            return;
        }
        else
        {
            // Add the session to the existing recents data source
            [recentsDataSource addMatrixSession:mxSession];
            
            // FIXME: Update messagesSearchDataSource and filesSearchDataSource
        }
    }
    
    [super addMatrixSession:mxSession];
}

- (void)removeMatrixSession:(MXSession *)mxSession
{
    [recentsDataSource removeMatrixSession:mxSession];
    
    // Check whether there are others sessions
    if (!recentsDataSource.mxSessions.count)
    {
        [recentsViewController displayList:nil];
        [recentsDataSource destroy];
        recentsDataSource = nil;
    }
    
    // FIXME: Handle correctly messagesSearchDataSource and filesSearchDataSource
    
    [super removeMatrixSession:mxSession];
}

- (void)selectRoomWithId:(NSString*)roomId andEventId:(NSString*)eventId inMatrixSession:(MXSession*)matrixSession
{
    // Force hiding the keyboard
    [self.searchBar resignFirstResponder];

    if (_selectedRoomId && [_selectedRoomId isEqualToString:roomId]
        && _selectedEventId && [_selectedEventId isEqualToString:eventId]
        && _selectedRoomSession && _selectedRoomSession == matrixSession)
    {
        // Nothing to do
        return;
    }

    _selectedRoomId = roomId;
    _selectedEventId = eventId;
    _selectedRoomSession = matrixSession;

    if (roomId && matrixSession)
    {
        [self performSegueWithIdentifier:@"showDetails" sender:self];
    }
    else
    {
        [self closeSelectedRoom];
    }
}

- (void)showRoomPreview:(RoomPreviewData *)roomPreviewData
{
    // Force hiding the keyboard
    [self.searchBar resignFirstResponder];

    _selectedRoomPreviewData = roomPreviewData;
    _selectedRoomId = roomPreviewData.roomId;
    _selectedRoomSession = roomPreviewData.mxSession;

    [self performSegueWithIdentifier:@"showDetails" sender:self];
}

- (void)closeSelectedRoom
{
    _selectedRoomId = nil;
    _selectedEventId = nil;
    _selectedRoomSession = nil;

    if (_currentRoomViewController)
    {
        // If the displayed data is not a preview, let the manager release the room data source
        // (except if the view controller has the room data source ownership).
        if (!_currentRoomViewController.roomPreviewData && _currentRoomViewController.roomDataSource && !_currentRoomViewController.hasRoomDataSourceOwnership)
        {
            MXSession *mxSession = _currentRoomViewController.roomDataSource.mxSession;
            MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:mxSession];

            // Let the manager release live room data sources where the user is in
            [roomDataSourceManager closeRoomDataSource:_currentRoomViewController.roomDataSource forceClose:NO];
        }

        [_currentRoomViewController destroy];
        _currentRoomViewController = nil;
    }
}

- (void)showPublicRoomsDirectory
{
    // Force hiding the keyboard
    [self.searchBar resignFirstResponder];
    
    [self performSegueWithIdentifier:@"showDirectory" sender:self];
}

#pragma mark - Override MXKViewController

- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    [self setKeyboardHeightForBackgroundImage:keyboardHeight];

    [super setKeyboardHeight:keyboardHeight];
    
    [self checkAndShowBackgroundImage];
}

- (void)startActivityIndicator
{
    // Redirect the operation to the currently displayed VC
    // It is a MXKViewController or a MXKTableViewController. So it supports startActivityIndicator
    [self.selectedViewController performSelector:@selector(startActivityIndicator)];
}

- (void)stopActivityIndicator
{
    // The selected view controller mwy have changed since the call of [self startActivityIndicator]
    // So, stop the activity indicator for all children
    for (UIViewController *viewController in self.viewControllers)
    {
        [viewController performSelector:@selector(stopActivityIndicator)];
    }
 }

#pragma mark - Override UIViewController+VectorSearch

- (void)setKeyboardHeightForBackgroundImage:(CGFloat)keyboardHeight
{
    [super setKeyboardHeightForBackgroundImage:keyboardHeight];

    if (keyboardHeight > 0)
    {
        [self checkAndShowBackgroundImage];
    }
}

// Check conditions before displaying the background
- (void)checkAndShowBackgroundImage
{
    // Note: This background is hidden when keyboard is dismissed.
    // The other conditions depend on the current selected view controller.
    if (self.selectedViewController == recentsViewController)
    {
        self.backgroundImageView.hidden = (!recentsDataSource.hideRecents || !recentsDataSource.hidePublicRoomsDirectory || (self.keyboardHeight == 0));
    }
    else if (self.selectedViewController == messagesSearchViewController)
    {
        self.backgroundImageView.hidden = ((messagesSearchDataSource.serverCount != 0) || !messagesSearchViewController.noResultsLabel.isHidden || (self.keyboardHeight == 0));
    }
    else if (self.selectedViewController == contactsViewController)
    {
        self.backgroundImageView.hidden = (([contactsViewController.contactsTableView numberOfRowsInSection:0] != 0) || !contactsViewController.noResultsLabel.isHidden || (self.keyboardHeight == 0));
    }
    else if (self.selectedViewController == filesSearchViewController)
    {
        self.backgroundImageView.hidden = ((filesSearchDataSource.serverCount != 0) || !filesSearchViewController.noResultsLabel.isHidden || (self.keyboardHeight == 0));
    }
    else
    {
        self.backgroundImageView.hidden = (self.keyboardHeight == 0);
    }
    
    if (!self.backgroundImageView.hidden)
    {
        [self.backgroundImageView layoutIfNeeded];
        [self.selectedViewController.view layoutIfNeeded];
        
        // Check whether there is enough space to display this background
        // For example, in landscape with the iPhone 5 & 6 screen size, the backgroundImageView must be hidden.
        if (self.backgroundImageView.frame.origin.y < 0 || (self.selectedViewController.view.frame.size.height - self.backgroundImageViewBottomConstraint.constant) < self.backgroundImageView.frame.size.height)
        {
            self.backgroundImageView.hidden = YES;
        }
    }
}

#pragma mark - Override SegmentedViewController

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    [super setSelectedIndex:selectedIndex];

    if (!self.searchBarHidden)
    {
        [self updateSearch];
    }
}

#pragma mark - Internal methods

- (void)addRoomCreationButton
{
    // Add blur mask programatically
    tableViewMaskLayer = [CAGradientLayer layer];
    
    CGColorRef opaqueWhiteColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
    CGColorRef transparentWhiteColor = [UIColor colorWithWhite:1.0 alpha:0].CGColor;
    
    tableViewMaskLayer.colors = [NSArray arrayWithObjects:(__bridge id)transparentWhiteColor, (__bridge id)transparentWhiteColor, (__bridge id)opaqueWhiteColor, nil];
    
    // display a gradient to the rencents bottom (20% of the bottom of the screen)
    tableViewMaskLayer.locations = [NSArray arrayWithObjects:
                                    [NSNumber numberWithFloat:0],
                                    [NSNumber numberWithFloat:0.85],
                                    [NSNumber numberWithFloat:1.0], nil];
    
    tableViewMaskLayer.bounds = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    tableViewMaskLayer.anchorPoint = CGPointZero;
    
    // CAConstraint is not supported on IOS.
    // it seems only being supported on Mac OS.
    // so viewDidLayoutSubviews will refresh the layout bounds.
    [self.view.layer addSublayer:tableViewMaskLayer];
    
    // Add room create button
    createNewRoomImageView = [[UIImageView alloc] init];
    [createNewRoomImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:createNewRoomImageView];
    
    createNewRoomImageView.backgroundColor = [UIColor clearColor];
    createNewRoomImageView.contentMode = UIViewContentModeCenter;
    createNewRoomImageView.image = [UIImage imageNamed:@"create_room"];
    
    CGFloat side = 78.0f;
    NSLayoutConstraint* widthConstraint = [NSLayoutConstraint constraintWithItem:createNewRoomImageView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1
                                                                        constant:side];
    
    NSLayoutConstraint* heightConstraint = [NSLayoutConstraint constraintWithItem:createNewRoomImageView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1
                                                                         constant:side];
    
    NSLayoutConstraint* centerXConstraint = [NSLayoutConstraint constraintWithItem:createNewRoomImageView
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1
                                                                          constant:0];
    
    NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:createNewRoomImageView
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1
                                                                         constant:9];
    
    // Available on iOS 8 and later
    [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint, centerXConstraint, bottomConstraint]];
    
    createNewRoomImageView.userInteractionEnabled = YES;
    
    // Handle tap gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onNewRoomPressed)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [createNewRoomImageView addGestureRecognizer:tap];
}

- (void)promptUserBeforeUsingGoogleAnalytics
{
    NSLog(@"[HomeViewController]: Invite the user to send crash reports");
    
    __weak typeof(self) weakSelf = self;
    
    [currentAlert dismiss:NO];

    NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];

    currentAlert = [[MXKAlert alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"google_analytics_use_prompt", @"Vector", nil), appDisplayName]
                                           message:nil
                                             style:MXKAlertStyleAlert];
    
    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"no"]
                                                                style:MXKAlertActionStyleDefault
                                                              handler:^(MXKAlert *alert) {
                                                                  
                                                                  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"enableCrashReport"];
                                                                  [[NSUserDefaults standardUserDefaults] synchronize];
                                                                  
                                                                  if (weakSelf)
                                                                  {
                                                                      __strong __typeof(weakSelf)strongSelf = weakSelf;
                                                                      strongSelf->currentAlert = nil;
                                                                  }
                                                                  
                                                              }];
    [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"yes"]
                               style:MXKAlertActionStyleDefault
                             handler:^(MXKAlert *alert) {
                                 
                                 [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"enableCrashReport"];
                                 [[NSUserDefaults standardUserDefaults] synchronize];
                                 
                                 if (weakSelf)
                                 {
                                     __strong __typeof(weakSelf)strongSelf = weakSelf;
                                     strongSelf->currentAlert = nil;
                                 }
                                 
                                 [[AppDelegate theDelegate] startGoogleAnalytics];
                                 
                             }];
    
    [currentAlert showInViewController:self];
}

// Made the currently displayed child update its selected cell
- (void)refreshCurrentSelectedCellInChild:(BOOL)forceVisible
{
    // TODO: Manage other children than recents
    [recentsViewController refreshCurrentSelectedCell:forceVisible];
}

- (void)setHidden:(BOOL)hidden
{
    _hidden = hidden;
    
    self.selectionContainer.hidden = hidden;
    self.viewControllerContainer.hidden = hidden;
    self.navigationController.navigationBar.hidden = hidden;
    
    createNewRoomImageView.hidden = (hidden ? YES : !self.searchBarHidden);
}

/**
 Check the existence of device id.
 */
- (void)checkDeviceId
{
    // In case of the app update for the e2e encryption, the app starts with
    // no device id provided by the homeserver.
    // Ask the user to login again in order to enable e2e. Ask it once
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"deviceIdAtStartupChecked"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"deviceIdAtStartupChecked"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        // Check if there is a device id
        if (!self.mainSession.matrixRestClient.credentials.deviceId)
        {
            NSLog(@"WARNING: The user has no device. Prompt for login again");

            NSString *msg = NSLocalizedStringFromTable(@"e2e_enabling_on_app_update", @"Vector", nil);

            __weak typeof(self) weakSelf = self;
            [currentAlert dismiss:NO];
            currentAlert = [[MXKAlert alloc] initWithTitle:nil message:msg style:MXKAlertStyleAlert];

            currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"later"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                if (weakSelf)
                {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->currentAlert = nil;
                }

            }];

            [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                if (weakSelf)
                {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->currentAlert = nil;

                    [strongSelf startActivityIndicator];

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{

                        [[MXKAccountManager sharedManager] logout];

                    });
                }

            }];

            [currentAlert showInViewController:self];
        }
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetails"])
    {
        UIViewController *controller;
        if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]])
        {
            controller = [[segue destinationViewController] topViewController];
        }
        else
        {
            controller = [segue destinationViewController];
        }

        if ([controller isKindOfClass:[RoomViewController class]])
        {
            // Release existing Room view controller (if any)
            if (_currentRoomViewController)
            {
                // If the displayed data is not a preview, let the manager release the room data source
                // (except if the view controller has the room data source ownership).
                if (!_currentRoomViewController.roomPreviewData && _currentRoomViewController.roomDataSource && !_currentRoomViewController.hasRoomDataSourceOwnership)
                {
                    MXSession *mxSession = _currentRoomViewController.roomDataSource.mxSession;
                    MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:mxSession];
                    
                    [roomDataSourceManager closeRoomDataSource:_currentRoomViewController.roomDataSource forceClose:NO];
                }

                [_currentRoomViewController destroy];
                _currentRoomViewController = nil;
            }

            _currentRoomViewController = (RoomViewController *)controller;

            if (!_selectedRoomPreviewData)
            {
                MXKRoomDataSource *roomDataSource;
                
                // Check whether an event has been selected from messages or files search tab. Live timeline or timeline from a search result?
                MXEvent *selectedSearchEvent = messagesSearchViewController.selectedEvent;
                MXSession *selectedSearchEventSession = messagesSearchDataSource.mxSession;
                if (!selectedSearchEvent)
                {
                    selectedSearchEvent = filesSearchViewController.selectedEvent;
                    selectedSearchEventSession = filesSearchDataSource.mxSession;
                }
                
                if (!selectedSearchEvent)
                {
                    if (!_selectedEventId)
                    {
                        // LIVE: Show the room live timeline managed by MXKRoomDataSourceManager
                        MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:_selectedRoomSession];
                        roomDataSource = [roomDataSourceManager roomDataSourceForRoom:_selectedRoomId create:YES];
                    }
                    else
                    {
                        // Open the room on the requested event
                        roomDataSource = [[RoomDataSource alloc] initWithRoomId:_selectedRoomId initialEventId:_selectedEventId andMatrixSession:_selectedRoomSession];
                        [roomDataSource finalizeInitialization];
                        
                        // Give the data source ownership to the room view controller.
                        _currentRoomViewController.hasRoomDataSourceOwnership = YES;
                    }
                }
                else
                {
                    // Search result: Create a temp timeline from the selected event
                    roomDataSource = [[RoomDataSource alloc] initWithRoomId:selectedSearchEvent.roomId initialEventId:selectedSearchEvent.eventId andMatrixSession:selectedSearchEventSession];
                    [roomDataSource finalizeInitialization];
                    
                    // Give the data source ownership to the room view controller.
                    _currentRoomViewController.hasRoomDataSourceOwnership = YES;
                }
                
                [_currentRoomViewController displayRoom:roomDataSource];
            }
            else
            {
                [_currentRoomViewController displayRoomPreview:_selectedRoomPreviewData];
                _selectedRoomPreviewData = nil;
            }
        }

        if (self.splitViewController)
        {
            // Refresh selected cell without scrolling the selected cell (We suppose it's visible here)
            [self refreshCurrentSelectedCellInChild:NO];

            // IOS >= 8
            if ([self.splitViewController respondsToSelector:@selector(displayModeButtonItem)])
            {
                controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
            }

            //
            controller.navigationItem.leftItemsSupplementBackButton = YES;
        }
    }
    else
    {
        // Keep ref on destinationViewController
        [super prepareForSegue:segue sender:sender];
        
        if ([[segue identifier] isEqualToString:@"showDirectory"])
        {
            DirectoryViewController *directoryViewController = segue.destinationViewController;
            [directoryViewController displayWitDataSource:recentsDataSource.publicRoomsDirectoryDataSource];
        }
        else if ([[segue identifier] isEqualToString:@"showContactDetails"])
        {
            ContactDetailsViewController *contactDetailsViewController = segue.destinationViewController;
            contactDetailsViewController.enableVoipCall = NO;
            contactDetailsViewController.contact = selectedContact;
        }
        else if ([[segue identifier] isEqualToString:@"showAuth"])
        {
            // Keep ref on the authentification view controller while it is displayed
            // ie until we get the notification about a new account
            _authViewController = segue.destinationViewController;
            isAuthViewControllerPreparing = NO;

            authViewControllerObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidAddAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

                _authViewController = nil;

                [[NSNotificationCenter defaultCenter] removeObserver:authViewControllerObserver];
                authViewControllerObserver = nil;
            }];

            // Forward parameters if any
            if (authViewControllerRegistrationParameters)
            {
                _authViewController.externalRegistrationParameters = authViewControllerRegistrationParameters;
                authViewControllerRegistrationParameters = nil;
            }
        }
    }

    // Hide back button title
    self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

#pragma mark - Search

- (void)showSearch:(BOOL)animated
{
    [super showSearch:animated];
    
    // Reset searches
    [recentsDataSource searchWithPatterns:nil];

    createNewRoomImageView.hidden = YES;
    tableViewMaskLayer.hidden = YES;

    [self updateSearch];
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:@"RoomsGlobalSearch"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
}

- (void)hideSearch:(BOOL)animated
{
    [super hideSearch:animated];

    createNewRoomImageView.hidden = NO;
    tableViewMaskLayer.hidden = NO;
    self.backgroundImageView.hidden = YES;

    [recentsDataSource searchWithPatterns:nil];

    recentsDataSource.hideRecents = NO;
    recentsDataSource.hidePublicRoomsDirectory = YES;
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        NSString *currentScreenName = [tracker get:kGAIScreenName];
        if (!currentScreenName || ![currentScreenName isEqualToString:@"RoomsList"])
        {
            [tracker set:kGAIScreenName value:@"RoomsList"];
            [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
        }
    }
}

// Update search results under the currently selected tab
- (void)updateSearch
{
    if (self.searchBar.text.length)
    {
        recentsDataSource.hideRecents = NO;
        recentsDataSource.hidePublicRoomsDirectory = NO;
        self.backgroundImageView.hidden = YES;

        // Forward the search request to the data source
        if (self.selectedViewController == recentsViewController)
        {
            // Do a AND search on words separated by a space
            NSArray *patterns = [self.searchBar.text componentsSeparatedByString:@" "];

            [recentsDataSource searchWithPatterns:patterns];
            recentsViewController.shouldScrollToTopOnRefresh = YES;
        }
        else if (self.selectedViewController == messagesSearchViewController)
        {
            // Launch the search only if the keyboard is no more visible
            if (!self.searchBar.isFirstResponder)
            {
                // Do it asynchronously to give time to messagesSearchViewController to be set up
                // so that it can display its loading wheel
                dispatch_async(dispatch_get_main_queue(), ^{
                    [messagesSearchDataSource searchMessages:self.searchBar.text force:NO];
                    messagesSearchViewController.shouldScrollToBottomOnRefresh = YES;
                });
            }
        }
        else if (self.selectedViewController == contactsViewController)
        {
            [contactsViewController searchWithPattern:self.searchBar.text];
        }
        else if (self.selectedViewController == filesSearchViewController)
        {
            // Launch the search only if the keyboard is no more visible
            if (!self.searchBar.isFirstResponder)
            {
                // Do it asynchronously to give time to filesSearchViewController to be set up
                // so that it can display its loading wheel
                dispatch_async(dispatch_get_main_queue(), ^{
                    [filesSearchDataSource searchMessages:self.searchBar.text force:NO];
                    filesSearchViewController.shouldScrollToBottomOnRefresh = YES;
                });
            }
        }
    }
    else
    {
        // Nothing to search, show only the public dictionary
        recentsDataSource.hideRecents = YES;
        recentsDataSource.hidePublicRoomsDirectory = NO;
        
        // Reset search result (if any)
        [recentsDataSource searchWithPatterns:nil];
        if (messagesSearchDataSource.searchText.length)
        {
            [messagesSearchDataSource searchMessages:nil force:NO];
        }
        [contactsViewController searchWithPattern:nil];
        if (filesSearchDataSource.searchText.length)
        {
            [filesSearchDataSource searchMessages:nil force:NO];
        }
    }
    
    [self checkAndShowBackgroundImage];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (self.selectedViewController == recentsViewController)
    {
        // As the public room search is local, it can be updated on each text change
        [self updateSearch];
    }
    else if (self.selectedViewController == contactsViewController)
    {
        // As the contact search is local, it can be updated on each text change
        [self updateSearch];
    }
    else if (!self.searchBar.text.length)
    {
        // Reset message search if any
        [self updateSearch];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    if (self.selectedViewController == messagesSearchViewController || self.selectedViewController == filesSearchViewController)
    {
        // As the messages/files search is done homeserver-side, launch it only on the "Search" button
        [self updateSearch];
    }
}

#pragma mark - MXKRecentListViewControllerDelegate

- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoom:(NSString *)roomId inMatrixSession:(MXSession *)matrixSession
{
    // Open the room
    [self selectRoomWithId:roomId andEventId:nil inMatrixSession:matrixSession];
}

#pragma mark - ContactPickerViewControllerDelegate

- (void)contactPickerViewController:(ContactPickerViewController *)contactPickerViewController didSelectContact:(MXKContact*)contact
{
    selectedContact = contact;
    
    // Force hiding the keyboard
    [self.searchBar resignFirstResponder];
    
    [self performSegueWithIdentifier:@"showContactDetails" sender:self];
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == _searchBarButtonIem)
    {
        [self showSearch:YES];
    }
}

- (void)onNewRoomPressed
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
        
        [strongSelf createEmptyRoom];
    }];
    
    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleCancel handler:^(MXKAlert *alert) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf->currentAlert = nil;
    }];
    
    currentAlert.sourceView = createNewRoomImageView;
    
    [currentAlert showInViewController:self];
}
    
- (void)createEmptyRoom
{
    // Sanity check
    if (self.mainSession)
    {
        // Create one room at time
        if (!roomCreationRequest)
        {
            [recentsViewController startActivityIndicator];

            // Create an empty room.
            roomCreationRequest = [self.mainSession createRoom:nil
                                                    visibility:kMXRoomDirectoryVisibilityPrivate
                                                     roomAlias:nil
                                                         topic:nil
                                                       success:^(MXRoom *room) {

                                                           roomCreationRequest = nil;
                                                           [recentsViewController stopActivityIndicator];
                                                           if (currentAlert)
                                                           {
                                                               [currentAlert dismiss:NO];
                                                               currentAlert = nil;
                                                           }

                                                           [self selectRoomWithId:room.state.roomId andEventId:nil inMatrixSession:self.mainSession];

                                                           // Force the expanded header
                                                           self.currentRoomViewController.showExpandedHeader = YES;

                                                       } failure:^(NSError *error) {

                                                           roomCreationRequest = nil;
                                                           [recentsViewController stopActivityIndicator];
                                                           if (currentAlert)
                                                           {
                                                               [currentAlert dismiss:NO];
                                                               currentAlert = nil;
                                                           }

                                                           NSLog(@"[HomeViewController] Create new room failed");

                                                           // Alert user
                                                           [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                           
                                                       }];
        }
        else
        {
            // Ask the user to wait
            __weak __typeof(self) weakSelf = self;
            currentAlert = [[MXKAlert alloc] initWithTitle:nil
                                                   message:NSLocalizedStringFromTable(@"room_creation_wait_for_creation", @"Vector", nil)
                                                     style:MXKAlertStyleAlert];

            currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                                        style:MXKAlertActionStyleCancel
                                                                      handler:^(MXKAlert *alert) {

                                                                          __strong __typeof(weakSelf)strongSelf = weakSelf;
                                                                          strongSelf->currentAlert = nil;

                                                                      }];
            [currentAlert showInViewController:self];

        }
    }
}

@end
