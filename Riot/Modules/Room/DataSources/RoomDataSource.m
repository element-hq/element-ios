/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "RoomDataSource.h"

#import "EventFormatter.h"
#import "RoomBubbleCellData.h"

#import "MXKRoomBubbleTableViewCell+Riot.h"
#import "AvatarGenerator.h"
#import "RiotDesignValues.h"

#import "MXRoom+Riot.h"

@interface RoomDataSource()
{
    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
}

@end

@implementation RoomDataSource

- (instancetype)initWithRoomId:(NSString *)roomId andMatrixSession:(MXSession *)matrixSession
{
    self = [super initWithRoomId:roomId andMatrixSession:matrixSession];
    if (self)
    {
        // Replace default Cell data class
        [self registerCellDataClass:RoomBubbleCellData.class forCellIdentifier:kMXKRoomBubbleCellDataIdentifier];
        
        // Replace the event formatter
        [self updateEventFormatter];

        // Handle timestamp and read receips display at Vector app level (see [tableView: cellForRowAtIndexPath:])
        self.useCustomDateTimeLabel = YES;
        self.useCustomReceipts = YES;
        self.useCustomUnsentButton = YES;
        
        // Set bubble pagination
        self.bubblesPagination = MXKRoomDataSourceBubblesPaginationPerDay;
        
        self.markTimelineInitialEvent = NO;
        
        // Observe user interface theme change.
        kRiotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            
            // Force room data reload.
            [self updateEventFormatter];
            [self reload];
            
        }];
    }
    return self;
}

- (void)updateEventFormatter
{
    // Set a new event formatter
    // TODO: We should use the same EventFormatter instance for all the rooms of a mxSession.
    self.eventFormatter = [[EventFormatter alloc] initWithMatrixSession:self.mxSession];
    self.eventFormatter.treatMatrixUserIdAsLink = YES;
    self.eventFormatter.treatMatrixRoomIdAsLink = YES;
    self.eventFormatter.treatMatrixRoomAliasAsLink = YES;
    self.eventFormatter.treatMatrixGroupIdAsLink = YES;
    
    // Apply the event types filter to display only the wanted event types.
    self.eventFormatter.eventTypesFilterForMessages = [MXKAppSettings standardAppSettings].eventsFilterForMessages;
}

- (void)destroy
{
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
    }
    
    [super destroy];
}

- (void)didReceiveReceiptEvent:(MXEvent *)receiptEvent roomState:(MXRoomState *)roomState
{
    // Do the processing on the same processing queue as MXKRoomDataSource
    dispatch_async(MXKRoomDataSource.processingQueue, ^{

        // Remove the previous displayed read receipt for each user who sent a
        // new read receipt.
        // To implement it, we need to find the sender id of each new read receipt
        // among the read receipts array of all events in all bubbles.
        NSArray *readReceiptSenders = receiptEvent.readReceiptSenders;

        @synchronized(bubbles)
        {
            for (RoomBubbleCellData *cellData in bubbles)
            {
                NSMutableDictionary<NSString* /* eventId */, NSArray<MXReceiptData*> *> *updatedCellDataReadReceipts = [NSMutableDictionary dictionary];

                for (NSString *eventId in cellData.readReceipts)
                {
                    for (MXReceiptData *receiptData in cellData.readReceipts[eventId])
                    {
                        for (NSString *senderId in readReceiptSenders)
                        {
                            if ([receiptData.userId isEqualToString:senderId])
                            {
                                 if (!updatedCellDataReadReceipts[eventId])
                                {
                                    updatedCellDataReadReceipts[eventId] = cellData.readReceipts[eventId];
                                }

                                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userId!=%@", receiptData.userId];
                                updatedCellDataReadReceipts[eventId] = [updatedCellDataReadReceipts[eventId] filteredArrayUsingPredicate:predicate];
                                break;
                            }
                        }

                    }
                }

                // Flush found changed to the cell data
                for (NSString *eventId in updatedCellDataReadReceipts)
                {
                    if (updatedCellDataReadReceipts[eventId].count)
                    {
                        cellData.readReceipts[eventId] = updatedCellDataReadReceipts[eventId];
                    }
                    else
                    {
                        cellData.readReceipts[eventId] = nil;
                    }
                }
            }
        }

        // Update cell data we have received a read receipt for
        NSArray *readEventIds = receiptEvent.readReceiptEventIds;
        for (NSString* eventId in readEventIds)
        {
            RoomBubbleCellData *cellData = [self cellDataOfEventWithEventId:eventId];
            if (cellData)
            {
                @synchronized(bubbles)
                {
                    if (!cellData.hasNoDisplay)
                    {
                        cellData.readReceipts[eventId] = [self.room getEventReceipts:eventId sorted:YES];
                    }
                    else
                    {
                        // Ignore the read receipts on the events without an actual display.
                        cellData.readReceipts[eventId] = nil;
                    }
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            // TODO: Be smarter and update only updated cells
            [super didReceiveReceiptEvent:receiptEvent roomState:roomState];
        });
    });
}

#pragma  mark -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = [super tableView:tableView numberOfRowsInSection:section];
    
    if (count)
    {
        // Enable the containsLastMessage flag for the cell data which contains the last message.
        @synchronized(bubbles)
        {
            // Reset first all cell data
            for (RoomBubbleCellData *cellData in bubbles)
            {
                cellData.containsLastMessage = NO;
            }

            // The cell containing the last message is the last one with an actual display.
            NSInteger index = bubbles.count;
            while (index--)
            {
                RoomBubbleCellData *cellData = bubbles[index];
                if (cellData.attributedTextMessage)
                {
                    cellData.containsLastMessage = YES;
                    break;
                }
            }
        }
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Do cell data customization that needs to be done before [MXKRoomBubbleTableViewCell render]
    RoomBubbleCellData *roomBubbleCellData = [self cellDataAtIndex:indexPath.row];

    // Use the Riot style placeholder
    if (!roomBubbleCellData.senderAvatarPlaceholder)
    {
        roomBubbleCellData.senderAvatarPlaceholder = [AvatarGenerator generateAvatarForMatrixItem:roomBubbleCellData.senderId withDisplayName:roomBubbleCellData.senderDisplayName];
    }

    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // Finalize cell view customization here
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
    {
        MXKRoomBubbleTableViewCell *bubbleCell = (MXKRoomBubbleTableViewCell*)cell;
        RoomBubbleCellData *cellData = (RoomBubbleCellData*)bubbleCell.bubbleData;
        NSArray *bubbleComponents = cellData.bubbleComponents;

        BOOL isCollapsableCellCollapsed = cellData.collapsable && cellData.collapsed;
        
        // Display timestamp of the last message
        if (cellData.containsLastMessage && !isCollapsableCellCollapsed)
        {
            [bubbleCell addTimestampLabelForComponent:cellData.mostRecentComponentIndex];
        }
        
        // Handle read receipts and read marker display.
        // Ignore the read receipts on the bubble without actual display.
        // Ignore the read receipts on collapsed bubbles
        if ((self.showBubbleReceipts && cellData.readReceipts.count && !isCollapsableCellCollapsed) || self.showReadMarker)
        {
            // Read receipts container are inserted here on the right side into the content view.
            // Some vertical whitespaces are added in message text view (see RoomBubbleCellData class) to insert correctly multiple receipts.
            NSInteger index = bubbleComponents.count;
            CGFloat bottomPositionY = bubbleCell.frame.size.height;
            while (index--)
            {
                MXKRoomBubbleComponent *component = bubbleComponents[index];
                
                if (component.event.sentState != MXEventSentStateFailed)
                {
                    // Handle read receipts (if any)
                    if (self.showBubbleReceipts && cellData.readReceipts.count && !isCollapsableCellCollapsed)
                    {
                        // Get the events receipts by ignoring the current user receipt.
                        NSArray* receipts =  cellData.readReceipts[component.event.eventId];
                        NSMutableArray *roomMembers;
                        NSMutableArray *placeholders;
                        
                        // Check whether some receipts are found
                        if (receipts.count)
                        {
                            // Retrieve the corresponding room members
                            roomMembers = [[NSMutableArray alloc] initWithCapacity:receipts.count];
                            placeholders = [[NSMutableArray alloc] initWithCapacity:receipts.count];
                            
                            for (MXReceiptData* data in receipts)
                            {
                                MXRoomMember * roomMember = [self.roomState.members memberWithUserId:data.userId];
                                if (roomMember)
                                {
                                    [roomMembers addObject:roomMember];
                                    [placeholders addObject:[AvatarGenerator generateAvatarForMatrixItem:roomMember.userId withDisplayName:roomMember.displayname]];
                                }
                            }
                        }
                        
                        // Check whether some receipts are found
                        if (roomMembers.count)
                        {
                            // Define the read receipts container, positioned on the right border of the bubble cell (Note the right margin 6 pts).
                            MXKReceiptSendersContainer* avatarsContainer = [[MXKReceiptSendersContainer alloc] initWithFrame:CGRectMake(bubbleCell.frame.size.width - 156, bottomPositionY - 13, 150, 12) andRestClient:self.mxSession.matrixRestClient];
                            
                            // Custom avatar display
                            avatarsContainer.maxDisplayedAvatars = 5;
                            avatarsContainer.avatarMargin = 6;
                            
                            // Set the container tag to be able to retrieve read receipts container from component index (see component selection in MXKRoomBubbleTableViewCell (Vector) category).
                            avatarsContainer.tag = index;
                            
                            [avatarsContainer refreshReceiptSenders:roomMembers withPlaceHolders:placeholders andAlignment:ReadReceiptAlignmentRight];
                            avatarsContainer.readReceipts = receipts;
                            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:cell action:@selector(onReceiptContainerTap:)];
                            [tapRecognizer setNumberOfTapsRequired:1];
                            [tapRecognizer setNumberOfTouchesRequired:1];
                            [avatarsContainer addGestureRecognizer:tapRecognizer];
                            avatarsContainer.userInteractionEnabled = YES;
                            
                            avatarsContainer.translatesAutoresizingMaskIntoConstraints = NO;
                            avatarsContainer.accessibilityIdentifier = @"readReceiptsContainer";
                            
                            // Add this read receipts container in the content view
                            if (!bubbleCell.tmpSubviews)
                            {
                                bubbleCell.tmpSubviews = [NSMutableArray arrayWithArray:@[avatarsContainer]];
                            }
                            else
                            {
                                [bubbleCell.tmpSubviews addObject:avatarsContainer];
                            }
                            [bubbleCell.contentView addSubview:avatarsContainer];
                            
                            // Force receipts container size
                            NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:avatarsContainer
                                                                                               attribute:NSLayoutAttributeWidth
                                                                                               relatedBy:NSLayoutRelationEqual
                                                                                                  toItem:nil
                                                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                                                              multiplier:1.0
                                                                                                constant:150];
                            NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:avatarsContainer
                                                                                                attribute:NSLayoutAttributeHeight
                                                                                                relatedBy:NSLayoutRelationEqual
                                                                                                   toItem:nil
                                                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                                                               multiplier:1.0
                                                                                                 constant:12];
                            
                            // Force receipts container position
                            NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:avatarsContainer
                                                                                                  attribute:NSLayoutAttributeTrailing
                                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                                     toItem:avatarsContainer.superview
                                                                                                  attribute:NSLayoutAttributeTrailing
                                                                                                 multiplier:1.0
                                                                                                   constant:-6];
                            NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:avatarsContainer
                                                                                             attribute:NSLayoutAttributeTop
                                                                                             relatedBy:NSLayoutRelationEqual
                                                                                                toItem:avatarsContainer.superview
                                                                                             attribute:NSLayoutAttributeTop
                                                                                            multiplier:1.0
                                                                                              constant:bottomPositionY - 13];
                            
                            // Available on iOS 8 and later
                            [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint, topConstraint, trailingConstraint]];
                        }
                    }
                    
                    // Check whether the read marker must be displayed here.
                    if (self.showReadMarker)
                    {
                        // The read marker is added into the overlay container.
                        // CAUTION: Keep disabled the user interaction on this container to not disturb tap gesture handling.
                        bubbleCell.bubbleOverlayContainer.backgroundColor = [UIColor clearColor];
                        bubbleCell.bubbleOverlayContainer.alpha = 1;
                        bubbleCell.bubbleOverlayContainer.userInteractionEnabled = NO;
                        bubbleCell.bubbleOverlayContainer.hidden = NO;
                        
                        if ([component.event.eventId isEqualToString:self.room.accountData.readMarkerEventId])
                        {
                            bubbleCell.readMarkerView = [[UIView alloc] initWithFrame:CGRectMake(0, bottomPositionY - 2, bubbleCell.bubbleOverlayContainer.frame.size.width, 2)];
                            bubbleCell.readMarkerView.backgroundColor = kRiotColorGreen;
                            // Hide by default the marker, it will be shown and animated when the cell will be rendered.
                            bubbleCell.readMarkerView.hidden = YES;
                            bubbleCell.readMarkerView.tag = index;
                            
                            bubbleCell.readMarkerView.translatesAutoresizingMaskIntoConstraints = NO;
                            bubbleCell.readMarkerView.accessibilityIdentifier = @"readMarker";
                            [bubbleCell.bubbleOverlayContainer addSubview:bubbleCell.readMarkerView];
                            
                            // Force read marker constraints
                            bubbleCell.readMarkerViewTopConstraint = [NSLayoutConstraint constraintWithItem:bubbleCell.readMarkerView
                                                                                             attribute:NSLayoutAttributeTop
                                                                                             relatedBy:NSLayoutRelationEqual
                                                                                                toItem:bubbleCell.bubbleOverlayContainer
                                                                                             attribute:NSLayoutAttributeTop
                                                                                            multiplier:1.0
                                                                                              constant:bottomPositionY - 2];
                            bubbleCell.readMarkerViewLeadingConstraint = [NSLayoutConstraint constraintWithItem:bubbleCell.readMarkerView
                                                                                                 attribute:NSLayoutAttributeLeading
                                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                                    toItem:bubbleCell.bubbleOverlayContainer
                                                                                                 attribute:NSLayoutAttributeLeading
                                                                                                multiplier:1.0
                                                                                                  constant:0];
                            bubbleCell.readMarkerViewTrailingConstraint = [NSLayoutConstraint constraintWithItem:bubbleCell.bubbleOverlayContainer
                                                                                                  attribute:NSLayoutAttributeTrailing
                                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                                     toItem:bubbleCell.readMarkerView
                                                                                                  attribute:NSLayoutAttributeTrailing
                                                                                                 multiplier:1.0
                                                                                                   constant:0];
                            
                            bubbleCell.readMarkerViewHeightConstraint = [NSLayoutConstraint constraintWithItem:bubbleCell.readMarkerView
                                                                                                attribute:NSLayoutAttributeHeight
                                                                                                relatedBy:NSLayoutRelationEqual
                                                                                                   toItem:nil
                                                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                                                               multiplier:1.0
                                                                                                 constant:2];
                            
                            [NSLayoutConstraint activateConstraints:@[bubbleCell.readMarkerViewTopConstraint, bubbleCell.readMarkerViewLeadingConstraint, bubbleCell.readMarkerViewTrailingConstraint, bubbleCell.readMarkerViewHeightConstraint]];
                        }
                    }
                }
                
                // Prepare the bottom position for the next read receipt container (if any)
                bottomPositionY = bubbleCell.msgTextViewTopConstraint.constant + component.position.y;
            }
        }
        
        // Check whether an event is currently selected: the other messages are then blurred
        if (_selectedEventId)
        {
            // Check whether the selected event belongs to this bubble
            NSInteger selectedComponentIndex = cellData.selectedComponentIndex;
            if (selectedComponentIndex != NSNotFound)
            {
                [bubbleCell selectComponent:cellData.selectedComponentIndex];
            }
            else
            {
                bubbleCell.blurred = YES;
            }
        }

        // Reset the marker if any
        if (bubbleCell.markerView)
        {
            [bubbleCell.markerView removeFromSuperview];
        }

        // Manage initial event (case of permalink or search result)
        if (self.timeline.initialEventId && self.markTimelineInitialEvent)
        {
            // Check if the cell contains this initial event
            for (NSUInteger index = 0; index < bubbleComponents.count; index++)
            {
                MXKRoomBubbleComponent *component = bubbleComponents[index];

                if ([component.event.eventId isEqualToString:self.timeline.initialEventId])
                {
                    // If yes, mark the event
                    [bubbleCell markComponent:index];
                    break;
                }
            }
        }
        
        // Auto animate the sticker in case of animated gif
        bubbleCell.isAutoAnimatedGif = (cellData.attachment && cellData.attachment.type == MXKAttachmentTypeSticker);
    }

    return cell;
}

#pragma mark -

- (void)setSelectedEventId:(NSString *)selectedEventId
{
    // Cancel the current selection (if any)
    if (_selectedEventId)
    {
        RoomBubbleCellData *cellData = [self cellDataOfEventWithEventId:_selectedEventId];
        cellData.selectedEventId = nil;
    }
    
    if (selectedEventId.length)
    {
        RoomBubbleCellData *cellData = [self cellDataOfEventWithEventId:selectedEventId];

        if (cellData.collapsed && cellData.nextCollapsableCellData)
        {
            // Select nothing for a collased cell but open it
            [self collapseRoomBubble:cellData collapsed:NO];
            return;
        }
        else
        {
            cellData.selectedEventId = selectedEventId;
        }
    }
    
    _selectedEventId = selectedEventId;
}

- (Widget *)jitsiWidget
{
    Widget *jitsiWidget;

    // Note: Manage only one jitsi widget at a time for the moment
    jitsiWidget = [[WidgetManager sharedManager] widgetsOfTypes:@[kWidgetTypeJitsi] inRoom:self.room withRoomState:self.roomState].firstObject;

    return jitsiWidget;
}

@end
