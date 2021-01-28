/*
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd

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

#import "MasterTabBarController.h"

#import "UnifiedSearchViewController.h"

#import "RecentsDataSource.h"
#import "GroupsDataSource.h"


#import "MXRoom+Riot.h"
#import "MXSession+Riot.h"

#import "SettingsViewController.h"
#import "SecurityViewController.h"

#import "Riot-Swift.h"

@interface MasterTabBarController () <AuthenticationViewControllerDelegate>
{
    // Array of `MXSession` instances.
    NSMutableArray *mxSessionArray;    
    
    // Tell whether the authentication screen is preparing.
    BOOL isAuthViewControllerPreparing;
    
    // Observer that checks when the Authentification view controller has gone.
    id authViewControllerObserver;
    id authViewRemovedAccountObserver;
    
    // The parameters to pass to the Authentification view controller.
    NSDictionary *authViewControllerRegistrationParameters;
    MXCredentials *softLogoutCredentials;
    
    // The recents data source shared between all the view controllers of the tab bar.
    RecentsDataSource *recentsDataSource;
    
    // The current unified search screen if any
    UnifiedSearchViewController *unifiedSearchViewController;
    
    // Current alert (if any).
    UIAlertController *currentAlert;
    
    // Keep reference on the pushed view controllers to release them correctly
    NSMutableArray *childViewControllers;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
    
    // The groups data source
    GroupsDataSource *groupsDataSource;
}

@property(nonatomic,getter=isHidden) BOOL hidden;

@property(nonatomic) BOOL reviewSessionAlertHasBeenDisplayed;

@end

@implementation MasterTabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _authenticationInProgress = NO;
    
    // Note: UITabBarViewController shoud not be embed in a UINavigationController (https://github.com/vector-im/riot-ios/issues/3086)
    [self vc_removeBackTitle];

    // Retrieve the all view controllers
    _homeViewController = self.viewControllers[TABBAR_HOME_INDEX];
    _favouritesViewController = self.viewControllers[TABBAR_FAVOURITES_INDEX];
    _peopleViewController = self.viewControllers[TABBAR_PEOPLE_INDEX];
    _roomsViewController = self.viewControllers[TABBAR_ROOMS_INDEX];
    _groupsViewController = self.viewControllers[TABBAR_GROUPS_INDEX];
    
    // Set the accessibility labels for all buttons #1842
    [_settingsBarButtonItem setAccessibilityLabel:NSLocalizedStringFromTable(@"settings_title", @"Vector", nil)];
    [_searchBarButtonIem setAccessibilityLabel:NSLocalizedStringFromTable(@"search_default_placeholder", @"Vector", nil)];
    [_homeViewController setAccessibilityLabel:NSLocalizedStringFromTable(@"title_home", @"Vector", nil)];
    [_favouritesViewController setAccessibilityLabel:NSLocalizedStringFromTable(@"title_favourites", @"Vector", nil)];
    [_peopleViewController setAccessibilityLabel:NSLocalizedStringFromTable(@"title_people", @"Vector", nil)];
    [_roomsViewController setAccessibilityLabel:NSLocalizedStringFromTable(@"title_rooms", @"Vector", nil)];
    [_groupsViewController setAccessibilityLabel:NSLocalizedStringFromTable(@"title_groups", @"Vector", nil)];
    
    // Sanity check
    NSAssert(_homeViewController && _favouritesViewController && _peopleViewController && _roomsViewController && _groupsViewController, @"Something wrong in Main.storyboard");

    // Adjust the display of the icons in the tabbar.
    for (UITabBarItem *tabBarItem in self.tabBar.items)
    {
        if (@available(iOS 13.0, *))
        {
            // Fix iOS 13 misalignment tab bar images. Some titles are nil and other empty strings. Nil title behaves as if a non-empty title was set.
            // Note: However no need to modify imageInsets property on iOS 13.
            tabBarItem.title = @"";            
        }
        else
        {
            tabBarItem.imageInsets = UIEdgeInsetsMake(5, 0, -5, 0);
        }
    }
    
    childViewControllers = [NSMutableArray array];
    
    // Initialize here the data sources if a matrix session has been already set.
    [self initializeDataSources];
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    [ThemeService.shared.theme applyStyleOnTabBar:self.tabBar];
    
    self.view.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.selectedViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.selectedViewController;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Show the tab bar view controller content only when a user is logged in.
    self.hidden = ([MXKAccountManager sharedManager].accounts.count == 0);
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"[MasterTabBarController] viewDidAppear");
    [super viewDidAppear:animated];
    
    // Check whether we're not logged in
    BOOL authIsShown = NO;
    if (![MXKAccountManager sharedManager].accounts.count)
    {
        [self showAuthenticationScreen];
        authIsShown = YES;
    }
    else if (![MXKAccountManager sharedManager].activeAccounts.count)
    {
        // Display a login screen if the account is soft logout
        // Note: We support only one account
        MXKAccount *account = [MXKAccountManager sharedManager].accounts.firstObject;
        if (account.isSoftLogout)
        {
            [self showAuthenticationScreenAfterSoftLogout:account.mxCredentials];
            authIsShown = YES;
        }
    }

    if (!authIsShown)
    {
        // Check whether the user has been already prompted to send crash reports.
        // (Check whether 'enableCrashReport' flag has been set once)        
        if (!RiotSettings.shared.isEnableCrashReportHasBeenSetOnce)
        {
            [self promptUserBeforeUsingAnalytics];
        }
        
        [self refreshTabBarBadges];
        
        // Release properly pushed and/or presented view controller
        if (childViewControllers.count)
        {
            for (id viewController in childViewControllers)
            {
                if ([viewController isKindOfClass:[UINavigationController class]])
                {
                    UINavigationController *navigationController = (UINavigationController*)viewController;
                    for (id subViewController in navigationController.viewControllers)
                    {
                        if ([subViewController respondsToSelector:@selector(destroy)])
                        {
                            [subViewController destroy];
                        }
                    }
                }
                else if ([viewController respondsToSelector:@selector(destroy)])
                {
                    [viewController destroy];
                }
            }
            
            [childViewControllers removeAllObjects];
        }
        
        [[AppDelegate theDelegate] checkAppVersion];
    }
    
    if (unifiedSearchViewController)
    {
        [unifiedSearchViewController destroy];
        unifiedSearchViewController = nil;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)dealloc
{
    mxSessionArray = nil;
    
    _homeViewController = nil;
    _favouritesViewController = nil;
    _peopleViewController = nil;
    _roomsViewController = nil;
    _groupsViewController = nil;
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    if (authViewControllerObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:authViewControllerObserver];
        authViewControllerObserver = nil;
    }
    if (authViewRemovedAccountObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:authViewRemovedAccountObserver];
        authViewRemovedAccountObserver = nil;
    }
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    
    childViewControllers = nil;
}

#pragma mark -

- (NSArray*)mxSessions
{
    return [NSArray arrayWithArray:mxSessionArray];
}

- (void)initializeDataSources
{
    MXSession *mainSession = mxSessionArray.firstObject;
    
    if (mainSession)
    {
        NSLog(@"[MasterTabBarController] initializeDataSources");
        
        // Init the recents data source
        recentsDataSource = [[RecentsDataSource alloc] initWithMatrixSession:mainSession];
        
        [_homeViewController displayList:recentsDataSource];
        [_favouritesViewController displayList:recentsDataSource];
        [_peopleViewController displayList:recentsDataSource];
        [_roomsViewController displayList:recentsDataSource];
        
        // Restore the right delegate of the shared recent data source.
        id<MXKDataSourceDelegate> recentsDataSourceDelegate = _homeViewController;
        RecentsDataSourceMode recentsDataSourceMode = RecentsDataSourceModeHome;
        switch (self.selectedIndex)
        {
            case TABBAR_HOME_INDEX:
                break;
            case TABBAR_FAVOURITES_INDEX:
                recentsDataSourceDelegate = _favouritesViewController;
                recentsDataSourceMode = RecentsDataSourceModeFavourites;
                break;
            case TABBAR_PEOPLE_INDEX:
                recentsDataSourceDelegate = _peopleViewController;
                recentsDataSourceMode = RecentsDataSourceModePeople;
                break;
            case TABBAR_ROOMS_INDEX:
                recentsDataSourceDelegate = _roomsViewController;
                recentsDataSourceMode = RecentsDataSourceModeRooms;
                break;
                
            default:
                break;
        }
        [recentsDataSource setDelegate:recentsDataSourceDelegate andRecentsDataSourceMode:recentsDataSourceMode];
        
        // Init the recents data source
        groupsDataSource = [[GroupsDataSource alloc] initWithMatrixSession:mainSession];
        [groupsDataSource finalizeInitialization];
        [_groupsViewController displayList:groupsDataSource];
        
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
                }
            }
        }
    }
}

- (void)addMatrixSession:(MXSession *)mxSession
{
    // Check whether the controller's view is loaded into memory.
    if (_homeViewController)
    {
        // Check whether the data sources have been initialized.
        if (!recentsDataSource)
        {
            // Add first the session. The updated sessions list will be used during data sources initialization.
            mxSessionArray = [NSMutableArray array];
            [mxSessionArray addObject:mxSession];
            
            // Prepare data sources and return
            [self initializeDataSources];
            
            // Add matrix sessions observer on first added session
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatrixSessionStateDidChange:) name:kMXSessionStateDidChangeNotification object:nil];
            return;
        }
        else
        {
            // Add the session to the existing data sources
            [recentsDataSource addMatrixSession:mxSession];
        }
    }
    
    if (!mxSessionArray)
    {
        mxSessionArray = [NSMutableArray array];
        
        // Add matrix sessions observer on first added session
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatrixSessionStateDidChange:) name:kMXSessionStateDidChangeNotification object:nil];
    }
    [mxSessionArray addObject:mxSession];
    
    // @TODO: handle multi sessions for groups
}

- (void)removeMatrixSession:(MXSession *)mxSession
{
    [recentsDataSource removeMatrixSession:mxSession];
    
    // Check whether there are others sessions
    if (!recentsDataSource.mxSessions.count)
    {
        // Remove matrix sessions observer
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionStateDidChangeNotification object:nil];
        
        [_homeViewController displayList:nil];
        [_favouritesViewController displayList:nil];
        [_peopleViewController displayList:nil];
        [_roomsViewController displayList:nil];
        
        [recentsDataSource destroy];
        recentsDataSource = nil;
    }
    
    [mxSessionArray removeObject:mxSession];
    
    // @TODO: handle multi sessions for groups
}

- (void)onMatrixSessionStateDidChange:(NSNotification *)notif
{
    [self refreshTabBarBadges];
}

- (void)showAuthenticationScreen
{
    NSLog(@"[MasterTabBarController] showAuthenticationScreen");
    
    // Check whether an authentication screen is not already shown or preparing
    if (!self.authViewController && !isAuthViewControllerPreparing)
    {
        isAuthViewControllerPreparing = YES;
        _authenticationInProgress = YES;
        
        [self resetReviewSessionsFlags];
        
        [[AppDelegate theDelegate] restoreInitialDisplay:^{
            
            [self performSegueWithIdentifier:@"showAuth" sender:self];
            
        }];
    }
}

- (void)showAuthenticationScreenWithRegistrationParameters:(NSDictionary *)parameters
{
    if (self.authViewController)
    {
        NSLog(@"[MasterTabBarController] Universal link: Forward registration parameter to the existing AuthViewController");
        self.authViewController.externalRegistrationParameters = parameters;
    }
    else
    {
        NSLog(@"[MasterTabBarController] Universal link: Prompt to logout current sessions and open AuthViewController to complete the registration");
        
        // Keep a ref on the params
        authViewControllerRegistrationParameters = parameters;
        
        // Prompt to logout. It will then display AuthViewController if the user is logged out.
        [[AppDelegate theDelegate] logoutWithConfirmation:YES completion:^(BOOL isLoggedOut) {
            if (!isLoggedOut)
            {
                // Reset temporary params
                authViewControllerRegistrationParameters = nil;
            }
        }];
    }
}

- (void)showAuthenticationScreenAfterSoftLogout:(MXCredentials*)credentials;
{
    NSLog(@"[MasterTabBarController] showAuthenticationScreenAfterSoftLogout");

    softLogoutCredentials = credentials;

    // Check whether an authentication screen is not already shown or preparing
    if (!self.authViewController && !isAuthViewControllerPreparing)
    {
        isAuthViewControllerPreparing = YES;
        _authenticationInProgress = YES;

        [[AppDelegate theDelegate] restoreInitialDisplay:^{

            [self performSegueWithIdentifier:@"showAuth" sender:self];

        }];
    }
}

- (void)showRoomDetails
{
    [self releaseCurrentDetailsViewController];
    
    if (_selectedRoomPreviewData)
    {
        // Replace the rootviewcontroller with a room view controller
        // Get the RoomViewController from the storyboard
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        _currentRoomViewController = [storyboard instantiateViewControllerWithIdentifier:@"RoomViewControllerStoryboardId"];
        
        [self.masterTabBarDelegate masterTabBarController:self wantsToDisplayDetailViewController:_currentRoomViewController];
        
        [_currentRoomViewController displayRoomPreview:_selectedRoomPreviewData];
        _selectedRoomPreviewData = nil;
        
        [self setupLeftBarButtonItem];
    }
    else
    {
        MXWeakify(self);
        void (^openRoomDataSource)(MXKRoomDataSource *roomDataSource) = ^(MXKRoomDataSource *roomDataSource) {
            MXStrongifyAndReturnIfNil(self);
            
            // Replace the rootviewcontroller with a room view controller
            // Get the RoomViewController from the storyboard
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
            self->_currentRoomViewController = [storyboard instantiateViewControllerWithIdentifier:@"RoomViewControllerStoryboardId"];
            
            [self.masterTabBarDelegate masterTabBarController:self wantsToDisplayDetailViewController:self.currentRoomViewController];
            
            [self.currentRoomViewController displayRoom:roomDataSource];
            
            [self setupLeftBarButtonItem];
            
        };
        
        if (_selectedRoomDataSource)
        {
            // If the room data source is already loaded, display it
            openRoomDataSource(_selectedRoomDataSource);
            _selectedRoomDataSource = nil;
        }
        else
        {
            // Else, load it. The user may see the EmptyDetailsViewControllerStoryboardId
            // screen in this case
            [self dataSourceOfRoomToDisplay:^(MXKRoomDataSource *roomDataSource) {
                openRoomDataSource(roomDataSource);
            }];
        }
    }
}

- (void)selectRoomWithId:(NSString*)roomId andEventId:(NSString*)eventId inMatrixSession:(MXSession*)matrixSession
{
    [self selectRoomWithId:roomId andEventId:eventId inMatrixSession:matrixSession completion:nil];
}

- (void)selectRoomWithId:(NSString*)roomId andEventId:(NSString*)eventId inMatrixSession:(MXSession*)matrixSession completion:(void (^)(void))completion
{
    if (_selectedRoomId && [_selectedRoomId isEqualToString:roomId]
        && _selectedEventId && [_selectedEventId isEqualToString:eventId]
        && _selectedRoomSession && _selectedRoomSession == matrixSession)
    {
        // Nothing to do
        if (completion)
        {
            completion();
        }
        return;
    }
    
    _selectedRoomId = roomId;
    _selectedEventId = eventId;
    _selectedRoomSession = matrixSession;
    
    if (roomId && matrixSession)
    {
        // Preload the data source before performing the segue
        MXWeakify(self);
        [self dataSourceOfRoomToDisplay:^(MXKRoomDataSource *roomDataSource) {
            MXStrongifyAndReturnIfNil(self);
            
            self->_selectedRoomDataSource = roomDataSource;
            
            [self showRoomDetails];
            
            if (completion)
            {
                completion();
            }
        }];
    }
    else
    {
        [self releaseSelectedItem];
        if (completion)
        {
            completion();
        }
    }
}

- (void)showRoomPreview:(RoomPreviewData *)roomPreviewData
{
    _selectedRoomPreviewData = roomPreviewData;
    _selectedRoomId = roomPreviewData.roomId;
    _selectedRoomSession = roomPreviewData.mxSession;
    
    [self showRoomDetails];
}

- (void)selectContact:(MXKContact*)contact
{
    _selectedContact = contact;
    
    [self showContactDetails];
}

- (void)showContactDetails
{
    [self releaseCurrentDetailsViewController];
    
    // Replace the rootviewcontroller with a contact details view controller
    _currentContactDetailViewController = [ContactDetailsViewController contactDetailsViewController];
    _currentContactDetailViewController.enableVoipCall = NO;
    _currentContactDetailViewController.contact = _selectedContact;
    
    [self.masterTabBarDelegate masterTabBarController:self wantsToDisplayDetailViewController:_currentContactDetailViewController];
    
    [self setupLeftBarButtonItem];
}

- (void)selectGroup:(MXGroup*)group inMatrixSession:(MXSession*)matrixSession
{
    _selectedGroup = group;
    _selectedGroupSession = matrixSession;
    
    [self showGroupDetails];
}

- (void)showGroupDetails
{
    [self releaseCurrentDetailsViewController];
    
    // Replace the rootviewcontroller with a group details view controller
    _currentGroupDetailViewController = [GroupDetailsViewController groupDetailsViewController];
    [_currentGroupDetailViewController setGroup:_selectedGroup withMatrixSession:_selectedGroupSession];
    
    [self.masterTabBarDelegate masterTabBarController:self wantsToDisplayDetailViewController:_currentGroupDetailViewController];
    
    [self setupLeftBarButtonItem];
}

- (void)releaseSelectedItem
{
    _selectedRoomId = nil;
    _selectedEventId = nil;
    _selectedRoomSession = nil;
    _selectedRoomDataSource = nil;
    _selectedRoomPreviewData = nil;
    
    _selectedContact = nil;
    
    _selectedGroup = nil;
    _selectedGroupSession = nil;
    
    [self releaseCurrentDetailsViewController];
}

- (void)dismissUnifiedSearch:(BOOL)animated completion:(void (^)(void))completion
{
    if (unifiedSearchViewController)
    {
        [self.navigationController dismissViewControllerAnimated:animated completion:completion];
    }
    else if (completion)
    {
        completion();
    }
}

- (NSUInteger)missedDiscussionsCount
{
    NSUInteger roomCount = 0;
    
    // Considering all the current sessions.
    for (MXSession *session in mxSessionArray)
    {
        roomCount += [session vc_missedDiscussionsCount];
    }
    
    return roomCount;
}

- (NSUInteger)missedHighlightDiscussionsCount
{
    NSUInteger roomCount = 0;
    
    for (MXSession *session in mxSessionArray)
    {
        roomCount += [session missedHighlightDiscussionsCount];
    }
    
    return roomCount;
}

#pragma mark -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Keep ref on destinationViewController
    [childViewControllers addObject:segue.destinationViewController];
    
    if ([[segue identifier] isEqualToString:@"showAuth"])
    {
        // Keep ref on the authentification view controller while it is displayed
        // ie until we get the notification about a new account
        _authViewController = segue.destinationViewController;
        isAuthViewControllerPreparing = NO;
        
        // Listen to the end of the authentication flow
        _authViewController.authVCDelegate = self;
        
        authViewControllerObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidAddAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            
            _authViewController = nil;
            
            [[NSNotificationCenter defaultCenter] removeObserver:authViewControllerObserver];
            authViewControllerObserver = nil;
        }];
        
        authViewRemovedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidRemoveAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            
            // The user has cleared data for their soft logged out account
            _authViewController = nil;
            
            [[NSNotificationCenter defaultCenter] removeObserver:authViewRemovedAccountObserver];
            authViewRemovedAccountObserver = nil;
        }];
        
        // Forward parameters if any
        if (authViewControllerRegistrationParameters)
        {
            _authViewController.externalRegistrationParameters = authViewControllerRegistrationParameters;
            authViewControllerRegistrationParameters = nil;
        }
        if (softLogoutCredentials)
        {
            _authViewController.softLogoutCredentials = softLogoutCredentials;
            softLogoutCredentials = nil;
        }
    }
    else if ([[segue identifier] isEqualToString:@"showUnifiedSearch"])
    {
        unifiedSearchViewController= segue.destinationViewController;
        
        for (MXSession *session in mxSessionArray)
        {
            [unifiedSearchViewController addMatrixSession:session];
        }
    }
    
    // Hide back button title
    self.navigationController.topViewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

/**
 Load the data source of the room to open.

 @param onComplete a block providing the loaded room data source.
 */
- (void)dataSourceOfRoomToDisplay:(void (^)(MXKRoomDataSource *roomDataSource))onComplete
{
    // Check whether an event has been selected from messages or files search tab.
    MXEvent *selectedSearchEvent = unifiedSearchViewController.selectedSearchEvent;
    MXSession *selectedSearchEventSession = unifiedSearchViewController.selectedSearchEventSession;

    if (!selectedSearchEvent)
    {
        if (!_selectedEventId)
        {
            // LIVE: Show the room live timeline managed by MXKRoomDataSourceManager
            MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:_selectedRoomSession];

            [roomDataSourceManager roomDataSourceForRoom:_selectedRoomId create:YES onComplete:^(MXKRoomDataSource *roomDataSource) {
                onComplete(roomDataSource);
            }];
        }
        else
        {
            // Open the room on the requested event
            [RoomDataSource loadRoomDataSourceWithRoomId:_selectedRoomId initialEventId:_selectedEventId andMatrixSession:_selectedRoomSession onComplete:^(id roomDataSource) {

                ((RoomDataSource*)roomDataSource).markTimelineInitialEvent = YES;

                // Give the data source ownership to the room view controller.
                self.currentRoomViewController.hasRoomDataSourceOwnership = YES;

                onComplete(roomDataSource);
            }];
        }
    }
    else
    {
        // Search result: Create a temp timeline from the selected event
        [RoomDataSource loadRoomDataSourceWithRoomId:selectedSearchEvent.roomId initialEventId:selectedSearchEvent.eventId andMatrixSession:selectedSearchEventSession onComplete:^(id roomDataSource) {

            [roomDataSource finalizeInitialization];

            ((RoomDataSource*)roomDataSource).markTimelineInitialEvent = YES;

            // Give the data source ownership to the room view controller.
            self.currentRoomViewController.hasRoomDataSourceOwnership = YES;

            onComplete(roomDataSource);
        }];
    }
}

- (void)setupLeftBarButtonItem
{
    if (self.splitViewController)
    {
        // Refresh selected cell without scrolling the selected cell (We suppose it's visible here)
        [self refreshCurrentSelectedCell:NO];

        if (_currentRoomViewController)
        {
            _currentRoomViewController.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
            _currentRoomViewController.navigationItem.leftItemsSupplementBackButton = YES;
        }
        else if (_currentContactDetailViewController)
        {
            _currentContactDetailViewController.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
            _currentContactDetailViewController.navigationItem.leftItemsSupplementBackButton = YES;
        }
        else if (_currentGroupDetailViewController)
        {
            _currentGroupDetailViewController.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
            _currentGroupDetailViewController.navigationItem.leftItemsSupplementBackButton = YES;
        }
    }
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
    // Keep ref on presented view controller
    [childViewControllers addObject:viewControllerToPresent];
    
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}

// Made the actual selected view controller update its selected cell.
- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    UIViewController *selectedViewController = self.selectedViewController;
    
    if ([selectedViewController respondsToSelector:@selector(refreshCurrentSelectedCell:)])
    {
        [(id)selectedViewController refreshCurrentSelectedCell:forceVisible];
    }
}

- (void)releaseCurrentDetailsViewController
{
    // Release the existing details view controller (if any).
    if (_currentRoomViewController)
    {
        // If the displayed data is not a preview, let the manager release the room data source
        // (except if the view controller has the room data source ownership).
        if (!_currentRoomViewController.roomPreviewData && _currentRoomViewController.roomDataSource && !_currentRoomViewController.hasRoomDataSourceOwnership)
        {
            MXSession *mxSession = _currentRoomViewController.roomDataSource.mxSession;
            MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:mxSession];
            
            // Let the manager release live room data sources where the user is in
            [roomDataSourceManager closeRoomDataSourceWithRoomId:_currentRoomViewController.roomDataSource.roomId forceClose:NO];
        }
        
        [_currentRoomViewController destroy];
        _currentRoomViewController = nil;
    }
    else if (_currentContactDetailViewController)
    {
        [_currentContactDetailViewController destroy];
        _currentContactDetailViewController = nil;
    }
    else if (_currentGroupDetailViewController)
    {
        [_currentGroupDetailViewController destroy];
        _currentGroupDetailViewController = nil;
    }
}

- (void)setHidden:(BOOL)hidden
{
    _hidden = hidden;
    
    [self.view superview].backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.view.hidden = hidden;
    self.navigationController.navigationBar.hidden = hidden;
}

#pragma mark -

- (void)refreshTabBarBadges
{
    // Use a middle dot to signal missed notif in favourites
    [self setMissedDiscussionsMark:(recentsDataSource.missedFavouriteDiscussionsCount? @"\u00B7": nil)
                      onTabBarItem:TABBAR_FAVOURITES_INDEX
                    withBadgeColor:(recentsDataSource.missedHighlightFavouriteDiscussionsCount ? ThemeService.shared.theme.noticeColor : ThemeService.shared.theme.noticeSecondaryColor)];
    
    // Update the badge on People and Rooms tabs
    [self setMissedDiscussionsCount:recentsDataSource.missedDirectDiscussionsCount
                       onTabBarItem:TABBAR_PEOPLE_INDEX
                     withBadgeColor:(recentsDataSource.missedHighlightDirectDiscussionsCount ? ThemeService.shared.theme.noticeColor : ThemeService.shared.theme.noticeSecondaryColor)];
    [self setMissedDiscussionsCount:recentsDataSource.missedGroupDiscussionsCount
                       onTabBarItem:TABBAR_ROOMS_INDEX
                     withBadgeColor:(recentsDataSource.missedHighlightGroupDiscussionsCount ? ThemeService.shared.theme.noticeColor : ThemeService.shared.theme.noticeSecondaryColor)];
}

- (void)setMissedDiscussionsCount:(NSUInteger)count onTabBarItem:(NSUInteger)index withBadgeColor:(UIColor*)badgeColor
{
    if (count)
    {
        NSString *badgeValue = [self tabBarBadgeStringValue:count];
        
        self.tabBar.items[index].badgeValue = badgeValue;
        
        self.tabBar.items[index].badgeColor = badgeColor;
        
        [self.tabBar.items[index] setBadgeTextAttributes:@{
                                                           NSForegroundColorAttributeName: ThemeService.shared.theme.baseTextPrimaryColor
                                                           }
                                                forState:UIControlStateNormal];
    }
    else
    {
        self.tabBar.items[index].badgeValue = nil;
    }
}

- (void)setMissedDiscussionsMark:(NSString*)mark onTabBarItem:(NSUInteger)index withBadgeColor:(UIColor*)badgeColor
{
    if (mark)
    {
        self.tabBar.items[index].badgeValue = mark;
                
        self.tabBar.items[index].badgeColor = badgeColor;
        
        [self.tabBar.items[index] setBadgeTextAttributes:@{
                                                           NSForegroundColorAttributeName: ThemeService.shared.theme.baseTextPrimaryColor
                                                           }
                                                forState:UIControlStateNormal];
    }
    else
    {
        self.tabBar.items[index].badgeValue = nil;
    }
}

- (NSString*)tabBarBadgeStringValue:(NSUInteger)count
{
    NSString *badgeValue;
    
    if (count > 1000)
    {
        CGFloat value = count / 1000.0;
        badgeValue = [NSString stringWithFormat:NSLocalizedStringFromTable(@"large_badge_value_k_format", @"Vector", nil), value];
    }
    else
    {
        badgeValue = [NSString stringWithFormat:@"%tu", count];
    }
    
    return badgeValue;
}

#pragma mark -

- (void)promptUserBeforeUsingAnalytics
{
    NSLog(@"[MasterTabBarController]: Invite the user to send crash reports");
    
    __weak typeof(self) weakSelf = self;
    
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    NSString *appDisplayName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
    
    currentAlert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"google_analytics_use_prompt", @"Vector", nil), appDisplayName] message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"no"]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       RiotSettings.shared.enableCrashReport = NO;
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"yes"]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                                                                              
                                                       RiotSettings.shared.enableCrashReport = YES;
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }

                                                       [[Analytics sharedInstance] start];
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier: @"HomeVCUseAnalyticsAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

#pragma mark - Review session

- (void)presentVerifyCurrentSessionAlertIfNeededWithSession:(MXSession*)session
{
    if (RiotSettings.shared.hideVerifyThisSessionAlert
        || self.reviewSessionAlertHasBeenDisplayed
        || self.authenticationInProgress)
    {
        return;
    }
    
    self.reviewSessionAlertHasBeenDisplayed = YES;
    [self presentVerifyCurrentSessionAlertWithSession:session];
}

- (void)presentVerifyCurrentSessionAlertWithSession:(MXSession*)session
{
    NSLog(@"[MasterTabBarController] presentVerifyCurrentSessionAlertWithSession");
    
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"key_verification_self_verify_current_session_alert_title", @"Vector", nil)
                                                                   message:NSLocalizedStringFromTable(@"key_verification_self_verify_current_session_alert_message", @"Vector", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"key_verification_self_verify_current_session_alert_validate_action", @"Vector", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [[AppDelegate theDelegate] presentCompleteSecurityForSession:session];
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"later", @"Vector", nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"do_not_ask_again", @"Vector", nil)
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action) {
                                                RiotSettings.shared.hideVerifyThisSessionAlert = YES;
                                            }]];
    
    
    [self presentViewController:alert animated:YES completion:nil];
    
    currentAlert = alert;
}

- (void)presentReviewUnverifiedSessionsAlertIfNeededWithSession:(MXSession*)session
{
    if (RiotSettings.shared.hideReviewSessionsAlert || self.reviewSessionAlertHasBeenDisplayed)
    {
        return;
    }
    
    NSArray<MXDeviceInfo*> *devices = [session.crypto.store devicesForUser:session.myUserId].allValues;
    
    BOOL isUserHasOneUnverifiedDevice = NO;
    
    for (MXDeviceInfo *device in devices)
    {
        if (!device.trustLevel.isCrossSigningVerified)
        {
            isUserHasOneUnverifiedDevice = YES;
            break;
        }
    }
    
    if (isUserHasOneUnverifiedDevice)
    {
        self.reviewSessionAlertHasBeenDisplayed = YES;
        [self presentReviewUnverifiedSessionsAlertWithSession:session];
    }
}

- (void)presentReviewUnverifiedSessionsAlertWithSession:(MXSession*)session
{
    NSLog(@"[MasterTabBarController] presentReviewUnverifiedSessionsAlertWithSession");
    
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"key_verification_self_verify_unverified_sessions_alert_title", @"Vector", nil)
                                                                   message:NSLocalizedStringFromTable(@"key_verification_self_verify_unverified_sessions_alert_message", @"Vector", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"key_verification_self_verify_unverified_sessions_alert_validate_action", @"Vector", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [self showSettingsSecurityScreenForSession:session];
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"later", @"Vector", nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"do_not_ask_again", @"Vector", nil)
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action) {
                                                RiotSettings.shared.hideReviewSessionsAlert = YES;
                                            }]];
    
    
    [self presentViewController:alert animated:YES completion:nil];
    
    currentAlert = alert;
}

- (void)showSettingsSecurityScreenForSession:(MXSession*)session
{
    SettingsViewController *settingsViewController = [SettingsViewController instantiate];
    [settingsViewController loadViewIfNeeded];
    SecurityViewController *securityViewController = [SecurityViewController instantiateWithMatrixSession:session];
    
    [[AppDelegate theDelegate] restoreInitialDisplay:^{
        self.navigationController.viewControllers = @[self, settingsViewController, securityViewController];
    }];
}

- (void)resetReviewSessionsFlags
{
    self.reviewSessionAlertHasBeenDisplayed = NO;
    RiotSettings.shared.hideVerifyThisSessionAlert = NO;
    RiotSettings.shared.hideReviewSessionsAlert = NO;
}

#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    // Detect multi-tap on the current selected tab.
    if (item.tag == self.selectedIndex)
    {
        // Scroll to the next room with missed notifications.
        if (item.tag == TABBAR_ROOMS_INDEX)
        {
            [self.roomsViewController scrollToNextRoomWithMissedNotifications];
        }
        else if (item.tag == TABBAR_PEOPLE_INDEX)
        {
            [self.peopleViewController scrollToNextRoomWithMissedNotifications];
        }
        else if (item.tag == TABBAR_FAVOURITES_INDEX)
        {
            [self.favouritesViewController scrollToNextRoomWithMissedNotifications];
        }
    }
}

#pragma mark - AuthenticationViewControllerDelegate

- (void)authenticationViewControllerDidDismiss:(AuthenticationViewController *)authenticationViewController
{
    _authenticationInProgress = NO;
    [self.masterTabBarDelegate masterTabBarControllerDidCompleteAuthentication:self];
}

@end
