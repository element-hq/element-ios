/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXRoomSummary+Riot.h"

#import "AvatarGenerator.h"

#import "GeneratedInterface-Swift.h"

@implementation MXRoomSummary (Riot)

- (void)setRoomAvatarImageIn:(MXKImageView*)mxkImageView
{
    [mxkImageView vc_setRoomAvatarImageWith:self.avatar
                                     roomId:self.roomId
                                displayName:self.displayName
                               mediaManager:self.mxSession.mediaManager];
}

- (RoomEncryptionTrustLevel)roomEncryptionTrustLevel
{
    MXUsersTrustLevelSummary *trust = self.trust;
    if (!trust)
    {
        MXLogError(@"[MXRoomSummary] roomEncryptionTrustLevel: trust is missing");
        return RoomEncryptionTrustLevelUnknown;
    }
    
    EncryptionTrustLevel *encryption = [[EncryptionTrustLevel alloc] init];
    return [encryption roomTrustLevelWithSummary:trust];
}

- (BOOL)isJoined
{
    return self.membership == MXMembershipJoin || self.membershipTransitionState == MXMembershipTransitionStateJoined;
}

@end
