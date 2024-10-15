/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomPreviewData.h"

#import "GeneratedInterface-Swift.h"

@implementation RoomPreviewData

- (instancetype)initWithRoomId:(NSString *)roomId andSession:(MXSession *)mxSession
{
    self = [super init];
    if (self)
    {
        _roomId = roomId;
        _mxSession = mxSession;
        _numJoinedMembers = -1;
    }
    return self;
}

- (instancetype)initWithRoomId:(NSString *)roomId emailInvitationParams:(NSDictionary *)emailInvitationParams andSession:(MXSession *)mxSession
{
    self = [self initWithRoomId:roomId andSession:mxSession];
    if (self)
    {
        _emailInvitation = [[RoomEmailInvitation alloc] initWithParams:emailInvitationParams];

        // Report decoded data
        _roomName = _emailInvitation.roomName;
        _roomAvatarUrl = _emailInvitation.roomAvatarUrl;
    }
    return self;
}

- (instancetype)initWithPublicRoom:(MXPublicRoom*)publicRoom andSession:(MXSession*)mxSession
{
    self = [self initWithRoomId:publicRoom.roomId andSession:mxSession];
    if (self)
    {
        // Report public room data
        _roomName = publicRoom.displayname;
        _roomAvatarUrl = publicRoom.avatarUrl;
        _roomTopic = publicRoom.topic;
        _roomCanonicalAlias = publicRoom.canonicalAlias;
        _roomAliases = publicRoom.aliases;
        _numJoinedMembers = publicRoom.numJoinedMembers;
        
        // First try to fallback to the name if displayname isn't present
        if (!_roomName.length)
        {
            _roomName = publicRoom.name;
        }
        
        if (!_roomName.length)
        {
            // Use the canonical alias if present.
            _roomName = publicRoom.canonicalAlias;
        }
        
        if (!_roomName.length)
        {
            // Consider the room aliases to define a default room name.
            _roomName = _roomAliases.firstObject;
        }
    }
    return self;
}

- (instancetype)initWithSpaceChildInfo:(MXSpaceChildInfo*)childInfo andSession:(MXSession*)mxSession
{
    self = [self init];
    if (self)
    {
        _roomId = childInfo.childRoomId;
        _roomName = childInfo.name;
        _roomAvatarUrl = childInfo.avatarUrl;
        _roomTopic = childInfo.topic;
        _numJoinedMembers = childInfo.activeMemberCount;
        _mxSession = mxSession;
    }
    return self;
}

- (void)dealloc
{
    if (_roomDataSource)
    {
        [_roomDataSource destroy];
        _roomDataSource = nil;
    }
    
    _emailInvitation = nil;
}

- (void)peekInRoom:(void (^)(BOOL succeeded))completion
{
    MXWeakify(self);
    [_mxSession peekInRoomWithRoomId:_roomId success:^(MXPeekingRoom *peekingRoom) {
        MXStrongifyAndReturnIfNil(self);

        // Create the room data source
        MXWeakify(self);
        [RoomDataSource loadRoomDataSourceWithPeekingRoom:peekingRoom andInitialEventId:self.eventId onComplete:^(id roomDataSource) {
            MXStrongifyAndReturnIfNil(self);

            self->_roomDataSource = roomDataSource;

            [self.roomDataSource finalizeInitialization];
            self.roomDataSource.markTimelineInitialEvent = YES;

            self->_roomName = peekingRoom.summary.displayName;
            self->_roomAvatarUrl = peekingRoom.summary.avatar;

            self->_roomTopic = [MXTools stripNewlineCharacters:peekingRoom.summary.topic];;
            self->_roomAliases = peekingRoom.summary.aliases;

            // Room members count
            // Note that room members presence/activity is not available
            self->_numJoinedMembers = peekingRoom.summary.membersCount.joined;

            completion(YES);
        }];

    } failure:^(NSError *error) {
        MXStrongifyAndReturnIfNil(self);
        
        if(self->_roomName == nil || self->_roomName.length == 0) {
            self->_roomName = self->_roomId;
        }
        completion(NO);
    }];
}

@end
