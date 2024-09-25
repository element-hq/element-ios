/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKQueuedEvent.h"

@implementation MXKQueuedEvent

- (instancetype)initWithEvent:(MXEvent *)event andRoomState:(MXRoomState *)state direction:(MXTimelineDirection)direction
{
    self = [super init];
    if (self)
    {
        _event = event;
        _state = state;
        _direction = direction;
    }
    return self;
}

- (NSDate *)eventDate
{
    if (_event.originServerTs != kMXUndefinedTimestamp)
    {
        return [NSDate dateWithTimeIntervalSince1970:(double)_event.originServerTs/1000];
    }
    
    return [NSDate date];
}

@end
