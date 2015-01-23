/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "RecentsViewController.h"
#import "RoomViewController.h"

#import "RecentRoom.h"
#import "RecentsTableViewCell.h"

#import "AppDelegate.h"
#import "MatrixHandler.h"

#import "MediaManager.h"

@interface RecentsViewController () {
    // Array of RecentRooms
    NSMutableArray  *recents;
    id               recentsListener;
    NSUInteger       unreadCount;
    
    // Search
    UISearchBar     *recentsSearchBar;
    NSMutableArray  *filteredRecents;
    BOOL             searchBarShouldEndEditing;
    
    // Date formatter
    NSDateFormatter *dateFormatter;
    
    RoomViewController *currentRoomViewController;
    BOOL                isVisible;
}
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation RecentsViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(search:)];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createNewRoom:)];
    self.navigationItem.rightBarButtonItems = @[searchButton, addButton];
    
    // Add background to activity indicator
    CGRect frame = _activityIndicator.frame;
    frame.size.width += 30;
    frame.size.height += 30;
    _activityIndicator.bounds = frame;
    _activityIndicator.backgroundColor = [UIColor darkGrayColor];
    [_activityIndicator.layer setCornerRadius:5];
    
    // Initialisation
    recents = nil;
    filteredRecents = nil;
    unreadCount = 0;
    
    NSString *dateFormat = @"MMM dd HH:mm";
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0]]];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:dateFormat];
    
    [[MatrixHandler sharedHandler] addObserver:self forKeyPath:@"status" options:0 context:nil];
}

- (void)dealloc {
    if (currentRoomViewController) {
        currentRoomViewController.roomId = nil;
        currentRoomViewController = nil;
    }
    if (recentsListener) {
        [[MatrixHandler sharedHandler].mxSession removeListener:recentsListener];
        recentsListener = nil;
    }
    recents = nil;
    _preSelectedRoomId = nil;
    recentsSearchBar = nil;
    filteredRecents = nil;
    
    if (dateFormatter) {
        dateFormatter = nil;
    }
    [[MatrixHandler sharedHandler] removeObserver:self forKeyPath:@"status"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Refresh display
    [self configureView];
    [[MatrixHandler sharedHandler] addObserver:self forKeyPath:@"isResumeDone" options:0 context:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Leave potential editing mode
    [self setEditing:NO];
    // Leave potential search session
    if (recentsSearchBar) {
        [self searchBarCancelButtonClicked:recentsSearchBar];
    }
    // Hide activity indicator
    [self stopActivityIndicator];
    
    _preSelectedRoomId = nil;
    [[MatrixHandler sharedHandler] removeObserver:self forKeyPath:@"isResumeDone"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    isVisible = YES;
    
    // Release potential Room ViewController if none is visible (Note: check on room visibility is required to handle correctly splitViewController)
    if ([AppDelegate theDelegate].masterTabBarController.visibleRoomId == nil && currentRoomViewController) {
        currentRoomViewController.roomId = nil;
        currentRoomViewController = nil;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    isVisible = NO;
}

#pragma mark -

- (void)setPreSelectedRoomId:(NSString *)roomId {
    _preSelectedRoomId = nil;

    if (roomId) {
        // Check whether recents update is in progress
        if ([_activityIndicator isAnimating]) {
            // Postpone room details display
            _preSelectedRoomId = roomId;
            return;
        }
        
        // Look for the room index in recents list
        NSIndexPath *indexPath = nil;
        for (NSUInteger index = 0; index < recents.count; index++) {
            RecentRoom *recentRoom = [recents objectAtIndex:index];
            if ([roomId isEqualToString:recentRoom.roomId]) {
                indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                break;
            }
        }
        
        if (indexPath) {
            // Open details view
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
            UITableViewCell *recentCell = [self.tableView cellForRowAtIndexPath:indexPath];
            [self performSegueWithIdentifier:@"showDetail" sender:recentCell];
        } else {
            NSLog(@"We are not able to open room (%@) because it does not appear in recents yet", roomId);
            // Postpone room details display. We run activity indicator until recents are updated (thanks to recents listener)
            _preSelectedRoomId = roomId;
            // Start activity indicator
            [self startActivityIndicator];
        }
    } else if (currentRoomViewController) {
        // Release the current selected room
        currentRoomViewController.roomId = nil;
        currentRoomViewController = nil;
    }
}

#pragma mark - Internal methods

- (void)refreshRecentsDisplay {
    // Check whether the current selected room has not been left
    if (currentRoomViewController.roomId) {
        MXRoom *mxRoom = [[MatrixHandler sharedHandler].mxSession roomWithRoomId:currentRoomViewController.roomId];
        if (mxRoom == nil || mxRoom.state.membership == MXMembershipLeave || mxRoom.state.membership == MXMembershipBan) {
            // release the room viewController
            currentRoomViewController.roomId = nil;
            currentRoomViewController = nil;
        }
    }
    
    [self.tableView reloadData];
}

- (void)configureView {
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
    [self startActivityIndicator];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRecentRoomUpdatedByBackPagination object:nil];
    
    if (mxHandler.mxSession) {
        // Check matrix handler status
        if (mxHandler.status == MatrixHandlerStatusStoreDataReady) {
            // Server sync is not complete yet
            if (!recents) {
                // Retrieve recents from local storage (some data may not be up-to-date)
                NSArray *recentEvents = [NSMutableArray arrayWithArray:[mxHandler.mxSession recentsWithTypeIn:mxHandler.eventsFilterForMessages]];
                recents = [NSMutableArray arrayWithCapacity:recentEvents.count];
                for (MXEvent *mxEvent in recentEvents) {
                    MXRoom *mxRoom = [mxHandler.mxSession roomWithRoomId:mxEvent.roomId];
                    RecentRoom *recentRoom = [[RecentRoom alloc] initWithLastEvent:mxEvent andRoomState:mxRoom.state markAsUnread:NO];
                    if (recentRoom) {
                        [recents addObject:recentRoom];
                    }
                }
                unreadCount = 0;
            }
        } else if (mxHandler.status == MatrixHandlerStatusServerSyncDone) {
            // Force recents refresh and add listener to update them (if it is not already done)
            if (!recentsListener) {
                NSArray *recentEvents = [NSMutableArray arrayWithArray:[mxHandler.mxSession recentsWithTypeIn:mxHandler.eventsFilterForMessages]];
                recents = [NSMutableArray arrayWithCapacity:recentEvents.count];
                for (MXEvent *mxEvent in recentEvents) {
                    MXRoom *mxRoom = [mxHandler.mxSession roomWithRoomId:mxEvent.roomId];
                    RecentRoom *recentRoom = [[RecentRoom alloc] initWithLastEvent:mxEvent andRoomState:mxRoom.state markAsUnread:NO];
                    if (recentRoom) {
                        [recents addObject:recentRoom];
                    }
                }
                unreadCount = 0;
                
                // Register recent listener
                recentsListener = [mxHandler.mxSession listenToEventsOfTypes:mxHandler.eventsFilterForMessages onEvent:^(MXEvent *event, MXEventDirection direction, MXRoomState *roomState) {
                    // Consider first live event
                    if (direction == MXEventDirectionForwards) {
                        // Check user's membership in live room state (We will remove left rooms from recents)
                        MXRoom *mxRoom = [mxHandler.mxSession roomWithRoomId:event.roomId];
                        BOOL isLeft = (mxRoom == nil || mxRoom.state.membership == MXMembershipLeave || mxRoom.state.membership == MXMembershipBan);
                        
                        // Consider this new event as unread only if the sender is not the user and if the room is not visible
                        BOOL isUnread = (![event.userId isEqualToString:mxHandler.userId]
                                         && ![[AppDelegate theDelegate].masterTabBarController.visibleRoomId isEqualToString:event.roomId]);
                        
                        // Look for the room
                        BOOL isFound = NO;
                        for (NSUInteger index = 0; index < recents.count; index++) {
                            RecentRoom *recentRoom = [recents objectAtIndex:index];
                            if ([event.roomId isEqualToString:recentRoom.roomId]) {
                                isFound = YES;
                                if (isLeft) {
                                    // Remove left room
                                    [recents removeObjectAtIndex:index];
                                    if (filteredRecents) {
                                        NSUInteger filteredIndex = [filteredRecents indexOfObject:recentRoom];
                                        if (filteredIndex != NSNotFound) {
                                            [filteredRecents removeObjectAtIndex:filteredIndex];
                                        }
                                    }
                                } else {
                                    if ([recentRoom updateWithLastEvent:event andRoomState:roomState markAsUnread:isUnread]) {
                                        if (index) {
                                            // Move this room at first position
                                            [recents removeObjectAtIndex:index];
                                            [recents insertObject:recentRoom atIndex:0];
                                        }
                                        // Update filtered recents (if any)
                                        if (filteredRecents) {
                                            NSUInteger filteredIndex = [filteredRecents indexOfObject:recentRoom];
                                            if (filteredIndex && filteredIndex != NSNotFound) {
                                                [filteredRecents removeObjectAtIndex:filteredIndex];
                                                [filteredRecents insertObject:recentRoom atIndex:0];
                                            }
                                        }
                                        
                                        if (isUnread) {
                                            unreadCount++;
                                            [self updateTitleView];
                                        }
                                    }
                                }
                                break;
                            }
                        }
                        if (!isFound && !isLeft) {
                            // Insert in first position this new room
                            RecentRoom *recentRoom = [[RecentRoom alloc] initWithLastEvent:event andRoomState:roomState markAsUnread:isUnread];
                            if (recentRoom) {
                                [recents insertObject:recentRoom atIndex:0];
                                if (isUnread) {
                                    unreadCount++;
                                    [self updateTitleView];
                                }
                                
                                // Check whether we were waiting for this room
                                if (_preSelectedRoomId) {
                                    if ([recentRoom.roomId isEqualToString:_preSelectedRoomId]) {
                                        [self stopActivityIndicator];
                                        self.preSelectedRoomId = _preSelectedRoomId;
                                    }
                                }
                            }
                        }
                        
                        // Reload table
                        [self refreshRecentsDisplay];
                    }
                }];
            }
            // else nothing to do
        } else {
            recents = nil;
        }
        
        // Reload table
        [self.tableView reloadData];
        if ([mxHandler isResumeDone]) {
            [self stopActivityIndicator];
        }
        
        // Check whether a room is preselected
        if (_preSelectedRoomId) {
            self.preSelectedRoomId = _preSelectedRoomId;
        }
    } else {
        if (mxHandler.status == MatrixHandlerStatusLoggedOut) {
            [self stopActivityIndicator];
            // Update title
            unreadCount = 0;
            [self updateTitleView];
        }
        
        recents = nil;
        [self.tableView reloadData];
    }
    
    if (recents) {
        // Add observer to force refresh when a recent last description is updated thanks to back pagination
        // (This happens when the current last event description is blank, a back pagination is triggered to display non empty description)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRecentRoomUpdatedByBackPagination) name:kRecentRoomUpdatedByBackPagination object:nil];
    } else {
        // Remove potential listener
        if (recentsListener && mxHandler.mxSession) {
            [mxHandler.mxSession removeListener:recentsListener];
            recentsListener = nil;
        }
    }
    
    [self updateTitleView];
}

- (void)onRecentRoomUpdatedByBackPagination {
    [self.tableView reloadData];
}

- (void)updateTitleView {
    NSString *title = @"Recents";
    if (unreadCount) {
         title = [NSString stringWithFormat:@"Recents (%tu)", unreadCount];
    }
    self.navigationItem.title = title;
}

- (void)createNewRoom:(id)sender {
    [[AppDelegate theDelegate].masterTabBarController showRoomCreationForm];
}

- (void)search:(id)sender {
    if (!recentsSearchBar) {
        // Check whether there are data in which search
        if (recents.count) {
            // Create search bar
            recentsSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
            recentsSearchBar.showsCancelButton = YES;
            recentsSearchBar.returnKeyType = UIReturnKeyDone;
            recentsSearchBar.delegate = self;
            searchBarShouldEndEditing = NO;
            // add it to the tableHeaderView
            // do not create a header view
            // the header view is refreshed every time there is a [tableView reloaddata]
            // i.e. there is a removeFromSuperView call, the view is added to the tableview..
            // with a first respondable view, IOS seems lost to find the first responder
            // so, the keyboard is always displayed and can not be dismissed
            // tableHeaderView is never removed from superview so the first responder is not lost
            self.tableView.tableHeaderView = recentsSearchBar;

            [recentsSearchBar becomeFirstResponder];
            
            [self scrollToTop];
        }
    } else {
        [self searchBarCancelButtonClicked: recentsSearchBar];
    }
}

- (void)startActivityIndicator {
    // Add the spinner on main screen in order to ignore potential table scrolling
    _activityIndicator.center = CGPointMake(self.view.center.x, self.view.center.x);
    [[AppDelegate theDelegate].window addSubview:_activityIndicator];
    [_activityIndicator startAnimating];
}

- (void)stopActivityIndicator {
    [_activityIndicator stopAnimating];
    [_activityIndicator removeFromSuperview];
}

- (void)scrollToTop {
    // stop any scrolling effect
    [UIView setAnimationsEnabled:NO];
    // before scrolling to the tableview top
    self.tableView.contentOffset = CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top);
    [UIView setAnimationsEnabled:YES];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([@"status" isEqualToString:keyPath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureView];
            // Hide the activity indicator when Recents is not visible
            if (!isVisible) {
                [self stopActivityIndicator];
            }
        });
    } else if ([@"isResumeDone" isEqualToString:keyPath]) {
        if ([[MatrixHandler sharedHandler] isResumeDone]) {
            [self stopActivityIndicator];
        } else {
            [self startActivityIndicator];
        }
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        RecentRoom *recentRoom;
        if (filteredRecents) {
            recentRoom = filteredRecents[indexPath.row];
        } else {
            recentRoom = recents[indexPath.row];
        }
        
        UIViewController *controller;
        if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            controller = [[segue destinationViewController] topViewController];
        } else {
            controller = [segue destinationViewController];
        }
        
        if ([controller isKindOfClass:[RoomViewController class]]) {
            // Release potential Room ViewController
            if (currentRoomViewController) {
                currentRoomViewController.roomId = nil;
                currentRoomViewController = nil;
            }
            currentRoomViewController = (RoomViewController *)controller;
            currentRoomViewController.roomId = recentRoom.roomId;
        }
        
        // Reset unread count for this room
        unreadCount -= recentRoom.unreadCount;
        [recentRoom resetUnreadCount];
        [self updateTitleView];
        
        if (self.splitViewController) {
            // IOS >= 8
            if ([self.splitViewController respondsToSelector:@selector(displayModeButtonItem)]) {
                controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
            }
            
            // hide the keyboard when opening a new controller
            // do not hide the searchBar until the RecentsViewController is dismissed
            // on tablets / iphone 6+, the user could expect to search again while looking at a room
            if ([recentsSearchBar isFirstResponder]) {
                searchBarShouldEndEditing = YES;
                [recentsSearchBar resignFirstResponder];
            }
    
            //
            controller.navigationItem.leftItemsSupplementBackButton = YES;
        }
        
        // Hide back button title
        self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (filteredRecents) {
        return filteredRecents.count;
    }
    return recents.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RecentsTableViewCell *cell = (RecentsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"RecentsCell" forIndexPath:indexPath];

    RecentRoom *recentRoom;
    if (filteredRecents) {
        recentRoom = filteredRecents[indexPath.row];
    } else {
        recentRoom = recents[indexPath.row];
    }
    
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    MXRoom *mxRoom = [mxHandler.mxSession roomWithRoomId:recentRoom.roomId];
    
    cell.roomTitle.text = [mxRoom.state displayname];
    cell.lastEventDescription.text = recentRoom.lastEventDescription;
    
    // Set in bold public room name
    if (mxRoom.state.isPublic) {
        cell.roomTitle.font = [UIFont boldSystemFontOfSize:20];
    } else {
        cell.roomTitle.font = [UIFont systemFontOfSize:19];
    }
    
    if (recentRoom.lastEventOriginServerTs != kMXUndefinedTimestamp) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:recentRoom.lastEventOriginServerTs/1000];
        cell.recentDate.text = [dateFormatter stringFromDate:date];
    } else {
        cell.recentDate.text = nil;
    }
    
    // set background color
    if (recentRoom.unreadCount) {
        cell.backgroundColor = [UIColor colorWithRed:1 green:0.9 blue:0.9 alpha:1.0];
        cell.roomTitle.text = [NSString stringWithFormat:@"%@ (%tu)", cell.roomTitle.text, recentRoom.unreadCount];
    } else {
        cell.backgroundColor = [UIColor clearColor];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Leave the selected room
        RecentRoom *selectedRoom;
        if (filteredRecents) {
            selectedRoom = filteredRecents[indexPath.row];
        } else {
            selectedRoom = recents[indexPath.row];
        }
        
        MXRoom *mxRoom = [[MatrixHandler sharedHandler].mxSession roomWithRoomId:selectedRoom.roomId];

        // cancel pending uploads/downloads
        // they are useless by now
        [MediaManager cancelDownloadsInFolder:selectedRoom.roomId];
        [MediaManager cancelUploadsInFolder:selectedRoom.roomId];
        
        [mxRoom leave:^{
            // Remove the selected room (if it is not already done by recents listener)
            for (NSUInteger index = 0; index < recents.count; index++) {
                RecentRoom *recentRoom = [recents objectAtIndex:index];
                if ([recentRoom.roomId isEqualToString:selectedRoom.roomId]) {
                    [recents removeObjectAtIndex:index];
                    if (filteredRecents) {
                        NSUInteger filteredIndex = [filteredRecents indexOfObject:selectedRoom];
                        if (filteredIndex != NSNotFound) {
                            [filteredRecents removeObjectAtIndex:filteredIndex];
                        }
                    }
                    break;
                }
            }
            // Refresh table display
            [self refreshRecentsDisplay];
        } failure:^(NSError *error) {
            NSLog(@"Failed to leave room (%@) failed: %@", selectedRoom.roomId, error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    }
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    searchBarShouldEndEditing = NO;
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return searchBarShouldEndEditing;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    // Update filtered list
    if (searchText.length) {
        if (filteredRecents) {
            [filteredRecents removeAllObjects];
        } else {
            filteredRecents = [NSMutableArray arrayWithCapacity:recents.count];
        }
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        for (RecentRoom *recentRoom in recents) {
            MXRoom *mxRoom = [mxHandler.mxSession roomWithRoomId:recentRoom.roomId];
            if ([[mxRoom.state displayname] rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [filteredRecents addObject:recentRoom];
            }
        }
    } else {
        filteredRecents = nil;
    }
    // Refresh display
    [self.tableView reloadData];
    [self scrollToTop];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    // "Done" key has been pressed
    searchBarShouldEndEditing = YES;
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    // Leave search
    searchBarShouldEndEditing = YES;
    [searchBar resignFirstResponder];
    recentsSearchBar = nil;
    filteredRecents = nil;
    self.tableView.tableHeaderView = nil;
    [self.tableView reloadData];
    [self scrollToTop];
}

@end
