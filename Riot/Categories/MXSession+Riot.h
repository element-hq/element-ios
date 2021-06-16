/*
 Copyright 2017 Vector Creations Ltd
 
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
