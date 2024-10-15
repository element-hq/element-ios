/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 `RoomIncomingAttachmentWithPaginationTitleBubbleCell` displays incoming attachment bubbles with sender's information and a pagination title.
 */
@interface RoomIncomingAttachmentWithPaginationTitleBubbleCell : MXKRoomIncomingAttachmentBubbleCell

@property (weak, nonatomic) IBOutlet UIView *paginationTitleView;
@property (weak, nonatomic) IBOutlet UILabel *paginationLabel;
@property (weak, nonatomic) IBOutlet UIView *paginationSeparatorView;

@end
