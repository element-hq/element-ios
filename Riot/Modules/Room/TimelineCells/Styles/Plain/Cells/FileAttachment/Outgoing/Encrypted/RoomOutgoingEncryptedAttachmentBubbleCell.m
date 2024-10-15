/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomOutgoingEncryptedAttachmentBubbleCell.h"

#import "RoomEncryptedDataBubbleCell.h"

@implementation RoomOutgoingEncryptedAttachmentBubbleCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Listen to encryption icon tap
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onEncryptionIconTap:)];
    [tapGesture setNumberOfTouchesRequired:1];
    [tapGesture setNumberOfTapsRequired:1];
    [tapGesture setDelegate:self];
    [self.encryptionStatusView addGestureRecognizer:tapGesture];
    self.encryptionStatusView.userInteractionEnabled = YES;
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    if (bubbleData)
    {
        // Set the right device info icon (only one component is handled by bubble in case of attachment)
        MXKRoomBubbleComponent *component = bubbleData.bubbleComponents.firstObject;
        if (component)
        {
            self.encryptionStatusView.image = [RoomEncryptedDataBubbleCell encryptionIconForBubbleComponent:component];
        }
    }
}

#pragma mark - User actions

- (IBAction)onEncryptionIconTap:(UITapGestureRecognizer*)sender
{
    if (self.delegate)
    {
        MXKRoomBubbleComponent *component = bubbleData.bubbleComponents.firstObject;
        if (component)
        {
            MXEvent *tappedEvent = component.event;
            [self.delegate cell:self didRecognizeAction:kRoomEncryptedDataBubbleCellTapOnEncryptionIcon userInfo:(tappedEvent ? @{kMXKRoomBubbleCellEventKey:tappedEvent} : nil)];
        }
    }
}

@end
