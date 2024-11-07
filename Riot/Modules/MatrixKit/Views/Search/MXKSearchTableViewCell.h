/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCell.h"

#import "MXKCellRendering.h"
#import "MXKImageView.h"

/**
 Each `MXKSearchTableViewCell` instance displays a search result.
 */
@interface MXKSearchTableViewCell : MXKTableViewCell <MXKCellRendering>

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *message;
@property (weak, nonatomic) IBOutlet UILabel *date;

@property (weak, nonatomic) IBOutlet MXKImageView *attachmentImageView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImage;

@end
