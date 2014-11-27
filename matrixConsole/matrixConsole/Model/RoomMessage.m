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

NSString *const kLocalEchoEventIdPrefix = @"localEcho-";
NSString *const kFailedEventId = @"failedEventId";

static NSDateFormatter *dateFormatter = nil;
static NSAttributedString *messageItemsSeparator = nil;

typedef enum : NSUInteger {
    RoomMessageItemDisplayModeDefault,
    RoomMessageItemDisplayModeHighlighted,
    RoomMessageItemDisplayModeLocalEcho,
    RoomMessageItemDisplayModeFailure,
    RoomMessageItemDisplayModeError
} RoomMessageItemDisplayMode;

@interface RoomMessageItem : NSObject
@property (nonatomic) NSString *textMessage;
@property (nonatomic) NSString *eventId;
@property (nonatomic) NSDate   *date;
@property (nonatomic) RoomMessageItemDisplayMode displayMode;
@property (nonatomic) NSUInteger height;
// True if text message starts with the sender name (see membership events, emote ...)
@property (nonatomic) BOOL startsWithSenderName;

- (id)initWithTextMessage:(NSString*)textMessage andEvent:(MXEvent*)event;
@end

#pragma mark -

@interface RoomMessage() {
    // Array of RoomMessageItem
    NSMutableArray *messageItems;
}

+ (NSDateFormatter *)dateFormatter;
+ (NSAttributedString *)messageItemsSeparator;
+ (NSDictionary*)stringAttributesForDisplayMode:(RoomMessageItemDisplayMode)displayMode;

@end

@implementation RoomMessage

- (id)initWithEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState {
    if (self = [super init]) {
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        
        _senderId = event.userId;
        _senderName = [roomState memberName:event.userId];
        _senderAvatarUrl = [roomState memberWithUserId:event.userId].avatarUrl;
        _contentSize = CGSizeZero;
        
        // Build text message from event
        NSString* textMessage = [mxHandler displayTextForEvent:event withRoomState:roomState inSubtitleMode:NO];
        
        // Set the message type (use Text by default), and check attachment if any
        _messageType = RoomMessageTypeText;
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
        
        if (textMessage) {
            // Create first message item
            RoomMessageItem *msgItem = [[RoomMessageItem alloc] initWithTextMessage:textMessage andEvent:event];
            msgItem.startsWithSenderName = ([textMessage hasPrefix:_senderName] || [mxHandler isEmote:event]);
            messageItems = [NSMutableArray array];
            [messageItems addObject:msgItem];
            msgItem.height = self.contentSize.height;
        }
        else {
            // Ignore this event
            self = nil;
        }
    }
    return self;
}

- (void)dealloc {
    messageItems = nil;
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
        
        NSString* textMessage = [mxHandler displayTextForEvent:event withRoomState:roomState inSubtitleMode:NO];
        if (textMessage) {
            // Create new message item
            RoomMessageItem *addedItem = [[RoomMessageItem alloc] initWithTextMessage:textMessage andEvent:event];
            addedItem.startsWithSenderName = ([textMessage hasPrefix:_senderName] || [mxHandler isEmote:event]);
            // Insert the new item according to its date
            NSUInteger index = messageItems.count;
            NSMutableArray *savedMessageItems = [NSMutableArray arrayWithCapacity:index];
            RoomMessageItem* msgItem;
            if (addedItem.date) {
                while (index--) {
                    msgItem = [messageItems lastObject];
                    if (!msgItem.date || [msgItem.date compare:addedItem.date] == NSOrderedDescending) {
                        [savedMessageItems insertObject:msgItem atIndex:0];
                        [messageItems removeLastObject];
                    } else {
                        break;
                    }
                }
            }
            // Force content size refresh
            _attributedTextMessage = nil;
            _contentSize = CGSizeZero;
            CGFloat previousHeight = self.contentSize.height;
            [messageItems addObject:addedItem];
            // Force content size refresh after adding new item in order to compute its height
            _attributedTextMessage = nil;
            _contentSize = CGSizeZero;
            addedItem.height = self.contentSize.height - previousHeight;
            // Re-add existing message items (later in time than the new one)
            for (msgItem in savedMessageItems) {
                previousHeight = self.contentSize.height;
                [messageItems addObject:msgItem];
                // Force content size refresh after adding new item in order to compute its height
                _attributedTextMessage = nil;
                _contentSize = CGSizeZero;
                msgItem.height = self.contentSize.height - previousHeight;
            }
        }
        // else the event is ignored, we consider it as handled
        return YES;
    }
    return NO;
}

- (BOOL)removeEvent:(NSString *)eventId {
    if (_messageType == RoomMessageTypeText) {
        NSUInteger index = messageItems.count;
        NSMutableArray *savedMessageItems = [NSMutableArray arrayWithCapacity:index];
        RoomMessageItem* msgItem;
        while (index--) {
            msgItem = [messageItems lastObject];
            if ([msgItem.eventId isEqualToString:eventId] == NO) {
                [savedMessageItems insertObject:msgItem atIndex:0];
                [messageItems removeLastObject];
            } else {
                [messageItems removeLastObject];
                _attributedTextMessage = nil;
                _contentSize = CGSizeZero;
                for (msgItem in savedMessageItems) {
                    // Re-add message items
                    CGFloat previousHeight = self.contentSize.height;
                    [messageItems addObject:msgItem];
                    // Force content size refresh after adding new item in order to compute its height
                    _attributedTextMessage = nil;
                    _contentSize = CGSizeZero;
                    msgItem.height = self.contentSize.height - previousHeight;
                }
                return YES;
            }
        }
        // here the provided eventId has not been found, restore message Items and return
        messageItems = savedMessageItems;
    }
    return NO;
}

- (BOOL)containsEventId:(NSString *)eventId {
    for (RoomMessageItem* msgItem in messageItems) {
        if ([msgItem.eventId isEqualToString:eventId]) {
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
                UITextView *dummyTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH, MAXFLOAT)];
                dummyTextView.attributedText = self.attributedTextMessage;
                _contentSize = [dummyTextView sizeThatFits:dummyTextView.frame.size];
            }
        } else if (_messageType == RoomMessageTypeImage || _messageType == RoomMessageTypeVideo) {
            CGFloat width, height;
            width = height = 40;
            if (_thumbnailInfo) {
                width = [_thumbnailInfo[@"w"] integerValue] + 2 * ROOM_MESSAGE_CELL_IMAGE_MARGIN;
                height = [_thumbnailInfo[@"h"] integerValue] + 2 * ROOM_MESSAGE_CELL_IMAGE_MARGIN;
                if (width > ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH || height > ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH) {
                    if (width > height) {
                        height = (height * ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH) / width;
                        height = floorf(height / 2) * 2;
                        width = ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH;
                    } else {
                        width = (width * ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH) / height;
                        width = floorf(width / 2) * 2;
                        height = ROOM_MESSAGE_CELL_MAX_TEXTVIEW_WIDTH;
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

- (NSAttributedString*)attributedTextMessage {
    if (!_attributedTextMessage && messageItems.count) {
        // Create attributed string
        NSMutableAttributedString *mutableAttributedString = nil;
        for (RoomMessageItem* msgItem in messageItems) {
            NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:msgItem.textMessage attributes:[RoomMessage stringAttributesForDisplayMode:msgItem.displayMode]];
            if (!mutableAttributedString) {
                mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
            } else {
                // Append attributed text
                [mutableAttributedString appendAttributedString:[RoomMessage messageItemsSeparator]];
                [mutableAttributedString appendAttributedString:attributedString];
            }
        }
        
        _attributedTextMessage = mutableAttributedString;
    }
    return _attributedTextMessage;
}

- (BOOL)startsWithSenderName {
    if (_messageType == RoomMessageTypeText) {
        if (messageItems.count) {
            RoomMessageItem *msgItem = [messageItems firstObject];
            return msgItem.startsWithSenderName;
        }
    }
    return NO;
}

- (BOOL)isUploadInProgress {
    if (_messageType != RoomMessageTypeText) {
        if (messageItems.count) {
            RoomMessageItem *msgItem = [messageItems firstObject];
            return (msgItem.displayMode == RoomMessageItemDisplayModeLocalEcho);
        }
    }
    return NO;
}

#pragma mark -

+ (NSDateFormatter *)dateFormatter {
    @synchronized(self) {
        if(dateFormatter == nil) {
            NSString *dateFormat = @"MMM dd HH:mm";
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0]]];
            [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
            [dateFormatter setDateFormat:dateFormat];
        }
    }
    return dateFormatter;
}

+ (NSAttributedString *)messageItemsSeparator {
    @synchronized(self) {
        if(messageItemsSeparator == nil) {
            messageItemsSeparator = [[NSAttributedString alloc] initWithString:@"\r\n\r\n" attributes:@{NSForegroundColorAttributeName : [UIColor blackColor],
                                                                                                    NSFontAttributeName: [UIFont systemFontOfSize:4]}];
        }
    }
    return messageItemsSeparator;
}

+ (NSDictionary*)stringAttributesForDisplayMode:(RoomMessageItemDisplayMode)displayMode {
    UIColor *textColor;
    switch (displayMode) {
        case RoomMessageItemDisplayModeDefault:
            textColor = [UIColor blackColor];
            break;
        case RoomMessageItemDisplayModeHighlighted:
            textColor = [UIColor blueColor];
            break;
        case RoomMessageItemDisplayModeLocalEcho:
            textColor = [UIColor lightGrayColor];
            break;
        case RoomMessageItemDisplayModeFailure:
        case RoomMessageItemDisplayModeError:
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

# pragma mark -

@implementation RoomMessageItem

- (id)initWithTextMessage:(NSString*)textMessage andEvent:(MXEvent*)event {
    if (self = [super init]) {
        _textMessage = textMessage;
        _eventId = event.eventId;
        _height = 0;
        
        // Set date time text label
        if (event.originServerTs != kMXUndefinedTimestamp) {
            _date = [NSDate dateWithTimeIntervalSince1970:event.originServerTs/1000];
//            NSString* dateTime = [[RoomMessage dateFormatter] stringFromDate:_date];
        } else {
            _date = nil;
        }
        
        // Set display mode
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        BOOL isIncomingMsg = ([event.userId isEqualToString:mxHandler.userId] == NO);
        if ([textMessage hasPrefix:kMatrixHandlerUnsupportedMessagePrefix]) {
            _displayMode = RoomMessageItemDisplayModeError;
        } else if ([_eventId hasPrefix:kFailedEventId]) {
            _displayMode = RoomMessageItemDisplayModeFailure;
        } else if (isIncomingMsg && ([textMessage rangeOfString:mxHandler.userDisplayName options:NSCaseInsensitiveSearch].location != NSNotFound || [textMessage rangeOfString:mxHandler.userId options:NSCaseInsensitiveSearch].location != NSNotFound)) {
            _displayMode = RoomMessageItemDisplayModeHighlighted;
        } else if (!isIncomingMsg && [_eventId hasPrefix:kLocalEchoEventIdPrefix]) {
            _displayMode = RoomMessageItemDisplayModeLocalEcho;
        } else {
            _displayMode = RoomMessageItemDisplayModeDefault;
        }
    }
    return self;
}
@end

