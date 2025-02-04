// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// BuildInfo gives build information made at compilation time.
@interface BuildInfo : NSObject

/// Git branch name. If GIT_BRANCH was provided during compilation in command line argument.
@property (nonatomic, copy, readonly, nullable) NSString *buildNumber;

/// Git branch name. If BUILD_NUMBER was provided during compilation in command line argument.
@property (nonatomic, copy, readonly, nullable) NSString *buildBranch;

/// Readable build version
@property (nonatomic, copy, readonly) NSString *readableBuildVersion;

/// Convenience init. Check whether GIT_BRANCH and BUILD_NUMBER were provided during compilation in command line argument.
- (instancetype)init;

/// Designated initializer to give input properties values
- (instancetype)initWithBuildBranch:(nullable NSString*)buildBranch buildNumber:(nullable NSString*)buildNumber NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
