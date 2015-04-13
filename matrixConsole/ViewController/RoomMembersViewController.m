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

#import "RoomMembersViewController.h"
#import "MemberViewController.h"

#import "MatrixSDKHandler.h"

#import "RageShakeManager.h"

@interface RoomMembersViewController () {

    // Search
    UISearchBar  *roomMembersSearchBar;
    BOOL searchBarShouldEndEditing;
    BOOL shouldScrollToTopOnRefresh;
    
    // Keep reference on the current member view controller to release it correctly
    MemberViewController *currentMemberViewController;
    
    // The selected member
    MXRoomMember *selectedMember;
}

@end

@implementation RoomMembersViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(search:)];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(inviteNewMember:)];
    self.navigationItem.rightBarButtonItems = @[searchButton, addButton];
    
    // Setup `MXKRoomMemberListViewController` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // The view controller handles itself the selected roomMember
    self.delegate = self;
}

- (void)dealloc {
    if (currentMemberViewController) {
        [currentMemberViewController destroy];
        currentMemberViewController = nil;
    }
    selectedMember = nil;
    roomMembersSearchBar = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Leave potential search session
    if (roomMembersSearchBar) {
        [self searchBarCancelButtonClicked:roomMembersSearchBar];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (currentMemberViewController) {
        [currentMemberViewController destroy];
        currentMemberViewController = nil;
    }
}


#pragma mark - Internal methods

- (void)refreshRoomMembersDisplay {
    
    if (shouldScrollToTopOnRefresh) {
        [self scrollToTop];
        shouldScrollToTopOnRefresh = NO;
    }
}

- (void)scrollToTop {
    // stop any scrolling effect
    [UIView setAnimationsEnabled:NO];
    // before scrolling to the tableview top
    self.tableView.contentOffset = CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top);
    [UIView setAnimationsEnabled:YES];
}

#pragma mark - Actions

- (void)search:(id)sender {
    if (!roomMembersSearchBar) {
        // Check whether there are data in which search
        if ([self.dataSource tableView:self.tableView numberOfRowsInSection:0]) {
            // Create search bar
            roomMembersSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
            roomMembersSearchBar.showsCancelButton = YES;
            roomMembersSearchBar.returnKeyType = UIReturnKeyDone;
            roomMembersSearchBar.delegate = self;
            searchBarShouldEndEditing = NO;
            [roomMembersSearchBar becomeFirstResponder];
            
            // Force table refresh to add search bar in section header
            shouldScrollToTopOnRefresh = YES;
            [self dataSource:self.dataSource didCellChange:nil];
        }
    } else {
        [self searchBarCancelButtonClicked: roomMembersSearchBar];
    }
}

- (void)inviteNewMember:(id)sender {
    // TODO GFO
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetails"]) {
        
        if ([[segue destinationViewController] isKindOfClass:[MemberViewController class]]) {
            if (selectedMember) {
                currentMemberViewController = (MemberViewController *)[segue destinationViewController];
                currentMemberViewController.mxRoomMember = selectedMember;
                currentMemberViewController.mxRoom = [[MatrixSDKHandler sharedHandler].mxSession roomWithRoomId:self.dataSource.roomId];
            }
        }
    }
}

#pragma mark - MXKDataSourceDelegate
- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes {
    [super dataSource:dataSource didCellChange:changes];
    
    [self refreshRoomMembersDisplay];
}

#pragma mark - MXKRoomMemberListViewControllerDelegate
- (void)roomMemberListViewController:(MXKRoomMemberListViewController *)roomMemberListViewController didSelectMember:(MXRoomMember *)member {
    
    // Report the selected member and open details view
    selectedMember = member;
    [self performSegueWithIdentifier:@"showDetails" sender:self];
}
#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (roomMembersSearchBar) {
        return (roomMembersSearchBar.frame.size.height);
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return roomMembersSearchBar;
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
    roomMembersSearchBar = nil;
    
    // Refresh display
    shouldScrollToTopOnRefresh = YES;
    [self.dataSource searchWithPatterns:nil];
}

@end
