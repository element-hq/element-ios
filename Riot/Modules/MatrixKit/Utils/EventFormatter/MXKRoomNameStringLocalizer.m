/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomNameStringLocalizer.h"
#import "MXKSwiftHeader.h"

@implementation MXKRoomNameStringLocalizer

- (NSString *)emptyRoom
{
    return [VectorL10n roomDisplaynameEmptyRoom];
}

- (NSString *)twoMembers:(NSString *)firstMember second:(NSString *)secondMember
{
    return [VectorL10n roomDisplaynameTwoMembers:firstMember :secondMember];
}

- (NSString *)moreThanTwoMembers:(NSString *)firstMember count:(NSNumber *)memberCount
{
    return [VectorL10n roomDisplaynameMoreThanTwoMembers:firstMember :memberCount.stringValue];
}

- (NSString *)allOtherMembersLeft:(NSString *)member
{
    return [VectorL10n roomDisplaynameAllOtherMembersLeft:member];
}

@end
