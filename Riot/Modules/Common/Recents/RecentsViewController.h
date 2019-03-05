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
     The room identifier related to the cell which is in editing mode (if any).
     */
    NSString *editedRoomId;
    
    /**
     The image view of the (+) button.
     */
    UIImageView* plusButtonImageView;
    
    /**
     Current alert (if any).
     */
    UIAlertController *currentAlert;
    
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

/**
 If YES, the table view will scroll at the top on the next data source refresh.
 It comes back to NO after each refresh.
 */
@property (nonatomic) BOOL shouldScrollToTopOnRefresh;

/**
 Tell whether the search bar at the top of the recents table is enabled. YES by default.
 */
@property (nonatomic) BOOL enableSearchBar;

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
 The analytics instance screen name (Default is "RecentsScreen").
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
 Prepare the sticky headers display.
 */
- (void)prepareStickyHeaders;

/**
 Refresh the cell selection in the table.

 This must be done accordingly to the currently selected room in the master tabbar of the application.

 @param forceVisible if YES and if the corresponding cell is not visible, scroll the table view to make it visible.
 */
- (void)refreshCurrentSelectedCell:(BOOL)forceVisible;

/**
 Leave the edition mode
 
 @param forceRefresh force table view refresh
 */
- (void)cancelEditionMode:(BOOL)forceRefresh;

#pragma mark - Room handling
/**
 Add the (+) button at the right bottom corner of the view.
 */
- (void)addPlusButton;

/**
 Action triggered when the user taps on the (+) button.
 Create an empty room by default.
 */
- (void)onPlusButtonPressed;

/**
 Create an empty room.
 */
- (void)createAnEmptyRoom;

/**
 Join a room by alias or id.
 */
- (void)joinARoom;

/**
 Leave the selected room.
 */
- (void)leaveEditedRoom;

/**
 Update the selected room tag.
 */
- (void)updateEditedRoomTag:(NSString*)tag;

/**
 Enable/disable the direct flag of the selected room.
 */
- (void)makeDirectEditedRoom:(BOOL)isDirect;

/**
 Enable/disable the notifications for the selected room.
 */
- (void)muteEditedRoomNotifications:(BOOL)mute;

#pragma mark - Scrolling

/**
 Scroll to the top of the recents list.
 */
- (void)scrollToTop:(BOOL)animated;

/**
 Scroll the next room with missed notifications to the top.
 
 @param section the table section in which the operation must be applied.
 */
- (void)scrollToTheTopTheNextRoomWithMissedNotificationsInSection:(NSInteger)section;

#pragma mark - Actions

- (void)didTapOnSectionHeader:(UIGestureRecognizer*)gestureRecognizer;
- (void)didSwipeOnSectionHeader:(UISwipeGestureRecognizer*)gestureRecognizer;

@end

