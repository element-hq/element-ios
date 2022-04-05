/*
 Copyright 2016 OpenMarket Ltd
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

#import "HomeMessagesSearchViewController.h"

#import "GeneratedInterface-Swift.h"

#import "HomeViewController.h"

// Use RoomViewController cells to display results
#import "RoomBubbleCellData.h"
#import "MessagesSearchResultAttachmentBubbleCell.h"
#import "MessagesSearchResultTextMsgBubbleCell.h"
#import "RoomIncomingAttachmentBubbleCell.h"
#import "RoomIncomingTextMsgBubbleCell.h"

#import "EventFormatter.h"

@interface HomeMessagesSearchViewController ()
{
    /**
     Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
     */
    id kThemeServiceDidChangeThemeNotificationObserver;
}

@end

@implementation HomeMessagesSearchViewController

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
    
    // Reuse cells from the RoomViewController to display results
    [self.searchTableView registerClass:MessagesSearchResultTextMsgBubbleCell.class forCellReuseIdentifier:MessagesSearchResultTextMsgBubbleCell.defaultReuseIdentifier];
    [self.searchTableView registerClass:MessagesSearchResultAttachmentBubbleCell.class forCellReuseIdentifier:MessagesSearchResultAttachmentBubbleCell.defaultReuseIdentifier];
    [self.searchTableView registerClass:RoomIncomingTextMsgBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgBubbleCell.defaultReuseIdentifier];
    [self.searchTableView registerClass:RoomIncomingAttachmentBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentBubbleCell.defaultReuseIdentifier];

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

    ScreenPresentationParameters *screenParameters = [[ScreenPresentationParameters alloc] initWithRestoreInitialDisplay:NO stackAboveVisibleViews:NO];

    RoomNavigationParameters *parameters = [[RoomNavigationParameters alloc] initWithRoomId:roomId
                                                                                    eventId:event.eventId
                                                                                  mxSession:self.mainSession
                                                                           threadParameters:threadParameters
                                                                     presentationParameters:screenParameters];
    Analytics.shared.viewRoomTrigger = AnalyticsViewRoomTriggerMessageSearch;
    [[LegacyAppDelegate theDelegate] showRoomWithParameters:parameters];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    Class cellViewClass = nil;
    
    // Sanity check
    if ([cellData conformsToProtocol:@protocol(MXKRoomBubbleCellDataStoring)])
    {
        id<MXKRoomBubbleCellDataStoring> bubbleData = (id<MXKRoomBubbleCellDataStoring>)cellData;
        
        // Select the suitable table view cell class
        if (bubbleData.isAttachmentWithThumbnail)
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                cellViewClass = MessagesSearchResultAttachmentBubbleCell.class;
            }
            else
            {
                cellViewClass = RoomIncomingAttachmentBubbleCell.class;
            }
        }
        else if (bubbleData.isPaginationFirstBubble)
        {
            cellViewClass = MessagesSearchResultTextMsgBubbleCell.class;
        }
        else
        {
            cellViewClass = RoomIncomingTextMsgBubbleCell.class;
        }
    }
    
    return cellViewClass;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    Class class = [self cellViewClassForCellData:cellData];
    
    if ([class respondsToSelector:@selector(defaultReuseIdentifier)])
    {
        return [class defaultReuseIdentifier];
    }
    
    return nil;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // `MXKRoomBubbleTableViewCell` cells displayed by the `RoomViewController`
    // do not have line separators.
    // The +1 here is for the line separator which is displayed by `HomeMessagesSearchViewController`.
    return [super tableView:tableView heightForRowAtIndexPath:indexPath] + 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Data in the cells are actually Vector RoomBubbleCellData
    RoomBubbleCellData *cellData = (RoomBubbleCellData*)[self.dataSource cellDataAtIndex:indexPath.row];
    _selectedEvent = cellData.bubbleComponents[0].event;

    // Hide the keyboard handled by the search text input which belongs to HomeViewController
    [((HomeViewController*)self.parentViewController).searchBar resignFirstResponder];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Make the master tabBar view controller open the RoomViewController
    [self showRoomWithId:cellData.roomId
                andEvent:_selectedEvent
         inMatrixSession:cellData.mxSession];
    
    // Reset the selected event. HomeViewController got it when here
    _selectedEvent = nil;
}

@end
