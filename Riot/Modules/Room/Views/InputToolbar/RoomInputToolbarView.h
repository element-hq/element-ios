/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

#import "MediaPickerViewController.h"

@class RoomActionsBar;
@class RoomInputToolbarView;
@class LinkActionWrapper;
@class SuggestionPatternWrapper;
@class CompletionSuggestionViewModelContextWrapper;

/**
 Destination of the message in the composer
 */
typedef NS_ENUM(NSUInteger, RoomInputToolbarViewSendMode)
{
    RoomInputToolbarViewSendModeSend,
    RoomInputToolbarViewSendModeReply,
    RoomInputToolbarViewSendModeEdit,
    RoomInputToolbarViewSendModeCreateDM
};


@protocol RoomInputToolbarViewProtocol

@property (nonatomic, strong) NSString *eventSenderDisplayName;
@property (nonatomic, assign) RoomInputToolbarViewSendMode sendMode;
@property (nonatomic, assign) BOOL isEncryptionEnabled;
- (void)setVoiceMessageToolbarView:(UIView *)voiceMessageToolbarView;
- (CGFloat)toolbarHeight;


@end

@protocol RoomInputToolbarViewDelegate <MXKRoomInputToolbarViewDelegate>

/**
 Tells the delegate that the user wants to cancel the current edition / reply.
 
 @param toolbarView the room input toolbar view
 */
- (void)roomInputToolbarViewDidTapCancel:(MXKRoomInputToolbarView<RoomInputToolbarViewProtocol>*)toolbarView;

/**
 Inform the delegate that the text message has changed.
 
 @param toolbarView the room input toolbar view
 */
- (void)roomInputToolbarViewDidChangeTextMessage:(MXKRoomInputToolbarView*)toolbarView;

/**
 Inform the delegate that the action menu was opened.
 
 @param toolbarView the room input toolbar view
 */
- (void)roomInputToolbarViewDidOpenActionMenu:(RoomInputToolbarView*)toolbarView;

/**
 Tells the delegate that the user wants to send an attributed text message.

 @param toolbarView the room input toolbar view.
 @param attributedTextMessage the attributed string to send.
 */
- (void)roomInputToolbarView:(RoomInputToolbarView *)toolbarView sendAttributedTextMessage:(NSAttributedString *)attributedTextMessage;

- (void)didChangeMaximisedState: (BOOL) isMaximised;

- (void)didSendLinkAction: (LinkActionWrapper *)linkAction;

- (void)didDetectTextPattern: (SuggestionPatternWrapper *)suggestionPattern;

- (CompletionSuggestionViewModelContextWrapper *)completionSuggestionContext;

- (MXMediaManager *)mediaManager;

@end

/**
 `RoomInputToolbarView` instance is a view used to handle all kinds of available inputs
 for a room (message composer, attachments selection...).
 */
@interface RoomInputToolbarView : MXKRoomInputToolbarView<RoomInputToolbarViewProtocol>

/**
 The delegate notified when inputs are ready.
 */
@property (nonatomic, weak) id<RoomInputToolbarViewDelegate> delegate;

/**
 Tell whether the filled data will be sent encrypted. NO by default.
 */
@property (nonatomic, assign) BOOL isEncryptionEnabled;

/**
 Sender of the event being edited / replied.
 */
@property (nonatomic, strong) NSString *eventSenderDisplayName;

/**
 Destination of the message in the composer.
 */
@property (nonatomic, assign) RoomInputToolbarViewSendMode sendMode;

/**
 YES if action menu is opened. NO otherwise
 */
@property (nonatomic, assign) BOOL actionMenuOpened;

/**
 The input toolbar's main height constraint
 */
@property (nonatomic, weak, readonly) NSLayoutConstraint *mainToolbarHeightConstraint;

/**
 The input toolbar's action bar
 */
@property (nonatomic, weak, readonly) RoomActionsBar *actionsBar;

/**
 The attach media button
 */
@property (nonatomic, weak, readonly) UIButton *attachMediaButton;

/**
 Adds a voice message toolbar view to be displayed inside this input toolbar
 */
- (void)setVoiceMessageToolbarView:(UIView *)toolbarView;

@end
