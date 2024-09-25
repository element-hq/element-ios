/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomOutgoingBubbleTableViewCell.h"

/**
 `MXKRoomOutgoingAttachmentBubbleCell` displays outgoing attachment bubbles.
 */
@interface MXKRoomOutgoingAttachmentBubbleCell : MXKRoomOutgoingBubbleTableViewCell

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
