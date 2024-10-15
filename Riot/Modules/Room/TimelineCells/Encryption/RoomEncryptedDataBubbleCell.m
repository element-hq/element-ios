/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomEncryptedDataBubbleCell.h"
#import "GeneratedInterface-Swift.h"

NSString *const kRoomEncryptedDataBubbleCellTapOnEncryptionIcon = @"kRoomEncryptedDataBubbleCellTapOnEncryptionIcon";

@implementation RoomEncryptedDataBubbleCell

+ (UIImage*)encryptionIconForBubbleComponent:(MXKRoomBubbleComponent *)bubbleComponent
{
    switch (bubbleComponent.encryptionDecoration) {
        case EventEncryptionDecorationNone:
            return nil;
        case EventEncryptionDecorationGrey:
            return AssetImages.encryptionUntrusted.image;
        case EventEncryptionDecorationRed:
            return AssetImages.encryptionWarning.image;
        default:
            return nil;
    }
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
        
        UIImage *icon = [[self class] encryptionIconForBubbleComponent:component];
        
        if (icon)
        {
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
}

@end
