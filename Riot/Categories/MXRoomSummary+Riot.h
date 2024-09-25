/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"
#import "RoomEncryptionTrustLevel.h"

/**
 Define a `MXRoomSummary` category at Riot level.
 */
@interface MXRoomSummary (Riot)

@property(nonatomic, readonly) BOOL isJoined;

/**
 Set the room avatar in the dedicated MXKImageView.
 The riot style implies to use in order :
 1 - the default avatar if there is one
 2 - the member avatar for < 3 members rooms
 3 - the first letter of the room name.
 
 @param mxkImageView the destinated MXKImageView.
 */
- (void)setRoomAvatarImageIn:(MXKImageView*)mxkImageView;

/**
 Get the trust level in the room.
 
 @return the trust level.
 */
- (RoomEncryptionTrustLevel)roomEncryptionTrustLevel;

@end
