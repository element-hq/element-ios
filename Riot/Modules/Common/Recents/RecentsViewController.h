/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

@class RootTabEmptyView;
@class AnalyticsScreenTracker;
@class UserIndicatorStore;
@class RecentCellContextMenuProvider;

/**
 Notification to be posted when recents data is ready. Notification object will be the RecentsViewController instance.
 */
FOUNDATION_EXPORT NSString *const RecentsViewControllerDataReadyNotification;

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
    __weak UIAlertController *currentAlert;
    
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
 Empty view to display when there is no item to show on the screen.
 */
@property (nonatomic, weak) RootTabEmptyView *emptyView;

/**
 The bottom anchor used to layout `emptyView` in the absence of a FAB.
 If this value is `nil` the empty view will be anchored to the bottom of its superview.
 */
@property (nonatomic, weak) NSLayoutYAxisAnchor *emptyViewBottomAnchor;

/**
 The screen timer used for analytics if they've been enabled. The default value is nil.
 */
@property (nonatomic) AnalyticsScreenTracker *screenTracker;

/**
 A store of user indicators that lets the room present and dismiss indicators without
 worrying about the presentation context or memory management.
 */
@property (nonatomic, strong) UserIndicatorStore *userIndicatorStore;

@property (nonatomic, readonly) RecentCellContextMenuProvider *contextMenuProvider;

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

- (void)userInterfaceThemeDidChange;

#pragma mark - Room handling

/**
 Action triggered when the user taps on the (+) button.
 Create an empty room by default.
 */
- (void)onPlusButtonPressed;

/**
 Open screen to create a new chat room.
 */
- (void)startChat;

/**
 Open screen to create a new room.
 */
- (void)createNewRoom;

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

/**
 Edit notification settings for the selected room.
 */
- (void)changeEditedRoomNotificationSettings;

/**
 Show room directory.
 */
- (void)showRoomDirectory;

/**
 Show a public room.
 */
- (void)openPublicRoom:(MXPublicRoom *)publicRoom;

/**
 Show a room using its roomID
 */
- (void)showRoomWithRoomId:(NSString*)roomId inMatrixSession:(MXSession*)matrixSession;

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

#pragma mark - Empty view

/**
 Overrides this method to fill the empty view with data.
 */
- (void)updateEmptyView;

/**
 Overrides this method to indicate if empty view should be shown. Returns NO by default.
 */
- (BOOL)shouldShowEmptyView;

@end

