// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
