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

#import "MXKRoomBubbleCellDataWithAppendingMode.h"

/**
 `RoomBubbleCellData` defines Vector bubble cell data model.
 */
@interface RoomBubbleCellData : MXKRoomBubbleCellDataWithAppendingMode

/**
 A Boolean value that determines whether this bubble is the current last one.
 Used to keep displaying the timestamp of the last message.

 CAUTION: This property is presently set during bubble rendering in order to be used during bubble cell life.
 */
@property(nonatomic) BOOL isLastBubble;

/**
 A Boolean value that determines whether some read receipts are currently displayed in this bubble.
 */
@property(nonatomic) BOOL hasReadReceipts;

@end
