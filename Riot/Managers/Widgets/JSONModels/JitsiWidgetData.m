/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "JitsiWidgetData.h"

@implementation JitsiWidgetData

#pragma mark - MXJSONModel

+ (instancetype)modelFromJSON:(NSDictionary *)JSONDictionary
{
    NSString *domain, *conferenceId;
    MXJSONModelSetString(domain, JSONDictionary[@"domain"]);
    MXJSONModelSetString(conferenceId, JSONDictionary[@"conferenceId"]);
    
    BOOL isAudioOnly = NO;
    MXJSONModelSetBoolean(isAudioOnly, JSONDictionary[@"isAudioOnly"])
    
    NSString *authenticationType;
    MXJSONModelSetString(authenticationType, JSONDictionary[@"auth"]);
    
    // Sanitiy check
    if (!conferenceId)
    {
        return nil;
    }
    
    JitsiWidgetData *model = [JitsiWidgetData new];
    model.domain = domain;
    model.conferenceId = conferenceId;
    model.isAudioOnly = isAudioOnly;
    model.authenticationType = authenticationType;
    
    return model;
}

- (NSDictionary *)JSONDictionary
{
    NSMutableDictionary *jsonDictionary = [@{
        @"domain": _domain,
        @"conferenceId": _conferenceId,
        @"isAudioOnly": @(_isAudioOnly),
    } mutableCopy];
            
    if (_authenticationType)
    {
        jsonDictionary[@"auth"] = _authenticationType;
    }
    
    return jsonDictionary;
}


@end
