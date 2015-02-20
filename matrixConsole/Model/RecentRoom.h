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
#import <MatrixSDK/MatrixSDK.h>

// When a recent is initialized with a blank last event description (unexpected/unsupported event),
// a back pagination is triggered to find a non empty description.
// The following notification is posted when this operation succeeds
extern NSString *const kRecentRoomUpdatedByBackPagination;

@interface RecentRoom : NSObject

@property (nonatomic, readonly) NSString *roomId;
@property (nonatomic, readonly) NSString *lastEventDescription;
@property (nonatomic, readonly) uint64_t lastEventOriginServerTs;
@property (nonatomic, readonly) NSUInteger unreadCount;
@property (nonatomic, readonly) BOOL containsBingUnread;

- (id)initWithLastEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState markAsUnread:(BOOL)isUnread;
// Update the current last event description with the provided event, except if this description is empty (see unsupported/unexpected events).
// Return true when the provided event is considered as new last event
- (BOOL)updateWithLastEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState markAsUnread:(BOOL)isUnread;
- (void)resetUnreadCount;

@end