/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomSearchViewController.h"

#import "RoomMessagesSearchViewController.h"
#import "RoomSearchDataSource.h"

#import "RoomFilesSearchViewController.h"
#import "FilesSearchCellData.h"

#import "GeneratedInterface-Swift.h"

@interface RoomSearchViewController ()
{
    RoomMessagesSearchViewController *messagesSearchViewController;
    RoomSearchDataSource *messagesSearchDataSource;
    
    RoomFilesSearchViewController *filesSearchViewController;
    MXKSearchDataSource *filesSearchDataSource;
}

@property (nonatomic) AnalyticsScreenTracker *screenTracker;

@end

@implementation RoomSearchViewController

+ (instancetype)instantiate
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    RoomSearchViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"RoomSearch"];
    return viewController;
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    // The navigation bar tint color and the rageShake Manager are handled by super (see SegmentedViewController).
    
    self.screenTracker = [[AnalyticsScreenTracker alloc] initWithScreen:AnalyticsScreenRoomSearch];
}

- (void)viewDidLoad
{
    // Set up the SegmentedVC tabs before calling [super viewDidLoad]
    NSMutableArray* viewControllers = [[NSMutableArray alloc] init];
    NSMutableArray* titles = [[NSMutableArray alloc] init];
    
    [titles addObject:[VectorL10n searchMessages]];
    messagesSearchViewController = [RoomMessagesSearchViewController searchViewController];
    [viewControllers addObject:messagesSearchViewController];
    
    // add Files tab
     [titles addObject:[VectorL10n searchFiles]];
    filesSearchViewController = [RoomFilesSearchViewController searchViewController];
    [viewControllers addObject:filesSearchViewController];
    
    [self initWithTitles:titles viewControllers:viewControllers defaultSelected:0];
    
    [super viewDidLoad];

    // Initialize here the data sources if a matrix session has been already set.
    [self initializeDataSources];
    
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
}

- (void)userInterfaceThemeDidChange
{
    [super userInterfaceThemeDidChange];
    
    // Match the search bar color to the navigation bar color as it extends slightly outside the frame.
    self.searchBar.backgroundColor = ThemeService.shared.theme.baseColor;
}

- (void)destroy
{
    [super destroy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.screenTracker trackScreen];

    // Let's child display the loading not this view controller
    if (self.activityIndicator)
    {
        [self.activityIndicator stopAnimating];
        self.activityIndicator = nil;
    }
    
    // Enable the search field by default at the screen opening
    if (self.searchBarHidden)
    {
        [self showSearch:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Refresh the search results.
    // Note: We wait for 'viewDidAppear' call to consider the actual view size during this update.
    [self updateSearch];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (!self.searchBarHidden && self.extendedLayoutIncludesOpaqueBars)
    {
        //  if a search bar is visible, navigationBar height will be increased. Below code will force update layout on previous view controller.
        [self.navigationController.view setNeedsLayout]; // force update layout
        [self.navigationController.view layoutIfNeeded]; // to fix height of the navigation bar
    }

    [super viewWillDisappear:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)selectEvent:(MXEvent *)event
{
    ThreadParameters *threadParameters = nil;
    if (RiotSettings.shared.enableThreads)
    {
        if (event.threadId)
        {
            threadParameters = [[ThreadParameters alloc] initWithThreadId:event.threadId
                                                          stackRoomScreen:NO];
        }
    }
    
    ScreenPresentationParameters *screenParameters = [[ScreenPresentationParameters alloc] initWithRestoreInitialDisplay:NO
                                                                                                  stackAboveVisibleViews:YES];
    
    RoomNavigationParameters *parameters = [[RoomNavigationParameters alloc] initWithRoomId:event.roomId
                                                                                    eventId:event.eventId
                                                                                  mxSession:self.mainSession
                                                                           threadParameters:threadParameters
                                                                     presentationParameters:screenParameters];
    Analytics.shared.viewRoomTrigger = AnalyticsViewRoomTriggerRoomSearch;
    [[LegacyAppDelegate theDelegate] showRoomWithParameters:parameters];
}

#pragma mark -

- (void)setRoomDataSource:(MXKRoomDataSource *)roomDataSource
{
    // Remove existing matrix session if any
    while (self.mainSession)
    {
        [self removeMatrixSession:self.mainSession];
    }
    
    _roomDataSource = roomDataSource;
    
    [self addMatrixSession:_roomDataSource.mxSession];
    
    // Check whether the controller's view is already loaded into memory.
    if (messagesSearchViewController)
    {
        // Prepare data sources
        [self initializeDataSources];
    }
}

- (void)initializeDataSources
{
    MXSession *mainSession = self.mainSession;
    
    if (mainSession && _roomDataSource)
    {
        // Init the search for messages
        messagesSearchDataSource = [[RoomSearchDataSource alloc] initWithRoomDataSource:_roomDataSource];
        [messagesSearchViewController displaySearch:messagesSearchDataSource];
        
        // Init the search for attachments
        filesSearchDataSource = [[MXKSearchDataSource alloc] initWithMatrixSession:mainSession];
        filesSearchDataSource.roomEventFilter.rooms = @[_roomDataSource.roomId];
        filesSearchDataSource.roomEventFilter.containsURL = YES;
        filesSearchDataSource.shouldShowRoomDisplayName = NO;
        [filesSearchDataSource registerCellDataClass:FilesSearchCellData.class forCellIdentifier:kMXKSearchCellDataIdentifier];
        [filesSearchViewController displaySearch:filesSearchDataSource];
    }
}

#pragma mark - Override MXKViewController

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

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (!self.searchBar.text.length)
    {
        // Reset current search if any
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

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    // Leave the screen
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Override SegmentedViewController

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    [super setSelectedIndex:selectedIndex];
    
    [self updateSearch];
}

#pragma mark - Search

// Update search results under the currently selected tab
- (void)updateSearch
{
    if (self.searchBar.text.length)
    {
        // Forward the search request to the data source
        if (self.selectedViewController == messagesSearchViewController)
        {
            // Launch the search only if the keyboard is no more visible
            if (!self.searchBar.isFirstResponder)
            {
                // Do it asynchronously to give time to messagesSearchViewController to be set up
                // so that it can display its loading wheel
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->messagesSearchDataSource searchMessages:self.searchBar.text force:NO];
                    self->messagesSearchViewController.shouldScrollToBottomOnRefresh = YES;
                });
            }
        }
        else if (self.selectedViewController == filesSearchViewController)
        {
            // Launch the search only if the keyboard is no more visible
            if (!self.searchBar.isFirstResponder)
            {
                // Do it asynchronously to give time to filesSearchViewController to be set up
                // so that it can display its loading wheel
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->filesSearchDataSource searchMessages:self.searchBar.text force:NO];
                    self->filesSearchViewController.shouldScrollToBottomOnRefresh = YES;
                });
            }
        }
    }
    else
    {
        // Nothing to search - Reset search result (if any)
        if (messagesSearchDataSource.searchText.length)
        {
            [messagesSearchDataSource searchMessages:nil force:NO];
        }
        if (filesSearchDataSource.searchText.length)
        {
            [filesSearchDataSource searchMessages:nil force:NO];
        }
    }
}

@end
