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
        // The Widget class works only with scalar, aka "im.vector.modular.widgets", widgets
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
        _url = [_url stringByReplacingOccurrencesOfString:@"$matrix_user_id" withString:mxSession.myUser.userId];
        _url = [_url stringByReplacingOccurrencesOfString:@"$matrix_display_name"
                                               withString:mxSession.myUser.displayname ? mxSession.myUser.displayname : mxSession.myUser.userId];
        _url = [_url stringByReplacingOccurrencesOfString:@"$matrix_avatar_url"
                                               withString:mxSession.myUser.avatarUrl ? mxSession.myUser.avatarUrl : @""];
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
