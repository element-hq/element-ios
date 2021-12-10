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

#import "MXKRoomBubbleCellData.h"

/**
 `MXKRoomBubbleCellDataWithAppendingMode` class inherits from `MXKRoomBubbleCellData`, it merges
 consecutive events from the same sender into one bubble.
 Each concatenated event is represented by a bubble component.
 */
@interface MXKRoomBubbleCellDataWithAppendingMode : MXKRoomBubbleCellData
{
@protected
    /**
     YES if position of each component must be refreshed
     */
    BOOL shouldUpdateComponentsPosition;
}

/**
 The string appended to the current message before adding a new component text.
 */
+ (NSAttributedString *)messageSeparator;

/**
 The maximum number of components in each bubble. Default is 10.
 We limit the number of components to reduce the computation time required during bubble handling.
 Indeed some process like [prepareBubbleComponentsPosition] is time consuming.
 */
@property (nonatomic) NSUInteger maxComponentCount;

@end
