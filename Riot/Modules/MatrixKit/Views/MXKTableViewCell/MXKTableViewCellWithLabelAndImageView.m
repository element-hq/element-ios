/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCellWithLabelAndImageView.h"

@implementation MXKTableViewCellWithLabelAndImageView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.mxkImageViewDisplayBoxType == MXKTableViewCellDisplayBoxTypeCircle)
    {
        // Round image view for thumbnail
        _mxkImageView.layer.cornerRadius = _mxkImageView.frame.size.width / 2;
        _mxkImageView.clipsToBounds = YES;
    }
    else if (self.mxkImageViewDisplayBoxType == MXKTableViewCellDisplayBoxTypeRoundedCorner)
    {
        _mxkImageView.layer.cornerRadius = 5;
        _mxkImageView.clipsToBounds = YES;
    }
    else
    {
        _mxkImageView.layer.cornerRadius = 0;
        _mxkImageView.clipsToBounds = NO;
    }
}

@end

