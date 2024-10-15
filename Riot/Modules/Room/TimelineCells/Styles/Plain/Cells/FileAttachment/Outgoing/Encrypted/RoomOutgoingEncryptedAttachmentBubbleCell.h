/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomOutgoingAttachmentBubbleCell.h"

/**
 `RoomOutgoingEncryptedAttachmentBubbleCell` displays outgoing attachment bubbles.
 */
@interface RoomOutgoingEncryptedAttachmentBubbleCell : RoomOutgoingAttachmentBubbleCell

@property (weak, nonatomic) IBOutlet UIImageView *encryptionStatusView;

@end
