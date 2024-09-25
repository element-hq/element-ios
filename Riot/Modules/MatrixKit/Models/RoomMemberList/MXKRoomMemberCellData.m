/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
