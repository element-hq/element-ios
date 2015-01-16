/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "RoomMessageComponent.h"

#define ROOM_MESSAGE_DEFAULT_MAX_TEXTVIEW_WIDTH 200
#define ROOM_MESSAGE_MAX_ATTACHMENTVIEW_WIDTH 192
#define ROOM_MESSAGE_TEXTVIEW_MARGIN 5

extern NSString *const kRoomMessageLocalPreviewKey;
extern NSString *const kRoomMessageUploadIdKey;

typedef enum : NSUInteger {
    // Text type
    RoomMessageTypeText,
    // Attachment type
    RoomMessageTypeImage,
    RoomMessageTypeAudio,
    RoomMessageTypeVideo,
    RoomMessageTypeLocation
} RoomMessageType;

// Converts matrix events in room messages
@interface RoomMessage : NSObject

@property (nonatomic) RoomMessageType messageType;
@property (nonatomic) NSString *senderId;
@property (nonatomic) NSString *senderName;
@property (nonatomic) NSString *senderAvatarUrl;

// The max width of the text view used to display the text message (relevant only when type = RoomMessageTypeText)
@property (nonatomic) CGFloat maxTextViewWidth;

// The message content size depends on its type:
// - Text (RoomMessageTypeText): returns suitable content size of a text view to display the whole text message (respecting maxTextViewWidth)
// - Attachment: returns suitable content size for an image view in order to display attachment thumbnail or icon.
@property (nonatomic) CGSize contentSize;
// Returns message components (Note: only one component is supported for attachment [messageType != RoomMessageTypeText])
@property (nonatomic) NSArray *components;

// The body of the message, or kind of content description in case of attachment (e.g. "image attachment")
@property (nonatomic) NSAttributedString *attributedTextMessage;
// True if the sender name appears at the beginning of the message text (available only for messageType is RoomMessageTypeText)
@property (nonatomic) BOOL startsWithSenderName;

// Attachment info (nil when messageType is RoomMessageTypeText)
@property (nonatomic) BOOL isUploadInProgress;
@property (nonatomic) NSString *attachmentURL;
@property (nonatomic) NSDictionary *attachmentInfo;
@property (nonatomic) NSString *thumbnailURL;
@property (nonatomic) NSDictionary *thumbnailInfo;
@property (nonatomic) NSString *previewURL;
@property (nonatomic) NSString *uploadId;
@property (nonatomic) CGFloat uploadProgress;

// Patch: Outgoing messages may be received from events stream whereas the app is waiting for our PUT to return.
// In this case, some messages are temporary hidden
// The following property is true when all components are hidden
@property (nonatomic, readonly) BOOL isHidden;

- (id)initWithEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState;

// Concatenates successive text messages from the same user
// Return false if the provided event could not be added (for example the sender id is not the same, the sender name has been changed, or the messageType is not RoomMessageTypeText)
- (BOOL)addEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState;
// Search a component with the local id, and update it with the provided id
// Return false if the local event id is not found
- (BOOL)replaceLocalEventId:(NSString *)localEventId withEventId:(NSString *)eventId;
// Remove the item defined with this event id
// Return false if the event id is not found
- (BOOL)removeEvent:(NSString*)eventId;
// Returns the component from the eventId
- (RoomMessageComponent*)componentWithEventId:(NSString *)eventId;
// Return true if the event id is one of the message items
- (BOOL)containsEventId:(NSString*)eventId;

// Show/Hide the component related to the provided event id (available only for type = RoomMessageTypeText)
- (void)hideComponent:(BOOL)isHidden withEventId:(NSString*)eventId;

// Return true if the provided message has the same sender as the receiver (same sender means here same id, same name and same avatar)
- (BOOL)hasSameSenderAsRoomMessage:(RoomMessage*)roomMessage;

// Add component(s) of the provided message to the receiver, return true on success (failed if one of the message type is not RoomMessageTypeText)
- (BOOL)mergeWithRoomMessage:(RoomMessage*)roomMessage;

@end