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

#import <Matrixkit/MatrixKit.h>

/**
 Define a `MXKRoomBubbleTableViewCell` category at Vector level to handle bubble customisation.
 */
@interface MXKRoomBubbleTableViewCell (Vector)

/**
 Add timestamp label for a component in receiver.
 
 Note: The label added here is automatically removed when [didEndDisplay] is called.
 
 @param componentIndex index of the component in bubble message data
 */
- (void)addTimestampLabelForComponent:(NSUInteger)componentIndex;

/**
 Remove timestamp labels
 */
- (void)removeTimestampLabels;

/**
 Highlight a component in receiver.
 
 @param componentIndex index of the component in bubble message data
 */
- (void)selectComponent:(NSUInteger)componentIndex;

/**
 Cancel the highlighting of a component in receiver.
 */
- (void)unselectComponent;

/**
 Blur the view by adding a transparent overlay. Default is NO.
 */
@property(nonatomic) BOOL blurred;

@end
