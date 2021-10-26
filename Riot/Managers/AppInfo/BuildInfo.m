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

#import "BuildInfo.h"

#import "GeneratedInterface-Swift.h"

#define MAKE_STRING(x) #x
#define MAKE_NS_STRING(x) @MAKE_STRING(x)

@interface BuildInfo()

@property (nonatomic, copy, readwrite, nullable) NSString *buildNumber;
@property (nonatomic, copy, readwrite, nullable) NSString *buildBranch;
@property (nonatomic, copy, readwrite) NSString *readableBuildVersion;

@end

@implementation BuildInfo

- (instancetype)init
{
    NSString *buildBranch;
    NSString *buildNumber;
    
    // Check whether GIT_BRANCH was provided during compilation in command line argument.
#ifdef GIT_BRANCH
    buildBranch = MAKE_NS_STRING(GIT_BRANCH);
#endif
    
    // Check whether BUILD_NUMBER was provided during compilation in command line argument.
#ifdef BUILD_NUMBER
    buildNumber = [NSString stringWithFormat:@"#%@", @(BUILD_NUMBER)];
#endif
    
    self = [self initWithBuildBranch:buildBranch buildNumber:buildNumber];
    return self;
}

- (instancetype)initWithBuildBranch:(NSString*)buildBranch buildNumber:(NSString*)buildNumber
{
    self = [super init];
    if (self)
    {
        _buildBranch = buildBranch;
        _buildNumber = buildNumber;
    }
    return self;
}

- (NSString*)readableBuildVersion
{
    if (!_readableBuildVersion)
    {
        NSString *buildBranch = self.buildBranch;
        NSString *buildNumber = self.buildNumber;
        
        if (buildBranch && buildNumber)
        {
            _readableBuildVersion = [NSString stringWithFormat:@"%@ %@", buildBranch, buildNumber];
        }
        else if (buildNumber)
        {
            _readableBuildVersion = buildNumber;
        }
        else if (buildBranch)
        {
            _readableBuildVersion = buildBranch;
        }
        else
        {
            _readableBuildVersion = [VectorL10n settingsConfigNoBuildInfo];
        }
    }
    return _readableBuildVersion;
}

@end
