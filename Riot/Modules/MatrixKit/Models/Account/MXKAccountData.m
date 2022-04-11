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
#import "MXKAccountData.h"

@interface MXKAccountData ()

@end

@implementation MXKAccountData

@synthesize mxCredentials = _mxCredentials;

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    
    if (self)
    {
        
        NSString *homeServerURL = [coder decodeObjectForKey:@"homeserverurl"];
        NSString *userId = [coder decodeObjectForKey:@"userid"];
        NSString *accessToken = [coder decodeObjectForKey:@"accesstoken"];
        _identityServerURL = [coder decodeObjectForKey:@"identityserverurl"];
        NSString *identityServerAccessToken = [coder decodeObjectForKey:@"identityserveraccesstoken"];
        
        _mxCredentials = [[MXCredentials alloc] initWithHomeServer:homeServerURL
                                                           userId:userId
                                                      accessToken:accessToken];

        _mxCredentials.accessTokenExpiresAt = [coder decodeInt64ForKey:@"accessTokenExpiresAt"];
        _mxCredentials.refreshToken = [coder decodeObjectForKey:@"refreshToken"];
        _mxCredentials.identityServer = _identityServerURL;
        _mxCredentials.identityServerAccessToken = identityServerAccessToken;
        _mxCredentials.deviceId = [coder decodeObjectForKey:@"deviceId"];
        _mxCredentials.allowedCertificate = [coder decodeObjectForKey:@"allowedCertificate"];

        if ([coder decodeObjectForKey:@"threePIDs"])
        {
            _threePIDs = [coder decodeObjectForKey:@"threePIDs"];
        }
        
        if ([coder decodeObjectForKey:@"device"])
        {
            _device = [coder decodeObjectForKey:@"device"];
        }
        
        if ([coder decodeObjectForKey:@"antivirusserverurl"])
        {
            _antivirusServerURL = [coder decodeObjectForKey:@"antivirusserverurl"];
        }
        
        if ([coder decodeObjectForKey:@"pushgatewayurl"])
        {
            _pushGatewayURL = [coder decodeObjectForKey:@"pushgatewayurl"];
        }
        
        _hasPusherForPushNotifications = [coder decodeBoolForKey:@"_enablePushNotifications"];
        _hasPusherForPushKitNotifications = [coder decodeBoolForKey:@"enablePushKitNotifications"];
        _enableInAppNotifications = [coder decodeBoolForKey:@"enableInAppNotifications"];
        
        _disabled = [coder decodeBoolForKey:@"disabled"];
        _isSoftLogout = [coder decodeBoolForKey:@"isSoftLogout"];

        _warnedAboutEncryption = [coder decodeBoolForKey:@"warnedAboutEncryption"];
        
        if ([coder decodeObjectOfClass:NSString.class forKey:@"preferredSyncPresence"])
        {
            MXPresenceString presenceString = [coder decodeObjectOfClass:NSString.class forKey:@"preferredSyncPresence"];
            _preferredSyncPresence = [MXTools presence:presenceString];
        }
        else
        {
            _preferredSyncPresence = MXPresenceOnline;
        }
        
        _others = [coder decodeObjectForKey:@"others"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_mxCredentials.homeServer forKey:@"homeserverurl"];
    [coder encodeObject:_mxCredentials.userId forKey:@"userid"];
    [coder encodeObject:_mxCredentials.accessToken forKey:@"accesstoken"];
    if (self.mxCredentials.accessTokenExpiresAt) {
        [coder encodeInt64:_mxCredentials.accessTokenExpiresAt forKey:@"accessTokenExpiresAt"];
    }
    if (self.mxCredentials.refreshToken) {
        [coder encodeObject:_mxCredentials.refreshToken forKey:@"refreshToken"];
    }
    [coder encodeObject:_mxCredentials.identityServerAccessToken forKey:@"identityserveraccesstoken"];

    if (self.mxCredentials.deviceId)
    {
        [coder encodeObject:_mxCredentials.deviceId forKey:@"deviceId"];
    }

    if (self.mxCredentials.allowedCertificate)
    {
        [coder encodeObject:_mxCredentials.allowedCertificate forKey:@"allowedCertificate"];
    }

    if (self.threePIDs)
    {
        [coder encodeObject:_threePIDs forKey:@"threePIDs"];
    }
    
    if (self.device)
    {
        [coder encodeObject:_device forKey:@"device"];
    }

    if (self.identityServerURL)
    {
        [coder encodeObject:_identityServerURL forKey:@"identityserverurl"];
    }
    
    if (self.antivirusServerURL)
    {
        [coder encodeObject:_antivirusServerURL forKey:@"antivirusserverurl"];
    }
    
    if (self.pushGatewayURL)
    {
        [coder encodeObject:_pushGatewayURL forKey:@"pushgatewayurl"];
    }
    
    [coder encodeBool:_hasPusherForPushNotifications forKey:@"_enablePushNotifications"];
    [coder encodeBool:_hasPusherForPushKitNotifications forKey:@"enablePushKitNotifications"];
    [coder encodeBool:_enableInAppNotifications forKey:@"enableInAppNotifications"];
    
    [coder encodeBool:_disabled forKey:@"disabled"];
    [coder encodeBool:_isSoftLogout forKey:@"isSoftLogout"];

    [coder encodeBool:_warnedAboutEncryption forKey:@"warnedAboutEncryption"];
    
    MXPresenceString presenceString = [MXTools presenceString:_preferredSyncPresence];
    [coder encodeObject:presenceString forKey:@"preferredSyncPresence"];
    
    [coder encodeObject:_others forKey:@"others"];
}


@end
