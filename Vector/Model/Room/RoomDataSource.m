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
        //FIXME GFO: disable default receipts display
        //self.useCustomReceipts = YES;
        
        // TODO custom here self.eventsFilterForMessages according to Vector requirements
        
        // Set bubble pagination
        self.bubblesPagination = MXKRoomDataSourceBubblesPaginationPerDay;
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // Finalize cell view customization here
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
    {
        MXKRoomBubbleTableViewCell *bubbleCell = (MXKRoomBubbleTableViewCell*)cell;
        
        // Display timestamp for the last message.
        if (indexPath.row == [tableView numberOfRowsInSection:0] - 1)
        {
            if (bubbleCell.bubbleData.bubbleComponents.count)
            {
                [bubbleCell addTimestampLabelForComponent:bubbleCell.bubbleData.bubbleComponents.count - 1];
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
                MXKRoomBubbleCellData *cellData = (MXKRoomBubbleCellData*)bubbleCell.bubbleData;
                
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
