/*
 Copyright 2016 OpenMarket Ltd

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

#import "RoomPreviewData.h"

@implementation RoomPreviewData

- (instancetype)initWithRoomId:(NSString *)roomId andSession:(MXSession *)mxSession
{
    self = [super init];
    if (self)
    {
        _roomId = roomId;
        _mxSession = mxSession;
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

- (void)peekInRoom:(void (^)(BOOL successed))completion
{
    [_mxSession peekInRoomWithRoomId:_roomId success:^(MXPeekingRoom *peekingRoom) {

        // Create the room data source
        // It will be automatically released in the destroy metho of the RoomViewController
        // that will display the data source
        _roomDataSource = [[RoomDataSource alloc] initWithPeekingRoom:peekingRoom andInitialEventId:_eventId];
        [_roomDataSource finalizeInitialization];

        _roomName = peekingRoom.state.displayname;
        _roomAvatarUrl = peekingRoom.state.avatar;

        completion(YES);

    } failure:^(NSError *error) {
        completion(NO);
    }];
}

@end
