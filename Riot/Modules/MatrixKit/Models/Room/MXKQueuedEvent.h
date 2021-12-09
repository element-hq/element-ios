/*
 Copyright 2015 OpenMarket Ltd

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
