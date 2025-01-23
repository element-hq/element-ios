// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
