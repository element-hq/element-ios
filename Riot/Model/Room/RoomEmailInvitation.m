/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
