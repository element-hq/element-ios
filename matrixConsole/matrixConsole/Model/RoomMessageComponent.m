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
#import "MatrixSDKHandler.h"

NSString *const kLocalEchoEventIdPrefix = @"localEcho-";
NSString *const kFailedEventIdPrefix = @"failedEventId-";

@implementation RoomMessageComponent

- (id)initWithEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState {
    if (self = [super init]) {
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        
        // Build text component related to this event
        NSString* textMessage = [mxHandler displayTextForEvent:event withRoomState:roomState inSubtitleMode:NO];
        if (textMessage) {
            _textMessage = textMessage;
            
            NSString *senderName = [mxHandler senderDisplayNameForEvent:event withRoomState:roomState];
            _startsWithSenderName = ([textMessage hasPrefix:senderName] || [mxHandler isEmote:event]);
            
            // Set date time text label
            if (event.originServerTs != kMXUndefinedTimestamp) {
                _date = [NSDate dateWithTimeIntervalSince1970:(double)event.originServerTs/1000];
            } else {
                _date = nil;
            }
            
            // Set component flags
            _isStateEvent = (event.eventType != MXEventTypeRoomMessage);
            _isIncomingMsg = ([event.userId isEqualToString:mxHandler.userId] == NO);
            _isRedactedEvent = (event.redactedBecause != nil);
            
            // Set eventId -> set the component style
            self.eventId = event.eventId;
        } else {
            // Ignore this event
            self = nil;
        }
    }
    return self;
}

- (void)setEventId:(NSString *)eventId {
    _eventId = eventId;
    
    // Update component style
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    if ([_textMessage hasPrefix:kMatrixSDKHandlerUnsupportedEventDescriptionPrefix]) {
        _style = RoomMessageComponentStyleUnsupported;
    } else if ([_eventId hasPrefix:kFailedEventIdPrefix]) {
        _style = RoomMessageComponentStyleFailed;
    } else if (_isIncomingMsg && !_isStateEvent && !_isRedactedEvent && [mxHandler containsBingWord:_textMessage]) {
        _style = RoomMessageComponentStyleBing;
    } else if (!_isIncomingMsg && [_eventId hasPrefix:kLocalEchoEventIdPrefix]) {
        _style = RoomMessageComponentStyleInProgress;
    } else {
        _style = RoomMessageComponentStyleDefault;
    }
}

- (NSDictionary*)stringAttributes {
    UIColor *textColor;
    UIFont *font;
    
    switch (_style) {
        case RoomMessageComponentStyleDefault:
            textColor = [UIColor blackColor];
            break;
        case RoomMessageComponentStyleBing:
            textColor = [UIColor blueColor];
            break;
        case RoomMessageComponentStyleInProgress:
            textColor = [UIColor lightGrayColor];
            break;
        case RoomMessageComponentStyleFailed:
        case RoomMessageComponentStyleUnsupported:
            textColor = [UIColor redColor];
            break;
        default:
            textColor = [UIColor blackColor];
            break;
    }
    
    if (_isStateEvent) {
        font = [UIFont italicSystemFontOfSize:14];
    } else {
        font = [UIFont systemFontOfSize:14];
    }
    
    return @{
             NSForegroundColorAttributeName : textColor,
             NSFontAttributeName: font
             };
}
@end

