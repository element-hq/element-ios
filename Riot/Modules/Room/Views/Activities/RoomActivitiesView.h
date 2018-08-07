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


/**
 `RoomExtraInfosInfoView` instance is a view used to display extra information
 */
@interface RoomActivitiesView : MXKRoomActivitiesView <UITextViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainHeightConstraint;

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
 Display a "scroll to bottom" icon.
 Replace the current notification if any.
 
 @param newMessagesCount the count of the unread messages.
 @param onIconTapGesture block called when user taps on notification icon.
 */
- (void)displayScrollToBottomIcon:(NSUInteger)newMessagesCount onIconTapGesture:(void (^)(void))onIconTapGesture;


/**
 Notify that the a room is obsolete and a replacement room is available.
 
 @param onRoomReplacementLinkTapped block called when user selects the room replacement link.
 */
- (void)displayRoomReplacementWithRoomLinkTappedHandler:(void (^)(void))onRoomReplacementLinkTapped;

/**
 Remove any displayed information.
 */
- (void)reset;

@end
