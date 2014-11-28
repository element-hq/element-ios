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

#import "RoomMessage.h"

#import "MatrixHandler.h"
#import "AppSettings.h"

static NSAttributedString *messageSeparator = nil;

@interface RoomMessage() {
    // Array of RoomMessageComponent
    NSMutableArray *messageComponents;
    // Current text message reset at each component change (see attributedTextMessage property)
    NSMutableAttributedString *currentAttributedTextMsg;
}

+ (NSAttributedString *)messageSeparator;
+ (NSDictionary *)stringAttributesForComponentStatus:(RoomMessageComponentStatus)status;

@end

@implementation RoomMessage

- (id)initWithEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState {
    if (self = [super init]) {
        _senderId = event.userId;
        _senderName = [roomState memberName:event.userId];
        _senderAvatarUrl = [roomState memberWithUserId:event.userId].avatarUrl;
        _contentSize = CGSizeZero;
        currentAttributedTextMsg = nil;
        
        // Set message type (consider text by default), and check attachment if any
        _messageType = RoomMessageTypeText;
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        if ([mxHandler isSupportedAttachment:event]) {
            // Note: event.eventType is equal here to MXEventTypeRoomMessage
            NSString *msgtype =  event.content[@"msgtype"];
            if ([msgtype isEqualToString:kMXMessageTypeImage]) {
                _messageType = RoomMessageTypeImage;
                
                _attachmentURL = event.content[@"url"];
                _attachmentInfo = event.content[@"info"];
                _thumbnailURL = event.content[@"thumbnail_url"];
                _thumbnailInfo = event.content[@"thumbnail_info"];
            } else if ([msgtype isEqualToString:kMXMessageTypeAudio]) {
                // Not supported yet
                //_messageType = RoomMessageTypeAudio;
            } else if ([msgtype isEqualToString:kMXMessageTypeVideo]) {
                _messageType = RoomMessageTypeVideo;
                _attachmentURL = event.content[@"url"];
                _attachmentInfo = event.content[@"info"];
                if (_attachmentInfo) {
                    _thumbnailURL = _attachmentInfo[@"thumbnail_url"];
                    _thumbnailInfo = _attachmentInfo[@"thumbnail_info"];
                }
            } else if ([msgtype isEqualToString:kMXMessageTypeLocation]) {
                // Not supported yet
                // _messageType = RoomMessageTypeLocation;
            }
        }
        
        // Set first component of the current message
        RoomMessageComponent *msgComponent = [[RoomMessageComponent alloc] initWithEvent:event andRoomState:roomState];
        if (msgComponent) {
            messageComponents = [NSMutableArray array];
            [messageComponents addObject:msgComponent];
            // Store the actual height of the text by removing textview margin from content height
            msgComponent.height = self.contentSize.height - (2 * ROOM_MESSAGE_TEXTVIEW_MARGIN);
        } else {
            // Ignore this event
            self = nil;
        }
    }
    return self;
}

- (void)dealloc {
    messageComponents = nil;
}

- (BOOL)addEvent:(MXEvent *)event withRoomState:(MXRoomState*)roomState {
    // We group together text messages from the same user
    if ([event.userId isEqualToString:_senderId] && (_messageType == RoomMessageTypeText)) {
        // Attachments (image, video ...) cannot be added here
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        if ([mxHandler isSupportedAttachment:event]) {
            return NO;
        }
        
        // Check sender information
        if ((_senderName || [roomState memberName:event.userId]) &&
            ([_senderName isEqualToString:[roomState memberName:event.userId]] == NO)) {
            return NO;
        }
        if ((_senderAvatarUrl || [roomState memberWithUserId:event.userId].avatarUrl) &&
            ([_senderAvatarUrl isEqualToString:[roomState memberWithUserId:event.userId].avatarUrl] == NO)) {
            return NO;
        }
        
        // Create new message component
        RoomMessageComponent *addedComponent = [[RoomMessageComponent alloc] initWithEvent:event andRoomState:roomState];
        if (addedComponent) {
            // Insert the new component according to its date
            NSUInteger index = messageComponents.count;
            NSMutableArray *savedComponents = [NSMutableArray arrayWithCapacity:index];
            RoomMessageComponent* msgComponent;
            if (addedComponent.date) {
                while (index--) {
                    msgComponent = [messageComponents lastObject];
                    if (!msgComponent.date || [msgComponent.date compare:addedComponent.date] == NSOrderedDescending) {
                        [savedComponents insertObject:msgComponent atIndex:0];
                        [messageComponents removeLastObject];
                    } else {
                        break;
                    }
                }
            }
            // Force text message refresh
            self.attributedTextMessage = nil;
            CGFloat previousTextViewHeight = self.contentSize.height ? self.contentSize.height : (2 * ROOM_MESSAGE_TEXTVIEW_MARGIN);
            [messageComponents addObject:addedComponent];
            // Force text message refresh after adding new component in order to compute its height
            self.attributedTextMessage = nil;
            addedComponent.height = self.contentSize.height - previousTextViewHeight;
            // Re-add existing message components (later in time than the new one)
            for (msgComponent in savedComponents) {
                previousTextViewHeight = self.contentSize.height ? self.contentSize.height : (2 * ROOM_MESSAGE_TEXTVIEW_MARGIN);
                [messageComponents addObject:msgComponent];
                // Force text message refresh
                self.attributedTextMessage = nil;
                msgComponent.height = self.contentSize.height - previousTextViewHeight;
            }
        }
        // else the event is ignored, we consider it as handled
        return YES;
    }
    return NO;
}

- (BOOL)removeEvent:(NSString *)eventId {
    if (_messageType == RoomMessageTypeText) {
        NSUInteger index = messageComponents.count;
        NSMutableArray *savedComponents = [NSMutableArray arrayWithCapacity:index];
        RoomMessageComponent* msgComponent;
        while (index--) {
            msgComponent = [messageComponents lastObject];
            if ([msgComponent.eventId isEqualToString:eventId] == NO) {
                [savedComponents insertObject:msgComponent atIndex:0];
                [messageComponents removeLastObject];
            } else {
                [messageComponents removeLastObject];
                // Force text message refresh
                self.attributedTextMessage = nil;
                for (msgComponent in savedComponents) {
                    // Re-add message components
                    CGFloat previousTextViewHeight = self.contentSize.height ? self.contentSize.height : (2 * ROOM_MESSAGE_TEXTVIEW_MARGIN);
                    [messageComponents addObject:msgComponent];
                    self.attributedTextMessage = nil;
                    msgComponent.height = self.contentSize.height - previousTextViewHeight;
                }
                return YES;
            }
        }
        // here the provided eventId has not been found, restore message components and return
        messageComponents = savedComponents;
    }
    return NO;
}

- (BOOL)containsEventId:(NSString *)eventId {
    for (RoomMessageComponent* msgComponent in messageComponents) {
        if ([msgComponent.eventId isEqualToString:eventId]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark -

- (CGSize)contentSize {
    if (CGSizeEqualToSize(_contentSize, CGSizeZero)) {
        if (_messageType == RoomMessageTypeText) {
            if (self.attributedTextMessage.length) {
                // Use a TextView template to compute cell height
                UITextView *dummyTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, ROOM_MESSAGE_MAX_TEXTVIEW_WIDTH, MAXFLOAT)];
                dummyTextView.attributedText = self.attributedTextMessage;
                _contentSize = [dummyTextView sizeThatFits:dummyTextView.frame.size];
            }
        } else if (_messageType == RoomMessageTypeImage || _messageType == RoomMessageTypeVideo) {
            CGFloat width, height;
            width = height = 40;
            if (_thumbnailInfo) {
                width = [_thumbnailInfo[@"w"] integerValue] + 2 * ROOM_MESSAGE_IMAGE_MARGIN;
                height = [_thumbnailInfo[@"h"] integerValue] + 2 * ROOM_MESSAGE_IMAGE_MARGIN;
                if (width > ROOM_MESSAGE_MAX_TEXTVIEW_WIDTH || height > ROOM_MESSAGE_MAX_TEXTVIEW_WIDTH) {
                    if (width > height) {
                        height = (height * ROOM_MESSAGE_MAX_TEXTVIEW_WIDTH) / width;
                        height = floorf(height / 2) * 2;
                        width = ROOM_MESSAGE_MAX_TEXTVIEW_WIDTH;
                    } else {
                        width = (width * ROOM_MESSAGE_MAX_TEXTVIEW_WIDTH) / height;
                        width = floorf(width / 2) * 2;
                        height = ROOM_MESSAGE_MAX_TEXTVIEW_WIDTH;
                    }
                }
            }
            _contentSize = CGSizeMake(width, height);
        } else {
            _contentSize = CGSizeMake(40, 40);
        }
    }
    return _contentSize;
}

- (NSArray*)components {
    return [messageComponents copy];
}

- (void)setAttributedTextMessage:(NSAttributedString *)inAttributedTextMessage {
    if (!inAttributedTextMessage.length) {
        currentAttributedTextMsg = nil;
    } else {
        currentAttributedTextMsg = [[NSMutableAttributedString alloc] initWithAttributedString:inAttributedTextMessage];
    }
    // Reset content size
    _contentSize = CGSizeZero;
}

- (NSAttributedString*)attributedTextMessage {
    if (!currentAttributedTextMsg && messageComponents.count) {
        // Create attributed string
        for (RoomMessageComponent* msgComponent in messageComponents) {
            NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:msgComponent.textMessage attributes:[RoomMessage stringAttributesForComponentStatus:msgComponent.status]];
            if (!currentAttributedTextMsg) {
                currentAttributedTextMsg = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
            } else {
                // Append attributed text
                [currentAttributedTextMsg appendAttributedString:[RoomMessage messageSeparator]];
                [currentAttributedTextMsg appendAttributedString:attributedString];
            }
        }
    }
    return currentAttributedTextMsg;
}

- (BOOL)startsWithSenderName {
    if (_messageType == RoomMessageTypeText) {
        if (messageComponents.count) {
            RoomMessageComponent *msgComponent = [messageComponents firstObject];
            return msgComponent.startsWithSenderName;
        }
    }
    return NO;
}

- (BOOL)isUploadInProgress {
    if (_messageType != RoomMessageTypeText) {
        if (messageComponents.count) {
            RoomMessageComponent *msgComponent = [messageComponents firstObject];
            return (msgComponent.status == RoomMessageComponentStatusInProgress);
        }
    }
    return NO;
}

#pragma mark -

+ (NSAttributedString *)messageSeparator {
    @synchronized(self) {
        if(messageSeparator == nil) {
            messageSeparator = [[NSAttributedString alloc] initWithString:@"\r\n\r\n" attributes:@{NSForegroundColorAttributeName : [UIColor blackColor],
                                                                                                    NSFontAttributeName: [UIFont systemFontOfSize:4]}];
        }
    }
    return messageSeparator;
}

+ (NSDictionary*)stringAttributesForComponentStatus:(RoomMessageComponentStatus)status {
    UIColor *textColor;
    switch (status) {
        case RoomMessageComponentStatusNormal:
            textColor = [UIColor blackColor];
            break;
        case RoomMessageComponentStatusHighlighted:
            textColor = [UIColor blueColor];
            break;
        case RoomMessageComponentStatusInProgress:
            textColor = [UIColor lightGrayColor];
            break;
        case RoomMessageComponentStatusFailed:
        case RoomMessageComponentStatusUnsupported:
            textColor = [UIColor redColor];
            break;
        default:
            textColor = [UIColor blackColor];
            break;
    }
    
    return @{
             NSForegroundColorAttributeName : textColor,
             NSFontAttributeName: [UIFont systemFontOfSize:14]
             };
}

@end
