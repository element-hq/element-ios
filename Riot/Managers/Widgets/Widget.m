/*
Copyright 2019-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
