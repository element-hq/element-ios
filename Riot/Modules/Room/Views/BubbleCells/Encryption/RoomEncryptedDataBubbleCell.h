/*
 Copyright 2016 OpenMarket Ltd

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

#import "MatrixKit.h"

/**
 Action identifier used when the user tapped on the marker displayed in front of an encrypted event.
 
 The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the encrypted event.
 */
extern NSString *const kRoomEncryptedDataBubbleCellTapOnEncryptionIcon;

/**
 `RoomEncryptedDataBubbleCell` defines static methods used to handle the encrypted data in bubbles.
 */
@interface RoomEncryptedDataBubbleCell : NSObject

/**
 Return the icon displayed in front of an event in an encrypted room if needed.
 
 @param bubbleComponent the bubble component.
 */
+ (UIImage*)encryptionIconForBubbleComponent:(MXKRoomBubbleComponent *)bubbleComponent;

/**
 Set the encryption status icon in front of each bubble component.
 
 @param bubbleData the bubble cell data
 @param containerView the container view in which the icons will be added.
 */
+ (void)addEncryptionStatusFromBubbleData:(MXKRoomBubbleCellData *)bubbleData inContainerView:(UIView *)containerView;

@end




