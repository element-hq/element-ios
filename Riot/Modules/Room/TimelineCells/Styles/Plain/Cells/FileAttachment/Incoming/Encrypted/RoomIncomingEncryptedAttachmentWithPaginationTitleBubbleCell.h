/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomIncomingAttachmentWithPaginationTitleBubbleCell.h"

/**
 `RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell` displays incoming attachment bubbles with sender's information and a pagination title.
 */
@interface RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell : RoomIncomingAttachmentWithPaginationTitleBubbleCell

@property (weak, nonatomic) IBOutlet UIImageView *encryptionStatusView;

@end
