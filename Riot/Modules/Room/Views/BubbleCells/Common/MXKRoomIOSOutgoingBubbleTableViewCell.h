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

#import "MXKRoomOutgoingBubbleTableViewCell.h"

/**
 `MXKRoomIOSBubbleTableViewCell` instances mimic bubbles in the stock iOS messages application.
 It is dedicated to outgoing messages.
 It subclasses `MXKRoomOutgoingBubbleTableViewCell` to take benefit of the available mechanic.
 */
@interface MXKRoomIOSOutgoingBubbleTableViewCell : MXKRoomOutgoingBubbleTableViewCell

/**
 The green bubble displayed in background.
 */
@property (weak, nonatomic) IBOutlet UIImageView *bubbleImageView;

/**
 The width constraint on this backgroung green bubble.
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bubbleImageViewWidthConstraint;

@end
