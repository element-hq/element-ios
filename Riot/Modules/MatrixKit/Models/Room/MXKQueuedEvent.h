/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>
#import <MatrixSDK/MatrixSDK.h>

/**
 `MXKQueuedEvent` represents an event waiting to be processed.
 */
@interface MXKQueuedEvent : NSObject

/**
 The event.
 */
@property (nonatomic, readonly) MXEvent *event;

/**
 The state of the room when the event has been received.
 */
@property (nonatomic, readonly) MXRoomState *state;

/**
 The direction of reception. Is it a live event or an event from the history?
 */
@property (nonatomic, readonly) MXTimelineDirection direction;

/**
 Tells whether the event is queued during server sync or not.
 */
@property (nonatomic) BOOL serverSyncEvent;

/**
 Date of the `event`. If event has a valid `originServerTs`, it's converted to a date object, otherwise current date.
 */
@property (nonatomic, readonly) NSDate *eventDate;

- (instancetype)initWithEvent:(MXEvent*)event andRoomState:(MXRoomState*)state direction:(MXTimelineDirection)direction;

@end
