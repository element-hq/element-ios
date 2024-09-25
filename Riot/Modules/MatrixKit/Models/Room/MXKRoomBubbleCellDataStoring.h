/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>
#import <MatrixSDK/MatrixSDK.h>

#import "MXKRoomDataSource.h"

#import "MXKAttachment.h"

#import "MXEvent+MatrixKit.h"

@class MXKRoomDataSource;
/**
 `MXKRoomBubbleCellDataStoring` defines a protocol a class must conform in order to store MXKRoomBubble cell data
 managed by `MXKRoomDataSource`.
 */
@protocol MXKRoomBubbleCellDataStoring <NSObject>

#pragma mark - Data displayed by a room bubble cell

/**
 The sender Id
 */
@property (nonatomic) NSString *senderId;

/**
 The target Id (may be nil)

 @discussion "target" refers to the room member who is the target of this event (if any), e.g.
 the invitee, the person being banned, etc.
 */
@property (nonatomic) NSString *targetId;

/**
 The room id
 */
@property (nonatomic) NSString *roomId;

/**
 The sender display name composed when event occured
 */
@property (nonatomic) NSString *senderDisplayName;

/**
 The sender avatar url retrieved when event occured
 */
@property (nonatomic) NSString *senderAvatarUrl;

/**
 The sender avatar placeholder (may be nil) - Used when url is nil, or during avatar download.
 */
@property (nonatomic) UIImage *senderAvatarPlaceholder;

/**
 The target display name composed when event occured (may be nil)

 @discussion "target" refers to the room member who is the target of this event (if any), e.g.
 the invitee, the person being banned, etc.
 */
@property (nonatomic) NSString *targetDisplayName;

/**
 The target avatar url retrieved when event occured (may be nil)

 @discussion "target" refers to the room member who is the target of this event (if any), e.g.
 the invitee, the person being banned, etc.
 */
@property (nonatomic) NSString *targetAvatarUrl;

/**
 The target avatar placeholder (may be nil) - Used when url is nil, or during avatar download.

 @discussion "target" refers to the room member who is the target of this event (if any), e.g.
 the invitee, the person being banned, etc.
 */
@property (nonatomic) UIImage *targetAvatarPlaceholder;

/**
 Tell whether the room is encrypted.
 */
@property (nonatomic) BOOL isEncryptedRoom;

/**
 Tell whether a new pagination starts with this bubble.
 */
@property (nonatomic) BOOL isPaginationFirstBubble;

/**
 Tell whether the sender information is relevant for this bubble
 (For example this information should be hidden in case of 2 consecutive bubbles from the same sender).
 */
@property (nonatomic) BOOL shouldHideSenderInformation;

/**
 Flag indicating whether the user can invite people in this room.
 */
@property (nonatomic, readonly) BOOL canInvitePeople;

/**
 Tell whether this bubble has nothing to display (neither a message nor an attachment).
 */
@property (nonatomic, readonly) BOOL hasNoDisplay;

/**
 Whether the data has a thread root in its components.
 */
@property (nonatomic, readonly) BOOL hasThreadRoot;

/**
 The list of events (`MXEvent` instances) handled by this bubble.
 */
@property (nonatomic, readonly) NSArray<MXEvent*> *events;

/**
 The bubble attachment (if any).
 */
@property (nonatomic) MXKAttachment *attachment;

/**
 The bubble date
 */
@property (nonatomic) NSDate *date;

/**
 YES when the bubble is composed by incoming event(s).
 */
@property (nonatomic) BOOL isIncoming;

/**
 YES when the bubble correspond to an attachment displayed with a thumbnail (see image, video).
 */
@property (nonatomic) BOOL isAttachmentWithThumbnail;

/**
 YES when the bubble correspond to an attachment displayed with an icon (audio, file...).
 */
@property (nonatomic) BOOL isAttachmentWithIcon;

/**
 YES when the bubble correspond to an attachment (audio, file...).
 */
@property (nonatomic, readonly) BOOL isAttachment;

/**
 Flag that indicates that self.attributedTextMessage will be not nil.
 This avoids the computation of self.attributedTextMessage that can take time.
 */
@property (nonatomic, readonly) BOOL hasAttributedTextMessage;

/**
 The body of the message with sets of attributes, or kind of content description in case of attachment (e.g. "image attachment")
 */
@property (nonatomic) NSAttributedString *attributedTextMessage;

/**
 Same as attributedTextMessage but without vertical positioning blank space
 */
@property (nonatomic) NSAttributedString *attributedTextMessageWithoutPositioningSpace;
/**
 The raw text message (without attributes)
 */
@property (nonatomic) NSString *textMessage;

/**
 Tell whether the sender's name is relevant or not for this bubble.
 Return YES if the first component of the bubble message corresponds to an emote, or a state event in which
 the sender's name appears at the beginning of the message text (for example membership events).
 */
@property (nonatomic) BOOL shouldHideSenderName;

/**
 YES if the sender is currently typing in the current room
 */
@property (nonatomic) BOOL isTyping;

/**
 Show the date time label in rendered bubble cell. NO by default.
 */
@property (nonatomic) BOOL showBubbleDateTime;

/**
 A Boolean value that determines whether the date time labels are customized (By default date time display is handled by MatrixKit). NO by default.
 */
@property (nonatomic) BOOL useCustomDateTimeLabel;

/**
 Show the receipts in rendered bubble cell. YES by default.
 */
@property (nonatomic) BOOL showBubbleReceipts;

/**
 A Boolean value that determines whether the read receipts are customized (By default read receipts display is handled by MatrixKit). NO by default.
 */
@property (nonatomic) BOOL useCustomReceipts;

/**
 A Boolean value that determines whether the unsent button is customized (By default an 'Unsent' button is displayed by MatrixKit in front of unsent events). NO by default.
 */
@property (nonatomic) BOOL useCustomUnsentButton;

/**
 An integer that you can use to identify cell data in your application.
 The default value is 0. You can set the value of this tag and use that value to identify the cell data later.
 */
@property (nonatomic) NSInteger tag;

/**
 Indicate if antivirus scan status should be shown.
 */
@property (nonatomic, readonly) BOOL showAntivirusScanStatus;

#pragma mark - Public methods
/**
 Create a new `MXKRoomBubbleCellDataStoring` object for a new bubble cell.
 
 @param event the event to be displayed in the cell.
 @param roomState the room state when the event occured.
 @param roomDataSource the `MXKRoomDataSource` object that will use this instance.
 @return the newly created instance.
 */
- (instancetype)initWithEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState andRoomDataSource:(MXKRoomDataSource*)roomDataSource;

/**
 Refresh avatars and display names (AKA profiles) displayed in the cell if needed. 

 @param latestRoomState the latest `MXRoomState` from the data source.
 */
- (void)refreshProfilesIfNeeded:(MXRoomState *)latestRoomState;

/**
Update the event because its sent state changed or it is has been redacted.
 
 @param eventId the id of the event to change.
 @param event the new event data
 @return the number of events hosting by the object after the update.
 */
- (NSUInteger)updateEvent:(NSString*)eventId withEvent:(MXEvent*)event;

/**
 Remove the event from the `MXKRoomBubbleCellDataStoring` object.

 @param eventId the id of the event to remove.
 @return the number of events still hosting by the object after the removal
 */
- (NSUInteger)removeEvent:(NSString*)eventId;

/**
 Remove the passed event and all events after it.

 @param eventId the id of the event where to start removing.
 @param removedEvents removedEvents will contain the list of removed events.
 @return the number of events still hosting by the object after the removal.
 */
- (NSUInteger)removeEventsFromEvent:(NSString*)eventId removedEvents:(NSArray<MXEvent*>**)removedEvents;

/**
 Check if the receiver has the same sender as another bubble.
 
 @param bubbleCellData an object conforms to `MXKRoomBubbleCellDataStoring` protocol.
 @return YES if the receiver has the same sender as the provided bubble
 */
- (BOOL)hasSameSenderAsBubbleCellData:(id<MXKRoomBubbleCellDataStoring>)bubbleCellData;

/**
 Highlight text message of an event in the resulting message body.
 
 @param eventId the id of the event to highlight.
 @param tintColor optional tint color
 @return The body of the message by highlighting the content related to the provided event id
 */
- (NSAttributedString*)attributedTextMessageWithHighlightedEvent:(NSString*)eventId tintColor:(UIColor*)tintColor;

/**
 Highlight all the occurrences of a pattern in the resulting message body 'attributedTextMessage'.
 
 @param pattern the text pattern to highlight.
 @param backgroundColor optional text background color (the patterns background color is unchanged if nil)
 @param foregroundColor optional text color (the pattern text color is unchanged if nil).
 @param patternFont optional text font (the pattern font is unchanged if nil).
 */
- (void)highlightPatternInTextMessage:(NSString*)pattern
                  withBackgroundColor:(UIColor *)backgroundColor
                      foregroundColor:(UIColor*)foregroundColor
                              andFont:(UIFont*)patternFont;

/**
 Indicate that the current text message layout is no longer valid and should be recomputed
 before presentation in a bubble cell. This could be due to the content changing, or the
 available space for the cell has been updated.
 */
- (void)invalidateTextLayout;

#pragma mark - Bubble collapsing

/**
 A Boolean value that indicates if the cell is collapsable.
 */
@property (nonatomic) BOOL collapsable;

/**
 A Boolean value that indicates if the cell and its series is collapsed.
 */
@property (nonatomic) BOOL collapsed;

/**
 The attributed string to display when the collapsable cells series is collapsed.
 It is not nil only for the start cell of the cells series.
 */
@property (nonatomic) NSAttributedString *collapsedAttributedTextMessage;

/**
 Bidirectional linked list of cells that can be collapsed together.
 If prevCollapsableCellData is nil, this cell data instance is the data of the start
 cell of the collapsable cells series.
 */
@property (nonatomic) id<MXKRoomBubbleCellDataStoring> prevCollapsableCellData;
@property (nonatomic) id<MXKRoomBubbleCellDataStoring> nextCollapsableCellData;

/**
 The room state to use for computing or updating the data to display for the series when it is
 collapsed.
 It is not nil only for the start cell of the cells series.
 */
@property (nonatomic) MXRoomState *collapseState;

/**
 Check whether the two cells can be collapsable together.

 @return YES if YES.
 */
- (BOOL)collapseWith:(id<MXKRoomBubbleCellDataStoring>)cellData;

@optional
/**
 Attempt to add a new event to the bubble.
 
 @param event the event to be displayed in the cell.
 @param roomState the room state when the event occured.
 @return YES if the model accepts that the event can concatenated to events already in the bubble.
 */
- (BOOL)addEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState;

/**
 The receiver appends to its content the provided bubble cell data, if both have the same sender.
 
 @param bubbleCellData an object conforms to `MXKRoomBubbleCellDataStoring` protocol.
 @return YES if the provided cell data has been merged into receiver.
 */
- (BOOL)mergeWithBubbleCellData:(id<MXKRoomBubbleCellDataStoring>)bubbleCellData;


@end
