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
- (NSUInteger)riot_missedDiscussionsCount;

/**
 Decide if E2E must be enabled in a new room with a list users

 @param userIds the list of users;

 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.

 @return a MXHTTPOperation instance.
 */
- (MXHTTPOperation*)canEnableE2EByDefaultInNewRoomWithUsers:(NSArray<NSString*>*)userIds
                                                    success:(void (^)(BOOL canEnableE2E))success
                                                    failure:(void (^)(NSError *error))failure;

@end
