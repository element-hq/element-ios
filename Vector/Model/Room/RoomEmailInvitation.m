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

#import "RoomEmailInvitation.h"

@implementation RoomEmailInvitation

- (instancetype)initWithParams:(NSDictionary *)params
{
    self = [super init];
    if (self)
    {
        if (params)
        {
            _email = params[@"email"];
            _signUrl = params[@"signurl"];
            _roomName = params[@"room_name"];
            _roomAvatarUrl = params[@"room_avatar_url"];
            _inviterName = params[@"inviter_name"];
            _guestAccessToken = params[@"guest_access_token"];
            _guestUserId = params[@"guest_user_id"];
        }
    }
    return self;
}
@end
