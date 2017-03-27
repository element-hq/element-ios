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

#import "RecentsDataSource.h"

#import "RageShakeManager.h"

//#import "RoomDataSource.h"
//#import "RoomViewController.h"
//
//#import "DirectoryViewController.h"
//#import "ContactDetailsViewController.h"
//#import "SettingsViewController.h"
//
//#import "HomeMessagesSearchViewController.h"
//#import "HomeMessagesSearchDataSource.h"
//#import "HomeFilesSearchViewController.h"
//#import "FilesSearchCellData.h"

#import "AppDelegate.h"

//#import "GBDeviceInfo_iOS.h"

@interface HomeViewController ()
{
    // Display a gradient view above the screen
    CAGradientLayer* tableViewMaskLayer;

    // Display a button to a new room
    UIImageView* createNewRoomImageView;
    
    MXHTTPOperation *roomCreationRequest;

    // Current alert (if any).
    MXKAlert *currentAlert;
}

@end

@implementation HomeViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kRiotNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    self.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [AppDelegate theDelegate].masterTabBarController.navigationItem.title = NSLocalizedStringFromTable(@"title_home", @"Vector", nil);
    
    // Add room creation button programatically
    [self addRoomCreationButton];
    
//    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
//    self.searchBar.placeholder = NSLocalizedStringFromTable(@"search_default_placeholder", @"Vector", nil);
}

- (void)dealloc
{
    
}

- (void)destroy
{
    [super destroy];

    if (currentAlert)
    {
        [currentAlert dismiss:NO];
        currentAlert = nil;
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
    
//    // Refresh the search results if a search in in progress
//    if (!self.searchBarHidden)
//    {
//        [self updateSearch];
//    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Release the current selected room (if any) except if the Room ViewController is still visible (see splitViewController.isCollapsed condition)
    if (!self.splitViewController || self.splitViewController.isCollapsed)
    {
        // Release the current selected room (if any).
        [[AppDelegate theDelegate].masterTabBarController closeSelectedRoom];
    }
    else
    {
        // In case of split view controller where the primary and secondary view controllers are displayed side-by-side onscreen,
        // the selected room (if any) is highlighted.
        [self refreshCurrentSelectedCell:YES];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    // sanity check
    if (tableViewMaskLayer)
    {
        tableViewMaskLayer.frame = self.recentsTableView.frame;
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
    
    tableViewMaskLayer.frame = self.recentsTableView.frame;
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
    
    NSLayoutConstraint* trailingConstraint = [NSLayoutConstraint constraintWithItem:createNewRoomImageView
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeTrailing
                                                                        multiplier:1
                                                                          constant:0];
    
    NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                                        attribute:NSLayoutAttributeTop
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:createNewRoomImageView
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1
                                                                         constant:9];
    
    // Available on iOS 8 and later
    [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint, trailingConstraint, bottomConstraint]];
    
    createNewRoomImageView.userInteractionEnabled = YES;
    
    // Handle tap gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onNewRoomPressed)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [createNewRoomImageView addGestureRecognizer:tap];
}

//#pragma mark - Search
//
//- (void)showSearch:(BOOL)animated
//{
//    [super showSearch:animated];
//    
//    // Reset searches
//    [recentsDataSource searchWithPatterns:nil];
//
//    createNewRoomImageView.hidden = YES;
//    tableViewMaskLayer.hidden = YES;
//
//    [self updateSearch];
//    
//    // Screen tracking (via Google Analytics)
//    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
//    if (tracker)
//    {
//        [tracker set:kGAIScreenName value:@"RoomsGlobalSearch"];
//        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
//    }
//}
//
//- (void)hideSearch:(BOOL)animated
//{
//    [super hideSearch:animated];
//
//    createNewRoomImageView.hidden = self.isHidden;
//    tableViewMaskLayer.hidden = NO;
//    self.backgroundImageView.hidden = YES;
//
//    [recentsDataSource searchWithPatterns:nil];
//
//    recentsDataSource.hideRecents = NO;
//    recentsDataSource.hidePublicRoomsDirectory = YES;
//    
//    // Screen tracking (via Google Analytics)
//    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
//    if (tracker)
//    {
//        NSString *currentScreenName = [tracker get:kGAIScreenName];
//        if (!currentScreenName || ![currentScreenName isEqualToString:@"RoomsList"])
//        {
//            [tracker set:kGAIScreenName value:@"RoomsList"];
//            [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
//        }
//    }
//}
//
//// Update search results under the currently selected tab
//- (void)updateSearch
//{
//    if (self.searchBar.text.length)
//    {
//        recentsDataSource.hideRecents = NO;
//        recentsDataSource.hidePublicRoomsDirectory = NO;
//        self.backgroundImageView.hidden = YES;
//
//        // Forward the search request to the data source
//        if (self.selectedViewController == recentsViewController)
//        {
//            // Do a AND search on words separated by a space
//            NSArray *patterns = [self.searchBar.text componentsSeparatedByString:@" "];
//
//            [recentsDataSource searchWithPatterns:patterns];
//            recentsViewController.shouldScrollToTopOnRefresh = YES;
//        }
//        else if (self.selectedViewController == messagesSearchViewController)
//        {
//            // Launch the search only if the keyboard is no more visible
//            if (!self.searchBar.isFirstResponder)
//            {
//                // Do it asynchronously to give time to messagesSearchViewController to be set up
//                // so that it can display its loading wheel
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [messagesSearchDataSource searchMessages:self.searchBar.text force:NO];
//                    messagesSearchViewController.shouldScrollToBottomOnRefresh = YES;
//                });
//            }
//        }
//        else if (self.selectedViewController == peopleSearchViewController)
//        {
//            [peopleSearchViewController searchWithPattern:self.searchBar.text forceReset:NO complete:^{
//                
//                [self checkAndShowBackgroundImage];
//                
//            }];
//        }
//        else if (self.selectedViewController == filesSearchViewController)
//        {
//            // Launch the search only if the keyboard is no more visible
//            if (!self.searchBar.isFirstResponder)
//            {
//                // Do it asynchronously to give time to filesSearchViewController to be set up
//                // so that it can display its loading wheel
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [filesSearchDataSource searchMessages:self.searchBar.text force:NO];
//                    filesSearchViewController.shouldScrollToBottomOnRefresh = YES;
//                });
//            }
//        }
//    }
//    else
//    {
//        // Nothing to search, show only the public dictionary
//        recentsDataSource.hideRecents = YES;
//        recentsDataSource.hidePublicRoomsDirectory = NO;
//        
//        // Reset search result (if any)
//        [recentsDataSource searchWithPatterns:nil];
//        if (messagesSearchDataSource.searchText.length)
//        {
//            [messagesSearchDataSource searchMessages:nil force:NO];
//        }
//        
//        [peopleSearchViewController searchWithPattern:nil forceReset:NO complete:^{
//            
//            [self checkAndShowBackgroundImage];
//            
//        }];
//        
//        if (filesSearchDataSource.searchText.length)
//        {
//            [filesSearchDataSource searchMessages:nil force:NO];
//        }
//    }
//    
//    [self checkAndShowBackgroundImage];
//}
//
//#pragma mark - UISearchBarDelegate
//
//- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
//{
//    if (self.selectedViewController == recentsViewController)
//    {
//        // As the public room search is local, it can be updated on each text change
//        [self updateSearch];
//    }
//    else if (self.selectedViewController == peopleSearchViewController)
//    {
//        // As the contact search is local, it can be updated on each text change
//        [self updateSearch];
//    }
//    else if (!self.searchBar.text.length)
//    {
//        // Reset message search if any
//        [self updateSearch];
//    }
//}
//
//- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
//{
//    [searchBar resignFirstResponder];
//    
//    if (self.selectedViewController == messagesSearchViewController || self.selectedViewController == filesSearchViewController)
//    {
//        // As the messages/files search is done homeserver-side, launch it only on the "Search" button
//        [self updateSearch];
//    }
//}

#pragma mark - MXKRecentListViewControllerDelegate

- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoom:(NSString *)roomId inMatrixSession:(MXSession *)matrixSession
{
    // Open the room
    [[AppDelegate theDelegate].masterTabBarController selectRoomWithId:roomId andEventId:nil inMatrixSession:matrixSession];
}

#pragma mark - Actions

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
    
    currentAlert.mxkAccessibilityIdentifier = @"HomeVCCreateRoomAlert";
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
            [self startActivityIndicator];

            // Create an empty room.
            roomCreationRequest = [self.mainSession createRoom:nil
                                                    visibility:kMXRoomDirectoryVisibilityPrivate
                                                     roomAlias:nil
                                                         topic:nil
                                                       success:^(MXRoom *room) {

                                                           roomCreationRequest = nil;
                                                           [self stopActivityIndicator];
                                                           if (currentAlert)
                                                           {
                                                               [currentAlert dismiss:NO];
                                                               currentAlert = nil;
                                                           }

                                                           [[AppDelegate theDelegate].masterTabBarController selectRoomWithId:room.state.roomId andEventId:nil inMatrixSession:self.mainSession];

                                                           // Force the expanded header
                                                           [AppDelegate theDelegate].masterTabBarController.currentRoomViewController.showExpandedHeader = YES;

                                                       } failure:^(NSError *error) {

                                                           roomCreationRequest = nil;
                                                           [self stopActivityIndicator];
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
            currentAlert.mxkAccessibilityIdentifier = @"HomeVCRoomCreationInProgressAlert";
            [currentAlert showInViewController:self];
        }
    }
}

@end
