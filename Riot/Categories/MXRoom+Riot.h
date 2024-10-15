/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "UserEncryptionTrustLevel.h"
#import <MatrixSDK/MatrixSDK.h>

/**
 Define a `MXRoom` category at Riot level.
 */
@interface MXRoom (Riot)

/**
 Tell whether all the notifications are disabled for the room.
 */
@property(nonatomic, readonly, getter=isMute) BOOL mute;

/**
 Tell whether the regular notifications are disabled for the room.
 */
@property(nonatomic, readonly, getter=isMentionsOnly) BOOL mentionsOnly;

/*
 Observer when a rules deletion fails.
 */
@property (nonatomic) id notificationCenterDidFailObserver;

/*
 Observer when a rules deletion succeeds.
 */
@property (nonatomic) id notificationCenterDidUpdateObserver;

/**
 Update the room tag.
 
 @param tag the new tag value
 @param completion the block to execute at the end of the operation (independently if it succeeded or not).
 You may specify nil for this parameter.
 */
- (void)setRoomTag:(NSString*)tag completion:(void (^)(void))completion;

/**
 Disable all the room notifications.
 
 @param completion the block to execute at the end of the operation (independently if it succeeded or not).
 You may specify nil for this parameter.
 */
- (void)mute:(void (^)(void))completion;

/**
 Set the room notifications in mention only mode.
 
 @param completion the block to execute at the end of the operation (independently if it succeeded or not).
 You may specify nil for this parameter.
 */
- (void)mentionsOnly:(void (^)(void))completion;

/**
 Enable the room notifications.
 
 @param completion the block to execute at the end of the operation (independently if it succeeded or not).
 You may specify nil for this parameter.
 */
- (void)allMessages:(void (^)(void))completion;

/**
 Get user encryption trust level.

 @param userId The user id.
 @param onComplete the block providing the trust level.
 */
- (void)encryptionTrustLevelForUserId:(NSString*)userId onComplete:(void (^)(UserEncryptionTrustLevel userEncryptionTrustLevel))onComplete;

@end
