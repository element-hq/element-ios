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

#import "RecentsViewController.h"
#import "RoomViewController.h"

#import "AppDelegate.h"
#import "MatrixSDKHandler.h"

#import "RageShakeManager.h"

@interface RecentsViewController () {

    // Search
    UISearchBar     *recentsSearchBar;
    BOOL             searchBarShouldEndEditing;
    
    //
    BOOL shouldScrollToTopOnRefresh;
    
    // Keep reference on the current room view controller to release it correctly
    RoomViewController *currentRoomViewController;
    
    // Keep the selected cell index to handle correctly split view controller display in landscape mode
    NSInteger currentSelectedCellIndexPathRow;
}

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
    
    // Initialisation
    currentSelectedCellIndexPathRow = -1;
    
    // Setup `MXKRecentListViewController` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // The view controller handles itself the selected recent
    self.delegate = self;
}

- (void)dealloc {
    if (currentRoomViewController) {
        [currentRoomViewController destroy];
        currentRoomViewController = nil;
    }
    _selectedRoomId = nil;
    recentsSearchBar = nil;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    self.tableView.editing = editing;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateTitleView];
    
//    if (self.splitViewController)
    {
        // Deselect the current selected row, it will be restored on viewDidAppear (if any)
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Leave potential editing mode
    [self setEditing:NO];
    // Leave potential search session
    if (recentsSearchBar) {
        [self searchBarCancelButtonClicked:recentsSearchBar];
    }
    
    _selectedRoomId = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Release the current selected room (if any) except if the Room ViewController is still visible (see splitViewController.isCollapsed condition)
    if (!self.splitViewController || self.splitViewController.isCollapsed) {
        if (currentRoomViewController) {
            [currentRoomViewController destroy];
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

- (void)setSelectedRoomId:(NSString *)roomId {
    if (_selectedRoomId && [_selectedRoomId isEqualToString:roomId]) {
        // Nothing to do
        return;
    }
    
    _selectedRoomId = roomId;
    if (roomId) {
        // Open details view
//        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//        if (indexPath) {
//            id<MXKRecentCellDataStoring> recentCellData = [self.dataSource cellDataAtIndex:indexPath.row];
//            if (![recentCellData.room.state.roomId isEqualToString:roomId]) {
//                [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
//                indexPath = nil;
//            }
//        }
//        
//        if (!indexPath) {
//            NSInteger cellCount = [self.dataSource tableView:self.tableView numberOfRowsInSection:0];
//            for (NSInteger index = 0; index < cellCount; index ++) {
//                id<MXKRecentCellDataStoring> recentCellData = [self.dataSource cellDataAtIndex:index];
//                if ([_selectedRoomId isEqualToString:recentCellData.room.state.roomId]) {
//                    indexPath = [NSIndexPath indexPathForRow:index inSection:0];
//                    break;
//                }
//            }
//            
//            if (indexPath) {
//                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
//            }
//        }
        
        [self performSegueWithIdentifier:@"showDetails" sender:self];
    } else if (currentRoomViewController) {
        // Release the current selected room
        [currentRoomViewController destroy];
        currentRoomViewController = nil;
        
        // Force table refresh to deselect related cell
        [self refreshRecentsDisplay];
    }
}

#pragma mark - Internal methods

- (void)refreshRecentsDisplay {

    // Update the unreadCount in the title
    [self updateTitleView];
    
    [self.tableView reloadData];
    
    if (shouldScrollToTopOnRefresh) {
        [self scrollToTop];
        shouldScrollToTopOnRefresh = NO;
    }
    
    // In case of split view controller where the primary and secondary view controllers are displayed side-by-side onscreen,
    // the selected room (if any) is updated and kept visible.
    if (self.splitViewController && !self.splitViewController.isCollapsed) {
        [self refreshCurrentSelectedCell:YES];
    }
}

//- (void)onRecentRoomUpdatedByBackPagination:(NSNotification *)notif{
//    [self refreshRecentsDisplay];
//    [self updateTitleView];
//    
//    if ([notif.object isKindOfClass:[NSString class]]) {
//        NSString* roomId = notif.object;
//        // Check whether this room is currently displayed in RoomViewController
//        if ([[AppDelegate theDelegate].masterTabBarController.visibleRoomId isEqualToString:roomId]) {
//            // For sanity reason, we have to force a full refresh in order to restore back state of the room
//            dispatch_async(dispatch_get_main_queue(), ^{
//                MXKRoomDataSource *roomDataSrc = currentRoomViewController.dataSource;
//                [currentRoomViewController displayRoom:roomDataSrc];
//            });
//        }
//    }
//}

- (void)updateTitleView {
    NSString *title = @"Recents";
    
    if (self.dataSource.unreadCount) {
         title = [NSString stringWithFormat:@"Recents (%tu)", self.dataSource.unreadCount];
    }
    self.navigationItem.title = title;
}

- (void)createNewRoom:(id)sender {
    [[AppDelegate theDelegate].masterTabBarController showRoomCreationForm];
}

- (void)search:(id)sender {
    if (!recentsSearchBar) {
        // Check whether there are data in which search
        if ([self.dataSource tableView:self.tableView numberOfRowsInSection:0]) {
            // Create search bar
            recentsSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
            recentsSearchBar.showsCancelButton = YES;
            recentsSearchBar.returnKeyType = UIReturnKeyDone;
            recentsSearchBar.delegate = self;
            searchBarShouldEndEditing = NO;
            [recentsSearchBar becomeFirstResponder];
            
            // Reload table to add this search bar in section header
            shouldScrollToTopOnRefresh = YES;
            [self refreshRecentsDisplay];
        }
    } else {
        [self searchBarCancelButtonClicked: recentsSearchBar];
    }
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
        // Restore the current selected room id, it is erased when view controller disappeared (see viewWillDisappear).
        if (!_selectedRoomId) {
            _selectedRoomId = currentRoomViewController.roomDataSource.roomId;
        }
        
        // Look for the rank of this selected room in displayed recents
        NSInteger cellCount = [self.dataSource tableView:self.tableView numberOfRowsInSection:0];
        for (NSInteger index = 0; index < cellCount; index ++) {
            id<MXKRecentCellDataStoring> recentCellData = [self.dataSource cellDataAtIndex:index];
            if ([_selectedRoomId isEqualToString:recentCellData.roomDataSource.room.state.roomId]) {
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

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetails"]) {

        UIViewController *controller;
        if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            controller = [[segue destinationViewController] topViewController];
        } else {
            controller = [segue destinationViewController];
        }
        
        if ([controller isKindOfClass:[RoomViewController class]]) {
            // Release potential Room ViewController
            if (currentRoomViewController) {
                [currentRoomViewController destroy];
                currentRoomViewController = nil;
            }
            
            currentRoomViewController = (RoomViewController *)controller;

            MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mxSession];
            MXKRoomDataSource *roomDataSource = [roomDataSourceManager roomDataSourceForRoom:_selectedRoomId create:YES];
            [currentRoomViewController displayRoom:roomDataSource];
        }
        
        // Reset unread count for this room
        //[roomDataSource resetUnreadCount]; // @TODO: This automatically done by roomDataSource. Is it a good thing?
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

#pragma mark - MXKDataSourceDelegate
- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes {
    [self refreshRecentsDisplay];
}

#pragma mark - MXKRecentListViewControllerDelegate
- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoom:(NSString *)aRoomId {
    
    // Change the current room id to open the room
    self.selectedRoomId = aRoomId;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (recentsSearchBar) {
        return (recentsSearchBar.frame.size.height);
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return recentsSearchBar;
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
    
    // Apply filter
    shouldScrollToTopOnRefresh = YES;
    if (searchText.length) {
        [self.dataSource searchWithPatterns:@[searchText]];
    } else {
        [self.dataSource searchWithPatterns:nil];
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
    
    // Refresh display
    shouldScrollToTopOnRefresh = YES;
    [self.dataSource searchWithPatterns:nil];
}

@end
