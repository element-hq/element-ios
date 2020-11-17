/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
