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

#import "RageShakeManager.h"

@interface RecentsViewController ()
{
    
    // Recents refresh handling
    BOOL shouldScrollToTopOnRefresh;
    
    // Selected room description
    NSString  *selectedRoomId;
    MXSession *selectedRoomSession;
    
    // Keep reference on the current room view controller to release it correctly
    RoomViewController *currentRoomViewController;
    
    // Keep the selected cell index to handle correctly split view controller display in landscape mode
    NSIndexPath *currentSelectedCellIndexPath;
    
    // "Mark all as read" option
    UITapGestureRecognizer *navigationBarTapGesture;
    MXKAlert *markAllAsReadAlert;
}

@end

@implementation RecentsViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    // Add navigation items
    NSArray *rightBarButtonItems = self.navigationItem.rightBarButtonItems;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createNewRoom:)];
    self.navigationItem.rightBarButtonItems = rightBarButtonItems ? [rightBarButtonItems arrayByAddingObject:addButton] : @[addButton];
    
    // Prepare tap gesture on title bar
    navigationBarTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onNavigationBarTap:)];
    [navigationBarTapGesture setNumberOfTouchesRequired:1];
    [navigationBarTapGesture setNumberOfTapsRequired:1];
    [navigationBarTapGesture setDelegate:self];
    
    // Initialisation
    currentSelectedCellIndexPath = nil;
    
    // Setup `MXKRecentListViewController` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // The view controller handles itself the selected recent
    self.delegate = self;
}

- (void)dealloc
{
    if (currentRoomViewController)
    {
        [currentRoomViewController destroy];
        currentRoomViewController = nil;
    }
    selectedRoomId = nil;
    selectedRoomSession = nil;
}

- (void)destroy
{
    if (markAllAsReadAlert)
        
    {
        [markAllAsReadAlert dismiss:NO];
        markAllAsReadAlert = nil;
    }
    
    if (navigationBarTapGesture)
    {
        [self.navigationController.navigationBar removeGestureRecognizer:navigationBarTapGesture];
        navigationBarTapGesture = nil;
    }
    
    [super destroy];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.recentsTableView.editing = editing;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateNavigationBarTitle];
    
    // Deselect the current selected row, it will be restored on viewDidAppear (if any)
    NSIndexPath *indexPath = [self.recentsTableView indexPathForSelectedRow];
    if (indexPath)
    {
        [self.recentsTableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    [self.navigationController.navigationBar addGestureRecognizer:navigationBarTapGesture];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Leave potential editing mode
    [self setEditing:NO];
    
    selectedRoomId = nil;
    selectedRoomSession = nil;
    
    if (markAllAsReadAlert)
        
    {
        [markAllAsReadAlert dismiss:NO];
        markAllAsReadAlert = nil;
    }
    
    [self.navigationController.navigationBar removeGestureRecognizer:navigationBarTapGesture];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Release the current selected room (if any) except if the Room ViewController is still visible (see splitViewController.isCollapsed condition)
    if (!self.splitViewController || self.splitViewController.isCollapsed)
    {
        // Release the current selected room (if any).
        [self closeSelectedRoom];
    }
    else
    {
        // In case of split view controller where the primary and secondary view controllers are displayed side-by-side onscreen,
        // the selected room (if any) is highlighted.
        [self refreshCurrentSelectedCell:YES];
    }
}

#pragma mark -

- (void)selectRoomWithId:(NSString*)roomId inMatrixSession:(MXSession*)matrixSession
{
    if (selectedRoomId && [selectedRoomId isEqualToString:roomId]
        && selectedRoomSession && selectedRoomSession == matrixSession)
    {
        // Nothing to do
        return;
    }
    
    selectedRoomId = roomId;
    selectedRoomSession = matrixSession;
    
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
    selectedRoomId = nil;
    selectedRoomSession = nil;
    
    if (currentRoomViewController)
    {
        // Release the current selected room
        [currentRoomViewController destroy];
        currentRoomViewController = nil;
    }
}

#pragma mark - Internal methods

- (void)updateNavigationBarTitle
{
    NSString *title = @"Recents";
    
    if (self.dataSource.unreadCount)
    {
        title = [NSString stringWithFormat:@"Recents (%tu)", self.dataSource.unreadCount];
    }
    self.navigationItem.title = title;
}

- (void)createNewRoom:(id)sender
{
    [[AppDelegate theDelegate].masterTabBarController showRoomCreationForm];
}

- (void)scrollToTop
{
    // stop any scrolling effect
    [UIView setAnimationsEnabled:NO];
    // before scrolling to the tableview top
    self.recentsTableView.contentOffset = CGPointMake(-self.recentsTableView.contentInset.left, -self.recentsTableView.contentInset.top);
    [UIView setAnimationsEnabled:YES];
}

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    // Update here the index of the current selected cell (if any) - Useful in landscape mode with split view controller.
    currentSelectedCellIndexPath = nil;
    if (currentRoomViewController)
    {
        // Restore the current selected room id, it is erased when view controller disappeared (see viewWillDisappear).
        if (!selectedRoomId)
        {
            selectedRoomId = currentRoomViewController.roomDataSource.roomId;
            selectedRoomSession = currentRoomViewController.mainSession;
        }
        
        // Look for the rank of this selected room in displayed recents
        currentSelectedCellIndexPath = [self.dataSource cellIndexPathWithRoomId:selectedRoomId andMatrixSession:selectedRoomSession];
    }
    
    if (currentSelectedCellIndexPath)
    {
        // Select the right row
        [self.recentsTableView selectRowAtIndexPath:currentSelectedCellIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        
        if (forceVisible)
        {
            // Scroll table view to make the selected row appear at second position
            NSInteger topCellIndexPathRow = currentSelectedCellIndexPath.row ? currentSelectedCellIndexPath.row - 1: currentSelectedCellIndexPath.row;
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:topCellIndexPathRow inSection:currentSelectedCellIndexPath.section];
            [self.recentsTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    }
    else
    {
        NSIndexPath *indexPath = [self.recentsTableView indexPathForSelectedRow];
        if (indexPath)
        {
            [self.recentsTableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

#pragma mark -

- (void)onNavigationBarTap:(id)sender
{
    if (self.dataSource.unreadCount)
        
    {
        __weak typeof(self) weakSelf = self;
        
        markAllAsReadAlert = [[MXKAlert alloc] initWithTitle:@"Mark all as read?" message:nil style:MXKAlertStyleAlert];
        
        markAllAsReadAlert.cancelButtonIndex = [markAllAsReadAlert addActionWithTitle:@"No" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
                                                {
                                                    typeof(self) strongSelf = weakSelf;
                                                    strongSelf->markAllAsReadAlert = nil;
                                                }];
        
        [markAllAsReadAlert addActionWithTitle:@"Yes" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
         {
             typeof(self) strongSelf = weakSelf;
             
             strongSelf->markAllAsReadAlert = nil;
             
             [strongSelf.dataSource markAllAsRead];
             [strongSelf updateNavigationBarTitle];
         }];
        
        [markAllAsReadAlert showInViewController:self];
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
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
            // Release potential Room ViewController
            if (currentRoomViewController)
            {
                [currentRoomViewController destroy];
                currentRoomViewController = nil;
            }
            
            currentRoomViewController = (RoomViewController *)controller;
            
            MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:selectedRoomSession];
            MXKRoomDataSource *roomDataSource = [roomDataSourceManager roomDataSourceForRoom:selectedRoomId create:YES];
            [currentRoomViewController displayRoom:roomDataSource];
        }
        
        // Reset unread count for this room
        //[roomDataSource resetUnreadCount]; // @TODO: This automatically done by roomDataSource. Is it a good thing?
        [self updateNavigationBarTitle];
        
        if (self.splitViewController)
        {
            // Refresh selected cell without scrolling the selected cell (We suppose it's visible here)
            [self refreshCurrentSelectedCell:NO];
            
            // IOS >= 8
            if ([self.splitViewController respondsToSelector:@selector(displayModeButtonItem)])
            {
                controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
            }
            
            //
            controller.navigationItem.leftItemsSupplementBackButton = YES;
        }
        
        // Hide back button title
        self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
}

#pragma mark - MXKDataSourceDelegate
- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    // Update the unreadCount in the title
    [self updateNavigationBarTitle];
    
    [self.recentsTableView reloadData];
    
    if (shouldScrollToTopOnRefresh)
    {
        [self scrollToTop];
        shouldScrollToTopOnRefresh = NO;
    }
    
    // In case of split view controller where the primary and secondary view controllers are displayed side-by-side onscreen,
    // the selected room (if any) is updated and kept visible.
    if (self.splitViewController && !self.splitViewController.isCollapsed)
    {
        [self refreshCurrentSelectedCell:YES];
    }
}

#pragma mark - MXKRecentListViewControllerDelegate
- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoom:(NSString *)roomId inMatrixSession:(MXSession *)matrixSession
{
    // Open the room
    [self selectRoomWithId:roomId inMatrixSession:matrixSession];
}

#pragma mark - Override UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Prepare table refresh on new search session
    shouldScrollToTopOnRefresh = YES;
    
    [super searchBar:searchBar textDidChange:searchText];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // Prepare table refresh on end of search
    shouldScrollToTopOnRefresh = YES;
    
    [super searchBarCancelButtonClicked: searchBar];
}

@end
