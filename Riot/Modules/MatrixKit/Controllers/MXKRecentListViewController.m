/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRecentListViewController.h"

#import "MXKRoomDataSourceManager.h"

#import "MXKInterleavedRecentsDataSource.h"
#import "MXKInterleavedRecentTableViewCell.h"

#import "MXKSwiftHeader.h"

@interface MXKRecentListViewController ()
{
    /**
     The data source providing UITableViewCells
     */
    MXKRecentsDataSource *dataSource;
    
    /**
     Search handling
     */
    UIBarButtonItem *searchButton;
    BOOL ignoreSearchRequest;
    
    /**
     The reconnection animated view.
     */
    __weak UIView* reconnectingView;
    
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

@implementation MXKRecentListViewController
@synthesize dataSource;

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKRecentListViewController class])
                          bundle:[NSBundle bundleForClass:[MXKRecentListViewController class]]];
}

+ (instancetype)recentListViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([MXKRecentListViewController class])
                                          bundle:[NSBundle bundleForClass:[MXKRecentListViewController class]]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    _recentsUpdateEnabled = YES;
    _enableBarButtonSearch = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Check whether the view controller has been pushed via storyboard
    if (!_recentsTableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"
    // Adjust search bar Top constraint to take into account potential navBar.
    if (_recentsSearchBarTopConstraint)
    {
        _recentsSearchBarTopConstraint.active = NO;
        _recentsSearchBarTopConstraint = [NSLayoutConstraint constraintWithItem:self.topLayoutGuide
                                                                      attribute:NSLayoutAttributeBottom
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.recentsSearchBar
                                                                      attribute:NSLayoutAttributeTop
                                                                     multiplier:1.0f
                                                                       constant:0.0f];

        _recentsSearchBarTopConstraint.active = YES;
    }
    
    // Adjust table view Bottom constraint to take into account tabBar.
    if (_recentsTableViewBottomConstraint)
    {
        _recentsTableViewBottomConstraint.active = NO;
        _recentsTableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomLayoutGuide
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.recentsTableView
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:1.0f
                                                                          constant:0.0f];

        _recentsTableViewBottomConstraint.active = YES;
    }
    #pragma clang diagnostic pop
    
    // Hide search bar by default
    [self hideSearchBar:YES];
    
    // Apply search option in navigation bar
    self.enableBarButtonSearch = _enableBarButtonSearch;
    
    // Add an accessory view to the search bar in order to retrieve keyboard view.
    self.recentsSearchBar.inputAccessoryView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Finalize table view configuration
    self.recentsTableView.delegate = self;
    self.recentsTableView.dataSource = dataSource; // Note: dataSource may be nil here
    
    // Set up classes to use for cells
    [self.recentsTableView registerNib:MXKRecentTableViewCell.nib forCellReuseIdentifier:MXKRecentTableViewCell.defaultReuseIdentifier];
    // Consider here the specific case where interleaved recents are supported
    [self.recentsTableView registerNib:MXKInterleavedRecentTableViewCell.nib forCellReuseIdentifier:MXKInterleavedRecentTableViewCell.defaultReuseIdentifier];
    
    // Add a top view which will be displayed in case of vertical bounce.
    CGFloat height = self.recentsTableView.frame.size.height;
    UIView *topview = [[UIView alloc] initWithFrame:CGRectMake(0,-height,self.recentsTableView.frame.size.width,height)];
    topview.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    topview.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self.recentsTableView addSubview:topview];
    self->topview = topview;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Restore search mechanism (if enabled)
    ignoreSearchRequest = NO;

    // Observe server sync at room data source level too
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatrixSessionChange) name:kMXKRoomDataSourceSyncStatusChanged object:nil];
    
    // Observe the server sync
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSyncNotification) name:kMXSessionDidSyncNotification object:nil];
    
    self.recentsUpdateEnabled = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // The user may still press search button whereas the view disappears
    ignoreSearchRequest = YES;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKRoomDataSourceSyncStatusChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidSyncNotification object:nil];
    
    [self removeReconnectingView];
}

- (void)dealloc
{
    self.recentsSearchBar.inputAccessoryView = nil;
    
    searchButton = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

#pragma mark - Override MXKViewController

- (void)onMatrixSessionChange
{
    [super onMatrixSessionChange];
    
    // Check whether no server sync is in progress in room data sources
    NSArray *mxSessions = self.mxSessions;
    for (MXSession *mxSession in mxSessions)
    {
        if ([MXKRoomDataSourceManager sharedManagerForMatrixSession:mxSession].isServerSyncInProgress)
        {
            // sync is in progress for at least one data source, keep running the loading wheel
            [self startActivityIndicator];
            break;
        }
    }
}

- (void)onKeyboardShowAnimationComplete
{
    // Report the keyboard view in order to track keyboard frame changes
    self.keyboardView = _recentsSearchBar.inputAccessoryView.superview;
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
    _recentsTableViewBottomConstraint.constant = tableViewBottomConst;
    
    // Force layout immediately to take into account new constraint
    [self.view layoutIfNeeded];
}
#pragma clang diagnostic pop

- (void)destroy
{
    self.recentsTableView.dataSource = nil;
    self.recentsTableView.delegate = nil;
    self.recentsTableView = nil;
    
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

- (void)displayList:(MXKRecentsDataSource *)listDataSource
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
    
    // Report all matrix sessions at view controller level to update UI according to sessions state
    NSArray *mxSessions = listDataSource.mxSessions;
    for (MXSession *mxSession in mxSessions)
    {
        [self addMatrixSession:mxSession];
    }
    
    if (self.recentsTableView)
    {
        // Set up table data source
        self.recentsTableView.dataSource = dataSource;
    }
}

- (void)refreshRecentsTable
{
    if (!self.recentsUpdateEnabled) return;
    
    isRefreshNeeded = NO;
    
    // For now, do a simple full reload
    [self.recentsTableView reloadData];
}

- (void)hideSearchBar:(BOOL)hidden
{
    self.recentsSearchBar.hidden = hidden;
    self.recentsSearchBarHeightConstraint.constant = hidden ? 0 : 44;
    [self.view setNeedsUpdateConstraints];
}

- (void)setRecentsUpdateEnabled:(BOOL)activeUpdate
{
    _recentsUpdateEnabled = activeUpdate;
    
    if (_recentsUpdateEnabled && isRefreshNeeded)
    {
        [self refreshRecentsTable];
    }
}

#pragma mark - Action

- (IBAction)search:(id)sender
{
    // The user may have pressed search button whereas the view controller was disappearing
    if (ignoreSearchRequest)
    {
        return;
    }
    
    if (self.recentsSearchBar.isHidden)
    {
        // Check whether there are data in which search
        if ([self.dataSource numberOfSectionsInTableView:self.recentsTableView])
        {
            [self hideSearchBar:NO];
            
            // Create search bar
            [self.recentsSearchBar becomeFirstResponder];
        }
    }
    else
    {
        [self searchBarCancelButtonClicked: self.recentsSearchBar];
    }
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    // Consider here the specific case where interleaved recents are supported
    if ([dataSource isKindOfClass:MXKInterleavedRecentsDataSource.class])
    {
        return MXKInterleavedRecentTableViewCell.class;
    }
    
    // Return the default recent table view cell
    return MXKRecentTableViewCell.class;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    // Consider here the specific case where interleaved recents are supported
    if ([dataSource isKindOfClass:MXKInterleavedRecentsDataSource.class])
    {
        return MXKInterleavedRecentTableViewCell.defaultReuseIdentifier;
    }
    
    // Return the default recent table view cell
    return MXKRecentTableViewCell.defaultReuseIdentifier;
}

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    if (!_recentsUpdateEnabled)
    {
        isRefreshNeeded = YES;
        return;
    }
    
    // For now, do a simple full reload
    [self refreshRecentsTable];
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
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [dataSource cellHeightAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // Section header is required only when several recent lists are displayed.
    if (self.dataSource.displayedRecentsDataSourcesCount > 1)
    {
        return 35;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // Let dataSource provide the section header.
    return [dataSource viewForHeaderInSection:section
                                    withFrame:[tableView rectForHeaderInSection:section]
                                  inTableView:tableView];
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
                if ([cellData conformsToProtocol:@protocol(MXKRecentCellDataStoring)])
                {
                    id<MXKRecentCellDataStoring> recentCellData = (id<MXKRecentCellDataStoring>)cellData;
                    if (recentCellData.isSuggestedRoom)
                    {
                        [_delegate recentListViewController:self
                                     didSelectSuggestedRoom:recentCellData.roomSummary.spaceChildInfo
                                                       from:selectedCell];
                    }
                    else
                    {
                        [_delegate recentListViewController:self
                                              didSelectRoom:recentCellData.roomIdentifier
                                            inMatrixSession:recentCellData.mxSession];
                    }
                }
            }
        }
    }
    
    // Hide the keyboard when user select a room
    // do not hide the searchBar until the view controller disappear
    // on tablets / iphone 6+, the user could expect to search again while looking at a room
    [self.recentsSearchBar resignFirstResponder];
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
    if (scrollView == _recentsTableView)
    {
        [self detectPullToKick:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == _recentsTableView)
    {
        [self managePullToKick:scrollView];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == _recentsTableView)
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
    
    self.recentsSearchBar.text = nil;
    
    // Refresh display
    [self.dataSource searchWithPatterns:nil];
}

#pragma mark - resync management

- (void)onSyncNotification
{
    latestServerSync = [NSDate date];
    [self removeReconnectingView];
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
        spinner.backgroundColor = _recentsTableView.backgroundColor;
        [spinner startAnimating];
        
        // no need to manage constraints here, IOS defines them.
        tableViewHeaderView = _recentsTableView.tableHeaderView;
        _recentsTableView.tableHeaderView = reconnectingView = spinner;
    }
}

- (void)removeReconnectingView
{
    if (reconnectingView && !restartConnection)
    {
        _recentsTableView.tableHeaderView = tableViewHeaderView;
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
