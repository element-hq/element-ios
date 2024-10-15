/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Aram Sargsyan

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomsListViewController.h"
#import "RecentRoomTableViewCell.h"
#import "ShareDataSource.h"
#import "RecentCellData.h"
#import "ThemeService.h"

#import "GeneratedInterface-Swift.h"

@interface RoomsListViewController ()

// The fake search bar displayed at the top of the recents table. We switch on the actual search bar (self.recentsSearchBar)
// when the user selects it.
@property (nonatomic) UISearchBar *tableSearchBar;

@end

@implementation RoomsListViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([RoomsListViewController class])
                          bundle:[NSBundle bundleForClass:[RoomsListViewController class]]];
}

+ (instancetype)recentListViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([RoomsListViewController class])
                                          bundle:[NSBundle bundleForClass:[RoomsListViewController class]]];
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    self.enableBarButtonSearch = NO;
    
    // Create the fake search bar
    _tableSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 600, 44)];
    _tableSearchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _tableSearchBar.showsCancelButton = NO;
    _tableSearchBar.searchBarStyle = UISearchBarStyleMinimal;
    _tableSearchBar.placeholder = [VectorL10n searchDefaultPlaceholder];
    _tableSearchBar.delegate = self;
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.recentsTableView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    [self.recentsTableView registerNib:[RecentRoomTableViewCell nib] forCellReuseIdentifier:[RecentRoomTableViewCell defaultReuseIdentifier]];
    
    [self configureSearchBar];
}

- (void)destroy
{
    // Release the room data source
    [self.dataSource destroy];
    
    [super destroy];
}

#pragma mark - Views

- (void)configureSearchBar
{
    self.recentsSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    self.recentsSearchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.recentsSearchBar.placeholder = [VectorL10n searchDefaultPlaceholder];
    self.recentsSearchBar.tintColor = ThemeService.shared.theme.tintColor;
    self.recentsSearchBar.backgroundColor = ThemeService.shared.theme.baseColor;
    
    _tableSearchBar.tintColor = self.recentsSearchBar.tintColor;
}

#pragma mark - Override MXKRecentListViewController

- (void)refreshRecentsTable
{
    [super refreshRecentsTable];
    
    // Check conditions to display the fake search bar into the table header
    if (self.recentsSearchBar.isHidden && self.recentsTableView.tableHeaderView == nil)
    {
        // Add the search bar by showing it by default.
        self.recentsTableView.tableHeaderView = _tableSearchBar;
    }
}

- (void)hideSearchBar:(BOOL)hidden
{
    [super hideSearchBar:hidden];
    
    if (!hidden)
    {
        // Remove the fake table header view if any
        self.recentsTableView.tableHeaderView = nil;
        self.recentsTableView.contentInset = UIEdgeInsetsZero;
    }
}

- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    // Bypass inherited keyboard handling to fix layout when searching.
    // There are no sticky headers to worry about updating.
    return;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [RecentRoomTableViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *roomIdentifier = [self.dataSource cellDataAtIndexPath:indexPath].roomSummary.roomId;
    
    ShareDataSource *dataSource = (ShareDataSource *)self.dataSource;
    if ([dataSource.selectedRoomIdentifiers containsObject:roomIdentifier]) {
        [dataSource deselectRoomWithIdentifier:roomIdentifier animated:YES];
    } else {
        [dataSource selectRoomWithIdentifier:roomIdentifier animated:YES];
    }
    
    [self.recentsTableView reloadData];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:[RecentCellData class]])
    {
        return [RecentRoomTableViewCell class];
    }
    return nil;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:[MXKRecentCellData class]])
    {
        return [RecentRoomTableViewCell defaultReuseIdentifier];
    }
    return nil;
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSArray *patterns = nil;
    if (searchText.length)
    {
        patterns = @[searchText];
    }
    [self.dataSource searchWithPatterns:patterns];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    if (searchBar == _tableSearchBar)
    {
        [self hideSearchBar:NO];
        [self.recentsSearchBar becomeFirstResponder];
        return NO;
    }
    
    return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.recentsSearchBar setShowsCancelButton:YES animated:NO];
    });
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self.recentsSearchBar setShowsCancelButton:NO animated:NO];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    
    if (scrollView == self.recentsTableView)
    {
        if (!self.recentsSearchBar.isHidden)
        {
            if (!self.recentsSearchBar.text.length && (scrollView.contentOffset.y + scrollView.adjustedContentInset.top > self.recentsSearchBar.frame.size.height))
            {
                // Hide the search bar
                [self hideSearchBar:YES];
                
                // Refresh display
                [self refreshRecentsTable];
            }
            
            // Dismiss the keyboard when scrolling to match the behaviour of the main app.
            if (self.recentsSearchBar.isFirstResponder)
            {
                [self.recentsSearchBar resignFirstResponder];
            }
        }
    }
}

@end
