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

#import "MatrixKit.h"

#import "RoomTitleView.h"

#import "RoomPreviewData.h"

#import "RoomParticipantsViewController.h"

#import "ContactsTableViewController.h"

#import "UIViewController+RiotSearch.h"

@class BadgeLabel;
@class UniversalLinkParameters;
@protocol RoomViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 Notification string used to indicate call tile tapped in a room. Notification object will be the `RoomBubbleCellData` object.
 */
extern NSNotificationName const RoomCallTileTappedNotification;

/**
 Notification string used to indicate group call tile tapped in a room. Notification object will be the `RoomBubbleCellData` object.
 */
extern NSNotificationName const RoomGroupCallTileTappedNotification;

@interface RoomViewController : MXKRoomViewController


// The delegate for the view controller.
@property (weak, nonatomic, nullable) id<RoomViewControllerDelegate> delegate;

// The preview header
@property (weak, nonatomic, nullable) IBOutlet UIView *previewHeaderContainer;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint *previewHeaderContainerHeightConstraint;

// The jump to last unread banner
@property (weak, nonatomic, nullable) IBOutlet UIView *jumpToLastUnreadBannerContainer;
@property (weak, nonatomic, nullable) IBOutlet UIView *jumpToLastUnreadBanner;
@property (weak, nonatomic, nullable) IBOutlet UIImageView *jumpToLastUnreadImageView;
@property (weak, nonatomic, nullable) IBOutlet UIButton *jumpToLastUnreadButton;
@property (weak, nonatomic, nullable) IBOutlet UILabel *jumpToLastUnreadLabel;
@property (weak, nonatomic, nullable) IBOutlet UIButton *resetReadMarkerButton;
@property (weak, nonatomic, nullable) IBOutlet UIView *inputBackgroundView;
@property (weak, nonatomic, nullable) IBOutlet UIButton *scrollToBottomButton;
@property (weak, nonatomic, nullable) IBOutlet BadgeLabel *scrollToBottomBadgeLabel;

// Remove Jitsi widget container
@property (weak, nonatomic, nullable) IBOutlet UIView *removeJitsiWidgetContainer;

/**
 Preview data for a room invitation received by email, or a link to a room.
 */
@property (nonatomic, readonly, nullable) RoomPreviewData *roomPreviewData;

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

- (IBAction)scrollToBottomAction:(id)sender;

/**
 Creates and returns a new `RoomViewController` object.
 
 @return An initialized `RoomViewController` object.
 */
+ (instancetype)instantiate;

@end

/**
 `RoomViewController` delegate.
 */
@protocol RoomViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user wants to open the room details (members, files, settings).
 
 @param roomViewController the `RoomViewController` instance.
 */
- (void)roomViewControllerShowRoomDetails:(RoomViewController *)roomViewController;

/**
 Tells the delegate that the user wants to display the details of a room member.
 
 @param roomViewController the `RoomViewController` instance.
 @param roomMember the selected member
 */
- (void)roomViewController:(RoomViewController *)roomViewController
         showMemberDetails:(MXRoomMember *)roomMember;

/**
 Tells the delegate that the user wants to display another room.
 
 @param roomViewController the `RoomViewController` instance.
 @param roomID the selected roomId
 */
- (void)roomViewController:(RoomViewController *)roomViewController
            showRoomWithId:(NSString *)roomID;

/**
 Tells the delegate that the user wants to start a direct chat with a user.
 
 @param roomViewController the `RoomViewController` instance.
 @param userId the selected user id
 @param completion Blocks called when the chat is created.
 */
- (void)roomViewController:(RoomViewController *)roomViewController
       startChatWithUserId:(NSString*)userId
                completion:(void (^)(void))completion;

/**
 Tells the delegate that the user wants to show complete security screen.
 
 @param roomViewController the `RoomViewController` instance.
 @param session The selected Matrix session.
 */
- (void)roomViewController:(RoomViewController *)roomViewController showCompleteSecurityForSession:(MXSession*)session;

/**
 Tells the delegate that the user left the room.
 
 @param roomViewController the `RoomViewController` instance.
 */
- (void)roomViewControllerDidLeaveRoom:(RoomViewController *)roomViewController;

/**
 Tells the delegate that the user wants to cancel the room preview.
 
 @param roomViewController the `RoomViewController` instance.
 */
- (void)roomViewControllerPreviewDidTapCancel:(RoomViewController *)roomViewController;

/**
 Process universal link.
 
 @param roomViewController the `RoomViewController` instance.
 @param parameters the universal link parameters.
 @return YES in case of processing success.
 */
- (BOOL)roomViewController:(RoomViewController *)roomViewController
handleUniversalLinkWithParameters:(UniversalLinkParameters*)parameters;

/**
 Ask the coordinator to invoke the poll creation form coordinator.
 
 @param roomViewController the `RoomViewController` instance.
 */
- (void)roomViewControllerDidRequestPollCreationFormPresentation:(RoomViewController *)roomViewController;

/**
 Ask the coordinator to invoke the location sharing form coordinator.
 
 @param roomViewController the `RoomViewController` instance.
 */
- (void)roomViewControllerDidRequestLocationSharingFormPresentation:(RoomViewController *)roomViewController;

/**
 Ask the coordinator to invoke the location sharing form coordinator.
 
 @param roomViewController the `RoomViewController` instance.
 @param event the event containing location information
 @param bubbleData the bubble data containing sender details
 */
- (void)roomViewController:(RoomViewController *)roomViewController
didRequestLocationPresentationForEvent:(MXEvent *)event
                bubbleData:(id<MXKRoomBubbleCellDataStoring>)bubbleData;

- (BOOL)roomViewController:(RoomViewController *)roomViewController
canEndPollWithEventIdentifier:(NSString *)eventIdentifier;

- (void)roomViewController:(RoomViewController *)roomViewController
endPollWithEventIdentifier:(NSString *)eventIdentifier;

- (BOOL)roomViewController:(RoomViewController *)roomViewController
canEditPollWithEventIdentifier:(NSString *)eventIdentifier;

- (void)roomViewController:(RoomViewController *)roomViewController
didRequestEditForPollWithStartEvent:(MXEvent *)startEvent;

@end

NS_ASSUME_NONNULL_END
