/*
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

#import "MXKGroupListViewController.h"

#import "MXKGroupTableViewCell.h"
#import "MXKTableViewHeaderFooterWithLabel.h"

@interface MXKGroupListViewController ()
{
    /**
     The data source providing UITableViewCells
     */
    MXKSessionGroupsDataSource *dataSource;
    
    /**
     Search handling
     */
    UIBarButtonItem *searchButton;
    BOOL ignoreSearchRequest;
    
    /**
     The reconnection animated view.
     */
    UIView* reconnectingView;
    
    /**
     The current table view header if any.
     */
    UIView* tableViewHeaderView;
    
    /**
     The latest server sync date
     */
    NSDate* latestServerSync;
    
    /**
     The restart the event connnection
     */
    BOOL restartConnection;
}

@end

@implementation MXKGroupListViewController
@synthesize dataSource;

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKGroupListViewController class])
                          bundle:[NSBundle bundleForClass:[MXKGroupListViewController class]]];
}

+ (instancetype)groupListViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([MXKGroupListViewController class])
                                          bundle:[NSBundle bundleForClass:[MXKGroupListViewController class]]];
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
    if (!_groupsTableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    // Adjust search bar Top constraint to take into account potential navBar.
    if (_groupsSearchBarTopConstraint)
    {
        [NSLayoutConstraint deactivateConstraints:@[_groupsSearchBarTopConstraint]];
        
        _groupsSearchBarTopConstraint = [NSLayoutConstraint constraintWithItem:self.topLayoutGuide
                                                                      attribute:NSLayoutAttributeBottom
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.groupsSearchBar
                                                                      attribute:NSLayoutAttributeTop
                                                                     multiplier:1.0f
                                                                       constant:0.0f];
        
        [NSLayoutConstraint activateConstraints:@[_groupsSearchBarTopConstraint]];
    }
    
    // Adjust table view Bottom constraint to take into account tabBar.
    if (_groupsTableViewBottomConstraint)
    {
        [NSLayoutConstraint deactivateConstraints:@[_groupsTableViewBottomConstraint]];
        
        _groupsTableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.groupsTableView
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:1.0f
                                                                          constant:0.0f];
        
        [NSLayoutConstraint activateConstraints:@[_groupsTableViewBottomConstraint]];
    }
    
    // Hide search bar by default
    [self hideSearchBar:YES];
    
    // Apply search option in navigation bar
    self.enableBarButtonSearch = _enableBarButtonSearch;
    
    // Add an accessory view to the search bar in order to retrieve keyboard view.
    self.groupsSearchBar.inputAccessoryView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Finalize table view configuration
    // Note: self-sizing cells and self-sizing section headers are enabled from the nib file.
    self.groupsTableView.delegate = self;
    self.groupsTableView.dataSource = dataSource; // Note: dataSource may be nil here
    self.groupsTableView.estimatedSectionHeaderHeight = 30; // The value set in the nib seems not available for iOS version < 10.
    
    // Set up classes to use for the cells and the section headers.
    [self.groupsTableView registerNib:MXKGroupTableViewCell.nib forCellReuseIdentifier:MXKGroupTableViewCell.defaultReuseIdentifier];
    [self.groupsTableView registerNib:MXKTableViewHeaderFooterWithLabel.nib forHeaderFooterViewReuseIdentifier:MXKTableViewHeaderFooterWithLabel.defaultReuseIdentifier];
    
    // Add a top view which will be displayed in case of vertical bounce.
    CGFloat height = self.groupsTableView.frame.size.height;
    UIView *topview = [[UIView alloc] initWithFrame:CGRectMake(0,-height,self.groupsTableView.frame.size.width,height)];
    topview.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    topview.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self.groupsTableView addSubview:topview];
    self->topview = topview;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Restore search mechanism (if enabled)
    ignoreSearchRequest = NO;

    // Observe the server sync
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSyncNotification) name:kMXSessionDidSyncNotification object:nil];
    
    // Do a full reload
    [self refreshGroupsTable];
    
    // Refresh all groups summary
    [self.dataSource refreshGroupsSummary:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // The user may still press search button whereas the view disappears
    ignoreSearchRequest = YES;

    // Leave potential search session
    if (!self.groupsSearchBar.isHidden)
    {
        [self searchBarCancelButtonClicked:self.groupsSearchBar];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidSyncNotification object:nil];
    
    [self removeReconnectingView];
}

- (void)dealloc
{
    self.groupsSearchBar.inputAccessoryView = nil;
    
    searchButton = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

#pragma mark - Override MXKViewController

- (void)onKeyboardShowAnimationComplete
{
    // Report the keyboard view in order to track keyboard frame changes
    self.keyboardView = _groupsSearchBar.inputAccessoryView.superview;
}

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
    _groupsTableViewBottomConstraint.constant = tableViewBottomConst;
    
    // Force layout immediately to take into account new constraint
    [self.view layoutIfNeeded];
}

- (void)destroy
{
    self.groupsTableView.dataSource = nil;
    self.groupsTableView.delegate = nil;
    self.groupsTableView = nil;
    
    dataSource.delegate = nil;
    dataSource = nil;
    
    _delegate = nil;
    
    [topview removeFromSuperview];
    topview = nil;
    
    [super destroy];
}

#pragma mark -

- (void)setEnableBarButtonSearch:(BOOL)enableBarButtonSearch
{
    _enableBarButtonSearch = enableBarButtonSearch;
    
    if (enableBarButtonSearch)
    {
        if (!searchButton)
        {
            searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(search:)];
        }
        
        // Add it in right bar items
        NSArray *rightBarButtonItems = self.navigationItem.rightBarButtonItems;
        self.navigationItem.rightBarButtonItems = rightBarButtonItems ? [rightBarButtonItems arrayByAddingObject:searchButton] : @[searchButton];
    }
    else
    {
        NSMutableArray *rightBarButtonItems = [NSMutableArray arrayWithArray: self.navigationItem.rightBarButtonItems];
        [rightBarButtonItems removeObject:searchButton];
        self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    }
}

- (void)displayList:(MXKSessionGroupsDataSource *)listDataSource
{
    // Cancel registration on existing dataSource if any
    if (dataSource)
    {
        dataSource.delegate = nil;
        
        // Remove associated matrix sessions
        NSArray *mxSessions = self.mxSessions;
        for (MXSession *mxSession in mxSessions)
        {
            [self removeMatrixSession:mxSession];
        }
    }
    
    dataSource = listDataSource;
    dataSource.delegate = self;
    
    // Report the matrix session at view controller level to update UI according to session state
    [self addMatrixSession:listDataSource.mxSession];
    
    if (self.groupsTableView)
    {
        // Set up table data source
        self.groupsTableView.dataSource = dataSource;
    }
}

- (void)refreshGroupsTable
{
    // For now, do a simple full reload
    [self.groupsTableView reloadData];
}

- (void)hideSearchBar:(BOOL)hidden
{
    self.groupsSearchBar.hidden = hidden;
    self.groupsSearchBarHeightConstraint.constant = hidden ? 0 : 44;
    [self.view setNeedsUpdateConstraints];
}

#pragma mark - Action

- (IBAction)search:(id)sender
{
    // The user may have pressed search button whereas the view controller was disappearing
    if (ignoreSearchRequest)
    {
        return;
    }
    
    if (self.groupsSearchBar.isHidden)
    {
        // Check whether there are data in which search
        if ([self.dataSource numberOfSectionsInTableView:self.groupsTableView])
        {
            [self hideSearchBar:NO];
            
            // Create search bar
            [self.groupsSearchBar becomeFirstResponder];
        }
    }
    else
    {
        [self searchBarCancelButtonClicked: self.groupsSearchBar];
    }
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    // Return the default group table view cell
    return MXKGroupTableViewCell.class;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    // Return the default group table view cell
    return MXKGroupTableViewCell.defaultReuseIdentifier;
}

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    // For now, do a simple full reload
    [self refreshGroupsTable];
}

- (void)dataSource:(MXKDataSource *)dataSource didAddMatrixSession:(MXSession *)mxSession
{
    [self addMatrixSession:mxSession];
}

- (void)dataSource:(MXKDataSource *)dataSource didRemoveMatrixSession:(MXSession *)mxSession
{
    [self removeMatrixSession:mxSession];
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView.estimatedRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    if (tableView.numberOfSections > 1)
    {
        return tableView.estimatedSectionHeaderHeight;
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Refresh here the estimated row height
    tableView.estimatedRowHeight = cell.frame.size.height;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(nonnull UIView *)view forSection:(NSInteger)section
{
    // Refresh here the estimated header height
    tableView.estimatedSectionHeaderHeight = view.frame.size.height;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    MXKTableViewHeaderFooterWithLabel *sectionHeader;
    
    if (tableView.numberOfSections > 1)
    {
        sectionHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:MXKTableViewHeaderFooterWithLabel.defaultReuseIdentifier];
        
        sectionHeader.mxkLabel.text = [self.dataSource tableView:tableView titleForHeaderInSection:section];
    }
    
    return sectionHeader;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_delegate)
    {
        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        
        if ([selectedCell conformsToProtocol:@protocol(MXKCellRendering)])
        {
            id<MXKCellRendering> cell = (id<MXKCellRendering>)selectedCell;
            
            if ([cell respondsToSelector:@selector(renderedCellData)])
            {
                MXKCellData *cellData = cell.renderedCellData;
                if ([cellData conformsToProtocol:@protocol(MXKGroupCellDataStoring)])
                {
                    id<MXKGroupCellDataStoring> groupCellData = (id<MXKGroupCellDataStoring>)cellData;
                    [_delegate groupListViewController:self didSelectGroup:groupCellData.group inMatrixSession:self.mainSession];
                }
            }
        }
    }
    
    // Hide the keyboard when user select a room
    // do not hide the searchBar until the view controller disappear
    // on tablets / iphone 6+, the user could expect to search again while looking at a room
    [self.groupsSearchBar resignFirstResponder];
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
    // Detect vertical bounce at the top of the tableview to trigger reconnection.
    if (scrollView == _groupsTableView)
    {
        [self detectPullToKick:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == _groupsTableView)
    {
        [self managePullToKick:scrollView];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == _groupsTableView)
    {
        if (scrollView.contentOffset.y + scrollView.adjustedContentInset.top == 0)
        {
            [self managePullToKick:scrollView];
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Apply filter
    if (searchText.length)
    {
        [self.dataSource searchWithPatterns:@[searchText]];
    }
    else
    {
        [self.dataSource searchWithPatterns:nil];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // "Done" key has been pressed
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // Leave search
    [searchBar resignFirstResponder];
    
    [self hideSearchBar:YES];
    
    self.groupsSearchBar.text = nil;
    
    // Refresh display
    [self.dataSource searchWithPatterns:nil];
}

#pragma mark - resync management

- (void)onSyncNotification
{
    latestServerSync = [NSDate date];
    
    MXWeakify(self);
    
    // Refresh all groups summary
    [self.dataSource refreshGroupsSummary:^{
        
        MXStrongifyAndReturnIfNil(self);
        
        [self removeReconnectingView];
    }];
}

- (BOOL)canReconnect
{
    // avoid restarting connection if some data has been received within 1 second (1000 : latestServerSync is null)
    NSTimeInterval interval = latestServerSync ? [[NSDate date] timeIntervalSinceDate:latestServerSync] : 1000;
    return  (interval > 1) && [self.mainSession reconnect];
}

- (void)addReconnectingView
{
    if (!reconnectingView)
    {
        UIActivityIndicatorView* spinner  = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinner.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
        CGRect frame = spinner.frame;
        frame.size.height = 80; // 80 * 0.75 = 60
        spinner.bounds = frame;
        spinner.color = [UIColor darkGrayColor];
        spinner.hidesWhenStopped = NO;
        spinner.backgroundColor = _groupsTableView.backgroundColor;
        [spinner startAnimating];
        
        // no need to manage constraints here, IOS defines them.
        tableViewHeaderView = _groupsTableView.tableHeaderView;
        _groupsTableView.tableHeaderView = reconnectingView = spinner;
    }
}

- (void)removeReconnectingView
{
    if (reconnectingView && !restartConnection)
    {
        _groupsTableView.tableHeaderView = tableViewHeaderView;
        reconnectingView = nil;
    }
}

/**
 Detect if the current connection must be restarted.
 The spinner is displayed until the overscroll ends (and scrollViewDidEndDecelerating is called).
 */
- (void)detectPullToKick:(UIScrollView *)scrollView
{
    if (!reconnectingView)
    {
        // detect if the user scrolls over the tableview top
        restartConnection = (scrollView.contentOffset.y + scrollView.adjustedContentInset.top < -128);
        
        if (restartConnection)
        {
            // wait that list decelerate to display / hide it
            [self addReconnectingView];
        }
    }
}

/**
 Restarts the current connection if it is required.
 The 0.3s delay is added to avoid flickering if the connection does not require to be restarted.
 */
- (void)managePullToKick:(UIScrollView *)scrollView
{
    // the current connection must be restarted
    if (restartConnection)
    {
        // display at least 0.3s the spinner to show to the user that something is pending
        // else the UI is flickering
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self->restartConnection = NO;
            
            if (![self canReconnect])
            {
                // if the event stream has not been restarted
                // hide the spinner
                [self removeReconnectingView];
            }
            // else wait that onSyncNotification is called.
        });
    }
}

@end
