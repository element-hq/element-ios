/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <MatrixSDK/MatrixSDK.h>

#import "MXKEventFormatter.h"
#import "MXKURLPreviewDataProtocol.h"
#import "EventEncryptionDecoration.h"

@protocol MXThreadProtocol;

/**
 Flags to indicate if a fix is required at the display time.
 */
typedef enum : NSUInteger {

    /**
     No fix required.
     */
    MXKRoomBubbleComponentDisplayFixNone = 0,

    /**
     Borders for HTML blockquotes need to be fixed.
     */
    MXKRoomBubbleComponentDisplayFixHtmlBlockquote = 0x1

} MXKRoomBubbleComponentDisplayFix;

/**
 `MXKRoomBubbleComponent` class compose data related to one `MXEvent` instance.
 */
@interface MXKRoomBubbleComponent : NSObject

/**
 The body of the message, or kind of content description in case of attachment (e.g. "image attachment").
 */
@property (nonatomic) NSString *textMessage;

/**
 The `textMessage` with sets of attributes.
 */
@property (nonatomic) NSAttributedString *attributedTextMessage;

/**
 The event date
 */
@property (nonatomic) NSDate *date;

/**
 Event formatter
 */
@property (nonatomic) MXKEventFormatter *eventFormatter;

/**
 The event on which the component is based (used in case of redaction)
 */
@property (nonatomic, readonly) MXEvent *event;

// The following properties are defined to store information on component.
// They must be handled by the object which creates the MXKRoomBubbleComponent instance.
//@property (nonatomic) CGFloat height;
@property (nonatomic) CGPoint position;

/**
 Set of flags indicating fixes that need to be applied at display time.
 */
@property (nonatomic) MXKRoomBubbleComponentDisplayFix displayFix;

/**
 The first link detected in the event's content, otherwise nil.
 */
@property (nonatomic) NSURL *link;

/**
 Any data necessary to show a URL preview.
 Note: MatrixKit is unable to display this data by itself.
 */
@property (nonatomic) id <MXKURLPreviewDataProtocol> urlPreviewData;

/**
 Whether a URL preview should be displayed for this cell.
 Note: MatrixKit is unable to display URL previews by itself.
 */
@property (nonatomic) BOOL showURLPreview;

/**
 Event antivirus scan. Present only if antivirus is enabled and event contains media.
 */
@property (nonatomic) MXEventScan *eventScan;

/**
 Type of encryption decoration (if any) for this event
 */
@property (nonatomic, readonly) EventEncryptionDecoration encryptionDecoration;

/**
 Thread for the bubble component. Should only exist for thread root events.
 */
@property (nonatomic, readonly) id<MXThreadProtocol> thread;

/**
 Create a new `MXKRoomBubbleComponent` object based on a `MXEvent` instance.
 
 @param event the event used to compose the bubble component.
 @param roomState the room state when the event occured.
 @param latestRoomState the latest room state of the room containing this event.
 @param eventFormatter object used to format event into displayable string.
 @param session the related matrix session.
 @return the newly created instance.
 */
- (instancetype)initWithEvent:(MXEvent*)event
                    roomState:(MXRoomState*)roomState
           andLatestRoomState:(MXRoomState*)latestRoomState
               eventFormatter:(MXKEventFormatter*)eventFormatter
                      session:(MXSession*)session;

/**
 Update the event because its sent state changed or it is has been redacted.

 @param event the new event data.
 @param roomState the up-to-date state of the room.
 @param latestRoomState the latest room state of the room containing this event.
 @param session the related matrix session.
 */
- (void)updateWithEvent:(MXEvent*)event
              roomState:(MXRoomState*)roomState
     andLatestRoomState:(MXRoomState*)latestRoomState
                session:(MXSession*)session;

@end

