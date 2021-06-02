/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2019 New Vector Ltd
 
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

#import "RoomBubbleCellData.h"

#import "EventFormatter.h"

#import "AvatarGenerator.h"
#import "Tools.h"
#import "BubbleReactionsViewSizer.h"

#import "Riot-Swift.h"

static NSAttributedString *timestampVerticalWhitespace = nil;

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

- (instancetype)initWithEvent:(MXEvent *)event andRoomState:(MXRoomState *)roomState andRoomDataSource:(MXKRoomDataSource *)roomDataSource2
{
    self = [super initWithEvent:event andRoomState:roomState andRoomDataSource:roomDataSource2];
    
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
                    self.tag = RoomBubbleCellDataTagRoomCreateConfiguration;
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
            }
                break;
            default:
                break;
        }
        
        [self keyVerificationDidUpdate];

        // Increase maximum number of components
        self.maxComponentCount = 20;

        // Reset attributedTextMessage to force reset MXKRoomCellData parameters
        self.attributedTextMessage = nil;
    }
    
    return self;
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
                    self.attributedTextMessage = [self refreshAttributedTextMessage];
                });
            }
            else
            {
                self.attributedTextMessage = [self refreshAttributedTextMessage];
            }
        }
    }
    
    return attributedTextMessage;
}

- (BOOL)hasNoDisplay
{
    if (self.tag == RoomBubbleCellDataTagKeyVerificationNoDisplay)
    {
        return YES;
    }
    
    if (self.tag == RoomBubbleCellDataTagRoomCreationIntro)
    {
        return NO;
    }
    
    return [super hasNoDisplay];
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
            attributedTextMessage = nil;
        }
    }
}

#pragma mark - 

- (NSAttributedString*)refreshAttributedTextMessage
{
    // CAUTION: This method must be called on the main thread.

    // Return the collapsed string only for cells series header
    if (self.collapsed && self.collapsedAttributedTextMessage && self.nextCollapsableCellData)
    {
        return super.collapsedAttributedTextMessage;
    }

    NSMutableAttributedString *currentAttributedTextMsg;
    
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
                componentString = [Tools setTextColorAlpha:.2 inAttributedString:componentString];
            }
            
            // Check whether the timestamp is displayed for this component, and check whether a vertical whitespace is required
            if (((selectedComponentIndex == index && self.addVerticalWhitespaceForSelectedComponentTimestamp) || lastMessageIndex == index) && (self.shouldHideSenderInformation || self.shouldHideSenderName))
            {
                currentAttributedTextMsg = [[NSMutableAttributedString alloc] initWithAttributedString:[RoomBubbleCellData timestampVerticalWhitespace]];
                [currentAttributedTextMsg appendAttributedString:componentString];
            }
            else
            {
                // Init attributed string with the first text component
                currentAttributedTextMsg = [[NSMutableAttributedString alloc] initWithAttributedString:componentString];
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
                componentString = [Tools setTextColorAlpha:.2 inAttributedString:componentString];
            }
            
            // Check whether the timestamp is displayed
            if ((selectedComponentIndex == index && self.addVerticalWhitespaceForSelectedComponentTimestamp) || lastMessageIndex == index)
            {
                [currentAttributedTextMsg appendAttributedString:[RoomBubbleCellData timestampVerticalWhitespace]];
            }
            
            // Append attributed text
            [currentAttributedTextMsg appendAttributedString:componentString];
            
            [self addVerticalWhitespaceToString:currentAttributedTextMsg forEvent:component.event.eventId];
        }
    }
    
    return currentAttributedTextMsg;
}

- (NSInteger)firstVisibleComponentIndex
{
    __block NSInteger firstVisibleComponentIndex = NSNotFound;
    
    if (self.attachment && self.bubbleComponents.count)
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
    
    // Add vertical whitespace in case of reactions.
    additionalVerticalHeight+= [self reactionHeightForEventId:eventId];
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
        
        height+= [self reactionHeightForEventId:eventId];
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

- (CGFloat)reactionHeightForEventId:(NSString*)eventId
{
    CGFloat height = 0;
    
    NSUInteger reactionCount = self.reactions[eventId].reactions.count;
    
    MXAggregatedReactions *aggregatedReactions = self.reactions[eventId];
    
    if (reactionCount)
    {
        CGFloat bubbleReactionsViewWidth = self.maxTextViewWidth - 4;
        
        static BubbleReactionsViewSizer *bubbleReactionsViewSizer;
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            bubbleReactionsViewSizer = [BubbleReactionsViewSizer new];
        });

        BOOL showAllReactions = [self.eventsToShowAllReactions containsObject:eventId];
        BubbleReactionsViewModel *viemModel = [[BubbleReactionsViewModel alloc] initWithAggregatedReactions:aggregatedReactions eventId:eventId showAll:showAllReactions];
        height = [bubbleReactionsViewSizer heightForViewModel:viemModel fittingWidth:bubbleReactionsViewWidth] + RoomBubbleCellLayout.reactionsViewTopMargin;
    }
    
    return height;
}

- (CGFloat)readReceiptHeightForEventId:(NSString*)eventId
{
    CGFloat height = 0;
    
    if (self.readReceipts[eventId].count)
    {
        height = RoomBubbleCellLayout.readReceiptsViewHeight + RoomBubbleCellLayout.readReceiptsViewTopMargin;
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
        
        // Recompute the text message layout
        self.attributedTextMessage = nil;
    }
}

- (void)setSelectedEventId:(NSString *)selectedEventId
{
    // Check whether there is something to do
    if (_selectedEventId || selectedEventId.length)
    { 
        // Update flag
        _selectedEventId = selectedEventId;
        
        // Recompute the text message layout
        self.attributedTextMessage = nil;
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

    return [super hasSameSenderAsBubbleCellData:bubbleCellData];
}

- (BOOL)addEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState
{
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
        case RoomBubbleCellDataTagRoomCreateConfiguration:
            shouldAddEvent = NO;
            break;
        case RoomBubbleCellDataTagRoomCreationIntro:
            shouldAddEvent = NO;
            break;
        default:
            break;
    }
    
    if (shouldAddEvent)
    {
        switch (event.eventType)
        {
            case MXEventTypeRoomMessage:
            {
                NSString *messageType = event.content[@"msgtype"];
                
                if ([messageType isEqualToString:kMXMessageTypeKeyVerificationRequest])
                {
                    shouldAddEvent = NO;
                }
            }
                break;
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
            NSString *msgType = event.content[@"msgtype"];
            
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

        MXJSONModelSetString(accessibilityLabel, self.events.firstObject.content[@"body"]);
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
            accessibilityLabel = NSLocalizedStringFromTable(@"media_type_accessibility_image", @"Vector", nil);
            break;
        case MXKAttachmentTypeAudio:
            accessibilityLabel = NSLocalizedStringFromTable(@"media_type_accessibility_audio", @"Vector", nil);
            break;
        case MXKAttachmentTypeVideo:
            accessibilityLabel = NSLocalizedStringFromTable(@"media_type_accessibility_video", @"Vector", nil);
            break;
        case MXKAttachmentTypeLocation:
            accessibilityLabel = NSLocalizedStringFromTable(@"media_type_accessibility_location", @"Vector", nil);
            break;
        case MXKAttachmentTypeFile:
            accessibilityLabel = NSLocalizedStringFromTable(@"media_type_accessibility_file", @"Vector", nil);
            break;
        case MXKAttachmentTypeSticker:
            accessibilityLabel = NSLocalizedStringFromTable(@"media_type_accessibility_sticker", @"Vector", nil);
            break;
        default:
            accessibilityLabel = @"";
            break;
    }

    return accessibilityLabel;
}

@end
