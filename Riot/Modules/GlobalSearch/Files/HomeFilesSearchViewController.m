/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "HomeFilesSearchViewController.h"

#import "GeneratedInterface-Swift.h"

#import "HomeViewController.h"

#import "FilesSearchCellData.h"
#import "FilesSearchTableViewCell.h"

#import "EventFormatter.h"

@interface HomeFilesSearchViewController()
{
    /**
     Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
     */
    id kThemeServiceDidChangeThemeNotificationObserver;
}

@end

@implementation HomeFilesSearchViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Register cell class used to display the files search result
    [self.searchTableView registerClass:FilesSearchTableViewCell.class forCellReuseIdentifier:FilesSearchTableViewCell.defaultReuseIdentifier];

    self.searchTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    // Hide line separators of empty cells
    self.searchTableView.tableFooterView = [[UIView alloc] init];
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    // Check the table view style to select its bg color.
    self.searchTableView.backgroundColor = ((self.searchTableView.style == UITableViewStylePlain) ? ThemeService.shared.theme.backgroundColor : ThemeService.shared.theme.headerBackgroundColor);
    self.view.backgroundColor = self.searchTableView.backgroundColor;
    self.searchTableView.separatorColor = ThemeService.shared.theme.lineBreakColor;
    
    self.noResultsLabel.textColor = ThemeService.shared.theme.backgroundColor;
    
    if (self.searchTableView.dataSource)
    {
        [self.searchTableView reloadData];
    }

    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)destroy
{
    [super destroy];
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSearchResult:) name:kMXSessionDidLeaveRoomNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSearchResult:) name:kMXSessionNewRoomNotification object:nil];
    
    [self.screenTracker trackScreen];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionDidLeaveRoomNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionNewRoomNotification object:nil];
}

#pragma mark -

- (void)refreshSearchResult:(NSNotification *)notif
{
    // Update here the search results when a room is joined or left in one of the observed sessions
    if (notif.object && [self.mxSessions indexOfObject:notif.object] != NSNotFound)
    {
        if (self.dataSource.searchText.length)
        {
            self.shouldScrollToBottomOnRefresh = YES;
            [self.dataSource searchMessages:self.dataSource.searchText force:YES];
        }
    }
}

- (void)showRoomWithId:(NSString*)roomId
              andEvent:(MXEvent*)event
       inMatrixSession:(MXSession*)session
{
    ThreadParameters *threadParameters = nil;
    if (RiotSettings.shared.enableThreads)
    {
        if (event.threadId)
        {
            threadParameters = [[ThreadParameters alloc] initWithThreadId:event.threadId
                                                          stackRoomScreen:NO];
        }
    }

    ScreenPresentationParameters *presentationParameters = [[ScreenPresentationParameters alloc] initWithRestoreInitialDisplay:NO stackAboveVisibleViews:NO];
    
    RoomNavigationParameters *parameters = [[RoomNavigationParameters alloc] initWithRoomId:roomId
                                                                                    eventId:event.eventId
                                                                                  mxSession:session
                                                                           threadParameters:threadParameters
                                                                     presentationParameters:presentationParameters];
    Analytics.shared.viewRoomTrigger = AnalyticsViewRoomTriggerFileSearch;
    [[AppDelegate theDelegate] showRoomWithParameters:parameters];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    return FilesSearchTableViewCell.class;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    return FilesSearchTableViewCell.defaultReuseIdentifier;
}

#pragma mark - Override UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    // Update the selected background view
    if (ThemeService.shared.theme.selectedBackgroundColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = ThemeService.shared.theme.selectedBackgroundColor;
    }
    else
    {
        if (tableView.style == UITableViewStylePlain)
        {
            cell.selectedBackgroundView = nil;
        }
        else
        {
            cell.selectedBackgroundView.backgroundColor = nil;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Data in the cells are actually Vector RoomBubbleCellData
    FilesSearchCellData *cellData = (FilesSearchCellData*)[self.dataSource cellDataAtIndex:indexPath.row];
    _selectedEvent = cellData.searchResult.result;

    // Hide the keyboard handled by the search text input which belongs to HomeViewController
    [((HomeViewController*)self.parentViewController).searchBar resignFirstResponder];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Make the master tabBar view controller open the RoomViewController
    [self showRoomWithId:cellData.roomId
                andEvent:_selectedEvent
         inMatrixSession:self.mainSession];

    // Reset the selected event. HomeViewController got it when here
    _selectedEvent = nil;
}

@end
