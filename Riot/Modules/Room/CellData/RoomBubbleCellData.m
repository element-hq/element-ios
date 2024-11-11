/*
Copyright 2019-2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomBubbleCellData.h"

#import "EventFormatter.h"

#import "AvatarGenerator.h"
#import "Tools.h"
#import "RoomReactionsViewSizer.h"

#import "GeneratedInterface-Swift.h"

static NSAttributedString *timestampVerticalWhitespace = nil;

NSString *const URLPreviewDidUpdateNotification = @"URLPreviewDidUpdateNotification";

@interface RoomBubbleCellData()

@property(nonatomic, readonly) BOOL addVerticalWhitespaceForSelectedComponentTimestamp;
@property(nonatomic, readwrite) CGFloat additionalContentHeight;
@property(nonatomic) BOOL shouldUpdateAdditionalContentHeight;

// Flags to "Show All" reactions for an event
@property(nonatomic) NSMutableSet<NSString* /* eventId */> *eventsToShowAllReactions;

@end

@implementation RoomBubbleCellData

- (BOOL)addVerticalWhitespaceForSelectedComponentTimestamp
{
    return self.showTimestampForSelectedComponent && !self.displayTimestampForSelectedComponentOnLeftWhenPossible;
}

#pragma mark - Override MXKRoomBubbleCellData

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _eventsToShowAllReactions = [NSMutableSet set];
        _componentIndexOfSentMessageTick = -1;
    }
    return self;
}

- (instancetype)initWithEvent:(MXEvent *)event andRoomState:(MXRoomState *)roomState andRoomDataSource:(MXKRoomDataSource *)roomDataSource
{
    self = [super initWithEvent:event andRoomState:roomState andRoomDataSource:roomDataSource];
    
    if (self)
    {
        self.displayTimestampForSelectedComponentOnLeftWhenPossible = YES;
        
        switch (event.eventType)
        {
            case MXEventTypeRoomMember:
            {
                // Membership events have their own cell type
                self.tag = RoomBubbleCellDataTagMembership;
                
                // Membership events can be collapsed together
                self.collapsable = YES;
                
                // Collapse them by default
                self.collapsed = YES;
                
                //  find the room create event in stateEvents
                MXEvent *roomCreateEvent = [roomState.stateEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"wireType == %@", kMXEventTypeStringRoomCreate]].firstObject;
                NSString *creatorUserId = [MXRoomCreateContent modelFromJSON:roomCreateEvent.content].creatorUserId;
                if (creatorUserId)
                {
                    MXRoomMemberEventContent *content = [MXRoomMemberEventContent modelFromJSON:event.content];
                    if ([kMXMembershipStringJoin isEqualToString:content.membership] &&
                        [creatorUserId isEqualToString:event.sender])
                    {
                        //  join event of the room creator
                        //  group it with room creation events
                        self.tag = RoomBubbleCellDataTagRoomCreateConfiguration;
                    }
                }
            }
                break;
            case MXEventTypeRoomCreate:
            {
                MXRoomCreateContent *createContent = [MXRoomCreateContent modelFromJSON:event.content];
                
                if (createContent.roomPredecessorInfo)
                {
                    self.tag = RoomBubbleCellDataTagRoomCreateWithPredecessor;
                }
                else
                {
                    self.tag = RoomBubbleCellDataTagRoomCreationIntro;
                }
                
                // Membership events can be collapsed together
                self.collapsable = YES;
                
                // Collapse them by default
                self.collapsed = YES;
            }
                break;
            case MXEventTypeRoomTopic:
            case MXEventTypeRoomName:
            case MXEventTypeRoomEncryption:
            case MXEventTypeRoomHistoryVisibility:
            case MXEventTypeRoomGuestAccess:
            case MXEventTypeRoomAvatar:
            case MXEventTypeRoomJoinRules:
            {
                self.tag = RoomBubbleCellDataTagRoomCreateConfiguration;
                
                // Membership events can be collapsed together
                self.collapsable = YES;
                
                // Collapse them by default
                self.collapsed = YES;
            }
                break;
            case MXEventTypeCallInvite:
            case MXEventTypeCallAnswer:
            case MXEventTypeCallHangup:
            case MXEventTypeCallReject:
            {
                self.tag = RoomBubbleCellDataTagCall;
                
                // Call events can be collapsed together
                self.collapsable = YES;
                
                // Collapse them by default
                self.collapsed = YES;
                
                // Show timestamps always on right
                self.displayTimestampForSelectedComponentOnLeftWhenPossible = NO;
                break;
            }
            case MXEventTypeCallNotify:
            {
                self.tag = RoomBubbleCellDataTagRTCCallNotify;
                self.collapsable = NO;
                self.collapsed = NO;
                self.displayTimestampForSelectedComponentOnLeftWhenPossible = NO;
                break;
            }
            case MXEventTypePollStart:
            case MXEventTypePollEnd:
            {
                self.tag = RoomBubbleCellDataTagPoll;
                self.collapsable = NO;
                self.collapsed = NO;
                
                break;
            }
            case MXEventTypeBeaconInfo:
            {
                self.tag = RoomBubbleCellDataTagLiveLocation;
                self.collapsable = NO;
                self.collapsed = NO;
                
                [self updateBeaconInfoSummaryWithId:event.eventId andEvent:event];
                break;
            }
            case MXEventTypeCustom:
            {
                if ([event.type isEqualToString:kWidgetMatrixEventTypeString]
                    || [event.type isEqualToString:kWidgetModularEventTypeString])
                {
                    Widget *widget = [[Widget alloc] initWithWidgetEvent:event inMatrixSession:roomDataSource.mxSession];
                    if ([widget.type isEqualToString:kWidgetTypeJitsiV1] ||
                        [widget.type isEqualToString:kWidgetTypeJitsiV2])
                    {
                        self.tag = RoomBubbleCellDataTagGroupCall;
                        
                        // Show timestamps always on right
                        self.displayTimestampForSelectedComponentOnLeftWhenPossible = NO;
                    }
                }
                else if ([event.type isEqualToString:VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType])
                {
                    VoiceBroadcastInfo *voiceBroadcastInfo = [VoiceBroadcastInfo modelFromJSON: event.content];
                    
                    // Check if the state event corresponds to the beginning of a voice broadcast
                    if ([VoiceBroadcastInfo isStartedFor:voiceBroadcastInfo.state])
                    {
                        // Retrieve the most recent voice broadcast info.
                        MXEvent *lastVoiceBroadcastInfoEvent = [roomDataSource.roomState stateEventsWithType:VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType].lastObject;
                        if (event.originServerTs > lastVoiceBroadcastInfoEvent.originServerTs)
                        {
                            lastVoiceBroadcastInfoEvent = event;
                        }
                        
                        VoiceBroadcastInfo *lastVoiceBroadcastInfo = [VoiceBroadcastInfo modelFromJSON: lastVoiceBroadcastInfoEvent.content];
                        
                        // Handle the specific case where the state event is a started voice broadcast (the voiceBroadcastId is the event id itself).
                        if (!lastVoiceBroadcastInfo.voiceBroadcastId)
                        {
                            lastVoiceBroadcastInfo.voiceBroadcastId = lastVoiceBroadcastInfoEvent.eventId;
                        }
                        
                        // Check if the voice broadcast is still alive.
                        if ([lastVoiceBroadcastInfo.voiceBroadcastId isEqualToString:event.eventId] && ![VoiceBroadcastInfo isStoppedFor:lastVoiceBroadcastInfo.state])
                        {
                            // Check whether this broadcast is sent from the currrent session to display it with the recorder view or not.
                            if ([event.stateKey isEqualToString:self.mxSession.myUserId] &&
                                [voiceBroadcastInfo.deviceId isEqualToString:self.mxSession.myDeviceId])
                            {
                                self.tag = RoomBubbleCellDataTagVoiceBroadcastRecord;
                            }
                            else
                            {
                                self.tag = RoomBubbleCellDataTagVoiceBroadcastPlayback;
                            }
                            
                            self.voiceBroadcastState = lastVoiceBroadcastInfo.state;
                        }
                        else
                        {
                            self.tag = RoomBubbleCellDataTagVoiceBroadcastPlayback;
                            self.voiceBroadcastState = VoiceBroadcastInfo.stoppedValue;
                        }
                    }
                    else
                    {
                        self.tag = RoomBubbleCellDataTagVoiceBroadcastNoDisplay;
                        
                        if ([VoiceBroadcastInfo isStoppedFor:voiceBroadcastInfo.state])
                        {
                            // This state event corresponds to the end of a voice broadcast
                            // Force the tag of the potential cellData which corresponds to the started event to switch the display from recorder to listener
                            RoomBubbleCellData *bubbleData = [roomDataSource cellDataOfEventWithEventId:voiceBroadcastInfo.voiceBroadcastId];
                            bubbleData.tag = RoomBubbleCellDataTagVoiceBroadcastPlayback;
                            bubbleData.voiceBroadcastState = VoiceBroadcastInfo.stoppedValue;
                        }
                    }
                    self.collapsable = NO;
                    self.collapsed = NO;
                    
                    break;
                }
                
                break;
            }
            case MXEventTypeRoomMessage:
            {
                if (event.location)
                {
                    self.tag = RoomBubbleCellDataTagLocation;
                    self.collapsable = NO;
                    self.collapsed = NO;
                }
                else if (event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType])
                {
                    self.tag = RoomBubbleCellDataTagVoiceBroadcastNoDisplay;
                    self.collapsable = NO;
                    self.collapsed = NO;
                }
                
                break;
            }
            default:
                break;
        }
        
        [self keyVerificationDidUpdate];

        // Increase maximum number of components
        self.maxComponentCount = 20;

        // Indicate that the text message layout should be recomputed.
        [self invalidateTextLayout];
        
        // Load a url preview if necessary.
        [self refreshURLPreviewForEventId:event.eventId];
    }
    
    return self;
}

- (NSUInteger)updateEvent:(NSString *)eventId withEvent:(MXEvent *)event
{
    NSUInteger retVal = [super updateEvent:eventId withEvent:event];

    // Update any URL preview data as necessary.
    [self refreshURLPreviewForEventId:event.eventId];
    
    if (self.tag == RoomBubbleCellDataTagLiveLocation)
    {
        [self updateBeaconInfoSummaryWithId:eventId andEvent:event];
    }
    
    // Handle here the case where an audio chunk of a voice broadcast have been decrypted with delay
    // We take the opportunity of this update to disable the display of this chunk in the room timeline
    if (event.eventType == MXEventTypeRoomMessage && event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType]) {
        self.tag = RoomBubbleCellDataTagVoiceBroadcastNoDisplay;
        self.collapsable = NO;
        self.collapsed = NO;
    }

    return retVal;
}

- (void)prepareBubbleComponentsPosition
{
    if (shouldUpdateComponentsPosition)
    {
        // The bubble layout depends on the room read receipts which must be retrieved on the main thread to prevent us from race conditions.
        // Check here the current thread, this is just a sanity check because this method is called during the rendering step
        // which takes place on the main thread.
        if ([NSThread currentThread] != [NSThread mainThread])
        {
            MXLogDebug(@"[RoomBubbleCellData] prepareBubbleComponentsPosition called on wrong thread");
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self refreshBubbleComponentsPosition];
            });
        }
        else
        {
            [self refreshBubbleComponentsPosition];
        }
        
        shouldUpdateComponentsPosition = NO;
    }
    
    [self updateAdditionalContentHeightIfNeeded];
}

- (NSAttributedString*)attributedTextMessage
{
    [self buildAttributedStringIfNeeded];
    
    return attributedTextMessage;
}

- (NSAttributedString*)attributedTextMessageWithoutPositioningSpace
{
    [self buildAttributedStringIfNeeded];
    
    return attributedTextMessageWithoutPositioningSpace;
}

- (BOOL)hasNoDisplay
{
    BOOL hasNoDisplay = YES;
    
    switch (self.tag)
    {
        case RoomBubbleCellDataTagKeyVerificationNoDisplay:
            hasNoDisplay = YES;
            break;
        case RoomBubbleCellDataTagRoomCreationIntro:
            hasNoDisplay = NO;
            break;
        case RoomBubbleCellDataTagPoll:
            if (!self.events.lastObject.isEditEvent)
            {
                hasNoDisplay = NO;
            }
            
            break;
        case RoomBubbleCellDataTagLocation:
            hasNoDisplay = NO;
            break;
        case RoomBubbleCellDataTagLiveLocation:
            // Show the cell only if the summary exists
            if (self.beaconInfoSummary)
            {
                hasNoDisplay = NO;
            }
            
            break;
        case RoomBubbleCellDataTagVoiceBroadcastRecord:
        case RoomBubbleCellDataTagVoiceBroadcastPlayback:
            hasNoDisplay = NO;
            break;
        case RoomBubbleCellDataTagVoiceBroadcastNoDisplay:
            break;
        case RoomBubbleCellDataTagRTCCallNotify:
        {
            hasNoDisplay = NO;
            break;
        }
        default:
            hasNoDisplay = [super hasNoDisplay];
            break;
    }
    
    return hasNoDisplay;
}

- (BOOL)hasThreadRoot
{
    if (!RiotSettings.shared.enableThreads)
    {
        //  do not consider this cell data if threads not enabled in the timeline
        return NO;
    }

    if (roomDataSource.threadId)
    {
        //  do not consider this cell data if in a thread view
        return NO;
    }
    
    return super.hasThreadRoot;
}

- (BOOL)mergeWithBubbleCellData:(id<MXKRoomBubbleCellDataStoring>)bubbleCellData
{
    RoomTimelineConfiguration *timelineConfiguration = [RoomTimelineConfiguration shared];
    if (NO == [timelineConfiguration.currentStyle canMergeWithCellData:bubbleCellData into:self]) {
        return NO;
    }

    return [super mergeWithBubbleCellData:bubbleCellData];
}

#pragma mark - Bubble collapsing

- (BOOL)collapseWith:(id<MXKRoomBubbleCellDataStoring>)cellData
{
    if (self.tag == RoomBubbleCellDataTagMembership
        && cellData.tag == RoomBubbleCellDataTagMembership)
    {
        // For now, do not merge VoIP conference events
        if (![MXCallManager isConferenceUser:cellData.events.firstObject.stateKey])
        {
            // Keep a pagination between events of different days
            NSString *bubbleDateString = [roomDataSource.eventFormatter dateStringFromDate:self.date withTime:NO];
            NSString *eventDateString = [roomDataSource.eventFormatter dateStringFromDate:((RoomBubbleCellData*)cellData).date withTime:NO];
            if (bubbleDateString && eventDateString && [bubbleDateString isEqualToString:eventDateString])
            {
                return YES;
            }
        }

        return NO;
    }
    else if (self.tag == RoomBubbleCellDataTagRoomCreateConfiguration && cellData.tag == RoomBubbleCellDataTagRoomCreateConfiguration)
    {
        return YES;
    }
    else if (self.tag == RoomBubbleCellDataTagCall && cellData.tag == RoomBubbleCellDataTagCall)
    {
        //  Check if the same call
        MXEvent * event1 = self.events.firstObject;
        MXCallEventContent *eventContent1 = [MXCallEventContent modelFromJSON:event1.content];

        MXEvent * event2 = cellData.events.firstObject;
        MXCallEventContent *eventContent2 = [MXCallEventContent modelFromJSON:event2.content];

        return [eventContent1.callId isEqualToString:eventContent2.callId];
    }
    
    if (self.tag == RoomBubbleCellDataTagRoomCreateWithPredecessor || cellData.tag == RoomBubbleCellDataTagRoomCreateWithPredecessor)
    {
        return NO;
    }
    
    return [super collapseWith:cellData];
}

- (void)setCollapsed:(BOOL)collapsed
{
    if (collapsed != self.collapsed)
    {
        super.collapsed = collapsed;

        // Refresh only cells series header
        if (self.collapsedAttributedTextMessage && self.nextCollapsableCellData)
        {
            [self invalidateTextLayout];
        }
    }
}

#pragma mark -

- (void)invalidateLayout
{
    [self invalidateTextLayout];
    [self setNeedsUpdateAdditionalContentHeight];
}

- (void)buildAttributedString
{
    // CAUTION: This method must be called on the main thread.

    // Return the collapsed string only for cells series header
    if (self.collapsed && self.collapsedAttributedTextMessage && self.nextCollapsableCellData)
    {
        NSAttributedString *attributedString = super.collapsedAttributedTextMessage;
        
        self.attributedTextMessage = attributedString;
        self.attributedTextMessageWithoutPositioningSpace = attributedString;
        
        return;
    }

    NSMutableAttributedString *currentAttributedTextMsg;
    
    NSMutableAttributedString *currentAttributedTextMsgWithoutVertSpace = [NSMutableAttributedString new];
    
    NSInteger selectedComponentIndex = self.selectedComponentIndex;
    NSInteger lastMessageIndex = self.containsLastMessage ? self.mostRecentComponentIndex : NSNotFound;
    
    MXKRoomBubbleComponent *component;
    NSAttributedString *componentString;
    NSUInteger index = 0;
    for (; index < bubbleComponents.count; index++)
    {
        component = bubbleComponents[index];
        componentString = component.attributedTextMessage;
        
        if (componentString)
        {
            // Check whether another component than this one is selected
            // Note: When a component is selected, it is highlighted by applying an alpha on other components.
            if (selectedComponentIndex != NSNotFound && selectedComponentIndex != index && componentString.length)
            {
                // Apply alpha to blur this component
                componentString = [componentString withTextColorAlpha:.2];
                if (@available(iOS 15.0, *)) {
                    [PillsFormatter setPillAlpha:.2 inAttributedString:componentString];
                }
            }
            else if (@available(iOS 15.0, *))
            {
                // PillTextAttachment are not created again every time, we have to set alpha back to standard if needed.
                [PillsFormatter setPillAlpha:1.f inAttributedString:componentString];
            }
            
            // Check whether the timestamp is displayed for this component, and check whether a vertical whitespace is required
            if (((selectedComponentIndex == index && self.addVerticalWhitespaceForSelectedComponentTimestamp) || lastMessageIndex == index) && (self.shouldHideSenderInformation || self.shouldHideSenderName))
            {
                currentAttributedTextMsg = [[NSMutableAttributedString alloc] initWithAttributedString:[RoomBubbleCellData timestampVerticalWhitespace]];
                [currentAttributedTextMsg appendAttributedString:componentString];
                
                [currentAttributedTextMsgWithoutVertSpace appendAttributedString:componentString];
            }
            else
            {
                // Init attributed string with the first text component
                currentAttributedTextMsg = [[NSMutableAttributedString alloc] initWithAttributedString:componentString];
                
                [currentAttributedTextMsgWithoutVertSpace appendAttributedString:componentString];
            }

            [self addVerticalWhitespaceToString:currentAttributedTextMsg forEvent:component.event.eventId];
            
            // The first non empty component has been handled.
            break;
        }
    }
    
    for (index++; index < bubbleComponents.count; index++)
    {
        component = bubbleComponents[index];
        componentString = component.attributedTextMessage;
        
        if (componentString)
        {
            [currentAttributedTextMsg appendAttributedString:[MXKRoomBubbleCellDataWithAppendingMode messageSeparator]];
            
            // Check whether another component than this one is selected
            if (selectedComponentIndex != NSNotFound && selectedComponentIndex != index && componentString.length)
            {
                // Apply alpha to blur this component
                componentString = [componentString withTextColorAlpha:.2];
                if (@available(iOS 15.0, *)) {
                    [PillsFormatter setPillAlpha:.2 inAttributedString:componentString];
                }
            }
            else if (@available(iOS 15.0, *))
            {
                // PillTextAttachment are not created again every time, we have to set alpha back to standard if needed.
                [PillsFormatter setPillAlpha:1.f inAttributedString:componentString];
            }
            
            // Check whether the timestamp is displayed
            if ((selectedComponentIndex == index && self.addVerticalWhitespaceForSelectedComponentTimestamp) || lastMessageIndex == index)
            {
                [currentAttributedTextMsg appendAttributedString:[RoomBubbleCellData timestampVerticalWhitespace]];
            }
            
            // Append attributed text
            [currentAttributedTextMsg appendAttributedString:componentString];
            
            [self addVerticalWhitespaceToString:currentAttributedTextMsg forEvent:component.event.eventId];
            
            [currentAttributedTextMsgWithoutVertSpace appendAttributedString:componentString];
        }
    }
    
    // With bubbles the text is truncated with quote messages containing vertical border view
    // Add horizontal space to fix the issue
    if (self.displayFix & MXKRoomBubbleComponentDisplayFixHtmlBlockquote)
    {
        [currentAttributedTextMsgWithoutVertSpace appendString:@"       "];
    }
        
    self.attributedTextMessage = currentAttributedTextMsg;
    
    self.attributedTextMessageWithoutPositioningSpace = currentAttributedTextMsgWithoutVertSpace;
}

- (void)buildAttributedStringIfNeeded
{
    @synchronized(bubbleComponents)
    {
        if (self.hasAttributedTextMessage && !attributedTextMessage.length)
        {
            // Attributed text message depends on the room read receipts which must be retrieved on the main thread to prevent us from race conditions.
            // Check here the current thread, this is just a sanity check because the attributed text message
            // is requested during the rendering step which takes place on the main thread.
            if ([NSThread currentThread] != [NSThread mainThread])
            {
                MXLogDebug(@"[RoomBubbleCellData] attributedTextMessage called on wrong thread");
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self buildAttributedString];
                });
            }
            else
            {
                [self buildAttributedString];
            }
        }
    }
}

- (NSInteger)firstVisibleComponentIndex
{
    __block NSInteger firstVisibleComponentIndex = NSNotFound;
    
    MXEvent *firstEvent = self.events.firstObject;
    BOOL isPoll = firstEvent.isTimelinePollEvent;
    BOOL isVoiceBroadcast = (firstEvent.eventType == MXEventTypeCustom && [firstEvent.type isEqualToString: VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType]);
    
    if ((isPoll || self.attachment || isVoiceBroadcast) && self.bubbleComponents.count)
    {
        firstVisibleComponentIndex = 0;
    }
    else
    {
        [self.bubbleComponents enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            MXKRoomBubbleComponent *component = (MXKRoomBubbleComponent*)obj;
            
            if (component.attributedTextMessage)
            {
                firstVisibleComponentIndex = idx;
                *stop = YES;
            }
        }];
    }
    
    return firstVisibleComponentIndex;
}

- (void)refreshBubbleComponentsPosition
{
    // CAUTION: This method must be called on the main thread.
    
    @synchronized(bubbleComponents)
    {
        NSInteger bubbleComponentsCount = bubbleComponents.count;
        
        // Check whether there is at least one component.
        if (bubbleComponentsCount)
        {
            // Set position of the first component
            CGFloat positionY = (self.attachment == nil || self.attachment.type == MXKAttachmentTypeFile || self.attachment.type == MXKAttachmentTypeAudio) ? MXKROOMBUBBLECELLDATA_TEXTVIEW_DEFAULT_VERTICAL_INSET : 0;
            MXKRoomBubbleComponent *component;
            NSUInteger index = 0;
            
            // Use same position for first components without render (redacted)
            for (; index < bubbleComponentsCount; index++)
            {
                // Compute the vertical position for next component
                component = bubbleComponents[index];
                
                component.position = CGPointMake(0, positionY);
                
                if (component.attributedTextMessage)
                {
                    break;
                }
            }
            
            // Check whether the position of other components need to be refreshed
            if (!self.attachment && index < bubbleComponentsCount)
            {
                NSMutableAttributedString *attributedString = [NSMutableAttributedString new];
                NSInteger selectedComponentIndex = self.selectedComponentIndex;
                NSInteger lastMessageIndex = self.containsLastMessage ? self.mostRecentComponentIndex : NSNotFound;
                NSInteger visibleMessageIndex = 0;

                for (; index < bubbleComponentsCount; index++)
                {
                    // Compute the vertical position for next component
                    component = bubbleComponents[index];
                    
                    if (component.attributedTextMessage)
                    {
                        // Prepare its attributed string by considering potential vertical margin required to display timestamp.
                        NSAttributedString *componentString = component.attributedTextMessage;

                        // Check whether the timestamp is displayed for this component, and check whether a vertical whitespace is required
                        
                        if (((selectedComponentIndex == index && self.addVerticalWhitespaceForSelectedComponentTimestamp) || lastMessageIndex == index)
                            && !(visibleMessageIndex == 0 && !(self.shouldHideSenderInformation || self.shouldHideSenderName)))
                        {
                            [attributedString appendAttributedString:[RoomBubbleCellData timestampVerticalWhitespace]];
                        }
                        
                        // Append this attributed string.
                        [attributedString appendAttributedString:componentString];
                        
                        // Compute the height of the resulting string.
                        CGFloat cumulatedHeight = [self rawTextHeight:attributedString];
                        
                        // Deduce the position of the beginning of this component.
                        positionY = MXKROOMBUBBLECELLDATA_TEXTVIEW_DEFAULT_VERTICAL_INSET + (cumulatedHeight - [self rawTextHeight:componentString]);
                        
                        component.position = CGPointMake(0, positionY);
                        
                        // Vertical whitespace is added in case of read receipts or reactions
                        [self addVerticalWhitespaceToString:attributedString forEvent:component.event.eventId];
                        
                        [attributedString appendAttributedString:[MXKRoomBubbleCellDataWithAppendingMode messageSeparator]];
                        
                        visibleMessageIndex++;
                    }
                    else
                    {
                        component.position = CGPointMake(0, positionY);
                    }
                }
            }
        }
    }
}

- (void)addVerticalWhitespaceToString:(NSMutableAttributedString *)attributedString forEvent:(NSString *)eventId
{
    CGFloat additionalVerticalHeight = 0;
    
    // Add vertical whitespace in case of a url preview.
    additionalVerticalHeight+= [self urlPreviewHeightForEventId:eventId];
    // Add vertical whitespace in case of reactions.
    additionalVerticalHeight+= [self reactionHeightForEventId:eventId];
    // Add vertical whitespace in case of a thread root
    additionalVerticalHeight+= [self threadSummaryViewHeightForEventId:eventId];
    // Add vertical whitespace in case of from a thread
    additionalVerticalHeight+= [self fromAThreadViewHeightForEventId:eventId];
    // Add vertical whitespace in case of read receipts.
    additionalVerticalHeight+= [self readReceiptHeightForEventId:eventId];
    
    if (additionalVerticalHeight)
    {
        [attributedString appendAttributedString:[RoomBubbleCellData verticalWhitespaceForHeight: additionalVerticalHeight]];
    }
}

- (CGFloat)computeAdditionalHeight
{
    CGFloat height = 0;
    
    for (MXKRoomBubbleComponent *bubbleComponent in self.bubbleComponents)
    {
        NSString *eventId = bubbleComponent.event.eventId;
        
        height+= [self urlPreviewHeightForEventId:eventId];
        height+= [self reactionHeightForEventId:eventId];
        height+= [self threadSummaryViewHeightForEventId:eventId];
        height+= [self fromAThreadViewHeightForEventId:eventId];
        height+= [self readReceiptHeightForEventId:eventId];
    }
    
    return height;
}

- (void)updateAdditionalContentHeightIfNeeded;
{
    if (self.shouldUpdateAdditionalContentHeight)
    {
        void(^updateAdditionalHeight)(void) = ^() {
            self.additionalContentHeight = [self computeAdditionalHeight];
        };
        
        // The additional height depends on the room read receipts and reactions view which must be calculated on the main thread.
        // Check here the current thread, this is just a sanity check because this method is called during the rendering step
        // which takes place on the main thread.
        if ([NSThread currentThread] != [NSThread mainThread])
        {
            MXLogDebug(@"[RoomBubbleCellData] prepareBubbleComponentsPosition called on wrong thread");
            dispatch_sync(dispatch_get_main_queue(), ^{
                updateAdditionalHeight();
            });
        }
        else
        {
            updateAdditionalHeight();
        }
        
        self.shouldUpdateAdditionalContentHeight = NO;
    }
}

- (void)setNeedsUpdateAdditionalContentHeight
{
    self.shouldUpdateAdditionalContentHeight = YES;
}

- (CGFloat)threadSummaryViewHeightForEventId:(NSString*)eventId
{
    if (!RiotSettings.shared.enableThreads)
    {
        //  do not show thread summary view if threads not enabled in the timeline
        return 0;
    }
    if (roomDataSource.threadId)
    {
        //  do not show thread summary view on threads
        return 0;
    }
    NSInteger index = [self bubbleComponentIndexForEventId:eventId];
    if (index == NSNotFound)
    {
        return 0;
    }
    MXKRoomBubbleComponent *component = self.bubbleComponents[index];
    if (!component.thread)
    {
        //  component is not a thread root
        return 0;
    }
    return PlainRoomCellLayoutConstants.threadSummaryViewTopMargin +
        [ThreadSummaryView contentViewHeightForThread:component.thread fitting:self.maxTextViewWidth];
}

- (CGFloat)fromAThreadViewHeightForEventId:(NSString*)eventId
{
    if (!RiotSettings.shared.enableThreads)
    {
        //  do not show from a thread view if threads not enabled
        return 0;
    }
    if (roomDataSource.threadId)
    {
        //  do not show from a thread view on threads
        return 0;
    }
    NSInteger index = [self bubbleComponentIndexForEventId:eventId];
    if (index == NSNotFound)
    {
        return 0;
    }
    MXKRoomBubbleComponent *component = self.bubbleComponents[index];
    if (!component.event.isInThread)
    {
        //  event is not in a thread
        return 0;
    }
    return PlainRoomCellLayoutConstants.fromAThreadViewTopMargin +
        [FromAThreadView contentViewHeightForEvent:component.event fitting:self.maxTextViewWidth];
}

- (CGFloat)urlPreviewHeightForEventId:(NSString*)eventId
{
    MXKRoomBubbleComponent *component = [self bubbleComponentWithLinkForEventId:eventId];
    if (!component.showURLPreview)
    {
        return 0;
    }
    
    return PlainRoomCellLayoutConstants.urlPreviewViewTopMargin + [URLPreviewView contentViewHeightFor:component.urlPreviewData
                                                                                       fitting:self.maxTextViewWidth];
}

- (CGFloat)reactionHeightForEventId:(NSString*)eventId
{
    CGFloat height = 0;
    
    NSUInteger reactionCount = self.reactions[eventId].reactions.count;
    
    MXAggregatedReactions *aggregatedReactions = self.reactions[eventId];
    
    if (reactionCount)
    {
        CGFloat reactionsViewWidth = self.maxTextViewWidth - 4;
        
        static RoomReactionsViewSizer *reactionsViewSizer;
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            reactionsViewSizer = [RoomReactionsViewSizer new];
        });

        BOOL showAllReactions = [self.eventsToShowAllReactions containsObject:eventId];
        RoomReactionsViewModel *viewModel = [[RoomReactionsViewModel alloc] initWithAggregatedReactions:aggregatedReactions eventId:eventId showAll:showAllReactions];
        height = [reactionsViewSizer heightForViewModel:viewModel fittingWidth:reactionsViewWidth] + PlainRoomCellLayoutConstants.reactionsViewTopMargin;
    }
    
    return height;
}

- (CGFloat)readReceiptHeightForEventId:(NSString*)eventId
{
    CGFloat height = 0;
    
    if (self.readReceipts[eventId].count)
    {
        height = PlainRoomCellLayoutConstants.readReceiptsViewHeight + PlainRoomCellLayoutConstants.readReceiptsViewTopMargin;
    }
    
    return height;
}

- (void)setContainsLastMessage:(BOOL)containsLastMessage
{
    // Check whether there is something to do
    if (_containsLastMessage || containsLastMessage)
    {
        // Update flag
        _containsLastMessage = containsLastMessage;
        
        // Indicate that the text message layout should be recomputed.
        [self invalidateTextLayout];
    }
}

- (void)setSelectedEventId:(NSString *)selectedEventId
{
    // Check whether there is something to do
    if (_selectedEventId || selectedEventId.length)
    { 
        // Update flag
        _selectedEventId = selectedEventId;
        
        // Indicate that the text message layout should be recomputed.
        [self invalidateTextLayout];
    }
}

- (NSInteger)oldestComponentIndex
{
    // Update the related component index
    NSInteger oldestComponentIndex = NSNotFound;
    
    NSArray *components = self.bubbleComponents;
    NSInteger index = 0;
    while (index < components.count)
    {
        MXKRoomBubbleComponent *component = components[index];
        if (component.attributedTextMessage && component.date)
        {
            oldestComponentIndex = index;
            break;
        }
        index++;
    }
    
    return oldestComponentIndex;
}

- (NSInteger)mostRecentComponentIndex
{
    // Update the related component index
    NSInteger mostRecentComponentIndex = NSNotFound;
    
    NSArray *components = self.bubbleComponents;
    NSInteger index = components.count;
    while (index--)
    {
        MXKRoomBubbleComponent *component = components[index];
        if (component.attributedTextMessage && component.date)
        {
            mostRecentComponentIndex = index;
            break;
        }
    }
    
    return mostRecentComponentIndex;
}

- (NSInteger)selectedComponentIndex
{
    // Update the related component index
    NSInteger selectedComponentIndex = NSNotFound;
    
    if (_selectedEventId)
    {
        NSArray *components = self.bubbleComponents;
        NSInteger index = components.count;
        while (index--)
        {
            MXKRoomBubbleComponent *component = components[index];
            if ([component.event.eventId isEqualToString:_selectedEventId])
            {
                selectedComponentIndex = index;
                break;
            }
        }
    }
    
    return selectedComponentIndex;
}

- (MXKRoomBubbleComponent *)bubbleComponentWithLinkForEventId:(NSString *)eventId
{
    NSInteger index = [self bubbleComponentIndexForEventId:eventId];
    if (index == NSNotFound)
    {
        return nil;
    }
    
    MXKRoomBubbleComponent *component = self.bubbleComponents[index];
    if (!component.link)
    {
        return nil;
    }
    
    return component;
}

#pragma mark -

+ (NSAttributedString *)timestampVerticalWhitespace
{
    @synchronized(self)
    {
        if (timestampVerticalWhitespace == nil)
        {
            timestampVerticalWhitespace = [[NSAttributedString alloc] initWithString:@"\n" attributes:@{NSForegroundColorAttributeName : [UIColor blackColor],
                                                                                                          NSFontAttributeName: [UIFont systemFontOfSize:12]}];
        }
    }
    return timestampVerticalWhitespace;
}

+ (NSAttributedString *)verticalWhitespaceForHeight:(CGFloat)height
{
    UIFont *sizingFont = [UIFont systemFontOfSize:2];
    CGFloat returnHeight = sizingFont.lineHeight;
    
    NSUInteger returns = (NSUInteger)round(height/returnHeight);
    NSMutableString *returnString = [NSMutableString string];
    
    for (NSUInteger i = 0; i < returns; i++)
    {
        [returnString appendString:@"\n"];
    }
    
    return [[NSAttributedString alloc] initWithString:returnString attributes:@{NSForegroundColorAttributeName : [UIColor blackColor],
                                                                                NSFontAttributeName: sizingFont}];
}

- (BOOL)hasSameSenderAsBubbleCellData:(id<MXKRoomBubbleCellDataStoring>)bubbleCellData
{
    if (self.tag == RoomBubbleCellDataTagMembership || bubbleCellData.tag == RoomBubbleCellDataTagMembership)
    {
        // We do not want to merge membership event cells with other cell types
        return NO;
    }
    
    if (self.tag == RoomBubbleCellDataTagRoomCreateWithPredecessor || bubbleCellData.tag == RoomBubbleCellDataTagRoomCreateWithPredecessor)
    {
        // We do not want to merge room create event cells with other cell types
        return NO;
    }
    
    if (self.tag == RoomBubbleCellDataTagPoll) {
        MXEvent* event = self.events.firstObject;
        
        if (event) {
            // m.poll.ended events should always show the sender information
            return event.eventType != MXEventTypePollEnd;
        }
    }

    if (self.hasThreadRoot || bubbleCellData.hasThreadRoot)
    {
        // We do not want to merge events containing thread roots
        return NO;
    }

    return [super hasSameSenderAsBubbleCellData:bubbleCellData];
}

- (BOOL)addEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState
{
    if (self.hasThreadRoot)
    {
        // We don't want to add any events into this bubble data if it's a thread root
        return NO;
    }
    RoomTimelineConfiguration *timelineConfiguration = [RoomTimelineConfiguration shared];
    
    if (NO == [timelineConfiguration.currentStyle canAddEvent:event and:roomState to:self]) {
        return NO;
    }
    
    BOOL shouldAddEvent = YES;
    
    switch (self.tag)
    {
        case RoomBubbleCellDataTagKeyVerificationNoDisplay:
        case RoomBubbleCellDataTagKeyVerificationRequest:
        case RoomBubbleCellDataTagKeyVerificationRequestIncomingApproval:
        case RoomBubbleCellDataTagKeyVerificationConclusion:
            shouldAddEvent = NO;
            break;
        case RoomBubbleCellDataTagRoomCreateWithPredecessor:
            // We do not want to merge room create event cells with other cell types
            shouldAddEvent = NO;
            break;
        case RoomBubbleCellDataTagMembership:
            // One single bubble per membership event
            shouldAddEvent = NO;
            break;
        case RoomBubbleCellDataTagCall:
            shouldAddEvent = NO;
            break;
        case RoomBubbleCellDataTagGroupCall:
            shouldAddEvent = NO;
            break;
        case RoomBubbleCellDataTagRTCCallNotify:
            shouldAddEvent = NO;
            break;
        case RoomBubbleCellDataTagRoomCreateConfiguration:
            shouldAddEvent = NO;
            break;
        case RoomBubbleCellDataTagRoomCreationIntro:
            shouldAddEvent = NO;
            break;
        case RoomBubbleCellDataTagPoll:
            shouldAddEvent = NO;
            break;
        case RoomBubbleCellDataTagLocation:
            shouldAddEvent = NO;
            break;
        case RoomBubbleCellDataTagLiveLocation:
            shouldAddEvent = NO;
            break;
        case RoomBubbleCellDataTagVoiceBroadcastRecord:
        case RoomBubbleCellDataTagVoiceBroadcastPlayback:
        case RoomBubbleCellDataTagVoiceBroadcastNoDisplay:
            shouldAddEvent = NO;
            break;
        default:
            break;
    }
    
    // If the current bubbleData supports adding events then check
    // if the incoming event can be added in
    if (shouldAddEvent)
    {
        switch (event.eventType)
        {
            case MXEventTypeRoomMessage:
            {
                if (event.location) {
                    shouldAddEvent = NO;
                    break;
                }
                
                NSString *messageType = event.content[kMXMessageTypeKey];
                
                if ([messageType isEqualToString:kMXMessageTypeKeyVerificationRequest])
                {
                    shouldAddEvent = NO;
                }
                break;
            }
            case MXEventTypeKeyVerificationStart:
            case MXEventTypeKeyVerificationAccept:
            case MXEventTypeKeyVerificationKey:
            case MXEventTypeKeyVerificationMac:
            case MXEventTypeKeyVerificationDone:
            case MXEventTypeKeyVerificationCancel:
                shouldAddEvent = NO;
                break;
            case MXEventTypeRoomMember:
                shouldAddEvent = NO;
                break;
            case MXEventTypeRoomCreate:
                shouldAddEvent = NO;
                break;
            case MXEventTypeRoomTopic:
            case MXEventTypeRoomName:
            case MXEventTypeRoomEncryption:
            case MXEventTypeRoomHistoryVisibility:
            case MXEventTypeRoomGuestAccess:
            case MXEventTypeRoomAvatar:
            case MXEventTypeRoomJoinRules:
                shouldAddEvent = NO;
                break;
            case MXEventTypeCallInvite:
            case MXEventTypeCallAnswer:
            case MXEventTypeCallHangup:
            case MXEventTypeCallReject:
                shouldAddEvent = NO;
                break;
            case MXEventTypeCallNotify:
                shouldAddEvent = NO;
                break;
            case MXEventTypePollStart:
            case MXEventTypePollEnd:
                shouldAddEvent = NO;
                break;
            case MXEventTypeBeaconInfo:
                shouldAddEvent = NO;
                break;
            case MXEventTypeCustom:
            {
                if ([event.type isEqualToString:kWidgetMatrixEventTypeString]
                    || [event.type isEqualToString:kWidgetModularEventTypeString])
                {
                    Widget *widget = [[Widget alloc] initWithWidgetEvent:event inMatrixSession:roomDataSource.mxSession];
                    if ([widget.type isEqualToString:kWidgetTypeJitsiV1] ||
                        [widget.type isEqualToString:kWidgetTypeJitsiV2])
                    {
                        shouldAddEvent = NO;
                    }
                } else if ([event.type isEqualToString:VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType]) {
                    shouldAddEvent = NO;
                }
                break;
            }
            default:
                break;
        }
    }
    
    if (shouldAddEvent)
    {
        shouldAddEvent = [super addEvent:event andRoomState:roomState];
        
        // If the event was added, load any url preview data if necessary.
        if (shouldAddEvent)
        {
            [self refreshURLPreviewForEventId:event.eventId];
        }
    }
    
    return shouldAddEvent;
}

- (void)setKeyVerification:(MXKeyVerification *)keyVerification
{
    _keyVerification = keyVerification;
    
    [self keyVerificationDidUpdate];
}

- (void)keyVerificationDidUpdate
{
    MXEvent *event = self.getFirstBubbleComponentWithDisplay.event;
    MXKeyVerification *keyVerification = _keyVerification;
    
    if (!event)
    {
        return;
    }
    
    switch (event.eventType)
    {
        case MXEventTypeKeyVerificationCancel:
        {
            RoomBubbleCellDataTag cellDataTag;
            
            MXTransactionCancelCode *transactionCancelCode = keyVerification.transaction.reasonCancelCode;
            
            if (transactionCancelCode
                && ([transactionCancelCode isEqual:[MXTransactionCancelCode mismatchedSas]]
                    || [transactionCancelCode isEqual:[MXTransactionCancelCode mismatchedKeys]]
                    || [transactionCancelCode isEqual:[MXTransactionCancelCode mismatchedCommitment]]
                    )
                )
            {
                cellDataTag = RoomBubbleCellDataTagKeyVerificationConclusion;
            }
            else
            {
                cellDataTag = RoomBubbleCellDataTagKeyVerificationNoDisplay;
            }
            
            self.tag = cellDataTag;
        }
            break;
        case MXEventTypeKeyVerificationDone:
        {
            RoomBubbleCellDataTag cellDataTag;
            
            // Avoid to display incoming and outgoing done, only display the incoming one.
            if (self.isIncoming && keyVerification && (keyVerification.state == MXKeyVerificationStateVerified))
            {
                cellDataTag = RoomBubbleCellDataTagKeyVerificationConclusion;
            }
            else
            {
                cellDataTag = RoomBubbleCellDataTagKeyVerificationNoDisplay;
            }
            
            self.tag = cellDataTag;
        }
            break;
        case MXEventTypeRoomMessage:
        {
            NSString *msgType = event.content[kMXMessageTypeKey];
            
            if ([msgType isEqualToString:kMXMessageTypeKeyVerificationRequest])
            {
                RoomBubbleCellDataTag cellDataTag;
                
                if (self.isIncoming && !self.isKeyVerificationOperationPending && keyVerification && keyVerification.state == MXKeyVerificationRequestStatePending)
                {
                    cellDataTag = RoomBubbleCellDataTagKeyVerificationRequestIncomingApproval;
                }
                else
                {
                    cellDataTag = RoomBubbleCellDataTagKeyVerificationRequest;
                }
                
                self.tag = cellDataTag;
            }
        }
            break;
        default:
            break;
    }
    
}

#pragma mark - Show all reactions

- (BOOL)showAllReactionsForEvent:(NSString*)eventId
{
    return [self.eventsToShowAllReactions containsObject:eventId];
}

- (void)setShowAllReactions:(BOOL)showAllReactions forEvent:(NSString*)eventId
{
    if (showAllReactions)
    {
        [self.eventsToShowAllReactions addObject:eventId];
    }
    else
    {
        [self.eventsToShowAllReactions removeObject:eventId];
    }
}

- (NSString *)accessibilityLabel
{
    NSString *accessibilityLabel;

    // Only media require manual handling for accessibility
    if (self.attachment)
    {
        NSString *mediaName = [self accessibilityLabelForAttachmentType:self.attachment.type];

        MXJSONModelSetString(accessibilityLabel, self.events.firstObject.content[kMXMessageBodyKey]);
        if (accessibilityLabel)
        {
            accessibilityLabel = [NSString stringWithFormat:@"%@ %@", mediaName, accessibilityLabel];
        }
        else
        {
            accessibilityLabel = mediaName;
        }
    }

    return accessibilityLabel;
}

- (NSString*)accessibilityLabelForAttachmentType:(MXKAttachmentType)attachmentType
{
    NSString *accessibilityLabel;
    switch (attachmentType)
    {
        case MXKAttachmentTypeImage:
            accessibilityLabel = [VectorL10n mediaTypeAccessibilityImage];
            break;
        case MXKAttachmentTypeAudio:
            accessibilityLabel = [VectorL10n mediaTypeAccessibilityAudio];
            break;
        case MXKAttachmentTypeVoiceMessage:
            accessibilityLabel = [VectorL10n mediaTypeAccessibilityAudio];
            break;
        case MXKAttachmentTypeVideo:
            accessibilityLabel = [VectorL10n mediaTypeAccessibilityVideo];
            break;
        case MXKAttachmentTypeFile:
            accessibilityLabel = [VectorL10n mediaTypeAccessibilityFile];
            break;
        case MXKAttachmentTypeSticker:
            accessibilityLabel = [VectorL10n mediaTypeAccessibilitySticker];
            break;
        default:
            accessibilityLabel = @"";
            break;
    }

    return accessibilityLabel;
}

#pragma mark - URL Previews

- (void)refreshURLPreviewForEventId:(NSString *)eventId
{
    // Get the event's component, but only if it has a link.
    MXKRoomBubbleComponent *component = [self bubbleComponentWithLinkForEventId:eventId];
    if (!component)
    {
        return;
    }
    
    // Don't show the preview if they're disabled globally or this one has been dismissed previously.
    component.showURLPreview = RiotSettings.shared.roomScreenShowsURLPreviews && [URLPreviewService.shared shouldShowPreviewFor:component.event];
    if (!component.showURLPreview)
    {
        return;
    }
    
    // If there is existing preview data, the message has been edited.
    // Clear the data to show the loading state when the preview isn't cached.
    if (component.urlPreviewData)
    {
        component.urlPreviewData = nil;
    }
    
    // Set the preview data.
    MXWeakify(self);
    
    NSDictionary<NSString *, NSString*> *userInfo = @{
        @"eventId": eventId,
        @"roomId": self.roomId
    };
    
    [URLPreviewService.shared previewFor:component.link
                                     and:component.event
                                    with:self.mxSession
                                 success:^(URLPreviewData * _Nonnull urlPreviewData) {
        MXStrongifyAndReturnIfNil(self);
        
        // Update the preview data, indicate that the message layout needs refreshing and send a notification for refresh
        component.urlPreviewData = urlPreviewData;
        [self invalidateLayout];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:URLPreviewDidUpdateNotification object:nil userInfo:userInfo];
        });
        
    } failure:^(NSError * _Nullable error) {
        MXStrongifyAndReturnIfNil(self);
        
        MXLogDebug(@"[RoomBubbleCellData] Failed to get url preview")
        
        // Remove the loading URLPreviewView, indicate that the layout needs refreshing and send a notification for refresh
        component.showURLPreview = NO;
        [self invalidateLayout];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:URLPreviewDidUpdateNotification object:nil userInfo:userInfo];
        });
    }];
}

- (void)updateBeaconInfoSummaryWithId:(NSString *)eventId andEvent:(MXEvent*)event
{
    if (event.eventType != MXEventTypeBeaconInfo)
    {
        MXLogErrorDetails(@"[RoomBubbleCellData] Try to update beacon info summary with wrong event type", @{
            @"event_id": eventId ?: @"unknown"
        });
        return;
    }
    
    id<MXBeaconInfoSummaryProtocol> beaconInfoSummary = [self.mxSession.aggregations.beaconAggregations beaconInfoSummaryFor:eventId inRoomWithId:self.roomId];
    
    if (!beaconInfoSummary)
    {
        MXBeaconInfo *beaconInfo = [[MXBeaconInfo alloc] initWithMXEvent:event];
        
        // A start beacon info event (isLive == true) should have an associated BeaconInfoSummary
        if (beaconInfo && beaconInfo.isLive)
        {
            MXLogErrorDetails(@"[RoomBubbleCellData] No beacon info summary found for beacon info start event", @{
                @"event_id": eventId ?: @"unknown"
            });
        }
    }
    
    self.beaconInfoSummary = beaconInfoSummary;
}

@end
