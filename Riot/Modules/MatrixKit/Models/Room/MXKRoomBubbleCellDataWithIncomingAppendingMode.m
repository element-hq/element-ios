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

#import "MXKRoomBubbleCellDataWithIncomingAppendingMode.h"

@implementation MXKRoomBubbleCellDataWithIncomingAppendingMode

#pragma mark - MXKRoomBubbleCellDataStoring

- (BOOL)addEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState
{
    // Do not merge outgoing events
    if  ([event.sender isEqualToString:roomDataSource.mxSession.myUser.userId])
    {
        return NO;
    }
    
    return [super addEvent:event andRoomState:roomState];
}

- (BOOL)mergeWithBubbleCellData:(id<MXKRoomBubbleCellDataStoring>)bubbleCellData
{
    // Do not merge outgoing events
    if  ([bubbleCellData.senderId isEqualToString:roomDataSource.mxSession.myUser.userId])
    {
        return NO;
    }
    
    return [super mergeWithBubbleCellData:bubbleCellData];
}

@end
