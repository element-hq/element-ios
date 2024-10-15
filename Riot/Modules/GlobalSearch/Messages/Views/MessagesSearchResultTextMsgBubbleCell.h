/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 `MessagesSearchResultTextMsgBubbleCell` displays a message text with the information of the room and the sender.
 */
@interface MessagesSearchResultTextMsgBubbleCell : MXKRoomBubbleTableViewCell

@property (weak, nonatomic) IBOutlet UIView *roomNameContainerView;
@property (weak, nonatomic) IBOutlet UILabel *roomNameLabel;

@end
