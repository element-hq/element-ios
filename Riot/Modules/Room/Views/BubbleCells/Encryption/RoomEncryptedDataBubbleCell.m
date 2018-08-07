/*
 Copyright 2016 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd

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

#import "RoomEncryptedDataBubbleCell.h"

NSString *const kRoomEncryptedDataBubbleCellTapOnEncryptionIcon = @"kRoomEncryptedDataBubbleCellTapOnEncryptionIcon";

@implementation RoomEncryptedDataBubbleCell

+ (UIImage*)encryptionIconForEvent:(MXEvent*)event andSession:(MXSession*)session
{
    NSString *encryptionIcon;
    
    if (!event.isEncrypted)
    {
        encryptionIcon = @"e2e_unencrypted";
        
        if (event.isLocalEvent)
        {
            // Patch: Display the verified icon by default on pending outgoing messages in the encrypted rooms when the encryption is enabled
            MXRoom *room = [session roomWithRoomId:event.roomId];
            if (room.summary.isEncrypted && session.crypto)
            {
                // The outgoing message are encrypted by default
                encryptionIcon = @"e2e_verified";
            }
        }
    }
    else if (event.decryptionError)
    {
        encryptionIcon = @"e2e_blocked";
    }
    else
    {
        MXDeviceInfo *deviceInfo = [session.crypto eventDeviceInfo:event];
        
        if (deviceInfo)
        {
            switch (deviceInfo.verified)
            {
                case MXDeviceUnknown:
                case MXDeviceUnverified:
                {
                    encryptionIcon = @"e2e_warning";
                    break;
                }
                case MXDeviceVerified:
                {
                    encryptionIcon = @"e2e_verified";
                    break;
                }
                default:
                    break;
            }
        }
    }
    
    if (!encryptionIcon)
    {
        // Use the warning icon by default
        encryptionIcon = @"e2e_warning";
    }
    
    return [UIImage imageNamed:encryptionIcon];
}

+ (void)addEncryptionStatusFromBubbleData:(MXKRoomBubbleCellData *)bubbleData inContainerView:(UIView *)containerView
{
    // Ensure that older subviews are removed
    // They should be (they are removed when the cell is not anymore used).
    // But, it seems that is not always true.
    NSArray* views = [containerView subviews];
    for (UIView* view in views)
    {
        [view removeFromSuperview];
    }
    
    NSArray *bubbleComponents = bubbleData.bubbleComponents;
    MXKRoomBubbleComponent *component;
    
    for (NSUInteger componentIndex = 0; componentIndex < bubbleComponents.count; componentIndex++)
    {
        component  = bubbleComponents[componentIndex];
        
        // Ignore components without display.
        if (!component.attributedTextMessage)
        {
            continue;
        }
    
        UIImage *icon = [RoomEncryptedDataBubbleCell encryptionIconForEvent:component.event andSession:bubbleData.mxSession];
        UIImageView *encryptStatusImageView = [[UIImageView alloc] initWithImage:icon];
        
        CGRect frame = encryptStatusImageView.frame;
        frame.origin.y = component.position.y + 3;
        encryptStatusImageView.frame = frame;
        
        CGPoint center = encryptStatusImageView.center;
        center.x = containerView.frame.size.width / 2;
        encryptStatusImageView.center = center;
        
        encryptStatusImageView.tag = componentIndex;
        
        [containerView addSubview:encryptStatusImageView];
    }
}

@end
