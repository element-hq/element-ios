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
