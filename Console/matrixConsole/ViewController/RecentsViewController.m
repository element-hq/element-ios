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
#import "MatrixSDKHandler.h"

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
    
    // Keep reference on the current room view controller to release it correctly
    RoomViewController *currentRoomViewController;
    
    // Keep the selected cell index to handle correctly split view controller display in landscape mode
    NSInteger currentSelectedCellIndexPathRow;
    
    // The activity indicator is displayed on main screen in order to ignore potential table scrolling
    // In some case this activity indicator shoud be hidden (For example when the recents view controller is not visible).
    BOOL shouldHideActivityIndicator;
}
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation RecentsViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
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
    currentSelectedCellIndexPathRow = -1;
    
    NSString *dateFormat = @"MMM dd HH:mm";
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0]]];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:dateFormat];
    
    [[MatrixSDKHandler sharedHandler] addObserver:self forKeyPath:@"status" options:0 context:nil];
}

- (void)dealloc {
    if (currentRoomViewController) {
        currentRoomViewController.roomId = nil;
        currentRoomViewController = nil;
    }
    if (recentsListener) {
        [[MatrixSDKHandler sharedHandler].mxSession removeListener:recentsListener];
        recentsListener = nil;
    }
    recents = nil;
    _preSelectedRoomId = nil;
    recentsSearchBar = nil;
    filteredRecents = nil;
    
    if (dateFormatter) {
        dateFormatter = nil;
    }
    [[MatrixSDKHandler sharedHandler] removeObserver:self forKeyPath:@"status"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    [mxHandler addObserver:self forKeyPath:@"isActivityInProgress" options:0 context:nil];
    
    // Refresh display
    shouldHideActivityIndicator = NO;
    if (mxHandler.isActivityInProgress) {
        [self startActivityIndicator];
    }
    [self configureView];
    
    if (self.splitViewController) {
        // Deselect the current selected row, it will be restored on viewDidAppear (if any)
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MatrixSDKHandler sharedHandler] removeObserver:self forKeyPath:@"isActivityInProgress"];
    
    // Leave potential editing mode
    [self setEditing:NO];
    // Leave potential search session
    if (recentsSearchBar) {
        [self searchBarCancelButtonClicked:recentsSearchBar];
    }
    // Hide activity indicator
    [self stopActivityIndicator];
    shouldHideActivityIndicator = YES;
    
    _preSelectedRoomId = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Release the current selected room (if any) except if the Room ViewController is still visible (see splitViewController.isCollapsed condition)
    if (!self.splitViewController || self.splitViewController.isCollapsed) {
        if (currentRoomViewController) {
            currentRoomViewController.roomId = nil;
            currentRoomViewController = nil;
            // Reset selected row index
            currentSelectedCellIndexPathRow = -1;
        }
    } else {
        // In case of split view controller where the primary and secondary view controllers are displayed side-by-side onscreen,
        // the selected room (if any) is highlighted.
        [self refreshCurrentSelectedCell:YES];
    }
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
            NSLog(@"[RecentsVC] We are not able to open room (%@) because it does not appear in recents yet", roomId);
            // Postpone room details display. We run activity indicator until recents are updated (thanks to recents listener)
            _preSelectedRoomId = roomId;
            // Start activity indicator
            [self startActivityIndicator];
        }
    } else if (currentRoomViewController) {
        // Release the current selected room
        currentRoomViewController.roomId = nil;
        currentRoomViewController = nil;
        
        // Force table refresh to deselect related cell
        [self refreshRecentsDisplay];
    }
}

#pragma mark - Internal methods

- (void)refreshRecentsDisplay {
    // Check whether the current selected room has not been left
    if (currentRoomViewController.roomId) {
        MXRoom *mxRoom = [[MatrixSDKHandler sharedHandler].mxSession roomWithRoomId:currentRoomViewController.roomId];
        if (mxRoom == nil || mxRoom.state.membership == MXMembershipLeave || mxRoom.state.membership == MXMembershipBan) {
            // release the room viewController
            currentRoomViewController.roomId = nil;
            currentRoomViewController = nil;
        }
    }
    
    [self.tableView reloadData];
    
    // In case of split view controller where the primary and secondary view controllers are displayed side-by-side onscreen,
    // the selected room (if any) is updated and kept visible.
    if (self.splitViewController && !self.splitViewController.isCollapsed) {
        [self refreshCurrentSelectedCell:YES];
    }
}

- (void)configureView {
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRecentRoomUpdatedByBackPagination object:nil];
    
    if (mxHandler.mxSession) {
        // Check matrix handler status
        if (mxHandler.status == MatrixSDKHandlerStatusStoreDataReady || mxHandler.status == MatrixSDKHandlerStatusInitialServerSyncInProgress) {
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
        } else if (mxHandler.status == MatrixSDKHandlerStatusServerSyncDone) {
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
                
                // Check whether redaction event belongs to the listened events list
                NSArray *listenedEventTypes = mxHandler.eventsFilterForMessages;
                BOOL hideRedactionEvent = ([listenedEventTypes indexOfObject:kMXEventTypeStringRoomRedaction] == NSNotFound);
                if (hideRedactionEvent) {
                    // Add redaction event to the listened events list in order to take into account redaction of the last event in recents.
                    // (See [RecentRoom updateWithLastEvent:...] for more details)
                    listenedEventTypes = [listenedEventTypes arrayByAddingObject:kMXEventTypeStringRoomRedaction];
                }
                // Register recent listener
                recentsListener = [mxHandler.mxSession listenToEventsOfTypes:listenedEventTypes onEvent:^(MXEvent *event, MXEventDirection direction, MXRoomState *roomState) {
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
                                // Decrement here unreads count for this recent (we will add later the refreshed count)
                                unreadCount -= recentRoom.unreadCount;
                                
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
                                    }
                                    // Refresh global unreads count
                                    unreadCount += recentRoom.unreadCount;
                                }
                                
                                // Refresh title
                                [self updateTitleView];
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
        } else if (mxHandler.status != MatrixSDKHandlerStatusPaused) {
            // Here status is MatrixSDKHandlerStatusLoggedOut or MatrixSDKHandlerStatusLogged - Reset recents
            recents = nil;
        }
        
        // Reload table
        [self refreshRecentsDisplay];
        
        // Check whether a room is preselected
        if (_preSelectedRoomId) {
            self.preSelectedRoomId = _preSelectedRoomId;
        }
    } else {
        if (mxHandler.status == MatrixSDKHandlerStatusLoggedOut) {
            // Update title
            unreadCount = 0;
            [self updateTitleView];
        }
        
        recents = nil;
        [self refreshRecentsDisplay];
    }
    
    if (recents) {
        // Add observer to force refresh when a recent last description is updated thanks to back pagination
        // (This happens when the current last event description is blank, a back pagination is triggered to display non empty description)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRecentRoomUpdatedByBackPagination:) name:kRecentRoomUpdatedByBackPagination object:nil];
    } else {
        // Remove potential listener
        if (recentsListener && mxHandler.mxSession) {
            [mxHandler.mxSession removeListener:recentsListener];
            recentsListener = nil;
        }
    }
    
    [self updateTitleView];
}

- (void)onRecentRoomUpdatedByBackPagination:(NSNotification *)notif{
    [self refreshRecentsDisplay];
    [self updateTitleView];
    
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* roomId = notif.object;
        // Check whether this room is currently displayed in RoomViewController
        if ([[AppDelegate theDelegate].masterTabBarController.visibleRoomId isEqualToString:roomId]) {
            // For sanity reason, we have to force a full refresh in order to restore back state of the room
            dispatch_async(dispatch_get_main_queue(), ^{
                [currentRoomViewController forceRefresh];
            });
        }
    }
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

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible {
    // Update here the index of the current selected cell (if any) - Useful in landscape mode with split view controller.
    currentSelectedCellIndexPathRow = -1;
    if (currentRoomViewController) {
        // Look for the rank of this selected room in displayed recents
        NSArray *displayedRecents = filteredRecents ? filteredRecents : recents;
        for (NSInteger index = 0; index < displayedRecents.count; index ++) {
            RecentRoom *recentRoom = [displayedRecents objectAtIndex:index];
            if ([currentRoomViewController.roomId isEqualToString:recentRoom.roomId]) {
                currentSelectedCellIndexPathRow = index;
                break;
            }
        }
    }
    
    if (currentSelectedCellIndexPathRow != -1) {
        // Select the right row
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:currentSelectedCellIndexPathRow inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        
        if (forceVisible) {
            // Scroll table view to make the selected row appear at second position
            NSInteger topCellIndexPathRow = currentSelectedCellIndexPathRow ? currentSelectedCellIndexPathRow - 1: currentSelectedCellIndexPathRow;
            indexPath = [NSIndexPath indexPathForRow:topCellIndexPathRow inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    } else {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([@"status" isEqualToString:keyPath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureView];
        });
    } else if ([@"isActivityInProgress" isEqualToString:keyPath]) {
        if (!shouldHideActivityIndicator && [MatrixSDKHandler sharedHandler].isActivityInProgress) {
            [self startActivityIndicator];
        } else {
            [self stopActivityIndicator];
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
            // Refresh selected cell without scrolling the selected cell (We suppose it's visible here)
            [self refreshCurrentSelectedCell:NO];
            
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
    
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
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
    
    // Set background color
    if (recentRoom.unreadCount) {
        if (recentRoom.containsBingUnread) {
            cell.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:1 alpha:1.0];
        } else {
            cell.backgroundColor = [UIColor colorWithRed:1 green:0.9 blue:0.9 alpha:1.0];
        }
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
        
        MXRoom *mxRoom = [[MatrixSDKHandler sharedHandler].mxSession roomWithRoomId:selectedRoom.roomId];

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
            NSLog(@"[RecentsVC] Failed to leave room (%@) failed: %@", selectedRoom.roomId, error);
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
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
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
    [self refreshRecentsDisplay];
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
    [self refreshRecentsDisplay];
    [self scrollToTop];
}

@end
