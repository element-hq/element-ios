/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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




