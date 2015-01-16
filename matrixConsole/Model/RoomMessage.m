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

NSString *const kRoomMessageLocalPreviewKey = @"kRoomMessageLocalPreviewKey";
NSString *const kRoomMessageUploadIdKey     = @"kRoomMessageUploadIdKey";

static NSAttributedString *messageSeparator = nil;

@interface RoomMessage() {
    // Array of RoomMessageComponent
    NSMutableArray *messageComponents;
    // Current text message reset at each component change (see attributedTextMessage property)
    NSMutableAttributedString *currentAttributedTextMsg;
}

+ (NSAttributedString *)messageSeparator;

@end

@implementation RoomMessage
@synthesize uploadProgress;

- (id)initWithEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState {
    if (self = [super init]) {
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        
        _senderId = event.userId;
        _senderName = [mxHandler senderDisplayNameForEvent:event withRoomState:roomState];
        _senderAvatarUrl = [mxHandler senderAvatarUrlForEvent:event withRoomState:roomState];
        _maxTextViewWidth = ROOM_MESSAGE_DEFAULT_MAX_TEXTVIEW_WIDTH;
        _contentSize = CGSizeZero;
        self.uploadProgress = -1;
        currentAttributedTextMsg = nil;
        
        // Set message type (consider text by default), and check attachment if any
        _messageType = RoomMessageTypeText;
        if ([mxHandler isSupportedAttachment:event]) {
            // Note: event.eventType is equal here to MXEventTypeRoomMessage
            NSString *msgtype =  event.content[@"msgtype"];
            if ([msgtype isEqualToString:kMXMessageTypeImage]) {
                _messageType = RoomMessageTypeImage;
                // Retrieve content url/info
                _attachmentURL = event.content[@"url"];
                _attachmentInfo = event.content[@"info"];
                // Handle thumbnail url/info
                _thumbnailURL = event.content[@"thumbnail_url"];
                _thumbnailInfo = event.content[@"thumbnail_info"];
                if (!_thumbnailURL) {
                    // Suppose _attachmentURL is a matrix content uri, we use SDK to get the well adapted thumbnail from server
                    _thumbnailURL = [mxHandler thumbnailURLForContent:_attachmentURL inViewSize:self.contentSize withMethod:MXThumbnailingMethodScale];
                }
            } else if ([msgtype isEqualToString:kMXMessageTypeAudio]) {
                // Not supported yet
                //_messageType = RoomMessageTypeAudio;
            } else if ([msgtype isEqualToString:kMXMessageTypeVideo]) {
                _messageType = RoomMessageTypeVideo;
                // Retrieve content url/info
                _attachmentURL = event.content[@"url"];
                _attachmentInfo = event.content[@"info"];
                if (_attachmentInfo) {
                    // Get video thumbnail info
                    _thumbnailURL = _attachmentInfo[@"thumbnail_url"];
                    _thumbnailInfo = _attachmentInfo[@"thumbnail_info"];
                }
            } else if ([msgtype isEqualToString:kMXMessageTypeLocation]) {
                // Not supported yet
                // _messageType = RoomMessageTypeLocation;
            }
            // Retrieve local preview url (if any)
            _previewURL = event.content[kRoomMessageLocalPreviewKey];
            // Retrieve upload id (if any)
            _uploadId = event.content[kRoomMessageUploadIdKey];
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
        NSString *eventSenderName = [mxHandler senderDisplayNameForEvent:event withRoomState:roomState];
        NSString *eventSenderAvatar = [mxHandler senderAvatarUrlForEvent:event withRoomState:roomState];
        if ((_senderName || eventSenderName) &&
            ([_senderName isEqualToString:eventSenderName] == NO)) {
            return NO;
        }
        if ((_senderAvatarUrl || eventSenderAvatar) &&
            ([_senderAvatarUrl isEqualToString:eventSenderAvatar] == NO)) {
            return NO;
        }
        
        // Create new message component
        RoomMessageComponent *addedComponent = [[RoomMessageComponent alloc] initWithEvent:event andRoomState:roomState];
        if (addedComponent) {
            [messageComponents addObject:addedComponent];
            // Sort components and update resulting text message
            [self sortComponents];
        }
        // else the event is ignored, we consider it as handled
        return YES;
    }
    return NO;
}

- (BOOL)removeEvent:(NSString *)eventId {
    if (_messageType == RoomMessageTypeText) {
        NSUInteger index = messageComponents.count;
        while (index--) {
            RoomMessageComponent* msgComponent = [messageComponents objectAtIndex:index];
            if ([msgComponent.eventId isEqualToString:eventId]) {
                [messageComponents removeObjectAtIndex:index];
                // Force text message refresh
                [self refreshMessageComponentsHeight];
                return YES;
            }
        }
        // here the provided eventId has not been found
    }
    return NO;
}

- (RoomMessageComponent*)componentWithEventId:(NSString *)eventId {
    for (RoomMessageComponent* msgComponent in messageComponents) {
        if ([msgComponent.eventId isEqualToString:eventId]) {
            return msgComponent;
        }
    }
    return nil;
}

- (BOOL)containsEventId:(NSString *)eventId {
    return nil != [self componentWithEventId:eventId];
}

- (void)hideComponent:(BOOL)isHidden withEventId:(NSString*)eventId {
    for (RoomMessageComponent *msgComponent in messageComponents) {
        if ([msgComponent.eventId isEqualToString:eventId]) {
            msgComponent.hidden = isHidden;
            // Force attributed string refresh
            [self refreshMessageComponentsHeight];
            break;
        }
    }
}

- (BOOL)hasSameSenderAsRoomMessage:(RoomMessage*)roomMessage {
    // NOTE: same sender means here same id, same name and same avatar
    // Check first user id
    if ([_senderId isEqualToString:roomMessage.senderId] == NO) {
        return NO;
    }
    // Check sender name
    if ((_senderName.length || roomMessage.senderName.length) && ([_senderName isEqualToString:roomMessage.senderName] == NO)) {
        return NO;
    }
    // Check avatar url
    if ((_senderAvatarUrl.length || roomMessage.senderAvatarUrl.length) && ([_senderAvatarUrl isEqualToString:roomMessage.senderAvatarUrl] == NO)) {
        return NO;
    }
        
    return YES;
}

- (BOOL)mergeWithRoomMessage:(RoomMessage*)roomMessage {
    if ([self hasSameSenderAsRoomMessage:roomMessage]) {
        if ((_messageType == RoomMessageTypeText) && (roomMessage.messageType == RoomMessageTypeText)) {
            // Add all components of the provided message
            for (RoomMessageComponent* msgComponent in roomMessage.components) {
                [messageComponents addObject:msgComponent];
            }
            // Sort components and update resulting text message
            [self sortComponents];
            return YES;
        }
    }
    return NO;
}

#pragma mark - Properties

- (void)setMaxTextViewWidth:(CGFloat)maxTextViewWidth {
    if (_messageType == RoomMessageTypeText) {
        // Check change
        if (_maxTextViewWidth != maxTextViewWidth) {
            _maxTextViewWidth = maxTextViewWidth;
            // Refresh height for all message components
            [self refreshMessageComponentsHeight];
        }
    }
}

- (CGSize)contentSize {
    if (CGSizeEqualToSize(_contentSize, CGSizeZero)) {
        if (_messageType == RoomMessageTypeText) {
            if (self.attributedTextMessage.length) {
                // Use a TextView template to compute cell height
                // The following code only run on the main thread
                if([NSThread currentThread] != [NSThread mainThread]) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        UITextView *dummyTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, _maxTextViewWidth, MAXFLOAT)];
                        dummyTextView.attributedText = self.attributedTextMessage;
                        _contentSize = [dummyTextView sizeThatFits:dummyTextView.frame.size];
                    });
                } else {
                    UITextView *dummyTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, _maxTextViewWidth, MAXFLOAT)];
                    dummyTextView.attributedText = self.attributedTextMessage;
                    _contentSize = [dummyTextView sizeThatFits:dummyTextView.frame.size];
                }
            }
        } else if (_messageType == RoomMessageTypeImage || _messageType == RoomMessageTypeVideo) {
            CGFloat width, height;
            width = height = 40;
            if (_thumbnailInfo || _attachmentInfo) {
                if (_thumbnailInfo) {
                    width = [_thumbnailInfo[@"w"] integerValue];
                    height = [_thumbnailInfo[@"h"] integerValue];
                } else {
                    width = [_attachmentInfo[@"w"] integerValue];
                    height = [_attachmentInfo[@"h"] integerValue];
                }
               
                if (width > ROOM_MESSAGE_MAX_ATTACHMENTVIEW_WIDTH || height > ROOM_MESSAGE_MAX_ATTACHMENTVIEW_WIDTH) {
                    if (width > height) {
                        height = (height * ROOM_MESSAGE_MAX_ATTACHMENTVIEW_WIDTH) / width;
                        height = floorf(height / 2) * 2;
                        width = ROOM_MESSAGE_MAX_ATTACHMENTVIEW_WIDTH;
                    } else {
                        width = (width * ROOM_MESSAGE_MAX_ATTACHMENTVIEW_WIDTH) / height;
                        width = floorf(width / 2) * 2;
                        height = ROOM_MESSAGE_MAX_ATTACHMENTVIEW_WIDTH;
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
            if (!msgComponent.isHidden) {
                NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:msgComponent.textMessage attributes:[msgComponent stringAttributes]];
                if (!currentAttributedTextMsg) {
                    currentAttributedTextMsg = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
                } else {
                    // Append attributed text
                    [currentAttributedTextMsg appendAttributedString:[RoomMessage messageSeparator]];
                    [currentAttributedTextMsg appendAttributedString:attributedString];
                }
            }
        }
    }
    return currentAttributedTextMsg;
}

- (BOOL)startsWithSenderName {
    if (_messageType == RoomMessageTypeText) {
        NSUInteger index = 0;
        while (index < messageComponents.count) {
            RoomMessageComponent *msgComponent = [messageComponents objectAtIndex:index];
            if (!msgComponent.isHidden) {
                return msgComponent.startsWithSenderName;
            }
            index++;
        }
    }
    return NO;
}

- (BOOL)isUploadInProgress {
    if (_messageType != RoomMessageTypeText) {
        if (messageComponents.count) {
            RoomMessageComponent *msgComponent = [messageComponents firstObject];
            return (msgComponent.style == RoomMessageComponentStyleInProgress);
        }
    }
    return NO;
}

- (BOOL)isHidden {
    if (_messageType == RoomMessageTypeText) {
        return (!self.attributedTextMessage.length);
    } else if (messageComponents.count) {
        RoomMessageComponent *msgComponent = [messageComponents firstObject];
        return msgComponent.isHidden;
    }
    return YES;
}

#pragma mark -

- (void)sortComponents {
    // Sort components according to their date
    [messageComponents sortUsingComparator:^NSComparisonResult(RoomMessageComponent *obj1, RoomMessageComponent *obj2) {
        if (obj1.date) {
            if (obj2.date) {
                return [obj1.date compare:obj2.date];
            } else {
                return NSOrderedAscending;
            }
        } else if (obj2.date) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    // Force text message refresh after sorting
    [self refreshMessageComponentsHeight];
}

- (void)refreshMessageComponentsHeight {
    NSMutableArray *components = messageComponents;
    messageComponents = [NSMutableArray arrayWithCapacity:components.count];
    self.attributedTextMessage = nil;
    for (RoomMessageComponent *msgComponent in components) {
        CGFloat previousTextViewHeight = self.contentSize.height ? self.contentSize.height : (2 * ROOM_MESSAGE_TEXTVIEW_MARGIN);
        [messageComponents addObject:msgComponent];
        if (msgComponent.isHidden) {
            msgComponent.height = 0;
        } else {
            // Force text message refresh
            self.attributedTextMessage = nil;
            msgComponent.height = self.contentSize.height - previousTextViewHeight;
        }
    }
}

+ (NSAttributedString *)messageSeparator {
    @synchronized(self) {
        if(messageSeparator == nil) {
            messageSeparator = [[NSAttributedString alloc] initWithString:@"\r\n\r\n" attributes:@{NSForegroundColorAttributeName : [UIColor blackColor],
                                                                                                    NSFontAttributeName: [UIFont systemFontOfSize:4]}];
        }
    }
    return messageSeparator;
}

@end
