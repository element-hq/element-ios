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

#import "RoomDataSource.h"

#import "EventFormatter.h"
#import "RoomBubbleCellData.h"

#import "MXKRoomBubbleTableViewCell+Vector.h"
#import "AvatarGenerator.h"

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
        
        // Handle timestamp and read receips display at Vector app level (see [tableView: cellForRowAtIndexPath:])
        self.useCustomDateTimeLabel = YES;
        self.useCustomReceipts = YES;
        self.useCustomUnsentButton = YES;
        
        // TODO custom here self.eventsFilterForMessages according to Vector requirements
        
        // Set bubble pagination
        self.bubblesPagination = MXKRoomDataSourceBubblesPaginationPerDay;
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
            if (cellData.hasReadReceipts)
            {
                // Recompute the text message layout
                cellData.attributedTextMessage = nil;
            }
        }
    }
    
    NSArray *readEventIds = receiptEvent.readReceiptEventIds;
    for (NSString* eventId in readEventIds)
    {
        id<MXKRoomBubbleCellDataStoring> bubbleData = [self cellDataOfEventWithEventId:eventId];
        // Recompute the text message layout
        bubbleData.attributedTextMessage = nil;
    }
    
    
    // Let super handle this receipt
    [super didReceiveReceiptEvent:receiptEvent roomState:roomState];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // Finalize cell view customization here
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
    {
        MXKRoomBubbleTableViewCell *bubbleCell = (MXKRoomBubbleTableViewCell*)cell;
        RoomBubbleCellData *cellData = (RoomBubbleCellData*)bubbleCell.bubbleData;
        
        // Check whether this bubble is the last one
        cellData.isLastBubble = (indexPath.row == [tableView numberOfRowsInSection:0] - 1);
        
        // Display timestamp for the last message.
        if (cellData.isLastBubble)
        {
            if (cellData.bubbleComponents.count)
            {
                [bubbleCell addTimestampLabelForComponent:cellData.bubbleComponents.count - 1];
            }
        }
        
        // Handle read receipts display.
        if (cellData.hasReadReceipts && self.showBubbleReceipts)
        {
            // Read receipts container are inserted here on the right side into the overlay container.
            // Some vertical whitespaces are added in message text view (see RoomBubbleCellData class) to insert correctly multiple receipts.
            bubbleCell.bubbleOverlayContainer.backgroundColor = [UIColor clearColor];
            bubbleCell.bubbleOverlayContainer.alpha = 1;
            bubbleCell.bubbleOverlayContainer.userInteractionEnabled = NO;
            bubbleCell.bubbleOverlayContainer.hidden = NO;
            
            NSInteger index = cellData.bubbleComponents.count;
            CGFloat bottomPositionY = bubbleCell.frame.size.height;
            while (index--)
            {
                MXKRoomBubbleComponent *component = cellData.bubbleComponents[index];
                
                if (component.event.mxkState != MXKEventStateSendingFailed)
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
                                [placeholders addObject:[AvatarGenerator generateRoomMemberAvatar:roomMember.userId displayName:roomMember.displayname]];
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
                
                // Prepare the bottom position for the next read receipt container (if any)
                bottomPositionY = bubbleCell.msgTextViewTopConstraint.constant + component.position.y;
            }
        }
        
        // Check whether an event is currently selected: the other messages are then blurred
        if (_selectedEventId)
        {
            NSInteger index = [self indexOfCellDataWithEventId:_selectedEventId];
            
            if (indexPath.row != index)
            {
                // The cell should be displayed in blur mode
                bubbleCell.blurred = YES;
            }
            else
            {
                // Highlight the selected event in the displayed message
                for (NSUInteger index = 0; index < cellData.bubbleComponents.count; index ++)
                {
                    MXKRoomBubbleComponent *component = cellData.bubbleComponents[index];
                    if ([component.event.eventId isEqualToString:_selectedEventId])
                    {
                        [bubbleCell selectComponent:index];
                        break;
                    }
                }
            }
        }
    }
    
    return cell;
}

@end
