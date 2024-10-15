/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"


/**
 `RoomExtraInfosInfoView` instance is a view used to display extra information
 */
@interface RoomActivitiesView : MXKRoomActivitiesView <UITextViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *unsentMessagesContentView;
@property (weak, nonatomic) IBOutlet UIButton *resendButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UILabel *unsentMessageLabel;

/**
 Notify that some messages are not sent.
 Replace the current notification if any.
 
 @param notification the notification message to display.
 @param onResendLinkPressed block called when user selects the resend link.
 @param onCancelLinkPressed block called when user selects the cancel link.
 @param onIconTapGesture block called when user taps on notification icon.
 */
- (void)displayUnsentMessagesNotification:(NSString*)notification withResendLink:(void (^)(void))onResendLinkPressed andCancelLink:(void (^)(void))onCancelLinkPressed andIconTapGesture:(void (^)(void))onIconTapGesture;

/**
 Display network error.
 Replace the current notification if any.
 
 @param labelText the notification message
 */
- (void)displayNetworkErrorNotification:(NSString*)labelText;

/**
 Display a typing notification.
 Replace the current notification if any.
 
 @param labelText the current typing message.
 */
- (void)displayTypingNotification:(NSString*)labelText;

/**
 Display an ongoing conference call.
 Replace the current notification if any.

 @param ongoingConferenceCallPressed the block called when the user clicks on the banner.
                                     video is YES if the user chose to join the conf in video mode.
 @param ongoingConferenceCallClosePressed the block called when the user clicks on the banner close button.
                                          nil means do not display a close button.
 */
- (void)displayOngoingConferenceCall:(void (^)(BOOL video))ongoingConferenceCallPressed onClosePressed:(void (^)(void))ongoingConferenceCallClosePressed;

/**
 Notify that the a room is obsolete and a replacement room is available.
 
 @param onRoomReplacementLinkTapped block called when user selects the room replacement link.
 */
- (void)displayRoomReplacementWithRoomLinkTappedHandler:(void (^)(void))onRoomReplacementLinkTapped;

/**
 Display a kMXErrCodeStringResourceLimitExceeded error received during a /sync request.

 @param errorDict the error data.
 @param onAdminContactTapped a callback indicating if the user wants to contact their admin.
 */
- (void)showResourceLimitExceededError:(NSDictionary *)errorDict onAdminContactTapped:(void (^)(NSURL *adminContact))onAdminContactTapped;

/**
 Display a usage limit notice sent in a system alert room.

 @param usageLimit the usage limit data.
 @param onAdminContactTapped a callback indicating if the user wants to contact their admin.
 */
- (void)showResourceUsageLimitNotice:(MXServerNoticeContent *)usageLimit onAdminContactTapped:(void (^)(NSURL *adminContact))onAdminContactTapped;

/**
 Remove any displayed information.
 */
- (void)reset;

@end
