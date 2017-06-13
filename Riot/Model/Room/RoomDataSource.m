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

@implementation RoomDataSource

- (instancetype)initWithRoomId:(NSString *)roomId andMatrixSession:(MXSession *)matrixSession
{
    self = [super initWithRoomId:roomId andMatrixSession:matrixSession];
    if (self)
    {
        // Replace default Cell data class
        [self registerCellDataClass:RoomBubbleCellData.class forCellIdentifier:kMXKRoomBubbleCellDataIdentifier];
        
        // Replace event formatter
        self.eventFormatter = [[EventFormatter alloc] initWithMatrixSession:self.mxSession];
        self.eventFormatter.treatMatrixUserIdAsLink = YES;
        self.eventFormatter.treatMatrixRoomIdAsLink = YES;
        self.eventFormatter.treatMatrixRoomAliasAsLink = YES;
        
        // Apply the event types filter to display only the wanted event types.
        self.eventFormatter.eventTypesFilterForMessages = [MXKAppSettings standardAppSettings].eventsFilterForMessages;

        // Handle timestamp and read receips display at Vector app level (see [tableView: cellForRowAtIndexPath:])
        self.useCustomDateTimeLabel = YES;
        self.useCustomReceipts = YES;
        self.useCustomUnsentButton = YES;
        
        // Set bubble pagination
        self.bubblesPagination = MXKRoomDataSourceBubblesPaginationPerDay;
        
        self.markTimelineInitialEvent = NO;
    }
    return self;
}

- (void)didReceiveReceiptEvent:(MXEvent *)receiptEvent roomState:(MXRoomState *)roomState
{
    // Override this callback to force rendering of each cell with read receipts information.
    @synchronized(bubbles)
    {
        for (RoomBubbleCellData *cellData in bubbles)
        {
            cellData.hasReadReceipts = NO;
        }
    }
    
    NSArray *readEventIds = receiptEvent.readReceiptEventIds;
    for (NSString* eventId in readEventIds)
    {
        RoomBubbleCellData *cellData = [self cellDataOfEventWithEventId:eventId];
        // Ignore the read receipts on the events without an actual display.
        cellData.hasReadReceipts = (cellData.attributedTextMessage != nil);
    }
    
    [super didReceiveReceiptEvent:receiptEvent roomState:roomState];
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
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // Finalize cell view customization here
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
    {
        MXKRoomBubbleTableViewCell *bubbleCell = (MXKRoomBubbleTableViewCell*)cell;
        RoomBubbleCellData *cellData = (RoomBubbleCellData*)bubbleCell.bubbleData;
        NSArray *bubbleComponents = cellData.bubbleComponents;
        
        // Display timestamp of the last message
        if (cellData.containsLastMessage)
        {
            [bubbleCell addTimestampLabelForComponent:cellData.mostRecentComponentIndex];
        }
        
        // Handle read receipts and read marker display.
        // Ignore the read receipts on the bubble without actual display.
        if ((self.showBubbleReceipts && cellData.hasReadReceipts) || self.showReadMarker)
        {
            // Read receipts container are inserted here on the right side into the overlay container.
            // Some vertical whitespaces are added in message text view (see RoomBubbleCellData class) to insert correctly multiple receipts.
            bubbleCell.bubbleOverlayContainer.backgroundColor = [UIColor clearColor];
            bubbleCell.bubbleOverlayContainer.alpha = 1;
            bubbleCell.bubbleOverlayContainer.userInteractionEnabled = NO;
            bubbleCell.bubbleOverlayContainer.hidden = NO;
            
            NSInteger index = bubbleComponents.count;
            CGFloat bottomPositionY = bubbleCell.frame.size.height;
            while (index--)
            {
                MXKRoomBubbleComponent *component = bubbleComponents[index];
                
                if (component.event.sentState != MXEventSentStateFailed)
                {
                    // Handle read receipts (if any)
                    if (self.showBubbleReceipts && cellData.hasReadReceipts)
                    {
                        // Get the events receipts by ignoring the current user receipt.
                        NSArray* receipts = [self.room getEventReceipts:component.event.eventId sorted:YES];
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
                                MXRoomMember * roomMember = [self.room.state memberWithUserId:data.userId];
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
                            
                            avatarsContainer.translatesAutoresizingMaskIntoConstraints = NO;
                            avatarsContainer.accessibilityIdentifier = @"readReceiptsContainer";
                            [bubbleCell.bubbleOverlayContainer addSubview:avatarsContainer];
                            
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
                                                                                                     toItem:bubbleCell.bubbleOverlayContainer
                                                                                                  attribute:NSLayoutAttributeTrailing
                                                                                                 multiplier:1.0
                                                                                                   constant:-6];
                            NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:avatarsContainer
                                                                                             attribute:NSLayoutAttributeTop
                                                                                             relatedBy:NSLayoutRelationEqual
                                                                                                toItem:bubbleCell.bubbleOverlayContainer
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
        cellData.selectedEventId = selectedEventId;
    }
    
    _selectedEventId = selectedEventId;
}

@end
