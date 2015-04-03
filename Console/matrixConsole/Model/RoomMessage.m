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

#import "MatrixSDKHandler.h"
#import "AppSettings.h"
#import "MXCTools.h"

NSString *const kRoomMessageLocalPreviewKey = @"kRoomMessageLocalPreviewKey";
NSString *const kRoomMessageUploadIdKey     = @"kRoomMessageUploadIdKey";

static NSAttributedString *messageSeparator = nil;

@interface RoomMessage() {
    // Array of RoomMessageComponent
    NSMutableArray *messageComponents;
    // Current text message reset at each component change (see attributedTextMessage property)
    NSMutableAttributedString *currentAttributedTextMsg;
    
    BOOL shouldUpdateComponentsHeight;
}

+ (NSAttributedString *)messageSeparator;

@end

@implementation RoomMessage

- (id)initWithEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState {
    if (self = [super init]) {
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        
        _senderId = event.userId;
        _senderName = [mxHandler senderDisplayNameForEvent:event withRoomState:roomState];
        _senderAvatarUrl = [mxHandler senderAvatarUrlForEvent:event withRoomState:roomState];
        _maxTextViewWidth = ROOM_MESSAGE_DEFAULT_MAX_TEXTVIEW_WIDTH;
        _contentSize = CGSizeZero;
        _uploadProgress = -1;
        currentAttributedTextMsg = nil;
        
        // Set message type (consider text by default), and check attachment if any
        _messageType = RoomMessageTypeText;
        if ([mxHandler isSupportedAttachment:event]) {
            // Note: event.eventType is equal here to MXEventTypeRoomMessage
            
            // Set default thumbnail orientation
            _thumbnailOrientation = UIImageOrientationUp;
            
            NSString *msgtype =  event.content[@"msgtype"];
            if ([msgtype isEqualToString:kMXMessageTypeImage]) {
                _messageType = RoomMessageTypeImage;
                // Retrieve content url/info
                _attachmentURL = event.content[@"url"];
                _attachmentInfo = event.content[@"info"];
                // Handle legacy thumbnail url/info (Not defined anymore in recent attachments)
                _thumbnailURL = event.content[@"thumbnail_url"];
                _thumbnailInfo = event.content[@"thumbnail_info"];
                if (!_thumbnailURL) {
                    // Suppose _attachmentURL is a matrix content uri, we use SDK to get the well adapted thumbnail from server
                    _thumbnailURL = [mxHandler thumbnailURLForContent:_attachmentURL inViewSize:self.contentSize withMethod:MXThumbnailingMethodScale];
                    
                    // Check whether the image has been uploaded with an orientation
                    if (_attachmentInfo[@"rotation"]) {
                        // Currently the matrix content server provides thumbnails by ignoring the original image orientation.
                        // We store here the actual orientation to apply it on downloaded thumbnail.
                        _thumbnailOrientation = [MXCTools imageOrientationForRotationAngleInDegree:[_attachmentInfo[@"rotation"] integerValue]];
                        
                        // Rotate the current content size (if need)
                        if (_thumbnailOrientation == UIImageOrientationLeft || _thumbnailOrientation == UIImageOrientationRight) {
                            _contentSize = CGSizeMake(_contentSize.height, _contentSize.width);
                        }
                    }
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
            if (_messageType == RoomMessageTypeText) {
                // Set text range
                msgComponent.range = NSMakeRange(0, msgComponent.textMessage.length);
                
                // Compute the height of the text component
                msgComponent.height = [self rawTextHeight:self.attributedTextMessage];
                shouldUpdateComponentsHeight = NO;
            }
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
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
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
            [self addComponent:addedComponent];
        }
        // else the event is ignored, we consider it as handled
        return YES;
    }
    return NO;
}

- (BOOL)replaceLocalEventId:(NSString *)localEventId withEventId:(NSString *)eventId {
    NSUInteger index = messageComponents.count;
    while (index--) {
        RoomMessageComponent* msgComponent = [messageComponents objectAtIndex:index];
        if ([msgComponent.eventId isEqualToString:localEventId]) {
            msgComponent.eventId = eventId;
            // Refresh global attributed string (if any) to take into account potential component style change
            if (currentAttributedTextMsg) {
                NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:msgComponent.textMessage attributes:[msgComponent stringAttributes]];
                [currentAttributedTextMsg replaceCharactersInRange:msgComponent.range withAttributedString:attributedString];
                
                // Reset content size
                _contentSize = CGSizeZero;
            } // else let the getter "attributedTextMessage" build it
            return YES;
        }
    }
    // here the provided eventId has not been found
    return NO;
}

- (BOOL)removeEvent:(NSString *)eventId {
    if (_messageType == RoomMessageTypeText) {
        NSUInteger index = messageComponents.count;
        while (index--) {
            RoomMessageComponent* msgComponent = [messageComponents objectAtIndex:index];
            if ([msgComponent.eventId isEqualToString:eventId]) {
                [messageComponents removeObjectAtIndex:index];
                
                // Refresh global attributed string (if any)
                if (currentAttributedTextMsg) {
                    if (!messageComponents.count) {
                        // The message is now empty - Reset
                        self.attributedTextMessage = nil;
                    } else {
                        // Update
                        [currentAttributedTextMsg deleteCharactersInRange:msgComponent.range];
                        // Remove a separator
                        NSRange separatorRange = NSMakeRange(0, [RoomMessage messageSeparator].length);
                        if (msgComponent.range.location) {
                            separatorRange.location = msgComponent.range.location - [RoomMessage messageSeparator].length;
                        }
                        [currentAttributedTextMsg deleteCharactersInRange:separatorRange];
                        
                        // Reset content size
                        _contentSize = CGSizeZero;
                    }
                } // else let the getter "attributedTextMessage" build it
                
                // Adjust range for components displayed after this removed component
                NSUInteger deletedLength = msgComponent.range.length + [RoomMessage messageSeparator].length;
                for (; index < messageComponents.count; index++) {
                    msgComponent = [messageComponents objectAtIndex:index];
                    NSRange range = msgComponent.range;
                    NSAssert(range.location >= deletedLength, @"RoomMessage: the ranges of msg components are corrupted");
                    if (range.location >= deletedLength) {
                        range.location -= deletedLength;
                    } else {
                        range.location = 0;
                    }
                    msgComponent.range = range;
                }
                
                // Height of each components should be updated
                shouldUpdateComponentsHeight = YES;
                return YES;
            }
        }
        // here the provided eventId has not been found
    } else {
        // Consider here message with no more than one element
        if (messageComponents.count) {
            RoomMessageComponent *msgComponent = [messageComponents firstObject];
            if ([msgComponent.eventId isEqualToString:eventId]) {
                [messageComponents removeObjectAtIndex:0];
                // Reset content size
                _contentSize = CGSizeZero;
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)updateRedactedEvent:(MXEvent*)redactedEvent {
    // Check whether the provided event is a redacted one
    if (!redactedEvent.redactedBecause) {
        return NO;
    }
    
    if (_messageType == RoomMessageTypeText) {
        NSUInteger index = messageComponents.count;
        while (index--) {
            RoomMessageComponent* msgComponent = [messageComponents objectAtIndex:index];
            if ([msgComponent.eventId isEqualToString:redactedEvent.eventId]) {
                // Update component with redacted event, remove it if the resulting string is empty
                [msgComponent updateWithRedactedEvent:redactedEvent];
                if (!msgComponent.textMessage.length) {
                    [self removeEvent:redactedEvent.eventId];
                } else {
                    // Compute the SIGNED difference of length (old length - new length)
                    NSInteger diffLength = msgComponent.range.length - msgComponent.textMessage.length;
                    
                    // Refresh global attributed string (if any)
                    if (currentAttributedTextMsg) {
                        // Replace the component string
                        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:msgComponent.textMessage attributes:[msgComponent stringAttributes]];
                        [currentAttributedTextMsg replaceCharactersInRange:msgComponent.range withAttributedString:attributedString];
                        
                        // Update the component range
                        NSRange updatedRange = msgComponent.range;
                        updatedRange.length = msgComponent.textMessage.length;
                        msgComponent.range = updatedRange;
                        
                        // Reset content size
                        _contentSize = CGSizeZero;
                    } // else let the getter "attributedTextMessage" build it
                    
                    // Adjust range for components displayed after this updated component
                    for (index++; index < messageComponents.count; index++) {
                        msgComponent = [messageComponents objectAtIndex:index];
                        NSRange range = msgComponent.range;
                        NSAssert((diffLength < 0) || (range.location >= diffLength), @"RoomMessage: the ranges of msg components are corrupted");
                        range.location -= diffLength;
                        msgComponent.range = range;
                    }
                    
                    // Height of each components should be updated
                    shouldUpdateComponentsHeight = YES;
                }
                return YES;
            }
        }
    } else {
        // Consider here message related to attachment (This message has no more than one element)
        if (messageComponents.count) {
            RoomMessageComponent *msgComponent = [messageComponents firstObject];
            if ([msgComponent.eventId isEqualToString:redactedEvent.eventId]) {
                // Redaction removes the attachment information, the message becomes a text message
                _messageType = RoomMessageTypeText;
                _attachmentURL = nil;
                _attachmentInfo = nil;
                _thumbnailURL = nil;
                _thumbnailInfo = nil;
                _previewURL = nil;
                _uploadId = nil;
                _uploadProgress = -1;
                
                [msgComponent updateWithRedactedEvent:redactedEvent];
                if (!msgComponent.textMessage.length) {
                    [self removeEvent:redactedEvent.eventId];
                } else {
                    // Set text range
                    msgComponent.range = NSMakeRange(0, msgComponent.textMessage.length);
                    
                    // Compute the height of the text component
                    msgComponent.height = [self rawTextHeight:self.attributedTextMessage];
                    shouldUpdateComponentsHeight = NO;
                    // Reset content size
                    _contentSize = CGSizeZero;
                }
                return YES;
            }
        }
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
                [self addComponent:msgComponent];
            }
            return YES;
        }
    }
    return NO;
}

- (void)checkComponentsHeight {
    // Check conditions to ignore this action
    if (_messageType != RoomMessageTypeText || !shouldUpdateComponentsHeight || !messageComponents.count) {
        return;
    }
    
    // This method should run on main thread
    if ([NSThread currentThread] != [NSThread mainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self checkComponentsHeight];
        });
        return;
    }
    
    // Compute height of the first component
    RoomMessageComponent *msgComponent = [messageComponents objectAtIndex:0];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:msgComponent.textMessage attributes:[msgComponent stringAttributes]];
    CGSize textContentSize = [self textContentSize:attributedString];
    if (textContentSize.height) {
        msgComponent.height = textContentSize.height - (2 * ROOM_MESSAGE_TEXTVIEW_MARGIN);
    } else {
        msgComponent.height = 0;
    }
    // Compute height of other components
    for (NSUInteger index = 1; index < messageComponents.count; index++) {
        CGFloat previousContentHeight = textContentSize.height ? textContentSize.height : (2 * ROOM_MESSAGE_TEXTVIEW_MARGIN);
        msgComponent = [messageComponents objectAtIndex:index];
        // Append attributed text
        [attributedString appendAttributedString:[RoomMessage messageSeparator]];
        [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:msgComponent.textMessage attributes:[msgComponent stringAttributes]]];
        textContentSize = [self textContentSize:attributedString];
        msgComponent.height = textContentSize.height - previousContentHeight;
    }
    shouldUpdateComponentsHeight = NO;
}

#pragma mark - Properties

- (void)setMaxTextViewWidth:(CGFloat)maxTextViewWidth {
    if (_messageType == RoomMessageTypeText) {
        // Check change
        if (_maxTextViewWidth != maxTextViewWidth) {
            _maxTextViewWidth = maxTextViewWidth;
            // Reset content size
            _contentSize = CGSizeZero;
            // Invalidate existing height for components
            shouldUpdateComponentsHeight = YES;
        }
    }
}

- (CGSize)contentSize {
    if (CGSizeEqualToSize(_contentSize, CGSizeZero)) {
        if (_messageType == RoomMessageTypeText) {
            if ([NSThread currentThread] != [NSThread mainThread]) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    _contentSize = [self textContentSize:self.attributedTextMessage];
                });
            } else {
                _contentSize = [self textContentSize:self.attributedTextMessage];
            }
        } else if (_messageType == RoomMessageTypeImage || _messageType == RoomMessageTypeVideo) {
            CGFloat width, height;
            width = height = 40;
            if (_thumbnailInfo || _attachmentInfo) {
                if (_thumbnailInfo && _thumbnailInfo[@"w"] && _thumbnailInfo[@"h"]) {
                    width = [_thumbnailInfo[@"w"] integerValue];
                    height = [_thumbnailInfo[@"h"] integerValue];
                } else if (_attachmentInfo[@"w"] && _attachmentInfo[@"h"]) {
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
            
            // Check here thumbnail orientation
            if (_thumbnailOrientation == UIImageOrientationLeft || _thumbnailOrientation == UIImageOrientationRight) {
                _contentSize = CGSizeMake(height, width);
            } else {
                _contentSize = CGSizeMake(width, height);
            }
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
    return currentAttributedTextMsg;
}

- (BOOL)startsWithSenderName {
    if (_messageType == RoomMessageTypeText) {
        if (messageComponents.count) {
            RoomMessageComponent *msgComponent = [messageComponents objectAtIndex:0];
            return msgComponent.startsWithSenderName;
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

#pragma mark - Privates

- (void)addComponent:(RoomMessageComponent*)addedComponent {
    // Check date of existing components to insert this new one
    NSUInteger addedTextLength = addedComponent.textMessage.length;
    NSUInteger addedTextLocation = 0;
    NSUInteger separatorLocation = 0;
    NSUInteger index = messageComponents.count;
    while (index) {
        RoomMessageComponent *msgComponent = [messageComponents objectAtIndex:(--index)];
        if ([msgComponent.date compare:addedComponent.date] == NSOrderedDescending) {
            // New component will be inserted before this one -> Adjust text range
            NSRange range = msgComponent.range;
            range.location += (addedTextLength + [RoomMessage messageSeparator].length);
            msgComponent.range = range;
        } else {
            // New component will be inserted here
            index ++;
            addedTextLocation = msgComponent.range.location + msgComponent.range.length;
            break;
        }
    }
    // Insert new component
    [messageComponents insertObject:addedComponent atIndex:index];
    
    // Adjust added component location
    if (addedTextLocation) {
        // We will insert separator before adding new component
        separatorLocation = addedTextLocation;
        addedTextLocation += [RoomMessage messageSeparator].length;
    } else {
        // The new component is inserted in first position, separator will be inserted after it
        separatorLocation = addedTextLength;
    }
    
    // Update global attributed string (if any)
    if (currentAttributedTextMsg) {
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:addedComponent.textMessage attributes:[addedComponent stringAttributes]];
        if (addedTextLocation) {
            // Add separator before added text component
            [currentAttributedTextMsg insertAttributedString:[RoomMessage messageSeparator] atIndex:separatorLocation];
            [currentAttributedTextMsg insertAttributedString:attributedString atIndex:addedTextLocation];
        } else {
            // The new component is inserted in first position
            [currentAttributedTextMsg insertAttributedString:attributedString atIndex:addedTextLocation];
            // Check whether a separator is required
            if (messageComponents.count > 1) {
                [currentAttributedTextMsg insertAttributedString:[RoomMessage messageSeparator] atIndex:separatorLocation];
            }
        }
        
        // Reset content size
        _contentSize = CGSizeZero;
        
    } // Else let the getter "attributedTextMessage" build it
    
    // Set text range
    addedComponent.range = NSMakeRange(addedTextLocation, addedTextLength);
    
    // Height of each components should be computed again
    shouldUpdateComponentsHeight = YES;
}

#pragma mark - Text measuring

// Return the raw height of the provided text by removing any margin
- (CGFloat)rawTextHeight: (NSAttributedString*)attributedText {
    __block CGSize textSize;
    if ([NSThread currentThread] != [NSThread mainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            textSize = [self textContentSize:attributedText];
        });
    } else {
        textSize = [self textContentSize:attributedText];
    }
    
    if (textSize.height) {
        // Return the actual height of the text by removing textview margin from content height
        return (textSize.height - (2 * ROOM_MESSAGE_TEXTVIEW_MARGIN));
    }
    return 0;
}

// Return the content size of a text view initialized with the provided attributed text
// CAUTION: This method runs only on main thread
- (CGSize)textContentSize: (NSAttributedString*)attributedText {
    if (attributedText.length) {
        // Use a TextView template
        UITextView *dummyTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, _maxTextViewWidth, MAXFLOAT)];
        dummyTextView.attributedText = attributedText;
        return [dummyTextView sizeThatFits:dummyTextView.frame.size];
    }
    return CGSizeZero;
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

@end
