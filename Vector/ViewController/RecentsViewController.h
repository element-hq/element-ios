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

#import <MatrixKit/MatrixKit.h>

@class HomeViewController;

@interface RecentsViewController : MXKRecentListViewController

/**
 If YES, the table view will scroll at the top on the next data source refresh.
 It comes back to NO after each refresh.
 */
@property (nonatomic) BOOL shouldScrollToTopOnRefresh;

/**
 Display the recents described in the provided data source.

 @param listDataSource the data source providing the recents list.
 @param homeViewController the segmentedViewController in which the RecentsViewController is displayed.
 */
- (void)displayList:(MXKRecentsDataSource*)listDataSource fromHomeViewController:(HomeViewController*)homeViewController;

/**
 Refresh the cell selection in the table.

 This must be done accordingly to the currently selected room in the parent HomeViewController.

 @param forceVisible if YES and if the corresponding cell is not visible, scroll the table view to make it visible.
 */
- (void)refreshCurrentSelectedCell:(BOOL)forceVisible;

@end

