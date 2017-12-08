/*
 Copyright 2017 Vector Creations Ltd

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

#import "Widget.h"

#import "WidgetManager.h"

@implementation Widget

- (instancetype)initWithWidgetEvent:(MXEvent *)widgetEvent inMatrixSession:(MXSession*)mxSession
{
    if (![widgetEvent.type isEqualToString:kWidgetEventTypeString])
    {
        // The Widget class works only with modular, aka "im.vector.modular.widgets", widgets
        return nil;
    }

    self = [super init];
    if (self)
    {
        _widgetId = widgetEvent.stateKey;
        _widgetEvent = widgetEvent;
        _mxSession = mxSession;

        MXJSONModelSetString(_type, widgetEvent.content[@"type"]);
        MXJSONModelSetString(_url, widgetEvent.content[@"url"]);
        MXJSONModelSetString(_name, widgetEvent.content[@"name"]);
        MXJSONModelSetDictionary(_data, widgetEvent.content[@"data"]);

        // Format the url string with user data
        if (_url)
        {
            NSString *userId = mxSession.myUser.userId;
            NSString *displayName = mxSession.myUser.displayname ? mxSession.myUser.displayname : mxSession.myUser.userId;
            NSString *avatarUrl = mxSession.myUser.avatarUrl ? mxSession.myUser.avatarUrl : @"";

            // Escape everything to build a valid URL string
            userId = [userId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            displayName = [displayName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            avatarUrl = [avatarUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

            _url = [_url stringByReplacingOccurrencesOfString:@"$matrix_user_id" withString:userId];
            _url = [_url stringByReplacingOccurrencesOfString:@"$matrix_display_name" withString:displayName];
            _url = [_url stringByReplacingOccurrencesOfString:@"$matrix_avatar_url" withString:avatarUrl];

            // And their scalar token
            NSString *scalarToken = [[WidgetManager sharedManager] scalarTokenForMXSession:mxSession];
            if (scalarToken)
            {
                _url = [_url stringByAppendingString:[NSString stringWithFormat:@"&scalar_token=%@", scalarToken]];
            }
            else
            {
                // Some widget can live without scalar token (ex: Jitsi widget)
                NSLog(@"[Widget] Note: There is no scalar token for %@", self);
            }

            // Integrate widget data into widget url
            for (NSString *key in _data)
            {
                NSString *paramKey = [NSString stringWithFormat:@"$%@", key];
                NSString *value = [_data[key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

                _url = [_url stringByReplacingOccurrencesOfString:paramKey
                                                       withString:value];
            }
        }
    }

    return self;
}

- (BOOL)isActive
{
    return (_type != nil && _url != nil);
}

- (NSString *)roomId
{
    return _widgetEvent.roomId;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Widget: %p> id: %@ - type: %@ - name: %@ - url: %@", self, _widgetId, _type, _name, _url];
}

@end
