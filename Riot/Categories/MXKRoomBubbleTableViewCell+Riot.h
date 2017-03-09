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

#import <MatrixKit/MatrixKit.h>

/**
 Action identifier used when the user pressed edit button displayed in front of a selected event.
 
 The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the selected event.
 */
extern NSString *const kMXKRoomBubbleCellRiotEditButtonPressed;

/**
 Define a `MXKRoomBubbleTableViewCell` category at Riot level to handle bubble customisation.
 */
@interface MXKRoomBubbleTableViewCell (Riot)

/**
 Add timestamp label for a component in receiver.
 
 Note: The label added here is automatically removed when [didEndDisplay] is called.
 
 @param componentIndex index of the component in bubble message data
 */
- (void)addTimestampLabelForComponent:(NSUInteger)componentIndex;

/**
 Highlight a component in receiver.
 
 @param componentIndex index of the component in bubble message data
 */
- (void)selectComponent:(NSUInteger)componentIndex;

/**
 Mark a component in receiver.

 @param componentIndex index of the component in bubble message data
 */
- (void)markComponent:(NSUInteger)componentIndex;

/**
 Add a label to display the date of the cell.
 */
- (void)addDateLabel;

/**
 Blur the view by adding a transparent overlay. Default is NO.
 */
@property(nonatomic) BOOL blurred;

/**
 The 'edit' button displayed at in the top-right corner of the selected component (if any). Default is nil.
 */
@property(nonatomic) UIButton *editButton;

/**
 The marker view displayed in front of the marked component (if any).
 */
@property (nonatomic) UIView *markerView;

@end
