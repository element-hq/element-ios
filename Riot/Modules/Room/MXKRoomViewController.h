/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2019 The Matrix.org Foundation C.I.C

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

#import <MatrixSDK/MatrixSDK.h>

#import "MXKViewController.h"
#import "MXKRoomDataSource.h"
#import "MXKRoomTitleView.h"
#import "MXKRoomInputToolbarView.h"
#import "MXKRoomActivitiesView.h"
#import "MXKEventDetailsView.h"

#import "MXKAttachmentsViewController.h"
#import "MXKAttachmentAnimator.h"

@class UserIndicatorStore;

typedef NS_ENUM(NSUInteger, MXKRoomViewControllerJoinRoomResult) {
    MXKRoomViewControllerJoinRoomResultSuccess,
    MXKRoomViewControllerJoinRoomResultFailureRoomEmpty,
    MXKRoomViewControllerJoinRoomResultFailureJoinInProgress,
    MXKRoomViewControllerJoinRoomResultFailureGeneric
};

/**
 This view controller displays messages of a room. Only one matrix session is handled by this view controller.
 */
@interface MXKRoomViewController : MXKViewController <MXKDataSourceDelegate, MXKRoomTitleViewDelegate, MXKRoomInputToolbarViewDelegate, UITableViewDelegate, UIDocumentInteractionControllerDelegate, MXKAttachmentsViewControllerDelegate, MXKRoomActivitiesViewDelegate, MXKSourceAttachmentAnimatorDelegate>
{
@protected
    /**
     The identifier of the current event displayed at the bottom of the table (just above the toolbar).
     Use to anchor the message displayed at the bottom during table refresh.
     */
    NSString *currentEventIdAtTableBottom;
    
    /**
     Boolean value used to scroll to bottom the bubble history after refresh.
     */
    BOOL shouldScrollToBottomOnTableRefresh;
    
    /**
     Potential event details view.
     */
    __weak MXKEventDetailsView *eventDetailsView;
    
    /**
     Current alert (if any).
     */
    __weak UIAlertController *currentAlert;
    
    /**
     The document interaction Controller used to share attachment
     */
    UIDocumentInteractionController *documentInteractionController;
    
    /**
     The current shared attachment.
     */
    MXKAttachment *currentSharedAttachment;
    
    /**
     Tell whether the input toolbar required to run an animation indicator.
     */
    BOOL isInputToolbarProcessing;
    
    /**
     Tell whether a device rotation is in progress
     */
    BOOL isSizeTransitionInProgress;
    
    /**
     The current visibility of the status bar in this view controller.
     */
    BOOL isStatusBarHidden;
    
    /**
     YES to prevent `bubblesTableView` scrolling when calling -[setBubbleTableViewContentOffset:animated:]
     */
    BOOL preventBubblesTableViewScroll;
}

/**
 The current data source associated to the view controller.
 */
@property (nonatomic, readonly) MXKRoomDataSource *roomDataSource;

/**
  The data source associated to live timeline, in the case the view controller show timeline not live.
 */
@property (nonatomic) MXKRoomDataSource *roomDataSourceLive;

/**
 Flag indicating if this instance has the memory ownership of its `roomDataSource`.
 If YES, it will release it on [self destroy] call;
 Default is NO.
 */
@property (nonatomic) BOOL hasRoomDataSourceOwnership;

/**
 Tell whether the bubbles table view display is in transition. Its display is not warranty during the transition.
 */
@property (nonatomic, getter=isBubbleTableViewDisplayInTransition) BOOL bubbleTableViewDisplayInTransition;

/**
 Tell whether the automatic events acknowledgement (based on read receipt) is enabled.
 Default is YES.
 */
@property (nonatomic, getter=isEventsAcknowledgementEnabled) BOOL eventsAcknowledgementEnabled;

/**
 Tell whether the room read marker must be updated when an event is acknowledged with a read receipt.
 Default is NO.
 */
@property (nonatomic) BOOL updateRoomReadMarker;

/**
 When the room view controller displays a room data source based on a timeline with an initial event,
 the bubble table view content is scrolled by default to display the top of this event at the center of the screen
 the first time it appears.
 Use this property to force the table view to center its content on the bottom part of the event.
 Default is NO.
 */
@property (nonatomic) BOOL centerBubblesTableViewContentOnTheInitialEventBottom;

/**
 The current title view defined into the view controller.
 */
@property (nonatomic, weak, readonly) MXKRoomTitleView* titleView;

/**
 The current input toolbar view defined into the view controller.
 */
@property (nonatomic, weak, readonly) MXKRoomInputToolbarView* inputToolbarView;

/**
 The current extra info view defined into the view controller.
 */
@property (nonatomic, readonly) MXKRoomActivitiesView* activitiesView;

/**
 The threshold used to trigger inconspicuous back pagination, or forwards pagination
 for non live timeline. A pagination is triggered when the vertical content offset
 is lower this threshold.
 Default is 300.
 */
@property (nonatomic) NSUInteger paginationThreshold;

/**
 The maximum number of messages to retrieve during a pagination. Default is 30.
 */
@property (nonatomic) NSUInteger paginationLimit;

/**
 Enable/disable saving of the current typed text in message composer when view disappears.
 The message composer is prefilled with this text when the room is opened again.
 This property value is YES by default.
 */
@property BOOL saveProgressTextInput;

/**
 The invited rooms can be automatically joined when the data source is ready.
 This property enable/disable this option. Its value is YES by default.
 */
@property BOOL autoJoinInvitedRoom;

/**
 Tell whether the room history is automatically scrolled to the most recent messages
 when a keyboard is presented. YES by default.
 This option is ignored when an alert is presented.
 */
@property BOOL scrollHistoryToTheBottomOnKeyboardPresentation;

/**
 YES (default) to show actions button in document preview. NO otherwise.
 */
@property BOOL allowActionsInDocumentPreview;

/**
 Duration of the animation in case of the composer needs to be resized (default 0.3s)
 */
@property NSTimeInterval resizeComposerAnimationDuration;

/**
 A store of user indicators that lets the room present and dismiss indicators without
 worrying about the presentation context or memory management.
 */
@property (strong, nonatomic) UserIndicatorStore *userIndicatorStore;

/**
 YES if the instance is used as context menu preview.
 */
@property (nonatomic, getter=isContextPreview) BOOL contextPeview;

/**
 This object is defined when the displayed room is left. It is added into the bubbles table header.
 This label is used to display the reason why the room has been left.
 */
@property (nonatomic, weak, readonly) UILabel *leftRoomReasonLabel;

@property (weak, nonatomic) IBOutlet UITableView *bubblesTableView;
@property (weak, nonatomic) IBOutlet UIView *roomTitleViewContainer;
@property (strong, nonatomic) IBOutlet UIView *roomInputToolbarContainer;
@property (weak, nonatomic) IBOutlet UIView *roomActivitiesContainer;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bubblesTableViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bubblesTableViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *roomActivitiesContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *roomInputToolbarContainerHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *roomInputToolbarContainerBottomConstraint;

#pragma mark - Class methods

/**
 Returns the `UINib` object initialized for a `MXKRoomViewController`.

 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `roomViewController` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKRoomViewController` object.

 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKRoomViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)roomViewController;

/**
 Display a room.
 
 @param dataSource the data source .
 */
- (void)displayRoom:(MXKRoomDataSource*)dataSource;

/**
 This method is called when the associated data source is ready.
 
 By default this operation triggers the initial back pagination when the user is an actual
 member of the room (membership = join).
 
 The invited rooms are automatically joined during this operation if 'autoJoinInvitedRoom' is YES.
 When the room is successfully joined, an initial back pagination is triggered too.
 Else nothing is done for the invited rooms.
 
 Override it to customize the view controller behavior when the data source is ready.
 */
- (void)onRoomDataSourceReady;

/**
 Update view controller appearance according to the state of its associated data source.
 This method is called in the following use cases:
 - on data source change (see `[MXKRoomViewController displayRoom:]`).
 - on data source state change (see `[MXKDataSourceDelegate dataSource:didStateChange:]`)
 - when view did appear.
 
 The default implementation:
 - show input toolbar view if the dataSource is defined and ready (`MXKDataSourceStateReady`), hide toolbar in others use cases.
 - stop activity indicator if the dataSource is defined and ready (`MXKDataSourceStateReady`).
 - update view controller title with room information.
 
 Override it to customize view appearance according to data source state.
 */
- (void)updateViewControllerAppearanceOnRoomDataSourceState;

/**
 This method is called when the associated data source has encountered an error on the timeline.

 Override it to customize the view controller behavior.

 @param notif the notification data sent with kMXKRoomDataSourceTimelineError notif.
 */
- (void)onTimelineError:(NSNotification *)notif;

/**
 Join the current displayed room.
 
 This operation fails if the user has already joined the room, or if the data source is not ready.
 It fails if a join request is already running too.
 
 @param completion the block to execute at the end of the operation.
 You may specify nil for this parameter.
 */
- (void)joinRoom:(void(^)(MXKRoomViewControllerJoinRoomResult result))completion;

/**
 Join a room with a room id or an alias.

 This operation fails if the user has already joined the room, or if the data source is not ready,
 or if the access to the room is forbidden to the user.
 It fails if a join request is already running too.
 
 @param roomIdOrAlias the id or the alias of the room to join.
 @param viaServers The server names to try and join through in addition to those that are automatically chosen. It is optional and can be nil.
 @param signUrl the signurl paramater passed with a 3PID invitation. It is optional and can be nil.

 @param completion the block to execute at the end of the operation.
 You may specify nil for this parameter.
 */
- (void)joinRoomWithRoomIdOrAlias:(NSString*)roomIdOrAlias
                       viaServers:(NSArray<NSString*>*)viaServers
                       andSignUrl:(NSString*)signUrl
                       completion:(void(^)(MXKRoomViewControllerJoinRoomResult result))completion;

/**
 Update view controller appearance when the user is about to leave the displayed room.
 This method is called when the user will leave the current room (see `kMXSessionWillLeaveRoomNotification`).
 
 The default implementation:
 - discard `roomDataSource`
 - hide input toolbar view
 - freeze the room title display
 - add a label (`leftRoomReasonLabel`) in bubbles table header to display the reason why the room has been left.
 
 Override it to customize view appearance, or to withdraw the view controller.
 
 @param event the MXEvent responsible for the leaving.
 */
- (void)leaveRoomOnEvent:(MXEvent*)event;

/**
 Register the class used to instantiate the title view which will handle the room name display.
 
 The resulting view is added into 'roomTitleViewContainer' view, which must be defined before calling this method.
 
 Note: By default the room name is displayed by using 'navigationItem.title' field of the view controller.
 
 @param roomTitleViewClass a MXKRoomTitleView-inherited class.
 */
- (void)setRoomTitleViewClass:(Class)roomTitleViewClass;

/**
 Register the class used to instantiate the input toolbar view which will handle message composer
 and attachments selection for the room.
 
 The resulting view is added into 'roomInputToolbarContainer' view, which must be defined before calling this method.
 
 @param roomInputToolbarViewClass a MXKRoomInputToolbarView-inherited class, or nil to remove the current view.
 */
- (void)setRoomInputToolbarViewClass:(Class)roomInputToolbarViewClass;

/**
 Register the class used to instantiate the extra info view.
 
 The resulting view is added into 'roomActivitiesContainer' view, which must be defined before calling this method.
 
 @param roomActivitiesViewClass a MXKRoomActivitiesViewClass-inherited class, or nil to remove the current view.
 */
- (void)setRoomActivitiesViewClass:(Class)roomActivitiesViewClass;

/**
 Register the class used to instantiate the viewer dedicated to the attachments with thumbnail.
 By default 'MXKAttachmentsViewController' class is used.
 
 @param attachmentsViewerClass a MXKAttachmentsViewController-inherited class, or nil to restore the default class.
 */
- (void)setAttachmentsViewerClass:(Class)attachmentsViewerClass;

/**
 Register the view class used to display the details of an event.
 MXKEventDetailsView is used by default.
 
 @param eventDetailsViewClass a MXKEventDetailsView-inherited class.
 */
- (void)setEventDetailsViewClass:(Class)eventDetailsViewClass;

/**
 Detect and process potential IRC command in provided string.
 
 @param string to analyse
 @return YES if IRC style command has been detected and interpreted.
 */
- (BOOL)sendAsIRCStyleCommandIfPossible:(NSString*)string;

/**
 Mention the member display name in the current text of the message composer.
 The message composer becomes then the first responder.
 */
- (void)mention:(MXRoomMember*)roomMember;

/**
 Force to dismiss keyboard if any
 */
- (void)dismissKeyboard;

/**
 Tell whether the most recent message of the room history is visible.
 */
- (BOOL)isBubblesTableScrollViewAtTheBottom;

/**
 Scroll the room history until the most recent message.
 */
- (void)scrollBubblesTableViewToBottomAnimated:(BOOL)animated;

/**
 Dismiss the keyboard and all the potential subviews.
 */
- (void)dismissTemporarySubViews;

/**
 Display a popup with the event detais.
 
 @param event the event to inspect.
 */
- (void)showEventDetails:(MXEvent *)event;

/**
 Present the attachments viewer by displaying the attachment of the provided cell.
 
 @param cell the table view cell with attachment
 */
- (void)showAttachmentInCell:(UITableViewCell*)cell;

/**
 Force a refresh of the room history display.
 
 You should not call this method directly.
 You may override it in inherited 'MXKRoomViewController' class.
 
 @param useBottomAnchor tells whether the updated history must keep display the same event at the bottom.
 @return a boolean value which tells whether the table has been scrolled to the bottom.
 */
- (BOOL)reloadBubblesTable:(BOOL)useBottomAnchor;

/**
 Sets the offset from the content `bubblesTableView`'s origin. Take into account `preventBubblesTableViewScroll` value.

 @param contentOffset Offset from the content `bubblesTableView`’s origin.
 @param animated YES to animate the transition.
 */
- (void)setBubbleTableViewContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;

/**
 Sends a typing notification with the specified timeout.
 
 @param typing Flag indicating whether the user is typing or not.
 @param notificationTimeoutMS The length of time the typing notification is valid for
 */
- (void)sendTypingNotification:(BOOL)typing timeout:(NSUInteger)notificationTimeoutMS;


/**
 Share encryption keys in this room.
 */
- (void)shareEncryptionKeys;

@end
