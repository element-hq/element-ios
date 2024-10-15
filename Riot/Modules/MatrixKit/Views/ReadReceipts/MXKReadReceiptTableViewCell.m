/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Aram Sargsyan

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKReadReceiptTableViewCell.h"
#import "MXKImageView.h"

@implementation MXKReadReceiptTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.avatarImageView.enableInMemoryCache = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.avatarImageView) {
        //Make imageView round
        self.avatarImageView.layer.cornerRadius = CGRectGetWidth(self.avatarImageView.frame)/2;
        self.avatarImageView.clipsToBounds = YES;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end
