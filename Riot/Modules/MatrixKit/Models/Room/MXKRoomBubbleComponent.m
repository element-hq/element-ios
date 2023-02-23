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

#import "MXKRoomBubbleComponent.h"

#import "MXEvent+MatrixKit.h"
#import "MXKSwiftHeader.h"
#import <MatrixSDK/MatrixSDK.h>

@interface MXKRoomBubbleComponent ()

@property (nonatomic, readwrite) id<MXThreadProtocol> thread;

@end

@implementation MXKRoomBubbleComponent

- (instancetype)initWithEvent:(MXEvent*)event
                    roomState:(MXRoomState*)roomState
           andLatestRoomState:(MXRoomState*)latestRoomState
               eventFormatter:(MXKEventFormatter*)eventFormatter
                      session:(MXSession*)session;
{
    if (self = [super init])
    {
        // Build text component related to this event
        _eventFormatter = eventFormatter;
        MXKEventFormatterError error;

        NSAttributedString *eventString = [_eventFormatter attributedStringFromEvent:event
                                                                       withRoomState:roomState
                                                                  andLatestRoomState:latestRoomState
                                                                               error:&error];
        
        // Store the potential error
        event.mxkEventFormatterError = error;
        
        _textMessage = nil;
        _attributedTextMessage = eventString;
        
        // Set date time
        if (event.originServerTs != kMXUndefinedTimestamp)
        {
            _date = [NSDate dateWithTimeIntervalSince1970:(double)event.originServerTs/1000];
        }
        else
        {
            _date = nil;
        }
        
        // Keep ref on event (used to handle the read marker, or a potential event redaction).
        _event = event;

        _displayFix = MXKRoomBubbleComponentDisplayFixNone;
        
        NSString *format = event.content[@"format"];
        if ([format isKindOfClass:[NSString class]] && [format isEqualToString:kMXRoomMessageFormatHTML])
        {
            NSString *formattedBody = (NSString*)event.content[@"formatted_body"];
            if ([formattedBody isKindOfClass:[NSString class]] && [formattedBody containsString:@"<blockquote"])
            {
                _displayFix |= MXKRoomBubbleComponentDisplayFixHtmlBlockquote;
            }
        }
        
        _encryptionDecoration = [self encryptionDecorationForEvent:event roomState:(MXRoomState*)roomState session:session];
        
        [self updateLinkWithRoomState:roomState];

        if (event.unsignedData.relations.thread)
        {
            self.thread = [[MXThreadModel alloc] initWithRootEvent:event
                                                 notificationCount:0
                                                    highlightCount:0];
        }
        else
        {
            self.thread = [session.threadingService threadWithId:event.eventId];
        }
    }
    return self;
}

- (void)updateWithEvent:(MXEvent*)event
              roomState:(MXRoomState*)roomState
     andLatestRoomState:(MXRoomState*)latestRoomState
                session:(MXSession*)session
{
    // Report the new event
    _event = event;

    if (_event.isRedactedEvent)
    {
        // Do not use the live room state for redacted events as they occurred in the past
        // Note: as we don't have valid room state in this case, userId will be used as display name
        roomState = nil;
    }
    // Other calls to updateWithEvent are made to update the state of an event (ex: MXKEventStateSending to MXKEventStateDefault).
    // They occur in live so we can use the room up-to-date state without making huge errors

    _textMessage = nil;

    MXKEventFormatterError error;
    _attributedTextMessage = [_eventFormatter attributedStringFromEvent:event
                                                          withRoomState:roomState
                                                     andLatestRoomState:latestRoomState
                                                                  error:&error];
    
    _encryptionDecoration = [self encryptionDecorationForEvent:event roomState:roomState session:session];
    
    [self updateLinkWithRoomState:roomState];
}

- (NSString *)textMessage
{
    if (!_textMessage)
    {
        _textMessage = _attributedTextMessage.string;
    }
    return _textMessage;
}

- (void)updateLinkWithRoomState:(MXRoomState*)roomState
{
    // Ensure link detection has been enabled
    if (!MXKAppSettings.standardAppSettings.enableBubbleComponentLinkDetection)
    {
        return;
    }
    
    // Only detect links in unencrypted rooms, for un-redacted message events that are text, notice or emote.
    // Specifically check the room's encryption state rather than the event's as outgoing events are always unencrypted initially.
    if (roomState.isEncrypted || self.event.eventType != MXEventTypeRoomMessage || [self.event isRedactedEvent])
    {
        self.link = nil;    // Ensure there's no link for a redacted event
        return;
    }
    
    NSString *messageType = self.event.content[kMXMessageTypeKey];
    
    if (!messageType || !([messageType isEqualToString:kMXMessageTypeText] || [messageType isEqualToString:kMXMessageTypeNotice] || [messageType isEqualToString:kMXMessageTypeEmote]))
    {
        return;
    }
    
    // Detect links in the attributed string which gets updated when the message is edited.
    // Restrict detection to the unquoted string so links are only found in the sender's message.
    NSString *body = [self.attributedTextMessage mxk_unquotedString];
    NSURL *url = [body mxk_firstURLDetected];
    
    if (!url)
    {
        self.link = nil;
        return;
    }
    
    self.link = url;
}

- (EventEncryptionDecoration)encryptionDecorationForEvent:(MXEvent*)event roomState:(MXRoomState*)roomState session:(MXSession*)session
{
    // Warning badges are unnecessary in unencrypted rooms
    if (!roomState.isEncrypted)
    {
        return EventEncryptionDecorationNone;
    }
    
    // Not all events are encrypted (e.g. state/reactions/redactions) and we only have encrypted cell subclasses for messages and attachments.
    if (event.eventType != MXEventTypeRoomMessage && !event.isMediaAttachment)
    {
        return EventEncryptionDecorationNone;
    }
    
    // Always show a warning badge if there was a decryption error.
    if (event.decryptionError)
    {
        return EventEncryptionDecorationDecryptionError;
    }
    
    // Unencrypted message events should show a warning unless they're pending local echoes
    if (!event.isEncrypted)
    {
        if (event.isLocalEvent
            || event.contentHasBeenEdited)    // Local echo for an edit is clear but uses a true event id, the one of the edited event
        {
            return EventEncryptionDecorationNone;
        }
            
        return EventEncryptionDecorationNotEncrypted;
    }
    
    // The encryption is in a good state.
    // Only show a warning badge if there are trust issues.
    if (event.sender)
    {
        MXUserTrustLevel *userTrustLevel = [session.crypto trustLevelForUser:event.sender];
        MXDeviceInfo *deviceInfo = [session.crypto eventDeviceInfo:event];
        
        if (userTrustLevel.isVerified && !deviceInfo.trustLevel.isVerified)
        {
            return EventEncryptionDecorationUntrustedDevice;
        }
    }
    
    if (event.isUntrusted)
    {
        return EventEncryptionDecorationUnsafeKey;
    }
    
    // Everything was fine
    return EventEncryptionDecorationNone;
}

@end

