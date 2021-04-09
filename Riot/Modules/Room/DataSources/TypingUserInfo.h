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

#import <Foundation/Foundation.h>
#import <MatrixSDK/MatrixSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface TypingUserInfo : NSObject

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong, nullable) NSString *displayName;
@property (nonatomic, strong, nullable) NSString *avatarUrl;

- (instancetype) initWithMember:(MXRoomMember*)member;

- (instancetype) initWithUserId:(NSString*)userId;

@end

NS_ASSUME_NONNULL_END
