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

#import "RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.h"

#import "RoomEncryptedDataBubbleCell.h"

@implementation RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell

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
