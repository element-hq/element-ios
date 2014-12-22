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
#import "MatrixHandler.h"

@interface RecentRoom() {
    MXRoom *mxRoom;
    id backPaginationListener;
    NSOperation *backPaginationOperation;
}
@end

@implementation RecentRoom

- (id)initWithLastEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState markAsUnread:(BOOL)isUnread {
    if (self = [super init]) {
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        _roomId = event.roomId;
        _lastEventDescription = [mxHandler displayTextForEvent:event withRoomState:roomState inSubtitleMode:YES];
        _lastEventOriginServerTs = event.originServerTs;
        _unreadCount = isUnread ? 1 : 0;
        
        if (!_lastEventDescription.length) {
            // Trigger back pagination to get an event with a non empty description
            mxRoom = [mxHandler.mxSession roomWithRoomId:event.roomId];
            if (mxRoom) {
                backPaginationListener = [mxRoom listenToEventsOfTypes:mxHandler.eventsFilterForMessages onEvent:^(MXEvent *event, MXEventDirection direction, MXRoomState *roomState) {
                    // Handle only backward events (Sanity check: be sure that the description has not been set by an other way)
                    if (direction == MXEventDirectionBackwards && !_lastEventDescription.length) {
                        if (![self updateWithLastEvent:event andRoomState:roomState markAsUnread:NO]) {
                            // get back one more event
                            [self triggerBackPagination];
                        }
                    }
                }];
                
                // Trigger a back pagination by reseting first backState to get room history from live
                [mxRoom resetBackState];
                [self triggerBackPagination];
            }
        }
    }
    return self;
}

- (BOOL)updateWithLastEvent:(MXEvent*)event andRoomState:(MXRoomState*)roomState markAsUnread:(BOOL)isUnread {
    // Check whether the description of the provided event is not empty
    NSString *description = [[MatrixHandler sharedHandler] displayTextForEvent:event withRoomState:roomState inSubtitleMode:YES];
    if (description.length) {
        [self cancelBackPagination];
        // Update current last event
        _lastEventDescription = description;
        _lastEventOriginServerTs = event.originServerTs;
        if (isUnread) {
            _unreadCount ++;
        }
        return YES;
    }
    return NO;
}

- (void)resetUnreadCount {
    _unreadCount = 0;
}

- (void)dealloc {
    [self cancelBackPagination];
    _lastEventDescription = nil;
}

- (void)triggerBackPagination {
    if (mxRoom.canPaginate) {
        backPaginationOperation = [mxRoom paginateBackMessages:1 complete:^{
            backPaginationOperation = nil;
        } failure:^(NSError *error) {
            backPaginationOperation = nil;
            NSLog(@"RecentRoom: Failed to paginate back: %@", error);
            [self cancelBackPagination];
        }];
    } else {
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
