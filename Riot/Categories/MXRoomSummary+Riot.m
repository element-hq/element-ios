/*
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd
 
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
