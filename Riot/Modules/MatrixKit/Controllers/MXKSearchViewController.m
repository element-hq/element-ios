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

#import "MXKSearchViewController.h"

#import "MXKSearchTableViewCell.h"

#import "NSBundle+MatrixKit.h"

#import "MXKSwiftHeader.h"

@interface MXKSearchViewController ()
{
    /**
     Optional bar buttons
     */
    UIBarButtonItem *searchBarButton;

    /**
     Search handling
     */
    BOOL ignoreSearchRequest;
}
@end

@implementation MXKSearchViewController
@synthesize dataSource, shouldScrollToBottomOnRefresh;

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKSearchViewController class])
                          bundle:[NSBundle bundleForClass:[MXKSearchViewController class]]];
}

+ (instancetype)searchViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([MXKSearchViewController class])
                                          bundle:[NSBundle bundleForClass:[MXKSearchViewController class]]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    _enableBarButtonSearch = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Check whether the view controller has been pushed via storyboard
    if (!_searchTableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }

    // Adjust Top and Bottom constraints to take into account potential navBar and tabBar.
    [NSLayoutConstraint deactivateConstraints:@[_searchSearchBarTopConstraint, _searchTableViewBottomConstraint]];

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"
    _searchSearchBarTopConstraint = [NSLayoutConstraint constraintWithItem:self.topLayoutGuide
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.searchSearchBar
                                                                  attribute:NSLayoutAttributeTop
                                                                 multiplier:1.0f
                                                                   constant:0.0f];

    _searchTableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.searchTableView
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0f
                                                                      constant:0.0f];
    #pragma clang diagnostic pop

    [NSLayoutConstraint activateConstraints:@[_searchSearchBarTopConstraint, _searchTableViewBottomConstraint]];

    // Hide search bar by default
    self.searchSearchBar.hidden = YES;
    self.searchSearchBarHeightConstraint.constant = 0;
    [self.view setNeedsUpdateConstraints];

    self.noResultsLabel.text = [VectorL10n searchNoResults];
    self.noResultsLabel.hidden = YES;

    searchBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearchBar:)];

    // Apply search option in navigation bar
    self.enableBarButtonSearch = _enableBarButtonSearch;

    // Finalize table view configuration
    _searchTableView.delegate = self;
    _searchTableView.dataSource = dataSource; // Note: dataSource may be nil here

    // Set up classes to use for cells
    [self.searchTableView registerNib:MXKSearchTableViewCell.nib forCellReuseIdentifier:MXKSearchTableViewCell.defaultReuseIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Restore search mechanism (if enabled)
    ignoreSearchRequest = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // The user may still press search button whereas the view disappears
    ignoreSearchRequest = YES;
}


#pragma mark - Override MXKViewController

- (void)onKeyboardShowAnimationComplete
{
    // Report the keyboard view in order to track keyboard frame changes
    self.keyboardView = _searchSearchBar.inputAccessoryView.superview;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    // Deduce the bottom constraint for the table view (Don't forget the potential tabBar)
    CGFloat tableViewBottomConst = keyboardHeight - self.bottomLayoutGuide.length;
    // Check whether the keyboard is over the tabBar
    if (tableViewBottomConst < 0)
    {
        tableViewBottomConst = 0;
    }

    // Update constraints
    _searchTableViewBottomConstraint.constant = tableViewBottomConst;

    // Force layout immediately to take into account new constraint
    [self.view layoutIfNeeded];
}
#pragma clang diagnostic pop

- (void)destroy
{
    _searchTableView.dataSource = nil;
    _searchTableView.delegate = nil;
    _searchTableView = nil;

    dataSource.delegate = nil;
    [dataSource destroy];
    dataSource = nil;
    
    [super destroy];
}

#pragma mark -

- (void)displaySearch:(MXKSearchDataSource*)searchDataSource
{
    // Cancel registration on existing dataSource if any
    if (dataSource)
    {
        dataSource.delegate = nil;
        
        // Remove associated matrix sessions
        [self removeMatrixSession:dataSource.mxSession];
        
        [dataSource destroy];
    }

    dataSource = searchDataSource;
    dataSource.delegate = self;
    
    // Report the related matrix sessions at view controller level to update UI according to sessions state
    [self addMatrixSession:searchDataSource.mxSession];

    if (_searchTableView)
    {
        // Set up table data source
        _searchTableView.dataSource = dataSource;
    }
}


#pragma mark - UIBarButton handling

- (void)setEnableBarButtonSearch:(BOOL)enableBarButtonSearch
{
    _enableBarButtonSearch = enableBarButtonSearch;
    [self refreshUIBarButtons];
}

- (void)refreshUIBarButtons
{
    if (_enableBarButtonSearch)
    {
        self.navigationItem.rightBarButtonItems = @[searchBarButton];
    }
    else
    {
        self.navigationItem.rightBarButtonItems = nil;
    }
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    return MXKSearchTableViewCell.class;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    return MXKSearchTableViewCell.defaultReuseIdentifier;
}

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    __block CGPoint tableViewOffset;
    
    if (!shouldScrollToBottomOnRefresh)
    {
        // Store current tableview scrolling point to restore it after [UITableView reloadData]
        // This avoids unexpected scrolling for the user
        tableViewOffset = _searchTableView.contentOffset;
    }

    [_searchTableView reloadData];

    if (shouldScrollToBottomOnRefresh)
    {
        [self scrollToBottomAnimated:NO];
        shouldScrollToBottomOnRefresh = NO;
    }
    else
    {
        // Restore the user scrolling point by computing the offset introduced by new cells
        // New cells are always introduced at the top of the table
        NSIndexSet *insertedIndexes = (NSIndexSet*)changes;

        // Get each new cell height
        [insertedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {

            MXKCellData* cellData = [self.dataSource cellDataAtIndex:idx];
            Class<MXKCellRendering> class = [self cellViewClassForCellData:cellData];

            tableViewOffset.y += [class heightForCellData:cellData withMaximumWidth:self->_searchTableView.frame.size.width];

        }];

        [_searchTableView setContentOffset:tableViewOffset animated:NO];
    }

    self.title = [NSString stringWithFormat:@"%@ (%tu)", self.dataSource.searchText, self.dataSource.serverCount];
}

- (void)dataSource:(MXKDataSource*)dataSource2 didStateChange:(MXKDataSourceState)state
{
    // MXKSearchDataSource comes back to the `MXKDataSourceStatePreparing` when searching
    if (state == MXKDataSourceStatePreparing)
    {
        _noResultsLabel.hidden = YES;
        [self startActivityIndicator];
    }
    else
    {
        [self stopActivityIndicator];

        // Display "No Results" if a search is active with an empty result
        if (dataSource.searchText.length && ![dataSource tableView:_searchTableView numberOfRowsInSection:0])
        {
            _noResultsLabel.hidden = NO;
            _searchTableView.hidden = YES;
        }
        else
        {
            _noResultsLabel.hidden = YES;
            _searchTableView.hidden = NO;
        }
    }
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MXKCellData *cellData = [dataSource cellDataAtIndex:indexPath.row];

    Class<MXKCellRendering> class = [self cellViewClassForCellData:cellData];
    return [class heightForCellData:cellData withMaximumWidth:tableView.frame.size.width];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Must be implemented at app level
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    // Release here resources, and restore reusable cells
    if ([cell respondsToSelector:@selector(didEndDisplay)])
    {
        [(id<MXKCellRendering>)cell didEndDisplay];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    // Detect vertical bounce at the top of the tableview to trigger pagination
    if (scrollView == _searchTableView)
    {
        // paginate ?
        if (scrollView.contentOffset.y < -64)
        {
            [self triggerBackPagination];
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // "Done" key has been pressed
    [searchBar resignFirstResponder];

    // Apply filter
    if (searchBar.text.length)
    {
        shouldScrollToBottomOnRefresh = YES;
        [dataSource searchMessages:searchBar.text force:NO];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // Leave search
    [searchBar resignFirstResponder];

    self.searchSearchBar.hidden = YES;
    self.searchSearchBarHeightConstraint.constant = 0;
    [self.view setNeedsUpdateConstraints];

    self.searchSearchBar.text = nil;
}

#pragma mark - Actions

- (void)showSearchBar:(id)sender
{
    // The user may have pressed search button whereas the view controller was disappearing
    if (ignoreSearchRequest)
    {
        return;
    }

    if (self.searchSearchBar.isHidden)
    {
        self.searchSearchBar.hidden = NO;
        self.searchSearchBarHeightConstraint.constant = 44;
        [self.view setNeedsUpdateConstraints];

        [self.searchSearchBar becomeFirstResponder];
    }
    else
    {
        [self searchBarCancelButtonClicked: self.searchSearchBar];
    }
}

#pragma mark - Private methods

- (void)triggerBackPagination
{
    // Paginate only if possible
    if (NO == dataSource.canPaginate)
    {
        return;
    }

    [dataSource paginateBack];
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    if (_searchTableView.contentSize.height)
    {
        CGFloat visibleHeight = _searchTableView.frame.size.height - _searchTableView.adjustedContentInset.top - _searchTableView.adjustedContentInset.bottom;
        if (visibleHeight < _searchTableView.contentSize.height)
        {
            CGFloat wantedOffsetY = _searchTableView.contentSize.height - visibleHeight - _searchTableView.adjustedContentInset.top;
            CGFloat currentOffsetY = _searchTableView.contentOffset.y;
            if (wantedOffsetY != currentOffsetY)
            {
                [_searchTableView setContentOffset:CGPointMake(0, wantedOffsetY) animated:animated];
            }
        }
        else
        {
            _searchTableView.contentOffset = CGPointMake(0, - _searchTableView.adjustedContentInset.top);
        }
    }
}

@end
