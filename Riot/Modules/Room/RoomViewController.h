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
@class RoomDisplayConfiguration;
@class ThreadsCoordinatorBridgePresenter;
@class LiveLocationSharingBannerView;

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
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint *userSuggestionContainerHeightConstraint;

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

// Error presenter
@property (nonatomic, strong, readonly) MXKErrorAlertPresentation *errorPresenter;

/**
 Preview data for a room invitation received by email, or a link to a room.
 */
@property (nonatomic, readonly, nullable) RoomPreviewData *roomPreviewData;

/**
 Display configuration for the room view controller.
 */
@property (nonatomic, readonly) RoomDisplayConfiguration *displayConfiguration;

/**
 Tell whether a badge must be added next to the chevron (back button) showing number of unread rooms.
 YES by default.
 */
@property (nonatomic) BOOL showMissedDiscussionsBadge;

/**
 ID of the parent space. `nil` for home space.
 */
@property (nonatomic, nullable) NSString *parentSpaceId;

/// Handles all banners that should be displayed at the top of the timeline but that should not scroll with the timeline
@property (weak, nonatomic, nullable) IBOutlet UIStackView *topBannersStackView;

/// Indicate YES to show live location sharing banner
@property (nonatomic, readonly) BOOL shouldShowLiveLocationSharingBannerView;

/// Displayed live location sharing banner if any
@property (nonatomic, weak) LiveLocationSharingBannerView *liveLocationSharingBannerView;

// The customized room data source for Vector
@property (nonatomic, nullable) RoomDataSource *customizedRoomDataSource;

/**
 Retrieve the live data source in cases where the timeline is not live.

 @param onComplete completion block
 */
- (void)setupRoomDataSourceToResolveEvent: (void (^)(MXKRoomDataSource *roomDataSource))onComplete;

/**
 Cancels current event selection inside the timeline.
 */
- (void)cancelEventSelection;

/**
 Display the preview of a room that is unknown for the user.

 This room can come from an email invitation link or a simple link to a room.

 @param roomPreviewData the data for the room preview.
 */
- (void)displayRoomPreview:(RoomPreviewData*)roomPreviewData;

/**
 Display a new discussion with a target user without associated room.
 
 @param directChatTargetUser Direct chat target user.
 @param session The Matrix session.
 */
- (void)displayNewDirectChatWithTargetUser:(nonnull MXUser*)directChatTargetUser session:(nonnull MXSession*)session;

/**
 Pop to home view controller
 */
- (void)popToHomeViewController;

/**
 If `YES`, the room settings screen will be initially displayed. Default `NO`
 */
@property (nonatomic) BOOL showSettingsInitially;

/**
 Action used to handle some buttons.
 */
- (IBAction)onButtonPressed:(id)sender;

- (IBAction)scrollToBottomAction:(id)sender;

/**
 Highlights an event in the timeline. Does not reload room data source if the event is already loaded. Otherwise, loads a new data source around the given event.
 
 @param eventId Identifier of the event to be highlighted.
 @param completion Completion block to be called at the end of process. Optional.
 */
- (void)highlightAndDisplayEvent:(NSString *)eventId completion:(nullable void (^)(void))completion;

/**
 Creates and returns a new `RoomViewController` object.
 
 @param configuration display configuration for the room view controller.
 
 @return An initialized `RoomViewController` object.
 */
+ (instancetype)instantiateWithConfiguration:(RoomDisplayConfiguration *)configuration;

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
 @param eventID the selected eventId
 */
- (void)roomViewController:(RoomViewController *)roomViewController
            showRoomWithId:(NSString *)roomID
                   eventId:(nullable NSString *)eventID;

/**
 Tells the delegate that the room has replaced by a room with a specific replacement room ID.
 
 @param roomViewController the `RoomViewController` instance.
 @param roomID the replacement roomId
 */
- (void)roomViewController:(RoomViewController *)roomViewController
didReplaceRoomWithReplacementId:(NSString *)roomID;

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

/// Ask the coordinator to present the live location sharing viewer.
- (void)roomViewController:(RoomViewController *)roomViewController
didRequestLiveLocationPresentationForBubbleData:(id<MXKRoomBubbleCellDataStoring>)bubbleData;

- (nullable UIActivityViewController *)roomViewController:(RoomViewController *)roomViewController
              locationShareActivityViewControllerForEvent:(MXEvent *)event;

- (BOOL)roomViewController:(RoomViewController *)roomViewController
canEndPollWithEventIdentifier:(NSString *)eventIdentifier;

- (void)roomViewController:(RoomViewController *)roomViewController
endPollWithEventIdentifier:(NSString *)eventIdentifier;

- (BOOL)roomViewController:(RoomViewController *)roomViewController
canEditPollWithEventIdentifier:(NSString *)eventIdentifier;

- (void)roomViewController:(RoomViewController *)roomViewController
didRequestEditForPollWithStartEvent:(MXEvent *)startEvent;

/**
 Indicate to the delegate that loading should start
 
 Note: Only called if the controller can delegate user indicators rather than managing
 loading indicators internally
 */
- (void)roomViewControllerDidStartLoading:(RoomViewController *)roomViewController;

/**
 Indicate to the delegate that loading should stop
 
 Note: Only called if the controller can delegate user indicators rather than managing
 loading indicators internally
 */
- (void)roomViewControllerDidStopLoading:(RoomViewController *)roomViewController;

/// User tap live location sharing stop action
- (void)roomViewControllerDidStopLiveLocationSharing:(RoomViewController *)roomViewController beaconInfoEventId:(nullable NSString*)beaconInfoEventId;

/// User tap live location sharing banner
- (void)roomViewControllerDidTapLiveLocationSharingBanner:(RoomViewController *)roomViewController;

/// Request a threads coordinator for a given threadId, used to open a thread from within a room.
- (nullable ThreadsCoordinatorBridgePresenter *)threadsCoordinatorForRoomViewController:(RoomViewController *)roomViewController threadId:(nullable NSString *)threadId;

@end

NS_ASSUME_NONNULL_END
