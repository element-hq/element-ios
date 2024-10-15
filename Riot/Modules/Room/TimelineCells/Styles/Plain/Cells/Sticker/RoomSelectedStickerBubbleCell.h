/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.h"

/**
 `RoomSelectedStickerBubbleCell` is used to display the current selected sticker if any
 */
@interface RoomSelectedStickerBubbleCell : RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell

@property (weak, nonatomic) IBOutlet UIView *descriptionContainerView;
@property (weak, nonatomic) IBOutlet UIView *arrowView;
@property (weak, nonatomic) IBOutlet UIView *descriptionView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *userNameLabelTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionContainerViewBottomConstraint;

@end
