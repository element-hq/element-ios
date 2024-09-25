/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKDirectoryServerCellData.h"

#import "NSBundle+MatrixKit.h"

#import "MXKSwiftHeader.h"

@implementation MXKDirectoryServerCellData;
@synthesize desc, icon;
@synthesize homeserver, includeAllNetworks;
@synthesize thirdPartyProtocolInstance, thirdPartyProtocol;
@synthesize mediaManager;

- (id)initWithHomeserver:(NSString *)theHomeserver includeAllNetworks:(BOOL)theIncludeAllNetworks
{
    self = [super init];
    if (self)
    {
        homeserver = theHomeserver;
        includeAllNetworks = theIncludeAllNetworks;

        if (theIncludeAllNetworks)
        {
            desc = homeserver;
            icon = nil;
        }
        else
        {
            // Use the Matrix name and logo when looking for Matrix rooms only
            desc = [VectorL10n matrix];
            icon = [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"network_matrix"];
        }
    }
    return self;
}

- (id)initWithProtocolInstance:(MXThirdPartyProtocolInstance *)instance protocol:(MXThirdPartyProtocol *)protocol
{
    self = [super init];
    if (self)
    {
        thirdPartyProtocolInstance = instance;
        thirdPartyProtocol = protocol;
        desc = thirdPartyProtocolInstance.desc;
        icon = nil;
    }
    return self;
}

@end
