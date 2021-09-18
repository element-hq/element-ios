// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#ifndef UserActivities_h
#define UserActivities_h

#import <Foundation/Foundation.h>

/**
 NSUserActivity types for rooms
 */
FOUNDATION_EXPORT NSString *const kUserActivityTypeMatrixRoom;

/**
 UserInfo field for the room id
 */
FOUNDATION_EXPORT NSString *const kUserActivityInfoRoomId;

/**
 UserInfo field for the user id
 */
FOUNDATION_EXPORT NSString *const kUserActivityInfoUserId;

#endif /* UserActivities_h */
