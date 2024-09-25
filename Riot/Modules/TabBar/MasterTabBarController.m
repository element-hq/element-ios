/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MasterTabBarController.h"

#import "RecentsDataSource.h"


#import "MXRoom+Riot.h"
#import "MXSession+Riot.h"

#import "SettingsViewController.h"
#import "SecurityViewController.h"

#import "GeneratedInterface-Swift.h"

@interface MasterTabBarController () <UITabBarControllerDelegate>
{
    // Array of `MXSession` instances.
    NSMutableArray<MXSession*> *mxSessionArray;
    
    // The recents data source shared between all the view controllers of the tab bar.
    RecentsDataSource *recentsDataSource;
        
    // Current alert (if any).
    UIAlertController *currentAlert;
    
    // Keep reference on the pushed view controllers to release them correctly
    NSMutableArray *childViewControllers;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
    
    // Custom title view of the navigation bar
    MainTitleView *titleView;
    
    id spaceNotificationCounterDidUpdateNotificationCountObserver;
}

@property(nonatomic,getter=isHidden) BOOL hidden;

@property (nonatomic, readwrite) OnboardingCoordinatorBridgePresenter *onboardingCoordinatorBridgePresenter;

// Tell whether the onboarding screen is preparing.
@property (nonatomic, readwrite) BOOL isOnboardingCoordinatorPreparing;
@property (nonatomic, readwrite) BOOL isOnboardingInProgress;

@property (nonatomic) BOOL reviewSessionAlertHasBeenDisplayed;

@end

@implementation MasterTabBarController
@synthesize onboardingCoordinatorBridgePresenter, selectedRoomId, selectedEventId, selectedRoomSession, selectedRoomPreviewData, selectedContact, isOnboardingInProgress;

#pragma mark - Properties override

- (HomeViewController *)homeViewController
{
    UIViewController *wrapperVC = [self viewControllerForClass:HomeViewControllerWithBannerWrapperViewController.class];
    return [(HomeViewControllerWithBannerWrapperViewController *)wrapperVC homeViewController];
}

- (FavouritesViewController *)favouritesViewController
{
    return (FavouritesViewController*)[self viewControllerForClass:FavouritesViewController.class];
}

- (PeopleViewController *)peopleViewController
{
    return (PeopleViewController*)[self viewControllerForClass:PeopleViewController.class];
}

- (RoomsViewController *)roomsViewController
{
    return (RoomsViewController*)[self viewControllerForClass:RoomsViewController.class];
}

#pragma mark - Life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.delegate = self;
    
    self.isOnboardingInProgress = NO;
    
    // Note: UITabBarViewController should not be embed in a UINavigationController (https://github.com/vector-im/riot-ios/issues/3086)
    [self vc_removeBackTitle];
    
    [self setupTitleView];
    titleView.titleLabel.text = [VectorL10n allChatsTitle];
    
    childViewControllers = [NSMutableArray array];
    
    MXWeakify(self);
    spaceNotificationCounterDidUpdateNotificationCountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:MXSpaceNotificationCounter.didUpdateNotificationCount object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        MXStrongifyAndReturnIfNil(self);
        [self updateSideMenuNotifcationIcon];
    }];
}

- (void)userInterfaceThemeDidChange
{
    id<Theme> theme = ThemeService.shared.theme;
    [theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    [theme applyStyleOnTabBar:self.tabBar];
    
    self.view.backgroundColor = theme.backgroundColor;
    [titleView updateWithTheme:theme];

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
    
    if (!kThemeServiceDidChangeThemeNotificationObserver)
    {
        // Observe user interface theme change.
        kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            
            [self userInterfaceThemeDidChange];
            
        }];
        [self userInterfaceThemeDidChange];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    MXLogDebug(@"[MasterTabBarController] viewDidAppear");
    [super viewDidAppear:animated];
    
    // Check whether we're not logged in
    BOOL authIsShown = NO;
    if (![MXKAccountManager sharedManager].accounts.count)
    {
        [self showOnboardingFlow];
        authIsShown = YES;
    }
    else if (![MXKAccountManager sharedManager].activeAccounts.count)
    {
        // Display a login screen if the account is soft logout
        // Note: We support only one account
        MXKAccount *account = [MXKAccountManager sharedManager].accounts.firstObject;
        if (account.isSoftLogout)
        {
            [self showSoftLogoutOnboardingFlowWithCredentials:account.mxCredentials];
            authIsShown = YES;
        }
    }

    if (!authIsShown)
    {
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
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)dealloc
{
    mxSessionArray = nil;
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    
    if (spaceNotificationCounterDidUpdateNotificationCountObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:spaceNotificationCounterDidUpdateNotificationCountObserver];
        spaceNotificationCounterDidUpdateNotificationCountObserver = nil;
    }
    
    childViewControllers = nil;
}

#pragma mark - Public

- (void)updateViewControllers:(NSArray<UIViewController*>*)viewControllers
{
    self.viewControllers = viewControllers;
    
    [self initializeDataSources];
    
    // Need to be called in case of the controllers have been replaced
    [self.selectedViewController viewWillAppear:NO];

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
    
    self.titleLabelText = [self getTitleForItemViewController:self.selectedViewController];

    // Need to be called in case of the controllers have been replaced
    [self.selectedViewController viewDidAppear:NO];
}

- (void)removeTabAt:(MasterTabBarIndex)tag
{
    NSInteger index = [self indexOfTabItemWithTag:tag];
    if (index != NSNotFound) {
        NSMutableArray<UIViewController*> *viewControllers = [NSMutableArray arrayWithArray:self.viewControllers];
        [viewControllers removeObjectAtIndex:index];
        self.viewControllers = viewControllers;
    }
}

- (void)selectTabAtIndex:(MasterTabBarIndex)tabBarIndex
{
    NSInteger index = [self indexOfTabItemWithTag:tabBarIndex];
    self.selectedIndex = index;
    
    self.titleLabelText = [self getTitleForItemViewController:self.selectedViewController];
}

#pragma mark -

- (NSArray<MXSession*>*)mxSessions
{
    return [NSArray arrayWithArray:mxSessionArray];
}

- (void)initializeDataSources
{
    MXSession *mainSession = mxSessionArray.firstObject;
    
    if (mainSession)
    {
        MXLogDebug(@"[MasterTabBarController] initializeDataSources");
        
        // Init the recents data source
        RecentsListService *recentsListService = [[RecentsListService alloc] initWithSession:mainSession];
        recentsDataSource = [[RecentsDataSource alloc] initWithMatrixSession:mainSession
                                                          recentsListService:recentsListService];
        
        [self.homeViewController displayList:recentsDataSource];
        [self.favouritesViewController displayList:recentsDataSource];
        [self.peopleViewController displayList:recentsDataSource];
        [self.roomsViewController displayList:recentsDataSource];
        
        // Restore the right delegate of the shared recent data source.
        id<MXKDataSourceDelegate> recentsDataSourceDelegate = self.homeViewController;
        RecentsDataSourceMode recentsDataSourceMode = self.homeViewController.recentsDataSourceMode;
        
        NSInteger tabItemTag = self.tabBar.items[self.selectedIndex].tag;
        
        switch (tabItemTag)
        {
            case TABBAR_HOME_INDEX:
                break;
            case TABBAR_FAVOURITES_INDEX:
                recentsDataSourceDelegate = self.favouritesViewController;
                recentsDataSourceMode = RecentsDataSourceModeFavourites;
                break;
            case TABBAR_PEOPLE_INDEX:
                recentsDataSourceDelegate = self.peopleViewController;
                recentsDataSourceMode = RecentsDataSourceModePeople;
                break;
            case TABBAR_ROOMS_INDEX:
                recentsDataSourceDelegate = self.roomsViewController;
                recentsDataSourceMode = RecentsDataSourceModeRooms;
                break;
                
            default:
                break;
        }
        [recentsDataSource setDelegate:recentsDataSourceDelegate andRecentsDataSourceMode:recentsDataSourceMode];
        
        // Check whether there are others sessions
        NSArray<MXSession*>* mxSessions = self.mxSessions;
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
    if ([mxSessionArray containsObject:mxSession])
    {
        MXLogDebug(@"MasterTabBarController already has %@ in mxSessionArray", mxSession)
        return;
    }
    
    // Check whether the controller's view is loaded into memory.
    if (self.homeViewController)
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
}

- (void)removeMatrixSession:(MXSession *)mxSession
{
    if (![mxSessionArray containsObject:mxSession])
    {
        MXLogDebug(@"MasterTabBarController does not contain %@ in mxSessionArray", mxSession)
        return;
    }
    
    [recentsDataSource removeMatrixSession:mxSession];
    
    // Check whether there are others sessions
    if (!recentsDataSource.mxSessions.count)
    {
        // Remove matrix sessions observer
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionStateDidChangeNotification object:nil];
        
        [self.homeViewController displayList:nil];
        [self.favouritesViewController displayList:nil];
        [self.peopleViewController displayList:nil];
        [self.roomsViewController displayList:nil];
        
        [recentsDataSource destroy];
        recentsDataSource = nil;
    }
    
    [mxSessionArray removeObject:mxSession];
}

- (void)onMatrixSessionStateDidChange:(NSNotification *)notif
{
    [self refreshTabBarBadges];
}

// TODO: Manage the onboarding coordinator at the AppCoordinator level
- (void)presentOnboardingFlow
{
    MXLogDebug(@"[MasterTabBarController] presentOnboardingFlow");
    
    MXWeakify(self);
    OnboardingCoordinatorBridgePresenter *onboardingCoordinatorBridgePresenter = [[OnboardingCoordinatorBridgePresenter alloc] init];
    onboardingCoordinatorBridgePresenter.completion = ^{
        MXStrongifyAndReturnIfNil(self);
        [self.onboardingCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
        self.onboardingCoordinatorBridgePresenter = nil;
        
        self.isOnboardingInProgress = NO;   // Must be set before calling didCompleteAuthentication
        [self.masterTabBarDelegate masterTabBarControllerDidCompleteAuthentication:self];
    };
    
    [onboardingCoordinatorBridgePresenter presentFrom:self animated:NO];
    
    self.onboardingCoordinatorBridgePresenter = onboardingCoordinatorBridgePresenter;
    self.isOnboardingCoordinatorPreparing = NO;
}

- (void)showOnboardingFlow
{
    MXLogDebug(@"[MasterTabBarController] showOnboardingFlow");
    [self showOnboardingFlowAndResetSessionFlags:YES];
}

- (void)showSoftLogoutOnboardingFlowWithCredentials:(MXCredentials*)credentials;
{
    MXLogDebug(@"[MasterTabBarController] showAuthenticationScreenAfterSoftLogout");
    
    // This method can be called after the user chooses to clear their data as the MXSession
    // is opened to call logout from. So we only set the credentials when authentication isn't
    // in progress to prevent a second soft logout screen being shown.
    if (!self.onboardingCoordinatorBridgePresenter && !self.isOnboardingCoordinatorPreparing)
    {
        AuthenticationService.shared.softLogoutCredentials = credentials;
        
        [self showOnboardingFlowAndResetSessionFlags:NO];
    }
}

- (void)showOnboardingFlowAndResetSessionFlags:(BOOL)resetSessionFlags
{
    // Check whether an authentication screen is not already shown or preparing
    if (!self.onboardingCoordinatorBridgePresenter && !self.isOnboardingCoordinatorPreparing)
    {
        self.isOnboardingCoordinatorPreparing = YES;
        self.isOnboardingInProgress = YES;
        
        if (resetSessionFlags)
        {
            [self resetReviewSessionsFlags];
        }
        
        [[AppDelegate theDelegate] restoreInitialDisplay:^{
            
            [self presentOnboardingFlow];
        }];
    }
}

- (void)selectRoomWithParameters:(RoomNavigationParameters*)paramaters completion:(void (^)(void))completion
{
    [self releaseSelectedItem];
    
    selectedRoomId = paramaters.roomId;
    selectedEventId = paramaters.eventId;
    selectedRoomSession = paramaters.mxSession;
    
    [self.masterTabBarDelegate masterTabBarController:self didSelectRoomWithParameters:paramaters completion:completion];
    
    [self refreshSelectedControllerSelectedCellIfNeeded];
}

- (void)selectRoomPreviewWithParameters:(RoomPreviewNavigationParameters*)parameters completion:(void (^)(void))completion
{
    [self releaseSelectedItem];
    
    RoomPreviewData *roomPreviewData = parameters.previewData;
    
    selectedRoomPreviewData = roomPreviewData;
    selectedRoomId = roomPreviewData.roomId;
    selectedRoomSession = roomPreviewData.mxSession;
    
    [self.masterTabBarDelegate masterTabBarController:self didSelectRoomPreviewWithParameters:parameters completion:completion];
    
    [self refreshSelectedControllerSelectedCellIfNeeded];
}

- (void)selectContact:(MXKContact*)contact
{
    ScreenPresentationParameters *presentationParameters = [[ScreenPresentationParameters alloc] initWithRestoreInitialDisplay:YES stackAboveVisibleViews:NO];
    
    [self selectContact:contact withPresentationParameters:presentationParameters];
}

- (void)selectContact:(MXKContact*)contact withPresentationParameters:(ScreenPresentationParameters*)presentationParameters
{
    [self releaseSelectedItem];
    
    selectedContact = contact;
    
    [self.masterTabBarDelegate masterTabBarController:self didSelectContact:contact withPresentationParameters:presentationParameters];
    
    [self refreshSelectedControllerSelectedCellIfNeeded];
}

- (void)releaseSelectedItem
{
    selectedRoomId = nil;
    selectedEventId = nil;
    selectedRoomSession = nil;
    selectedRoomPreviewData = nil;
    
    selectedContact = nil;
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

- (UIViewController*)viewControllerForClass:(Class)klass
{
    UIViewController *foundViewController;
    
    NSInteger viewControllerIndex = [self.viewControllers indexOfObjectPassingTest:^BOOL(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:klass])
        {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    
    if (viewControllerIndex != NSNotFound)
    {
        foundViewController = self.viewControllers[viewControllerIndex];
    }
    
    return foundViewController;
}

- (void)filterRoomsWithParentId:(NSString*)roomParentId
                inMatrixSession:(MXSession*)mxSession
{
    if (roomParentId) {
        NSString *parentName = [mxSession roomSummaryWithRoomId:roomParentId].displayName;
        NSMutableArray<NSString *> *breadcrumbs = [[NSMutableArray alloc] initWithObjects:parentName, nil];

        MXSpace *firstRootAncestor = roomParentId ? [mxSession.spaceService firstRootAncestorForRoomWithId:roomParentId] : nil;
        NSString *rootName = nil;
        if (firstRootAncestor)
        {
            rootName = [mxSession roomSummaryWithRoomId:firstRootAncestor.spaceId].displayName;
            [breadcrumbs insertObject:rootName atIndex:0];
        }
        titleView.breadcrumbView.breadcrumbs = breadcrumbs;
    }
    else
    {
        titleView.breadcrumbView.breadcrumbs = @[];
    }
    
    recentsDataSource.currentSpace = [mxSession.spaceService getSpaceWithId:roomParentId];
    [self updateSideMenuNotifcationIcon];
}

- (void)updateSideMenuNotifcationIcon
{
    BOOL displayNotification = NO;
    
    for (MXRoomSummary *summary in recentsDataSource.mxSession.spaceService.rootSpaceSummaries) {
        if (summary.membership == MXMembershipInvite) {
            displayNotification = YES;
            break;
        }
    }
    
    if (!displayNotification) {
        MXSpaceNotificationState *notificationState = [recentsDataSource.mxSession.spaceService.notificationCounter notificationStateForAllSpacesExcept: recentsDataSource.currentSpace.spaceId];
        
        if (recentsDataSource.currentSpace)
        {
            MXSpaceNotificationState *homeNotificationState = recentsDataSource.mxSession.spaceService.notificationCounter.homeNotificationState;
            displayNotification = notificationState.groupMissedDiscussionsCount > 0 || notificationState.groupMissedDiscussionsHighlightedCount > 0 || homeNotificationState.allCount > 0 || homeNotificationState.allHighlightCount > 0;
        }
        else
        {
            displayNotification = notificationState.groupMissedDiscussionsCount > 0 || notificationState.groupMissedDiscussionsHighlightedCount > 0;
        }
    }
    
    [self.masterTabBarDelegate masterTabBarController:self needsSideMenuIconWithNotification:displayNotification];
}

#pragma mark -

-(void)setupTitleView
{
    titleView = [MainTitleView new];
    self.navigationItem.titleView = titleView;
}

-(void)setTitleLabelText:(NSString *)text
{
    titleView.titleLabel.text = text;
    self.navigationItem.backButtonTitle = text;
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
    // Keep ref on presented view controller
    [childViewControllers addObject:viewControllerToPresent];
    
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}

- (void)refreshSelectedControllerSelectedCellIfNeeded
{
    if (self.splitViewController)
    {
        // Refresh selected cell without scrolling the selected cell (We suppose it's visible here)
        [self refreshCurrentSelectedCell:NO];
    }
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

- (void)setHidden:(BOOL)hidden
{
    _hidden = hidden;
    
    [self.view superview].backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.view.hidden = hidden;
    self.navigationController.navigationBar.hidden = hidden;
}

- (NSString*)getTitleForItemViewController:(UIViewController*)itemViewController
{
    if ([itemViewController conformsToProtocol:@protocol(MasterTabBarItemDisplayProtocol)])
    {
        UIViewController<MasterTabBarItemDisplayProtocol> *masterTabBarItem = (UIViewController<MasterTabBarItemDisplayProtocol>*)itemViewController;
        return masterTabBarItem.masterTabBarItemTitle;
    }
        
    return nil;
}

#pragma mark -

- (void)refreshTabBarBadges
{
    // Use a middle dot to signal missed notif in favourites
    if (RiotSettings.shared.homeScreenShowFavouritesTab)
    {
        [self setMissedDiscussionsMark:(recentsDataSource.favoriteMissedDiscussionsCount.numberOfNotified ? @"\u00B7": nil)
                          onTabBarItem:TABBAR_FAVOURITES_INDEX
                        withBadgeColor:(recentsDataSource.favoriteMissedDiscussionsCount.hasHighlight ? ThemeService.shared.theme.noticeColor : ThemeService.shared.theme.noticeSecondaryColor)];
    }
    
    // Update the badge on People and Rooms tabs
    if (RiotSettings.shared.homeScreenShowPeopleTab)
    {
        if (recentsDataSource.directMissedDiscussionsCount.hasUnsent)
        {
            [self setBadgeValue:@"!"
                               onTabBarItem:TABBAR_PEOPLE_INDEX
                             withBadgeColor:ThemeService.shared.theme.noticeColor];
        }
        else
        {
            [self setMissedDiscussionsCount:recentsDataSource.directMissedDiscussionsCount.numberOfNotified
                               onTabBarItem:TABBAR_PEOPLE_INDEX
                             withBadgeColor:(recentsDataSource.directMissedDiscussionsCount.hasHighlight ? ThemeService.shared.theme.noticeColor : ThemeService.shared.theme.noticeSecondaryColor)];
        }
    }
    
    if (RiotSettings.shared.homeScreenShowRoomsTab)
    {
        if (recentsDataSource.groupMissedDiscussionsCount.hasUnsent)
        {
            [self setMissedDiscussionsCount:recentsDataSource.groupMissedDiscussionsCount.numberOfUnsent
                               onTabBarItem:TABBAR_ROOMS_INDEX
                             withBadgeColor:ThemeService.shared.theme.noticeColor];
        }
        else
        {
            [self setMissedDiscussionsCount:recentsDataSource.groupMissedDiscussionsCount.numberOfNotified
                               onTabBarItem:TABBAR_ROOMS_INDEX
                             withBadgeColor:(recentsDataSource.groupMissedDiscussionsCount.hasHighlight ? ThemeService.shared.theme.noticeColor : ThemeService.shared.theme.noticeSecondaryColor)];
        }
    }
}

- (void)setMissedDiscussionsCount:(NSUInteger)count onTabBarItem:(NSUInteger)index withBadgeColor:(UIColor*)badgeColor
{
    [self setBadgeValue:count ? [self tabBarBadgeStringValue:count] : nil onTabBarItem:index withBadgeColor:badgeColor];
}

- (void)setBadgeValue:(NSString *)value onTabBarItem:(NSUInteger)index withBadgeColor:(UIColor*)badgeColor
{
    NSInteger itemIndex = [self indexOfTabItemWithTag:index];
    if (itemIndex != NSNotFound)
    {
        if (value)
        {
            self.tabBar.items[itemIndex].badgeValue = value;
            
            self.tabBar.items[itemIndex].badgeColor = badgeColor;
            
            [self.tabBar.items[itemIndex] setBadgeTextAttributes:@{
                                                               NSForegroundColorAttributeName: ThemeService.shared.theme.baseTextPrimaryColor
                                                               }
                                                    forState:UIControlStateNormal];
        }
        else
        {
            self.tabBar.items[itemIndex].badgeValue = nil;
        }
    }
}

- (void)setMissedDiscussionsMark:(NSString*)mark onTabBarItem:(NSUInteger)index withBadgeColor:(UIColor*)badgeColor
{
    NSInteger itemIndex = [self indexOfTabItemWithTag:index];
    if (itemIndex != NSNotFound)
    {
        if (mark)
        {
            self.tabBar.items[itemIndex].badgeValue = mark;
                    
            self.tabBar.items[itemIndex].badgeColor = badgeColor;
            
            [self.tabBar.items[itemIndex] setBadgeTextAttributes:@{
                                                               NSForegroundColorAttributeName: ThemeService.shared.theme.baseTextPrimaryColor
                                                               }
                                                    forState:UIControlStateNormal];
        }
        else
        {
            self.tabBar.items[itemIndex].badgeValue = nil;
        }
    }
}

- (NSString*)tabBarBadgeStringValue:(NSUInteger)count
{
    NSString *badgeValue;
    
    if (count > 1000)
    {
        CGFloat value = count / 1000.0;
        badgeValue = [VectorL10n largeBadgeValueKFormat:value];
    }
    else
    {
        badgeValue = [NSString stringWithFormat:@"%tu", count];
    }
    
    return badgeValue;
}

- (NSInteger)indexOfTabItemWithTag:(NSUInteger)tag
{
    for (int i = 0 ; i < self.tabBar.items.count ; i++)
    {
        if (self.tabBar.items[i].tag == tag)
        {
            return i;
        }
    }
    
    return NSNotFound;
}

#pragma mark - Review session

- (void)presentVerifyCurrentSessionAlertIfNeededWithSession:(MXSession*)session
{
    if (RiotSettings.shared.hideVerifyThisSessionAlert
        || self.reviewSessionAlertHasBeenDisplayed
        || self.isOnboardingInProgress)
    {
        return;
    }
    
    self.reviewSessionAlertHasBeenDisplayed = YES;

    // Force verification if required by the HS configuration
    if (session.vc_homeserverConfiguration.encryption.isSecureBackupRequired)
    {
        NSLog(@"[MasterTabBarController] presentVerifyCurrentSessionAlertIfNeededWithSession: Force verification of the device");
        [[AppDelegate theDelegate] presentCompleteSecurityForSession:session];
        return;
    }

    [self presentVerifyCurrentSessionAlertWithSession:session];
}

- (void)presentVerifyCurrentSessionAlertWithSession:(MXSession*)session
{
    MXLogDebug(@"[MasterTabBarController] presentVerifyCurrentSessionAlertWithSession");
    
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[VectorL10n keyVerificationSelfVerifyCurrentSessionAlertTitle]
                                                                   message:[VectorL10n keyVerificationSelfVerifyCurrentSessionAlertMessage]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n keyVerificationSelfVerifyCurrentSessionAlertValidateAction]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [[AppDelegate theDelegate] presentCompleteSecurityForSession:session];
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n later]
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n doNotAskAgain]
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * action) {
                                                RiotSettings.shared.hideVerifyThisSessionAlert = YES;
                                            }]];
    
    
    [self presentViewController:alert animated:YES completion:nil];
    
    currentAlert = alert;
}

- (void)presentReviewUnverifiedSessionsAlertIfNeededWithSession:(MXSession*)session
{
    if (self.reviewSessionAlertHasBeenDisplayed)
    {
        return;
    }
    
    NSArray<MXDeviceInfo*> *devices = [session.crypto devicesForUser:session.myUserId].allValues;
    
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
    MXLogDebug(@"[MasterTabBarController] presentReviewUnverifiedSessionsAlertWithSession");
    
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[VectorL10n keyVerificationAlertTitle]
                                                                   message:[VectorL10n keyVerificationAlertBody]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n keyVerificationSelfVerifyUnverifiedSessionsAlertValidateAction]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [self showSettingsSecurityScreenForSession:session];
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n later]
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
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

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    self.titleLabelText = [self getTitleForItemViewController:viewController];
}

@end
