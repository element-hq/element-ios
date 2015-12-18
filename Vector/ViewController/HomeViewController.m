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

#import "RoomViewController.h"
#import "DirectoryViewController.h"

@interface HomeViewController ()
{
    // The search bar
    UISearchBar *searchBar;

    RecentsViewController *recentsViewController;
    RecentsDataSource *recentsDataSource;

    // Display a gradient view above the screen
    CAGradientLayer* tableViewMaskLayer;

    // Display a button to a new room
    UIImageView* createNewRoomImageView;

    // Backup of view when displaying search
    UIView *backupTitleView;
    UIBarButtonItem *backupLeftBarButtonItem;
    UIBarButtonItem *backupRightBarButtonItem;
}

@end

@implementation HomeViewController

- (void)viewDidLoad
{
    // Set up the SegmentedVC tabs before calling [super viewDidLoad]
    NSMutableArray* viewControllers = [[NSMutableArray alloc] init];
    NSMutableArray* titles = [[NSMutableArray alloc] init];

    [titles addObject: NSLocalizedStringFromTable(@"Rooms", @"Vector", nil)];
    recentsViewController = [RecentsViewController recentListViewController];
    recentsViewController.delegate = self;
    [viewControllers addObject:recentsViewController];

    [titles addObject: NSLocalizedStringFromTable(@"Messages", @"Vector", nil)];
    MXKViewController *tempMessagesVC = [[MXKViewController alloc] init];
    [viewControllers addObject:tempMessagesVC];

    [titles addObject: NSLocalizedStringFromTable(@"People", @"Vector", nil)];
    MXKViewController *tempPeopleVC = [[MXKViewController alloc] init];
    [viewControllers addObject:tempPeopleVC];

    [self initWithTitles:titles viewControllers:viewControllers defaultSelected:0];

    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedStringFromTable(@"recents", @"Vector", nil);
    
    self.backgroundImageView.image = [UIImage imageNamed:@"search_bg"];

    // Search bar
    searchBar = [[UISearchBar alloc] init];
    searchBar.showsCancelButton = YES;
    searchBar.delegate = self;
}

- (void)dealloc
{
    [self closeSelectedRoom];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Let's child display the loading not the home view controller
    if (self.activityIndicator)
    {
        [self.activityIndicator stopAnimating];
        self.activityIndicator = nil;
    }

    // Add blur mask programatically
    if (!tableViewMaskLayer)
    {
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
    }

    // Add new room button programatically
    if (!createNewRoomImageView)
    {
        createNewRoomImageView = [[UIImageView alloc] init];
        [createNewRoomImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addSubview:createNewRoomImageView];

        createNewRoomImageView.backgroundColor = [UIColor clearColor];
        createNewRoomImageView.image = [UIImage imageNamed:@"create_room"];

        CGFloat side = 58.0f;
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
                                                                             constant:19];

        if ([NSLayoutConstraint respondsToSelector:@selector(activateConstraints:)])
        {
            [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint, centerXConstraint, bottomConstraint]];
        }
        else
        {
            [createNewRoomImageView addConstraint:widthConstraint];
            [createNewRoomImageView addConstraint:heightConstraint];

            [self.view addConstraint:bottomConstraint];
            [self.view addConstraint:centerXConstraint];
        }

        createNewRoomImageView.userInteractionEnabled = YES;

        // tap -> switch to text edition
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onNewRoomPressed)];
        [tap setNumberOfTouchesRequired:1];
        [tap setNumberOfTapsRequired:1];
        [tap setDelegate:self];
        [createNewRoomImageView addGestureRecognizer:tap];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Release the current selected room (if any) except if the Room ViewController is still visible (see splitViewController.isCollapsed condition)
    // Note: 'isCollapsed' property is available in UISplitViewController for iOS 8 and later.
    if (!self.splitViewController || ([self.splitViewController respondsToSelector:@selector(isCollapsed)] && self.splitViewController.isCollapsed))
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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // TODO: Check why it was done before
    //_selectedRoomId = nil;
    //_selectedRoomSession = nil;
}

- (void) viewDidLayoutSubviews
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

- (void)displayWithSession:(MXSession *)mxSession
{
    [super addMatrixSession:mxSession];

    // Init the recents data source
    recentsDataSource = [[RecentsDataSource alloc] initWithMatrixSession:mxSession];
    [recentsViewController displayList:recentsDataSource fromHomeViewController:self];

    // Do not go to search mode when first opening the home
    [self hideSearch:NO];
}

- (void)addMatrixSession:(MXSession *)mxSession
{
    // Add the session to the existing recents data source
    if (recentsDataSource)
    {
        [recentsDataSource addMatrixSession:mxSession];
    }
}

- (void)removeMatrixSession:(MXSession *)mxSession
{
    [recentsDataSource removeMatrixSession:mxSession];
    
    // Check whether there are others sessions
    if (!self.mxSessions.count)
    {
        // Keep reference on existing dataSource to release it properly
        MXKRecentsDataSource *previousRecentlistDataSource = recentsViewController.dataSource;
        [recentsViewController displayList:nil];
        [previousRecentlistDataSource destroy];
    }
}

- (void)selectRoomWithId:(NSString*)roomId inMatrixSession:(MXSession*)matrixSession
{
    if (_selectedRoomId && [_selectedRoomId isEqualToString:roomId]
        && _selectedRoomSession && _selectedRoomSession == matrixSession)
    {
        // Nothing to do
        return;
    }

    _selectedRoomId = roomId;
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

- (void)closeSelectedRoom
{
    _selectedRoomId = nil;
    _selectedRoomSession = nil;

    if (_currentRoomViewController)
    {
        if (_currentRoomViewController.roomDataSource)
        {
            // Let the manager release this room data source
            MXSession *mxSession = _currentRoomViewController.roomDataSource.mxSession;
            MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:mxSession];
            [roomDataSourceManager closeRoomDataSource:_currentRoomViewController.roomDataSource forceClose:NO];
        }

        [_currentRoomViewController destroy];
        _currentRoomViewController = nil;
    }
}

- (void)showPublicRoomsDirectory
{
    [self performSegueWithIdentifier:@"showDirectory" sender:self];
}

#pragma mark - Internal methods

// Made the currently displayed child update its selected cell
- (void)refreshCurrentSelectedCellInChild:(BOOL)forceVisible
{
    // TODO: Manage other children than recents
    [recentsViewController refreshCurrentSelectedCell:YES];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Keep ref on destinationViewController
    [super prepareForSegue:segue sender:sender];

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
                if (_currentRoomViewController.roomDataSource)
                {
                    // Let the manager release this room data source
                    MXSession *mxSession = _currentRoomViewController.roomDataSource.mxSession;
                    MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:mxSession];
                    [roomDataSourceManager closeRoomDataSource:_currentRoomViewController.roomDataSource forceClose:NO];
                }

                [_currentRoomViewController destroy];
                _currentRoomViewController = nil;
            }

            _currentRoomViewController = (RoomViewController *)controller;

            MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:_selectedRoomSession];
            MXKRoomDataSource *roomDataSource = [roomDataSourceManager roomDataSourceForRoom:_selectedRoomId create:YES];
            [_currentRoomViewController displayRoom:roomDataSource];
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
    else if ([[segue identifier] isEqualToString:@"showDirectory"])
    {
        DirectoryViewController *directoryViewController = segue.destinationViewController;
        [directoryViewController displayWitDataSource:recentsDataSource.publicRoomsDirectoryDataSource];
    }

    // Hide back button title
    self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

#pragma mark - Search

- (void)showSearch:(BOOL)animated
{
    backupTitleView = self.navigationItem.titleView;
    backupLeftBarButtonItem = self.navigationItem.leftBarButtonItem;
    backupRightBarButtonItem = self.navigationItem.rightBarButtonItem;

    // Remove navigation buttons
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.leftBarButtonItem = nil;

    // Add the search bar and
    self.navigationItem.titleView = searchBar;
    [searchBar becomeFirstResponder];

    // Show the tabs header
    if (animated)
    {
        [self updateSearch];

        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:^{

                             self.selectionContainerHeightConstraint.constant = 44;
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished){
                         }];
    }
    else
    {
        [self updateSearch];
        self.selectionContainerHeightConstraint.constant = 44;
        [self.view layoutIfNeeded];
    }
}

- (void)hideSearch:(BOOL)animated
{
    if (backupLeftBarButtonItem)
    {
        self.navigationItem.titleView = backupTitleView;
        self.navigationItem.leftBarButtonItem = backupLeftBarButtonItem;
        self.navigationItem.rightBarButtonItem = backupRightBarButtonItem;
    }

    [recentsDataSource searchWithPatterns:nil];

    // Hide the tabs header
    if (animated)
    {
        // If the currently selected tab is the recents, force to show it right now
        // The transition looks smoother
        if (self.selectedViewController.view.hidden == YES && self.selectedViewController == recentsViewController)
        {
            self.selectedViewController.view.hidden = NO;
        }

        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:^{

                             self.selectionContainerHeightConstraint.constant = 0;
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished) {
                             // Go back to the recents tab
                             // Do it at the end of the animation when the tabs header of the SegmentedVC is hidden
                             // so that the user cannot see the selection bar of this header moving
                             self.selectedIndex = 0;
                             self.selectedViewController.view.hidden = NO;
                         }];
    }
    else
    {
        self.selectionContainerHeightConstraint.constant = 0;
        [self.view layoutIfNeeded];

        // Go back to the recents tab
        self.selectedIndex = 0;
        self.selectedViewController.view.hidden = NO;
    }
}

// Update search results under the currently selected tab
- (void)updateSearch
{
    if (searchBar.text.length)
    {
        self.selectedViewController.view.hidden = NO;

        // Forward the search request to the data source
        if (self.selectedViewController == recentsViewController)
        {
            [recentsDataSource searchWithPatterns:@[searchBar.text]];
        }
    }
    else
    {
        // Nothing to search = Show nothing
        self.selectedViewController.view.hidden = YES;
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (self.selectedViewController == recentsViewController)
    {
        // As the search is local, it can be updated on each text change
        [self updateSearch];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar2
{
    // "Search" key has been pressed
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar2
{
    [self hideSearch:YES];
}

#pragma mark - MXKRecentListViewControllerDelegate

- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoom:(NSString *)roomId inMatrixSession:(MXSession *)matrixSession
{
    // Open the room
    [self selectRoomWithId:roomId inMatrixSession:matrixSession];
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
    [self performSegueWithIdentifier:@"presentRoomCreationStep1" sender:self];
}

@end
