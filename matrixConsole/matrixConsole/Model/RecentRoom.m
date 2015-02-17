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
#import "MatrixSDKHandler.h"

NSString *const kRecentRoomUpdatedByBackPagination = @"kRecentRoomUpdatedByBackPagination";

@interface RecentRoom() {
    MXRoom *mxRoom;
    id backPaginationListener;
    MXHTTPOperation *backPaginationOperation;
    
    // Keep reference on last event (used in case of redaction)
    MXEvent *lastEvent;
}
@end

@implementation RecentRoom

- (id)initWithLastEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState markAsUnread:(BOOL)isUnread {
    if (self = [super init]) {
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        _roomId = event.roomId;
        _lastEventDescription = [mxHandler displayTextForEvent:event withRoomState:roomState inSubtitleMode:YES];
        _lastEventOriginServerTs = event.originServerTs;
        _unreadCount = isUnread ? 1 : 0;
        
        // Keep ref on event
        lastEvent = event;
        
        if (!_lastEventDescription.length) {
            // Trigger back pagination to get an event with a non empty description
            [self triggerBackPagination];
        }
    }
    return self;
}

- (BOOL)updateWithLastEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState markAsUnread:(BOOL)isUnread {
    // Check whether the description of the provided event is not empty
    NSString *description = [[MatrixSDKHandler sharedHandler] displayTextForEvent:event withRoomState:roomState inSubtitleMode:YES];
    if (description.length) {
        [self cancelBackPagination];
        // Update current last event
        lastEvent = event;
        _lastEventDescription = description;
        _lastEventOriginServerTs = event.originServerTs;
        if (isUnread) {
            _unreadCount ++;
        }
        return YES;
    } else if (_lastEventDescription.length) {
        // Here we tried to update the last event with a new live one, but the description of this new one is empty.
        // Consider the specific case of redaction event
        if (event.eventType == MXEventTypeRoomRedaction) {
            // Check whether the redacted event is the current last event
            if ([event.redacts isEqualToString:lastEvent.eventId]) {
                // Update last event description
                MXEvent *redactedEvent = [lastEvent prune];
                redactedEvent.redactedBecause = event.originalDictionary;
                
                _lastEventDescription = [[MatrixSDKHandler sharedHandler] displayTextForEvent:redactedEvent withRoomState:nil inSubtitleMode:YES];
                if (!_lastEventDescription.length) {
                    // The current last event must be removed, decrement the unread count (if not null)
                    if (_unreadCount) {
                        _unreadCount--;
                    }
                    // Trigger back pagination to get an event with a non empty description
                    [self triggerBackPagination];
                }
                return YES;
            }
        }
    }
    return NO;
}

- (void)resetUnreadCount {
    _unreadCount = 0;
}

- (void)dealloc {
    [self cancelBackPagination];
    lastEvent = nil;
    _lastEventDescription = nil;
}

- (void)triggerBackPagination {
    // Add listener if it is not already done
    if (!backPaginationListener) {
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        mxRoom = [mxHandler.mxSession roomWithRoomId:_roomId];
        if (mxRoom) {
            backPaginationListener = [mxRoom listenToEventsOfTypes:mxHandler.eventsFilterForMessages onEvent:^(MXEvent *event, MXEventDirection direction, MXRoomState *roomState) {
                // Handle only backward events (Sanity check: be sure that the description has not been set by an other way)
                if (direction == MXEventDirectionBackwards && !_lastEventDescription.length) {
                    if ([self updateWithLastEvent:event andRoomState:roomState markAsUnread:NO]) {
                        // Force recents refresh
                        [[NSNotificationCenter defaultCenter] postNotificationName:kRecentRoomUpdatedByBackPagination object:_roomId];
                    }
                }
            }];
            
            // Trigger a back pagination by reseting first backState to get room history from live
            [mxRoom resetBackState];
        } else {
            return;
        }
    }
    
    if (mxRoom.canPaginate) {
        backPaginationOperation = [mxRoom paginateBackMessages:10 complete:^{
            backPaginationOperation = nil;
            // Check whether another back pagination is required
            if (!_lastEventDescription.length) {
                [self triggerBackPagination];
            }
        } failure:^(NSError *error) {
            backPaginationOperation = nil;
            NSLog(@"RecentRoom: Failed to paginate back: %@", error);
            [self cancelBackPagination];
        }];
    } else {
        // Force recents refresh
        [[NSNotificationCenter defaultCenter] postNotificationName:kRecentRoomUpdatedByBackPagination object:_roomId];
        [self cancelBackPagination];
    }
}

- (void)cancelBackPagination {
    if (backPaginationListener && mxRoom) {
        [mxRoom removeListener:backPaginationListener];
        backPaginationListener = nil;
        mxRoom = nil;
    }
    if (backPaginationOperation) {
        [backPaginationOperation cancel];
        backPaginationOperation = nil;
    }
}

@end
