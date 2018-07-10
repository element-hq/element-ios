/*
 Copyright 2015 OpenMarket Ltd
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

#import <MatrixKit/MatrixKit.h>

#import "WidgetManager.h"

/**
 The data source for `RoomViewController` in Vector.
 */
@interface RoomDataSource : MXKRoomDataSource

/**
 The event id of the current selected event if any. Default is nil.
 */
@property(nonatomic) NSString *selectedEventId;

/**
 Tell whether the initial event of the timeline (if any) must be marked. Default is NO.
 */
@property(nonatomic) BOOL markTimelineInitialEvent;

/**
 Check if there is an active jitsi widget in the room and return it.

 @return a widget representating the active jitsi conference in the room. Else, nil.
 */
- (Widget *)jitsiWidget;

@end
