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

#import "RoomTitleView.h"
#import "MatrixHandler.h"

@interface RoomTitleView () {
    id messagesListener;
}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *displayNameTextFieldTopConstraint;
@end

@implementation RoomTitleView

- (void)dealloc {
    if (messagesListener && _mxRoom) {
        [_mxRoom removeListener:messagesListener];
        messagesListener = nil;
    }
    _mxRoom = nil;
}

- (void)refreshDisplay {
    if (_mxRoom) {
        _displayNameTextField.text = _mxRoom.state.displayname;
        _topicTextField.text = _mxRoom.state.topic;
    } else {
        _displayNameTextField.text = nil;
        _topicTextField.text = nil;
    }
    
    self.hiddenTopic = (!_topicTextField.text.length);
}

- (void)setMxRoom:(MXRoom *)mxRoom {
    // Check whether the room is actually changed
    if (_mxRoom != mxRoom) {
        // Remove potential listener
        if (messagesListener && _mxRoom) {
            [_mxRoom removeListener:messagesListener];
            messagesListener = nil;
        }
        
        if (mxRoom) {
            // Register a listener to handle messages related to room name
            messagesListener = [mxRoom listenToEventsOfTypes:@[kMXEventTypeStringRoomName, kMXEventTypeStringRoomTopic, kMXEventTypeStringRoomAliases]
                                                          onEvent:^(MXEvent *event, MXEventDirection direction, MXRoomState *roomState) {
                                                              // Consider only live events
                                                              if (direction == MXEventDirectionForwards) {
                                                                  [self refreshDisplay];
                                                              }
                                                          }];
        }
        _mxRoom = mxRoom;
    }
    // Force refresh
    [self refreshDisplay];
}

- (void)setEditable:(BOOL)editable {
    self.displayNameTextField.enabled = editable;
    self.topicTextField.enabled = editable;
}

- (void)setHiddenTopic:(BOOL)hiddenTopic {
    if (hiddenTopic) {
        _topicTextField.hidden = YES;
        _displayNameTextFieldTopConstraint.constant = 10;
    } else {
        _topicTextField.hidden = NO;
        _displayNameTextFieldTopConstraint.constant = 2;
    }
}

- (void)dismissKeyboard {
    // Hide the keyboard
    [_displayNameTextField resignFirstResponder];
    [_topicTextField resignFirstResponder];
}

@end
