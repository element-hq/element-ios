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

#import "AppDelegate.h"

#import "MXRoom+Riot.h"
#import "MXSession+Riot.h"

#import "Riot-Swift.h"

@interface MasterTabBarController ()
{
    // Array of `MXSession` instances.
    NSMutableArray *mxSessionArray;    
    
    // Tell whether the authentication screen is preparing.
    BOOL isAuthViewControllerPreparing;
    
    // Observer that checks when the Authentification view controller has gone.
    id authViewControllerObserver;
    
    // The parameters to pass to the Authentification view controller.
    NSDictionary *authViewControllerRegistrationParameters;
    
    // The recents data source shared between all the view controllers of the tab bar.
    RecentsDataSource *recentsDataSource;
    
    // The current unified search screen if any
    UnifiedSearchViewController *unifiedSearchViewController;
    
    // Current alert (if any).
    UIAlertController *currentAlert;
    
    // Keep reference on the pushed view controllers to release them correctly
    NSMutableArray *childViewControllers;
    
    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
    
    // The groups data source
    GroupsDataSource *groupsDataSource;
}

@property(nonatomic,getter=isHidden) BOOL hidden;

@end

@implementation MasterTabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    // Retrieve the all view controllers
    _homeViewController = [self.viewControllers objectAtIndex:TABBAR_HOME_INDEX];
    _favouritesViewController = [self.viewControllers objectAtIndex:TABBAR_FAVOURITES_INDEX];
    _peopleViewController = [self.viewControllers objectAtIndex:TABBAR_PEOPLE_INDEX];
    _roomsViewController = [self.viewControllers objectAtIndex:TABBAR_ROOMS_INDEX];
    _groupsViewController = [self.viewControllers objectAtIndex:TABBAR_GROUPS_INDEX];
    
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
        tabBarItem.imageInsets = UIEdgeInsetsMake(5, 0, -5, 0);
    }
    
    childViewControllers = [NSMutableArray array];
    
    // Initialize here the data sources if a matrix session has been already set.
    [self initializeDataSources];
    
    // Observe user interface theme change.
    kRiotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    self.tabBar.tintColor = kRiotColorGreen;
    self.tabBar.barTintColor = kRiotSecondaryBgColor;
    
    self.view.backgroundColor = kRiotPrimaryBgColor;
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return kRiotDesignStatusBarStyle;
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
    if (![MXKAccountManager sharedManager].accounts.count)
    {
        [self showAuthenticationScreen];
    }
    else
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
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
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

- (void)selectRoomWithId:(NSString*)roomId andEventId:(NSString*)eventId inMatrixSession:(MXSession*)matrixSession
{
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
        // Preload the data source before performing the segue
        MXWeakify(self);
        [self dataSourceOfRoomToDisplay:^(MXKRoomDataSource *roomDataSource) {
            MXStrongifyAndReturnIfNil(self);

            self->_selectedRoomDataSource = roomDataSource;

            [self performSegueWithIdentifier:@"showRoomDetails" sender:self];
        }];
    }
    else
    {
        [self releaseSelectedItem];
    }
}

- (void)showRoomPreview:(RoomPreviewData *)roomPreviewData
{
    _selectedRoomPreviewData = roomPreviewData;
    _selectedRoomId = roomPreviewData.roomId;
    _selectedRoomSession = roomPreviewData.mxSession;
    
    [self performSegueWithIdentifier:@"showRoomDetails" sender:self];
}

- (void)selectContact:(MXKContact*)contact
{
    _selectedContact = contact;
    
    [self performSegueWithIdentifier:@"showContactDetails" sender:self];
}

- (void)selectGroup:(MXGroup*)group inMatrixSession:(MXSession*)matrixSession
{
    _selectedGroup = group;
    _selectedGroupSession = matrixSession;
    
    [self performSegueWithIdentifier:@"showGroupDetails" sender:self];
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
        roomCount += [session riot_missedDiscussionsCount];
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
    if ([[segue identifier] isEqualToString:@"showRoomDetails"] || [[segue identifier] isEqualToString:@"showContactDetails"] || [[segue identifier] isEqualToString:@"showGroupDetails"])
    {
        UINavigationController *navigationController = [segue destinationViewController];
        
        [self releaseCurrentDetailsViewController];
        
        if ([[segue identifier] isEqualToString:@"showRoomDetails"])
        {
            if (_selectedRoomPreviewData)
            {
                // Replace the rootviewcontroller with a room view controller
                // Get the RoomViewController from the storyboard
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
                _currentRoomViewController = [storyboard instantiateViewControllerWithIdentifier:@"RoomViewControllerStoryboardId"];

                navigationController.viewControllers = @[_currentRoomViewController];

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

                    navigationController.viewControllers = @[self.currentRoomViewController];

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
        else if ([[segue identifier] isEqualToString:@"showContactDetails"])
        {
            // Replace the rootviewcontroller with a contact details view controller
            _currentContactDetailViewController = [ContactDetailsViewController contactDetailsViewController];
            _currentContactDetailViewController.enableVoipCall = NO;
            _currentContactDetailViewController.contact = _selectedContact;
            
            navigationController.viewControllers = @[_currentContactDetailViewController];

            [self setupLeftBarButtonItem];
        }
        else
        {
            // Replace the rootviewcontroller with a group details view controller
            _currentGroupDetailViewController = [GroupDetailsViewController groupDetailsViewController];
            [_currentGroupDetailViewController setGroup:_selectedGroup withMatrixSession:_selectedGroupSession];
            
            navigationController.viewControllers = @[_currentGroupDetailViewController];

            [self setupLeftBarButtonItem];
        }
    }
    else
    {
        // Keep ref on destinationViewController
        [childViewControllers addObject:segue.destinationViewController];
        
        if ([[segue identifier] isEqualToString:@"showAuth"])
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
        else if ([[segue identifier] isEqualToString:@"showUnifiedSearch"])
        {
            unifiedSearchViewController= segue.destinationViewController;
            
            for (MXSession *session in mxSessionArray)
            {
                [unifiedSearchViewController addMatrixSession:session];
            }
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
    
    [self.view superview].backgroundColor = kRiotPrimaryBgColor;
    self.view.hidden = hidden;
    self.navigationController.navigationBar.hidden = hidden;
}

#pragma mark -

- (void)refreshTabBarBadges
{
    // Use a middle dot to signal missed notif in favourites
    [self setMissedDiscussionsMark:(recentsDataSource.missedFavouriteDiscussionsCount? @"\u00B7": nil) onTabBarItem:TABBAR_FAVOURITES_INDEX withBadgeColor:(recentsDataSource.missedHighlightFavouriteDiscussionsCount ? kRiotColorPinkRed : kRiotColorGreen)];
    
    // Update the badge on People and Rooms tabs
    [self setMissedDiscussionsCount:recentsDataSource.missedDirectDiscussionsCount onTabBarItem:TABBAR_PEOPLE_INDEX withBadgeColor:(recentsDataSource.missedHighlightDirectDiscussionsCount ? kRiotColorPinkRed : kRiotColorGreen)];
    [self setMissedDiscussionsCount:recentsDataSource.missedGroupDiscussionsCount onTabBarItem:TABBAR_ROOMS_INDEX withBadgeColor:(recentsDataSource.missedHighlightGroupDiscussionsCount ? kRiotColorPinkRed : kRiotColorGreen)];
}

- (void)setMissedDiscussionsCount:(NSUInteger)count onTabBarItem:(NSUInteger)index withBadgeColor:(UIColor*)badgeColor
{
    if (count)
    {
        NSString *badgeValue = [self tabBarBadgeStringValue:count];
        
        self.tabBar.items[index].badgeValue = badgeValue;
        
        if ([UITabBarItem instancesRespondToSelector:@selector(setBadgeColor:)])
        {
            self.tabBar.items[index].badgeColor = badgeColor;
        }
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
        
        if ([UITabBarItem instancesRespondToSelector:@selector(setBadgeColor:)])
        {
            self.tabBar.items[index].badgeColor = badgeColor;
        }
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
    
    NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    
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

@end
