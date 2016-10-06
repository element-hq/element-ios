/*
 Copyright 2016 OpenMarket Ltd

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

#import "RoomFilesSearchViewController.h"

#import "RoomSearchViewController.h"

#import "UIViewController+VectorSearch.h"

#import "FilesSearchCellData.h"
#import "FilesSearchTableViewCell.h"

#import "VectorDesignValues.h"

#import "RageShakeManager.h"

#import "AppDelegate.h"

@interface RoomFilesSearchViewController ()
{
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;
}

@end

@implementation RoomFilesSearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];

    // Hide line separators of empty cells
    self.searchTableView.tableFooterView = [[UIView alloc] init];

    // Register cell class used to display the files search result
    [self.searchTableView registerClass:FilesSearchTableViewCell.class forCellReuseIdentifier:FilesSearchTableViewCell.defaultReuseIdentifier];
    
    self.searchTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:@"RoomFilesSearch"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
    
    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.searchTableView setContentOffset:CGPointMake(-self.searchTableView.contentInset.left, -self.searchTableView.contentInset.top) animated:YES];
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // `MXKRoomBubbleTableViewCell` cells displayed by the `RoomViewController`
    // do not have line separators.
    // The +1 here is for the line separator which is displayed by `RoomSearchViewController`.
    return [super tableView:tableView heightForRowAtIndexPath:indexPath] + 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Data in the cells are actually Vector RoomBubbleCellData
    FilesSearchCellData *cellData = (FilesSearchCellData*)[self.dataSource cellDataAtIndex:indexPath.row];
    _selectedEvent = cellData.searchResult.result;
    
    // Hide the keyboard handled by the search text input which belongs to RoomSearchViewController
    [((RoomSearchViewController*)self.parentViewController).searchBar resignFirstResponder];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Make the RoomSearchViewController (that contains this VC) open the RoomViewController
    [self.parentViewController performSegueWithIdentifier:@"showTimeline" sender:self];
    
    // Reset the selected event. RoomSearchViewController got it when here
    _selectedEvent = nil;
}

@end
