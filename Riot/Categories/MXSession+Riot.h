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

@interface MXSession (Riot)

/**
 The current number of rooms with missed notifications, including the invites.
 */
- (NSUInteger)vc_missedDiscussionsCount;

/**
 Check if E2E by default is welcomed on the user's HS.
 The default value is YES.
 
 HS admins can disable it in /.well-known/matrix/client by returning:
 "im.vector.riot.e2ee": {
 "default": false
 }
 */
- (BOOL)vc_isE2EByDefaultEnabledByHSAdmin;

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

@end
