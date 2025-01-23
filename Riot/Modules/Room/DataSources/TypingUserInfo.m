// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#import "TypingUserInfo.h"

@implementation TypingUserInfo

- (instancetype) initWithMember:(MXRoomMember*)member
{
    self = [self initWithUserId:member.userId];
    
    if (self)
    {
        self.displayName = member.displayname;
        self.avatarUrl = member.avatarUrl;
    }
    
    return self;
}

- (instancetype) initWithUserId:(NSString*)userId
{
    self = [super init];
    
    if (self)
    {
        self.userId = userId;
    }
    
    return self;
}

@end
