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

#import "MXKRoomMemberCellData.h"

#import "MXKRoomMemberListDataSource.h"

@interface MXKRoomMemberCellData ()
{
    MXKRoomMemberListDataSource *roomMemberListDataSource;
}

@end

@implementation MXKRoomMemberCellData
@synthesize roomMember;
@synthesize memberDisplayName, powerLevel, isTyping;

- (instancetype)initWithRoomMember:(MXRoomMember*)member roomState:(MXRoomState*)roomState andRoomMemberListDataSource:(MXKRoomMemberListDataSource*)memberListDataSource
{
    self = [self init];
    if (self)
    {
        roomMember = member;
        roomMemberListDataSource = memberListDataSource;
        
        // Report member info from the current room state
        memberDisplayName = [roomState.members memberName:roomMember.userId];
        powerLevel = [roomState memberNormalizedPowerLevel:roomMember.userId];
        isTyping = NO;
    }
    
    return  self;
}

- (void)updateWithRoomState:(MXRoomState*)roomState
{
    memberDisplayName = [roomState.members memberName:roomMember.userId];
    powerLevel = [roomState memberNormalizedPowerLevel:roomMember.userId];
}

- (void)dealloc
{
    roomMember = nil;
    roomMemberListDataSource = nil;
}

- (MXSession*)mxSession
{
    return roomMemberListDataSource.mxSession;
}

@end
