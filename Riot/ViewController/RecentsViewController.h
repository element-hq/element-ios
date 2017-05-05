/*
 Copyright 2015 OpenMarket Ltd
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

#import <MatrixKit/MatrixKit.h>

@interface RecentsViewController : MXKRecentListViewController <MXKRecentListViewControllerDelegate>
{
@protected
    /**
     The image view of the room creation button.
     */
    UIImageView* createNewRoomImageView;
    
    /**
     Current alert (if any).
     */
    MXKAlert *currentAlert;
    
    /**
     The list of the section headers currently displayed in the recents table.
     */
    NSMutableArray<UIView*> *displayedSectionHeaders;
    
    /**
     The current vertical position of the first displayed section header.
     */
    CGFloat firstDisplayedSectionHeaderPosY;
}

@property (weak, nonatomic) IBOutlet UIView *stickyHeadersTopContainer;
@property (weak, nonatomic) IBOutlet UIView *stickyHeadersBottomContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *stickyHeadersTopContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *stickyHeadersBottomContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *stickyHeadersBottomContainerBottomConstraint;

/**
 If YES, the table view will scroll at the top on the next data source refresh.
 It comes back to NO after each refresh.
 */
@property (nonatomic) BOOL shouldScrollToTopOnRefresh;

/**
 Tell whether the drag and drop option are enabled. NO by default.
 This option is used to move a room from a section to another.
 */
@property (nonatomic) BOOL enableDragging;

/**
 Tell whether the sticky headers are enabled. NO by default.
 */
@property (nonatomic) BOOL enableStickyHeaders;

/**
 Define the height of each sticky headers (30.0 by default).
 */
@property (nonatomic) CGFloat stickyHeaderHeight;

/**
 The Google Analytics Instance screen name (Default is "RecentsScreen").
 */
@property (nonatomic) NSString *screenName;

/**
 Return the sticky header for the specified section of the table view
 
 @param tableView the table view object asking for the view object.
 @param section an index number identifying a section of tableView .
 @return the sticky header.
 */
- (UIView *)tableView:(UITableView *)tableView viewForStickyHeaderInSection:(NSInteger)section;

/**
 Release the resources used to display the sticky headers.
 */
- (void)resetStickyHeaders;

/**
 Update the sticky headers display.
 */
- (void)updateStickyHeaders;

/**
 Refresh the cell selection in the table.

 This must be done accordingly to the currently selected room in the master tabbar of the application.

 @param forceVisible if YES and if the corresponding cell is not visible, scroll the table view to make it visible.
 */
- (void)refreshCurrentSelectedCell:(BOOL)forceVisible;


#pragma mark - Room creation
/**
 Add a Room creation button at the right bottom corner of the view.
 */
- (void)addRoomCreationButton;

/**
 Action triggered when the user taps on the Room creation button.
 Create an empty room by default.
 */
- (void)onRoomCreationButtonPressed;

/**
 Create an empty room.
 */
- (void)createAnEmptyRoom;

/**
 Join a room by alias or id.
 */
- (void)joinARoom;

#pragma mark - Actions

- (void)didTapOnSectionHeader:(UIGestureRecognizer*)gestureRecognizer;
- (void)didSwipeOnSectionHeader:(UISwipeGestureRecognizer*)gestureRecognizer;

@end

