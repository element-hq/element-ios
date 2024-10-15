/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomIncomingAttachmentWithoutSenderInfoBubbleCell.h"

/**
 `RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell` displays incoming encrypted attachment without sender's information.
 */
@interface RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell : RoomIncomingAttachmentWithoutSenderInfoBubbleCell

@property (weak, nonatomic) IBOutlet UIImageView *encryptionStatusView;

@end
