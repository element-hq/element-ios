/*
 Copyright 2014 OpenMarket Ltd
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

#import "RoomTitleView.h"

#import "RoomPreviewData.h"

#import "RoomParticipantsViewController.h"

#import "ContactsTableViewController.h"

#import "UIViewController+RiotSearch.h"

@interface RoomViewController : MXKRoomViewController <UISearchBarDelegate, UIGestureRecognizerDelegate, RoomTitleViewTapGestureDelegate, RoomParticipantsViewControllerDelegate, MXKRoomMemberDetailsViewControllerDelegate, ContactsTableViewControllerDelegate>

// The expanded header
@property (weak, nonatomic) IBOutlet UIView *expandedHeaderContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *expandedHeaderContainerHeightConstraint;

// The preview header
@property (weak, nonatomic) IBOutlet UIView *previewHeaderContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewHeaderContainerHeightConstraint;

// The jump to last unread banner
@property (weak, nonatomic) IBOutlet UIView *jumpToLastUnreadBannerContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *jumpToLastUnreadBannerContainerTopConstraint;
@property (weak, nonatomic) IBOutlet UIButton *jumpToLastUnreadButton;
@property (weak, nonatomic) IBOutlet UILabel *jumpToLastUnreadLabel;
@property (weak, nonatomic) IBOutlet UIButton *resetReadMarkerButton;

/**
 Force the display of the expanded header.
 The default value is NO: this expanded header is hidden on new instantiated RoomViewController object.
 
 When this property is YES, the expanded header is forced each time the view controller appears.
 */
@property (nonatomic) BOOL showExpandedHeader;

/**
 Preview data for a room invitation received by email, or a link to a room.
 */
@property (nonatomic, readonly) RoomPreviewData *roomPreviewData;

/**
 Tell whether a badge must be added next to the chevron (back button) showing number of unread rooms.
 YES by default.
 */
@property (nonatomic) BOOL showMissedDiscussionsBadge;

/**
 Display the preview of a room that is unknown for the user.

 This room can come from an email invitation link or a simple link to a room.

 @param roomPreviewData the data for the room preview.
 */
- (void)displayRoomPreview:(RoomPreviewData*)roomPreviewData;

/**
 Action used to handle some buttons.
 */
- (IBAction)onButtonPressed:(id)sender;

@end

