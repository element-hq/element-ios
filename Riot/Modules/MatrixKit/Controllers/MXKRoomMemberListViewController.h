/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

#import "MXKViewController.h"
#import "MXKRoomMemberListDataSource.h"

@class MXKRoomMemberListViewController;

/**
 `MXKRoomMemberListViewController` delegate.
 */
@protocol MXKRoomMemberListViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user selected a member.

 @param roomMemberListViewController the `MXKRoomMemberListViewController` instance.
 @param member the selected member.
 */
- (void)roomMemberListViewController:(MXKRoomMemberListViewController *)roomMemberListViewController didSelectMember:(MXRoomMember*)member;

@end


/**
 This view controller displays members of a room. Only one matrix session is handled by this view controller.
 */
@interface MXKRoomMemberListViewController : MXKViewController <MXKDataSourceDelegate, UITableViewDelegate, UISearchBarDelegate>
{
@protected    
    /**
     Used to auto scroll at the top when search session is started or cancelled.
     */
    BOOL shouldScrollToTopOnRefresh;
}

@property (weak, nonatomic) IBOutlet UISearchBar *membersSearchBar;
@property (weak, nonatomic) IBOutlet UITableView *membersTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *membersSearchBarTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *membersSearchBarHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *membersTableViewBottomConstraint;

/**
 The current data source associated to the view controller.
 */
@property (nonatomic, readonly) MXKRoomMemberListDataSource *dataSource;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<MXKRoomMemberListViewControllerDelegate> delegate;

/**
 Enable the search in room members list according to the member's display name (YES by default).
 Set NO this property to disable this option and hide the related bar button.
 */
@property (nonatomic) BOOL enableMemberSearch;

/**
 Enable the invitation of a new member (YES by default).
 Set NO this property to disable this option and hide the related bar button.
 */
@property (nonatomic) BOOL enableMemberInvitation;

#pragma mark - Class methods

/**
 Returns the `UINib` object initialized for a `MXKRoomMemberListViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `roomMemberListViewController` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKRoomMemberListViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKRoomMemberListViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)roomMemberListViewController;

/**
 Display the members list.

 @param listDataSource the data source providing the members list.
 */
- (void)displayList:(MXKRoomMemberListDataSource*)listDataSource;

/**
 Scroll the members list to the top.
 
 @param animated YES to animate the transition at a constant velocity to the new offset, NO to make the transition immediate.
 */
- (void)scrollToTop:(BOOL)animated;

@end
