/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd

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

#define MXKROOMBUBBLECELLDATA_MAX_ATTACHMENTVIEW_WIDTH 192

#define MXKROOMBUBBLECELLDATA_DEFAULT_MAX_TEXTVIEW_WIDTH 200

@import MatrixSDK;

#import "MXKRoomBubbleCellData.h"

#import "MXKTools.h"

#import "GeneratedInterface-Swift.h"

@implementation MXKRoomBubbleCellData
@synthesize senderId, targetId, roomId, senderDisplayName, senderAvatarUrl, senderAvatarPlaceholder, targetDisplayName, targetAvatarUrl, targetAvatarPlaceholder, isEncryptedRoom, isPaginationFirstBubble, shouldHideSenderInformation, date, isIncoming, isAttachmentWithThumbnail, isAttachmentWithIcon, attachment;
@synthesize textMessage, attributedTextMessage, attributedTextMessageWithoutPositioningSpace;
@synthesize shouldHideSenderName, isTyping, showBubbleDateTime, showBubbleReceipts, useCustomDateTimeLabel, useCustomReceipts, useCustomUnsentButton, hasNoDisplay;
@synthesize tag;
@synthesize collapsable, collapsed, collapsedAttributedTextMessage, prevCollapsableCellData, nextCollapsableCellData, collapseState;

#pragma mark - MXKRoomBubbleCellDataStoring

- (instancetype)initWithEvent:(MXEvent *)event andRoomState:(MXRoomState *)roomState andRoomDataSource:(MXKRoomDataSource *)roomDataSource
{
    self = [self init];
    if (self)
    {
        self->roomDataSource = roomDataSource;

        // Initialize read receipts
        self.readReceipts = [NSMutableDictionary dictionary];
        
        // Create the bubble component based on matrix event
        MXKRoomBubbleComponent *firstComponent = [[MXKRoomBubbleComponent alloc] initWithEvent:event
                                                                                     roomState:roomState
                                                                            andLatestRoomState:roomDataSource.roomState
                                                                                eventFormatter:roomDataSource.eventFormatter
                                                                                       session:roomDataSource.mxSession];
        if (firstComponent)
        {
            bubbleComponents = [NSMutableArray array];
            [bubbleComponents addObject:firstComponent];
            
            senderId = event.sender;
            if ([event.type isEqualToString:kMXEventTypeStringRoomMember])
            {
                MXRoomMemberEventContent *content = [MXRoomMemberEventContent modelFromJSON:event.content];
                if (![content.membership isEqualToString:kMXMembershipStringJoin])
                {
                    targetId = event.stateKey;
                }
                else
                {
                    targetId = event.sender;
                }
            }
            else
            {
                targetId = nil;
            }
            roomId = roomDataSource.roomId;

            // If `roomScreenUseOnlyLatestUserAvatarAndName`is enabled, the avatar and name are
            // displayed from the latest room state perspective rather than the historical.
            MXRoomState *latestRoomState = roomDataSource.roomState;
            MXRoomState *displayRoomState = RiotSettings.shared.roomScreenUseOnlyLatestUserAvatarAndName ? latestRoomState : roomState;
            [self setRoomState:displayRoomState];
            senderAvatarPlaceholder = nil;
            targetAvatarPlaceholder = nil;

            // Encryption status should always rely on the `MXRoomState`
            // from the event rather than the latest.
            isEncryptedRoom = roomState.isEncrypted;
            isIncoming = ([event.sender isEqualToString:roomDataSource.mxSession.myUser.userId] == NO);
            
            // Check attachment if any
            if ([roomDataSource.eventFormatter isSupportedAttachment:event])
            {
                // Note: event.eventType is equal here to MXEventTypeRoomMessage or MXEventTypeSticker
                attachment = [[MXKAttachment alloc] initWithEvent:event andMediaManager:roomDataSource.mxSession.mediaManager];
                if (attachment && attachment.type == MXKAttachmentTypeImage)
                {
                    // Check the current thumbnail orientation. Rotate the current content size (if need)
                    if (attachment.thumbnailOrientation == UIImageOrientationLeft || attachment.thumbnailOrientation == UIImageOrientationRight)
                    {
                        _contentSize = CGSizeMake(_contentSize.height, _contentSize.width);
                    }
                }
            }
            
            // Report the attributed string (This will initialize _contentSize attribute)
            self.attributedTextMessage = firstComponent.attributedTextMessage;
            
            // Initialize rendering attributes
            _maxTextViewWidth = MXKROOMBUBBLECELLDATA_DEFAULT_MAX_TEXTVIEW_WIDTH;
        }
        else
        {
            // Ignore this event
            self = nil;
        }
    }
    return self;
}

- (void)dealloc
{
    roomDataSource = nil;
    bubbleComponents = nil;
}

- (void)refreshProfilesIfNeeded:(MXRoomState *)latestRoomState
{
    if (RiotSettings.shared.roomScreenUseOnlyLatestUserAvatarAndName)
    {
        [self setRoomState:latestRoomState];
    }
}

/**
 Sets the `MXRoomState` for a buble cell. This allows to adapt the display
 of a cell with a different room state than its historical. This won't update critical
 flag/status, such as `isEncryptedRoom`.

 @param roomState the `MXRoomState` to use for this cell.
 */
- (void)setRoomState:(MXRoomState *)roomState;
{
    MXEvent* firstEvent = self.events.firstObject;

    if (firstEvent == nil || roomState == nil)
    {
        return;
    }

    senderDisplayName = [roomDataSource.eventFormatter senderDisplayNameForEvent:firstEvent
                                                                   withRoomState:roomState];
    senderAvatarUrl = [roomDataSource.eventFormatter senderAvatarUrlForEvent:firstEvent
                                                               withRoomState:roomState];
    targetDisplayName = [roomDataSource.eventFormatter targetDisplayNameForEvent:firstEvent
                                                                   withRoomState:roomState];
    targetAvatarUrl = [roomDataSource.eventFormatter targetAvatarUrlForEvent:firstEvent
                                                               withRoomState:roomState];
}

- (NSUInteger)updateEvent:(NSString *)eventId withEvent:(MXEvent *)event
{
    NSUInteger count = 0;

    @synchronized(bubbleComponents)
    {
        // Retrieve the component storing the event and update it
        for (NSUInteger index = 0; index < bubbleComponents.count; index++)
        {
            MXKRoomBubbleComponent *roomBubbleComponent = [bubbleComponents objectAtIndex:index];
            if ([roomBubbleComponent.event.eventId isEqualToString:eventId])
            {
                [roomBubbleComponent updateWithEvent:event
                                           roomState:roomDataSource.roomState
                                  andLatestRoomState:nil
                                             session:self.mxSession];
                if (!roomBubbleComponent.textMessage.length)
                {
                    [bubbleComponents removeObjectAtIndex:index];
                }
                // Indicate that the text message layout should be recomputed.
                [self invalidateTextLayout];
                
                // Handle here attachment update.
                // For example: the case of update of attachment event happens when an echo is replaced by its true event
                // received back by the events stream.
                if (attachment)
                {
                    // Check the current content url, to update it with the actual one
                    // Retrieve content url/info
                    NSString *eventContentURL = event.content[@"url"];
                    if (event.content[@"file"][@"url"])
                    {
                        eventContentURL = event.content[@"file"][@"url"];
                    }
                    
                    if (!eventContentURL.length)
                    {
                        // The attachment has been redacted.
                        attachment = nil;
                        _contentSize = CGSizeZero;
                    }
                    else if (![attachment.eventId isEqualToString:event.eventId] || ![attachment.contentURL isEqualToString:eventContentURL])
                    {
                        MXKAttachment *updatedAttachment = [[MXKAttachment alloc] initWithEvent:event andMediaManager:roomDataSource.mxSession.mediaManager];
                        
                        // Sanity check on attachment type
                        if (updatedAttachment && attachment.type == updatedAttachment.type)
                        {
                            // Re-use the current image as preview to prevent the cell from flashing
                            updatedAttachment.previewImage = [attachment getCachedThumbnail];
                            if (!updatedAttachment.previewImage && attachment.type == MXKAttachmentTypeImage)
                            {
                                updatedAttachment.previewImage = [MXMediaManager loadPictureFromFilePath:attachment.cacheFilePath];
                            }
                            
                            // Clean the cache by removing the useless data
                            if (![updatedAttachment.cacheFilePath isEqualToString:attachment.cacheFilePath])
                            {
                                [[NSFileManager defaultManager] removeItemAtPath:attachment.cacheFilePath error:nil];
                            }
                            if (![updatedAttachment.thumbnailCachePath isEqualToString:attachment.thumbnailCachePath])
                            {
                                [[NSFileManager defaultManager] removeItemAtPath:attachment.thumbnailCachePath error:nil];
                            }
                            
                            // Update the current attachment description
                            attachment = updatedAttachment;
                            
                            if (attachment.type == MXKAttachmentTypeImage)
                            {
                                // Reset content size
                                _contentSize = CGSizeZero;
                                
                                // Check the current thumbnail orientation. Rotate the current content size (if need)
                                if (attachment.thumbnailOrientation == UIImageOrientationLeft || attachment.thumbnailOrientation == UIImageOrientationRight)
                                {
                                    _contentSize = CGSizeMake(_contentSize.height, _contentSize.width);
                                }
                            }
                        }
                        else
                        {
                            MXLogDebug(@"[MXKRoomBubbleCellData] updateEvent: Warning: Does not support change of attachment type");
                        }
                    }
                }
                else if ([roomDataSource.eventFormatter isSupportedAttachment:event])
                {
                    // The event is updated to an event with attachement
                    attachment = [[MXKAttachment alloc] initWithEvent:event andMediaManager:roomDataSource.mxSession.mediaManager];
                    if (attachment && attachment.type == MXKAttachmentTypeImage)
                    {
                        // Check the current thumbnail orientation. Rotate the current content size (if need)
                        if (attachment.thumbnailOrientation == UIImageOrientationLeft || attachment.thumbnailOrientation == UIImageOrientationRight)
                        {
                            _contentSize = CGSizeMake(_contentSize.height, _contentSize.width);
                        }
                    }
                }

                break;
            }
        }
        
        count = bubbleComponents.count;
    }
    
    return count;
}

- (NSUInteger)removeEvent:(NSString *)eventId
{
    NSUInteger count = 0;
    
    @synchronized(bubbleComponents)
    {
        for (MXKRoomBubbleComponent *roomBubbleComponent in bubbleComponents)
        {
            if ([roomBubbleComponent.event.eventId isEqualToString:eventId])
            {
                [bubbleComponents removeObject:roomBubbleComponent];
                
                // Indicate that the text message layout should be recomputed.
                [self invalidateTextLayout];
                
                break;
            }
        }
        
        count = bubbleComponents.count;
    }

    return count;
}

- (NSUInteger)removeEventsFromEvent:(NSString*)eventId removedEvents:(NSArray<MXEvent*>**)removedEvents;
{
    NSMutableArray *cuttedEvents = [NSMutableArray array];

    @synchronized(bubbleComponents)
    {
        NSInteger componentIndex = [self bubbleComponentIndexForEventId:eventId];

        if (NSNotFound != componentIndex)
        {
            NSArray *newBubbleComponents = [bubbleComponents subarrayWithRange:NSMakeRange(0, componentIndex)];

            for (NSUInteger i = componentIndex; i < bubbleComponents.count; i++)
            {
                MXKRoomBubbleComponent *roomBubbleComponent = bubbleComponents[i];
                [cuttedEvents addObject:roomBubbleComponent.event];
            }

            bubbleComponents = [NSMutableArray arrayWithArray:newBubbleComponents];

            // Indicate that the text message layout should be recomputed.
            [self invalidateTextLayout];
        }
    }

    *removedEvents = cuttedEvents;
    return bubbleComponents.count;
}

- (BOOL)hasSameSenderAsBubbleCellData:(id<MXKRoomBubbleCellDataStoring>)bubbleCellData
{
    // Sanity check: accept only object of MXKRoomBubbleCellData classes or sub-classes
    NSParameterAssert([bubbleCellData isKindOfClass:[MXKRoomBubbleCellData class]]);
    
    // NOTE: Same sender means here same id, same display name and same avatar
    
    // Check first user id
    if ([senderId isEqualToString:bubbleCellData.senderId] == NO)
    {
        return NO;
    }
    // Check sender name
    if ((senderDisplayName.length || bubbleCellData.senderDisplayName.length) && ([senderDisplayName isEqualToString:bubbleCellData.senderDisplayName] == NO))
    {
        return NO;
    }
    // Check avatar url
    if ((senderAvatarUrl.length || bubbleCellData.senderAvatarUrl.length) && ([senderAvatarUrl isEqualToString:bubbleCellData.senderAvatarUrl] == NO))
    {
        return NO;
    }
    
    return YES;
}

- (MXKRoomBubbleComponent*) getFirstBubbleComponent
{
    MXKRoomBubbleComponent* first = nil;
    
    @synchronized(bubbleComponents)
    {
        if (bubbleComponents.count)
        {
            first = [bubbleComponents firstObject];
        }
    }
    
    return first;
}

- (MXKRoomBubbleComponent*)getFirstBubbleComponentWithDisplay
{
    // Look for the first component which is actually displayed (some event are ignored in room history display).
    MXKRoomBubbleComponent* first = nil;
    
    @synchronized(bubbleComponents)
    {
        for (MXKRoomBubbleComponent *component in bubbleComponents)
        {
            if (component.attributedTextMessage)
            {
                first = component;
                break;
            }
        }
    }
    
    return first;
}

- (MXKRoomBubbleComponent*)getLastBubbleComponentWithDisplay
{
    // Look for the first component which is actually displayed (some event are ignored in room history display).
    MXKRoomBubbleComponent* lastVisibleComponent = nil;

    @synchronized(bubbleComponents)
    {
        for (MXKRoomBubbleComponent *component in bubbleComponents.reverseObjectEnumerator)
        {
            if (component.attributedTextMessage)
            {
                lastVisibleComponent = component;
                break;
            }
        }
    }

    return lastVisibleComponent;
}

- (NSAttributedString*)attributedTextMessageWithHighlightedEvent:(NSString*)eventId tintColor:(UIColor*)tintColor
{
    NSAttributedString *customAttributedTextMsg;
    
    // By default only one component is supported, consider here the first component
    MXKRoomBubbleComponent *firstComponent = [self getFirstBubbleComponent];
    
    if (firstComponent)
    {
        customAttributedTextMsg = firstComponent.attributedTextMessage;
        
        // Sanity check
        if (customAttributedTextMsg && [firstComponent.event.eventId isEqualToString:eventId])
        {
            NSMutableAttributedString *customComponentString = [[NSMutableAttributedString alloc] initWithAttributedString:customAttributedTextMsg];
            UIColor *color = tintColor ? tintColor : [UIColor lightGrayColor];
            [customComponentString addAttribute:NSBackgroundColorAttributeName value:color range:NSMakeRange(0, customComponentString.length)];
            customAttributedTextMsg = customComponentString;
        }
    }

    return customAttributedTextMsg;
}

- (void)highlightPatternInTextMessage:(NSString*)pattern
                  withBackgroundColor:(UIColor *)backgroundColor
                      foregroundColor:(UIColor*)foregroundColor
                              andFont:(UIFont*)patternFont
{
    highlightedPattern = pattern;
    highlightedPatternBackgroundColor = backgroundColor;
    highlightedPatternForegroundColor = foregroundColor;
    highlightedPatternFont = patternFont;
    
    // Indicate that the text message layout should be recomputed.
    [self invalidateTextLayout];
}

- (void)setShouldHideSenderInformation:(BOOL)inShouldHideSenderInformation
{
    shouldHideSenderInformation = inShouldHideSenderInformation;
}

- (BOOL)hasThreadRoot
{
    @synchronized (bubbleComponents)
    {
        for (MXKRoomBubbleComponent *component in bubbleComponents)
        {
            if (component.thread)
            {
                return YES;
            }
        }
    }

    return NO;
}

#pragma mark -

- (void)invalidateTextLayout
{
    self.attributedTextMessage = nil;
}

- (void)prepareBubbleComponentsPosition
{
    // Consider here only the first component if any
    MXKRoomBubbleComponent *firstComponent = [self getFirstBubbleComponent];
    
    if (firstComponent)
    {
        CGFloat positionY = (attachment == nil || attachment.type == MXKAttachmentTypeFile || attachment.type == MXKAttachmentTypeAudio || attachment.type == MXKAttachmentTypeVoiceMessage) ? MXKROOMBUBBLECELLDATA_TEXTVIEW_DEFAULT_VERTICAL_INSET : 0;
        firstComponent.position = CGPointMake(0, positionY);
    }
}

- (NSInteger)bubbleComponentIndexForEventId:(NSString *)eventId
{
    return [self.bubbleComponents indexOfObjectPassingTest:^BOOL(MXKRoomBubbleComponent * _Nonnull bubbleComponent, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([bubbleComponent.event.eventId isEqualToString:eventId])
        {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
}

#pragma mark - Text measuring

// Return the raw height of the provided text by removing any margin
- (CGFloat)rawTextHeight: (NSAttributedString*)attributedText
{
    __block CGSize textSize;
    if ([NSThread currentThread] != [NSThread mainThread])
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            textSize = [self textContentSize:attributedText removeVerticalInset:YES];
        });
    }
    else
    {
        textSize = [self textContentSize:attributedText removeVerticalInset:YES];
    }
    
    return textSize.height;
}

- (CGSize)textContentSize:(NSAttributedString*)attributedText removeVerticalInset:(BOOL)removeVerticalInset
{
    static UITextView* measurementTextView = nil;
    static UITextView* measurementTextViewWithoutInset = nil;
    
    if (attributedText.length)
    {
        if (!measurementTextView)
        {
            measurementTextView = [[UITextView alloc] init];
            
            measurementTextViewWithoutInset = [[UITextView alloc] init];
            // Remove the container inset: this operation impacts only the vertical margin.
            // Note: consider textContainer.lineFragmentPadding to remove horizontal margin
            measurementTextViewWithoutInset.textContainerInset = UIEdgeInsetsZero;
        }
        
        // Select the right text view for measurement
        UITextView *selectedTextView = (removeVerticalInset ? measurementTextViewWithoutInset : measurementTextView);
        
        selectedTextView.frame = CGRectMake(0, 0, _maxTextViewWidth, 0);
        selectedTextView.attributedText = attributedText;
        
        // Force the layout manager to layout the text, fixes problems starting iOS 16
        [selectedTextView.layoutManager ensureLayoutForTextContainer:selectedTextView.textContainer];
            
        CGSize size = [selectedTextView sizeThatFits:selectedTextView.frame.size];

        // Manage the case where a string attribute has a single paragraph with a left indent
        // In this case, [UITextView sizeThatFits] ignores the indent and return the width
        // of the text only.
        // So, add this indent afterwards
        NSRange textRange = NSMakeRange(0, attributedText.length);
        NSRange longestEffectiveRange;
        NSParagraphStyle *paragraphStyle = [attributedText attribute:NSParagraphStyleAttributeName atIndex:0 longestEffectiveRange:&longestEffectiveRange inRange:textRange];

        if (NSEqualRanges(textRange, longestEffectiveRange))
        {
            size.width = size.width + paragraphStyle.headIndent;
        }

        return size;
    }
    
    return CGSizeZero;
}

#pragma mark - Properties

- (MXSession*)mxSession
{
    return roomDataSource.mxSession;
}

- (NSArray*)bubbleComponents
{
    NSArray* copy;
    
    @synchronized(bubbleComponents)
    {
        copy = [bubbleComponents copy];
    }
    
    return copy;
}

- (NSString*)textMessage
{
    return self.attributedTextMessage.string;
}

- (void)setAttributedTextMessage:(NSAttributedString *)inAttributedTextMessage
{
    attributedTextMessage = inAttributedTextMessage;
    
    if (attributedTextMessage.length && highlightedPattern)
    {
        [self highlightPattern];
    }
    
    // Reset content size
    _contentSize = CGSizeZero;
}

- (NSAttributedString*)attributedTextMessage
{
    if (self.hasAttributedTextMessage && !attributedTextMessage.length)
    {
        // By default only one component is supported, consider here the first component
        MXKRoomBubbleComponent *firstComponent = [self getFirstBubbleComponent];
        
        if (firstComponent)
        {
            attributedTextMessage = firstComponent.attributedTextMessage;
            
            if (attributedTextMessage.length && highlightedPattern)
            {
                [self highlightPattern];
            }
        }
    }

    return attributedTextMessage;
}

- (BOOL)hasAttributedTextMessage
{
    // Determine if the event formatter will return at least one string for the events in this cell.
    // No string means that the event formatter has been configured so that it did not accept all events
    // of the cell.
    BOOL hasAttributedTextMessage = NO;

    @synchronized(bubbleComponents)
    {
        for (MXKRoomBubbleComponent *roomBubbleComponent in bubbleComponents)
        {
            if (roomBubbleComponent.attributedTextMessage)
            {
                hasAttributedTextMessage = YES;
                break;
            }
        }
    }
    return hasAttributedTextMessage;
}

- (BOOL)hasLink
{
    @synchronized (bubbleComponents) {
        for (MXKRoomBubbleComponent *component in bubbleComponents)
        {
            if (component.link)
            {
                return YES;
            }
        }
    }
    
    return NO;
}

- (MXKRoomBubbleComponentDisplayFix)displayFix
{
    MXKRoomBubbleComponentDisplayFix displayFix = MXKRoomBubbleComponentDisplayFixNone;

    @synchronized(bubbleComponents)
    {
        for (MXKRoomBubbleComponent *component in self.bubbleComponents)
        {
            displayFix |= component.displayFix;
        }
    }
    return displayFix;
}

- (BOOL)shouldHideSenderName
{
    BOOL res = NO;
    
    MXKRoomBubbleComponent *firstDisplayedComponent = [self getFirstBubbleComponentWithDisplay];
    NSString *senderDisplayName = self.senderDisplayName;
    
    if (firstDisplayedComponent)
    {
        res = (firstDisplayedComponent.event.isEmote || (firstDisplayedComponent.event.isState && senderDisplayName && [firstDisplayedComponent.textMessage hasPrefix:senderDisplayName]));
    }
    
    return res;
}

- (BOOL)canInvitePeople
{
    NSInteger requiredLevel = roomDataSource.roomState.powerLevels.invite;
    NSInteger myLevel = [roomDataSource.roomState.powerLevels powerLevelOfUserWithUserID:roomDataSource.mxSession.myUserId];
    return myLevel >= requiredLevel;
}

- (NSArray*)events
{
    NSMutableArray* eventsArray;
    
    @synchronized(bubbleComponents)
    {
        eventsArray = [NSMutableArray arrayWithCapacity:bubbleComponents.count];
        for (MXKRoomBubbleComponent *roomBubbleComponent in bubbleComponents)
        {
            if (roomBubbleComponent.event)
            {
                [eventsArray addObject:roomBubbleComponent.event];
            }
        }
    }
    return eventsArray;
}

- (NSDate*)date
{
    MXKRoomBubbleComponent *firstDisplayedComponent = [self getFirstBubbleComponentWithDisplay];
    
    if (firstDisplayedComponent)
    {
        return firstDisplayedComponent.date;
    }
    
    return nil;
}

- (BOOL)hasNoDisplay
{
    BOOL noDisplay = YES;
    
    // Check whether at least one component has a string description.
    @synchronized(bubbleComponents)
    {
        if (self.collapsed)
        {
            // Collapsed cells have no display except their cell header
            noDisplay = !self.collapsedAttributedTextMessage;
        }
        else
        {
            for (MXKRoomBubbleComponent *roomBubbleComponent in bubbleComponents)
            {
                if (roomBubbleComponent.attributedTextMessage)
                {
                    noDisplay = NO;
                    break;
                }
            }
        }
    }
    
    return (noDisplay && !attachment);
}

- (BOOL)isAttachmentWithThumbnail
{
    return (attachment && (attachment.type == MXKAttachmentTypeImage || attachment.type == MXKAttachmentTypeVideo || attachment.type == MXKAttachmentTypeSticker));
}

- (BOOL)isAttachmentWithIcon
{
    // Not supported yet (TODO for audio, file).
    return NO;
}

- (BOOL)isAttachment
{
    if (!self.attachment)
    {
        return NO;
    }
    
    if (!attachment.contentURL || !attachment.contentInfo) {
        return NO;
    }
    
    switch (self.attachment.type) {
        case MXKAttachmentTypeFile:
        case MXKAttachmentTypeAudio:
        case MXKAttachmentTypeVoiceMessage:
            return YES;
        default:
            return NO;
    }
}

- (void)setMaxTextViewWidth:(CGFloat)inMaxTextViewWidth
{
    // Check change
    if (inMaxTextViewWidth != _maxTextViewWidth)
    {
        _maxTextViewWidth = inMaxTextViewWidth;
        // Reset content size
        _contentSize = CGSizeZero;
    }
}

- (CGSize)contentSize
{
    if (CGSizeEqualToSize(_contentSize, CGSizeZero))
    {
        if (attachment == nil)
        {
            // Here the bubble is a text message
            if ([NSThread currentThread] != [NSThread mainThread])
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    self->_contentSize = [self textContentSize:self.attributedTextMessage removeVerticalInset:NO];
                });
            }
            else
            {
                _contentSize = [self textContentSize:self.attributedTextMessage removeVerticalInset:NO];
            }
        }
        else if (self.isAttachmentWithThumbnail)
        {
            CGFloat width, height;
            
            // Set default content size
            width = height = MXKROOMBUBBLECELLDATA_MAX_ATTACHMENTVIEW_WIDTH;
            
            if (attachment.thumbnailInfo || attachment.contentInfo)
            {
                if (attachment.thumbnailInfo && attachment.thumbnailInfo[@"w"] && attachment.thumbnailInfo[@"h"])
                {
                    width = [attachment.thumbnailInfo[@"w"] integerValue];
                    height = [attachment.thumbnailInfo[@"h"] integerValue];
                }
                else if (attachment.contentInfo[@"w"] && attachment.contentInfo[@"h"])
                {
                    width = [attachment.contentInfo[@"w"] integerValue];
                    height = [attachment.contentInfo[@"h"] integerValue];
                }
                
                if (width > MXKROOMBUBBLECELLDATA_MAX_ATTACHMENTVIEW_WIDTH || height > MXKROOMBUBBLECELLDATA_MAX_ATTACHMENTVIEW_WIDTH)
                {
                    if (width > height)
                    {
                        height = (height * MXKROOMBUBBLECELLDATA_MAX_ATTACHMENTVIEW_WIDTH) / width;
                        height = floorf(height / 2) * 2;
                        width = MXKROOMBUBBLECELLDATA_MAX_ATTACHMENTVIEW_WIDTH;
                    }
                    else
                    {
                        width = (width * MXKROOMBUBBLECELLDATA_MAX_ATTACHMENTVIEW_WIDTH) / height;
                        width = floorf(width / 2) * 2;
                        height = MXKROOMBUBBLECELLDATA_MAX_ATTACHMENTVIEW_WIDTH;
                    }
                }
            }
            
            // Check here thumbnail orientation
            if (attachment.thumbnailOrientation == UIImageOrientationLeft || attachment.thumbnailOrientation == UIImageOrientationRight)
            {
                _contentSize = CGSizeMake(height, width);
            }
            else
            {
                _contentSize = CGSizeMake(width, height);
            }
        }
        else if (attachment.type == MXKAttachmentTypeFile || attachment.type == MXKAttachmentTypeAudio)
        {
            // Presently we displayed only the file name for attached file (no icon yet)
            // Return suitable content size of a text view to display the file name (available in text message). 
            if ([NSThread currentThread] != [NSThread mainThread])
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    self->_contentSize = [self textContentSize:self.attributedTextMessage removeVerticalInset:NO];
                });
            }
            else
            {
                _contentSize = [self textContentSize:self.attributedTextMessage removeVerticalInset:NO];
            }
        }
        else
        {
            _contentSize = CGSizeMake(40, 40);
        }
    }
    return _contentSize;
}

- (MXKEventFormatter *)eventFormatter
{
    MXKRoomBubbleComponent *firstComponent = [bubbleComponents firstObject];
    
    // Retrieve event formatter from the first component
    if (firstComponent)
    {
        return firstComponent.eventFormatter;
    }
    
    return nil;
}

- (BOOL)showAntivirusScanStatus
{
    MXKRoomBubbleComponent *firstBubbleComponent = self.bubbleComponents.firstObject;
    
    if (self.attachment == nil || firstBubbleComponent == nil)
    {
        return NO;
    }
    
    MXEventScan *eventScan = firstBubbleComponent.eventScan;
    
    return eventScan != nil && eventScan.antivirusScanStatus != MXAntivirusScanStatusTrusted;
}

- (BOOL)containsBubbleComponentWithEncryptionBadge
{
    BOOL containsBubbleComponentWithEncryptionBadge = NO;
    
    @synchronized(bubbleComponents)
    {
        for (MXKRoomBubbleComponent *component in bubbleComponents)
        {
            if (component.encryptionDecoration != EventEncryptionDecorationNone)
            {
                containsBubbleComponentWithEncryptionBadge = YES;
                break;
            }
        }
    }
    
    return containsBubbleComponentWithEncryptionBadge;
}

#pragma mark - Bubble collapsing

- (BOOL)collapseWith:(id<MXKRoomBubbleCellDataStoring>)cellData
{
    // NO by default
    return NO;
}

#pragma mark - Internals

- (void)highlightPattern
{
    NSMutableAttributedString *customAttributedTextMsg = nil;
    
    NSString *currentTextMessage = self.textMessage;
    NSRange range = [currentTextMessage rangeOfString:highlightedPattern options:NSCaseInsensitiveSearch];
    
    if (range.location != NSNotFound)
    {
        customAttributedTextMsg = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedTextMessage];
        
        while (range.location != NSNotFound)
        {
            if (highlightedPatternBackgroundColor)
            {
                // Update background color
                [customAttributedTextMsg addAttribute:NSBackgroundColorAttributeName value:highlightedPatternBackgroundColor range:range];
            }

            if (highlightedPatternForegroundColor)
            {
                // Update text color
                [customAttributedTextMsg addAttribute:NSForegroundColorAttributeName value:highlightedPatternForegroundColor range:range];
            }
            
            if (highlightedPatternFont)
            {
                // Update text font
                [customAttributedTextMsg addAttribute:NSFontAttributeName value:highlightedPatternFont range:range];
            }
            
            // Look for the next pattern occurrence
            range.location += range.length;
            if (range.location < currentTextMessage.length)
            {
                range.length = currentTextMessage.length - range.location;
                range = [currentTextMessage rangeOfString:highlightedPattern options:NSCaseInsensitiveSearch range:range];
            }
            else
            {
                range.location = NSNotFound;
            }
        }
    }
    
    if (customAttributedTextMsg)
    {
        // Update resulting message body
        attributedTextMessage = customAttributedTextMsg;
    }
}

@end
