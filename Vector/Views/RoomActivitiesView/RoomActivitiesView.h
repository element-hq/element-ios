/*
 Copyright 2015 OpenMarket Ltd

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
@interface RoomActivitiesView : MXKRoomActivitiesView <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainHeightConstraint;

/**
 Notify that some messages are not sent.
 Replace the current notification if any.
 
 @param labelText the notification message
 @param onLabelTapGesture block called when user taps on label.
 */
- (void)displayUnsentMessagesNotification:(NSAttributedString*)labelText onLabelTapGesture:(void (^)(void))onLabelTapGesture;

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
 Remove any displayed information.
 */
- (void)reset;

@end
