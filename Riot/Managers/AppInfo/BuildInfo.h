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
