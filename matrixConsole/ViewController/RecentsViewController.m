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

#import "RecentsTableViewCell.h"

#import "AppDelegate.h"
#import "MatrixHandler.h"

@interface RecentsViewController () {
    NSMutableArray  *recents;
    id               recentsListener;
    
    // Search
    UISearchBar     *recentsSearchBar;
    NSMutableArray  *filteredRecents;
    BOOL             searchBarShouldEndEditing;
    
    // Date formatter
    NSDateFormatter *dateFormatter;
    
    RoomViewController *currentRoomViewController;
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
    
    // Add activity indicator
    [self.view addSubview:_activityIndicator];
    _activityIndicator.center = CGPointMake(self.view.center.x, 100);
    [self.view bringSubviewToFront:_activityIndicator];
    
    // Initialisation
    recents = nil;
    filteredRecents = nil;
    
    NSString *dateFormat =  @"MMM dd HH:mm";
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0]]];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:dateFormat];
}

- (void)dealloc {
    if (currentRoomViewController) {
        currentRoomViewController.roomId = nil;
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Refresh recents table
    [self configureView];
    [[MatrixHandler sharedHandler] addObserver:self forKeyPath:@"isInitialSyncDone" options:0 context:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Leave potential editing mode
    [self setEditing:NO];
    // Leave potential search session
    if (recentsSearchBar) {
        [self searchBarCancelButtonClicked:recentsSearchBar];
    }
    
    if (recentsListener) {
        [[MatrixHandler sharedHandler].mxSession removeListener:recentsListener];
        recentsListener = nil;
    }
    
    _preSelectedRoomId = nil;
    [[MatrixHandler sharedHandler] removeObserver:self forKeyPath:@"isInitialSyncDone"];
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
            MXEvent *mxEvent = [recents objectAtIndex:index];
            if ([roomId isEqualToString:mxEvent.roomId]) {
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
            // Postpone room details display. We run activity indicator until recents are updated
            _preSelectedRoomId = roomId;
            // Start activity indicator
            [_activityIndicator startAnimating];
        }
    }
}

#pragma mark - Internal methods

- (void)configureView {
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
    // Remove potential listener
    if (recentsListener && mxHandler.mxSession) {
        [mxHandler.mxSession removeListener:recentsListener];
        recentsListener = nil;
    }
    
    [_activityIndicator startAnimating];
    
    if ([mxHandler isInitialSyncDone] || [mxHandler isLogged] == NO) {
        // Update recents
        if (mxHandler.mxSession) {
            recents = [NSMutableArray arrayWithArray:[mxHandler.mxSession recentsWithTypeIn:mxHandler.eventsFilterForMessages]];
            // Register recent listener
            recentsListener = [mxHandler.mxSession listenToEventsOfTypes:mxHandler.eventsFilterForMessages onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {
                // consider only live event
                if (direction == MXEventDirectionForwards) {
                    // Refresh the whole recents list
                    recents = [NSMutableArray arrayWithArray:[mxHandler.mxSession recentsWithTypeIn:mxHandler.eventsFilterForMessages]];
                    // Reload table
                    [self.tableView reloadData];
                    [_activityIndicator stopAnimating];
                    
                    // Check whether a room is preselected
                    if (_preSelectedRoomId) {
                        self.preSelectedRoomId = _preSelectedRoomId;
                    }
                }
            }];
        } else {
            recents = nil;
        }
        
        // Reload table
        [self.tableView reloadData];
        [_activityIndicator stopAnimating];
        
        // Check whether a room is preselected
        if (_preSelectedRoomId) {
            self.preSelectedRoomId = _preSelectedRoomId;
        }
    } else {
        recents = nil;
        [self.tableView reloadData];
    }
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
            [recentsSearchBar becomeFirstResponder];
            // Reload table in order to display search bar as section header
            [self.tableView reloadData];
        }
    } else {
        [self searchBarCancelButtonClicked: recentsSearchBar];
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([@"isInitialSyncDone" isEqualToString:keyPath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureView];
        });
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        MXEvent *mxEvent;
        if (filteredRecents) {
            mxEvent = filteredRecents[indexPath.row];
        } else {
            mxEvent = recents[indexPath.row];
        }
        
        UIViewController *controller;
        if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            controller = [[segue destinationViewController] topViewController];
        } else {
            controller = [segue destinationViewController];
        }
        
        if ([controller isKindOfClass:[RoomViewController class]]) {
            if (currentRoomViewController) {
                if ((currentRoomViewController != controller) || (![currentRoomViewController.roomId isEqualToString:mxEvent.roomId])) {
                    // Release the current one
                    currentRoomViewController.roomId = nil;
                }
            }
            currentRoomViewController = (RoomViewController *)controller;
            currentRoomViewController.roomId = mxEvent.roomId;
        }
        
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (recentsSearchBar) {
        return recentsSearchBar.frame.size.height;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return recentsSearchBar;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RecentsTableViewCell *cell = (RecentsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"RecentsCell" forIndexPath:indexPath];

    MXEvent *mxEvent;
    if (filteredRecents) {
        mxEvent = filteredRecents[indexPath.row];
    } else {
        mxEvent = recents[indexPath.row];
    }
    
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    MXRoom *mxRoom = [mxHandler.mxSession roomWithRoomId:mxEvent.roomId];
    
    cell.roomTitle.text = [mxRoom.state displayname];
    cell.lastEventDescription.text = [mxHandler displayTextForEvent:mxEvent withRoomState:mxRoom.state inSubtitleMode:YES];
    
    // Set in bold public room name
    if (mxRoom.state.isPublic) {
        cell.roomTitle.font = [UIFont boldSystemFontOfSize:20];
    } else {
        cell.roomTitle.font = [UIFont systemFontOfSize:19];
    }
    
    if (mxEvent.originServerTs != kMXUndefinedTimestamp) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:mxEvent.originServerTs/1000];
        cell.recentDate.text = [dateFormatter stringFromDate:date];
    } else {
        cell.recentDate.text = nil;
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
        MXEvent *mxEvent;
        if (filteredRecents) {
            mxEvent = filteredRecents[indexPath.row];
        } else {
            mxEvent = recents[indexPath.row];
        }
        MXRoom *mxRoom = [[MatrixHandler sharedHandler].mxSession roomWithRoomId:mxEvent.roomId];
        [mxRoom leave:^{
            // Refresh table display
            if (filteredRecents) {
                [filteredRecents removeObjectAtIndex:indexPath.row];
            } else {
                [recents removeObjectAtIndex:indexPath.row];
            }
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } failure:^(NSError *error) {
            NSLog(@"Failed to leave room (%@) failed: %@", mxEvent.roomId, error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    }
}

#pragma mark - UISearchBarDelegate

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
        for (MXEvent *mxEvent in recents) {
            MXRoom *mxRoom = [mxHandler.mxSession roomWithRoomId:mxEvent.roomId];
            if ([[mxRoom.state displayname] rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [filteredRecents addObject:mxEvent];
            }
        }
    } else {
        filteredRecents = nil;
    }
    // Refresh display
    [self.tableView reloadData];
    if (filteredRecents.count) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
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
    [self.tableView reloadData];
}

@end
