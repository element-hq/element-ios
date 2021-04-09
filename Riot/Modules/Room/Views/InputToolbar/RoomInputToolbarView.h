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

#import "MediaPickerViewController.h"

@class RoomActionsBar;

/**
 Destination of the message in the composer
 */
typedef enum : NSUInteger
{
    RoomInputToolbarViewSendModeSend,
    RoomInputToolbarViewSendModeReply,
    RoomInputToolbarViewSendModeEdit
} RoomInputToolbarViewSendMode;


@protocol RoomInputToolbarViewDelegate <MXKRoomInputToolbarViewDelegate>

/**
 Tells the delegate that the user wants to cancel the current edition / reply.
 
 @param toolbarView the room input toolbar view
 */
- (void)roomInputToolbarViewDidTapCancel:(MXKRoomInputToolbarView*)toolbarView;

@end

/**
 `RoomInputToolbarView` instance is a view used to handle all kinds of available inputs
 for a room (message composer, attachments selection...).
 */
@interface RoomInputToolbarView : MXKRoomInputToolbarViewWithHPGrowingText

/**
 The delegate notified when inputs are ready.
 */
@property (nonatomic, weak) id<RoomInputToolbarViewDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView *mainToolbarView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainToolbarMinHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainToolbarHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageComposerContainerLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageComposerContainerTrailingConstraint;

@property (weak, nonatomic) IBOutlet UIButton *attachMediaButton;

@property (weak, nonatomic) IBOutlet UIImageView *inputTextBackgroundView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inputContextViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *inputContextImageView;
@property (weak, nonatomic) IBOutlet UILabel *inputContextLabel;
@property (weak, nonatomic) IBOutlet UIButton *inputContextButton;
@property (weak, nonatomic) IBOutlet RoomActionsBar *actionsBar;

/**
 Tell whether the filled data will be sent encrypted. NO by default.
 */
@property (nonatomic) BOOL isEncryptionEnabled;

/**
 Sender of the event being edited / replied.
 */
@property (nonatomic, strong) NSString *eventSenderDisplayName;

/**
 Destination of the message in the composer.
 */
@property (nonatomic) RoomInputToolbarViewSendMode sendMode;

/**
 YES if action menu is opened. NO otherwise
 */
@property (nonatomic, getter=isActionMenuOpened) BOOL actionMenuOpened;

@end
