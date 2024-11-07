/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

#import <MatrixSDK/MXSession.h>

@class HomeserverConfiguration;

@interface MXSession (Riot)

/**
 The current number of rooms with missed notifications, including the invites.
 */
- (NSUInteger)vc_missedDiscussionsCount;

/**
Return the homeserver configuration based on HS Well-Known or BuildSettings properties according to existing values.
*/
- (HomeserverConfiguration*)vc_homeserverConfiguration;

/**
 Riot version of [MXSession canEnableE2EByDefaultInNewRoomWithUsers:]
 */
- (MXHTTPOperation*)vc_canEnableE2EByDefaultInNewRoomWithUsers:(NSArray<NSString*>*)userIds
                                                         success:(void (^)(BOOL canEnableE2E))success
                                                         failure:(void (^)(NSError *error))failure;

/**
 Indicate YES if secure key backup can be setup
 */
- (BOOL)vc_canSetupSecureBackup;

// TODO: Move to SDK
- (MXRoom*)vc_roomWithIdOrAlias:(NSString*)roomIdOrAlias;

@end
