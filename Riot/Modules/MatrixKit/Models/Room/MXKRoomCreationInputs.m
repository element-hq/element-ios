/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomCreationInputs.h"

#import <MatrixSDK/MXSession.h>

@interface MXKRoomCreationInputs ()
{
    NSMutableArray *participants;
}
@end

@implementation MXKRoomCreationInputs

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _roomVisibility = kMXRoomDirectoryVisibilityPrivate;
    }
    return self;
}

- (void)setRoomParticipants:(NSArray *)roomParticipants
{
    participants = [NSMutableArray arrayWithArray:roomParticipants];
}

- (NSArray*)roomParticipants
{
    return participants;
}

- (void)addParticipant:(NSString *)participantId
{
    if (participantId.length)
    {
        if (!participants)
        {
            participants = [NSMutableArray array];
        }
        [participants addObject:participantId];
    }
}

- (void)removeParticipant:(NSString *)participantId
{
    if (participantId.length)
    {
        [participants removeObject:participantId];
        
        if (!participants.count)
        {
            participants = nil;
        }
    }
}

@end
