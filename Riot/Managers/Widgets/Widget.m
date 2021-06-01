/*
 Copyright 2017 Vector Creations Ltd
 Copyright 2019 New Vector Ltd

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
    // TODO - Room widgets need to be moved to 'm.widget' state events
    // https://docs.google.com/document/d/1uPF7XWY_dXTKVKV7jZQ2KmsI19wn9-kFRgQ1tFQP7wQ/edit?usp=sharing
    if (![widgetEvent.type isEqualToString:kWidgetMatrixEventTypeString]
        && ![widgetEvent.type isEqualToString:kWidgetModularEventTypeString])
    {
        // The Widget class works only with modular, aka "m.widget" or "im.vector.modular.widgets", widgets
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
    }

    return self;
}

- (MXHTTPOperation *)widgetUrl:(void (^)(NSString * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure
{
    __block NSString *widgetUrl = _url;

    // Format the url string with user data
    NSString *userId = self.mxSession.myUser.userId;
    NSString *displayName = self.mxSession.myUser.displayname ? self.mxSession.myUser.displayname : self.mxSession.myUser.userId;
    NSString *avatarUrl = self.mxSession.myUser.avatarUrl ? self.mxSession.myUser.avatarUrl : @"";
    NSString *widgetId = self.widgetId;

    // Escape everything to build a valid URL string
    // We can't know where the values escaped here will be inserted in the URL, so the alphanumeric charset is used
    userId = [MXTools encodeURIComponent:userId];
    displayName = [MXTools encodeURIComponent:displayName];
    avatarUrl = [MXTools encodeURIComponent:avatarUrl];
    widgetId = [MXTools encodeURIComponent:widgetId];

    widgetUrl = [widgetUrl stringByReplacingOccurrencesOfString:@"$matrix_user_id" withString:userId];
    widgetUrl = [widgetUrl stringByReplacingOccurrencesOfString:@"$matrix_display_name" withString:displayName];
    widgetUrl = [widgetUrl stringByReplacingOccurrencesOfString:@"$matrix_avatar_url" withString:avatarUrl];
    widgetUrl = [widgetUrl stringByReplacingOccurrencesOfString:@"$matrix_widget_id" withString:widgetId];
    
    if (self.roomId)
    {
        NSString *roomId = [MXTools encodeURIComponent:self.roomId];
        widgetUrl = [widgetUrl stringByReplacingOccurrencesOfString:@"$matrix_room_id" withString:roomId];
    }


    // Integrate widget data into widget url
    for (NSString *key in _data)
    {
        NSString *paramKey = [NSString stringWithFormat:@"$%@", key];

        NSString *dataString;
        MXJSONModelSetString(dataString, _data[key]);

        // Fix number data instead of expected string data
        if (!dataString && [_data[key] isKindOfClass:NSNumber.class])
        {
            dataString = [((NSNumber*)_data[key]) stringValue];
        }

        if (dataString)
        {
            // same question as above
            NSString *value = [MXTools encodeURIComponent:dataString];

            widgetUrl = [widgetUrl stringByReplacingOccurrencesOfString:paramKey
                                                             withString:value];
        }
        else
        {
            MXLogDebug(@"[Widget] Error: Invalid data field value in %@ for key %@ in data %@", self, key, _data);
        }
    }

    // Add the widget id
    widgetUrl = [widgetUrl stringByAppendingString:[NSString stringWithFormat:@"%@widgetId=%@",
                                                    [widgetUrl containsString:@"?"] ? @"&" : @"?",
                                                    _widgetId]];

    // Check if their scalar token must added
    if ([[WidgetManager sharedManager] isScalarUrl:widgetUrl forUser:userId])
    {
        return [[WidgetManager sharedManager] getScalarTokenForMXSession:_mxSession validate:YES success:^(NSString *scalarToken) {
            // Add the user scalar token
            widgetUrl = [widgetUrl stringByAppendingString:[NSString stringWithFormat:@"&scalar_token=%@",
                                                            scalarToken]];

            success(widgetUrl);
        } failure:failure];
    }
    else
    {
        success(widgetUrl);
    }
    
    return nil;
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
