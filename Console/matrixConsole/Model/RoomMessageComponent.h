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

#import <MatrixSDK/MatrixSDK.h>

extern NSString *const kLocalEchoEventIdPrefix;
extern NSString *const kFailedEventIdPrefix;

typedef enum : NSUInteger {
    RoomMessageComponentStyleDefault,
    RoomMessageComponentStyleBing,
    RoomMessageComponentStyleInProgress,
    RoomMessageComponentStyleFailed,
    RoomMessageComponentStyleUnsupported
} RoomMessageComponentStyle;

@interface RoomMessageComponent : NSObject

@property (nonatomic) NSString *textMessage;
@property (nonatomic) NSString *eventId;
@property (nonatomic) NSDate   *date;
@property (nonatomic) RoomMessageComponentStyle style;
@property (nonatomic) BOOL isStateEvent;
@property (nonatomic) BOOL isRedactedEvent;
@property (nonatomic) BOOL isIncomingMsg;

// Keep a reference on related event (used in case of redaction)
@property (nonatomic, readonly) MXEvent *event;

// The following properties are defined to store information on component.
// They must be handled by the object which creates the RoomMessageComponent instance.
@property (nonatomic) CGFloat height;
@property (nonatomic) NSRange range;

// True if text message starts with the sender name (see membership events, emote ...)
@property (nonatomic) BOOL startsWithSenderName;

- (id)initWithEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState;
- (NSDictionary *)stringAttributes;

- (void)updateWithRedactedEvent:(MXEvent*)redactedEvent;

@end