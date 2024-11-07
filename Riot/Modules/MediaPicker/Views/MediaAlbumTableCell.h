/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 'MediaAlbumTableCell' is a base class for displaying a user album.
 */
@interface MediaAlbumTableCell : MXKTableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *albumThumbnail;
@property (weak, nonatomic) IBOutlet UIImageView *bottomLeftIcon;

@property (strong, nonatomic) IBOutlet UILabel *albumDisplayNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *albumCountLabel;

@end

