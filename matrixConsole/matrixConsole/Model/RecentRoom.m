/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "RecentRoom.h"

@implementation RecentRoom

- (id)initWithLastEvent:(MXEvent*)event andMarkAsUnread:(BOOL)isUnread {
    if (self = [super init]) {
        _lastEvent = event;
        _unreadCount = isUnread ? 1 : 0;
    }
    return self;
}

- (void)updateWithLastEvent:(MXEvent*)event andMarkAsUnread:(BOOL)isUnread {
    _lastEvent = event;
    if (isUnread) {
        _unreadCount ++;
    }
}

- (void)resetUnreadCount {
    _unreadCount = 0;
}

- (void)dealloc {
    _lastEvent = nil;
}

#pragma mark -

- (NSString*)roomId {
    return _lastEvent.roomId;
}

@end
