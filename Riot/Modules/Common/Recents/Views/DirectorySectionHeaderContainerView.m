/*
Copyright 2024 New Vector Ltd.
Copyright 2020 Vector Creations Ltd
Copyright 2014 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "DirectorySectionHeaderContainerView.h"

static const CGFloat kInterItemsSpaceHorizontal = 8.0;

@implementation DirectorySectionHeaderContainerView

- (void)setNetworkLabel:(UILabel *)networkLabel
{
    _networkLabel = networkLabel;
    [self setNeedsLayout];
}

- (void)setDirectoryServerLabel:(UIView *)directoryServerLabel
{
    _directoryServerLabel = directoryServerLabel;
    [self setNeedsLayout];
}

- (void)setDisclosureView:(UIView *)disclosureView
{
    _disclosureView = disclosureView;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat leftMargin = 0;
    CGFloat rightMargin = 0;

    if (_networkLabel)
    {
        CGRect frame = _networkLabel.frame;
        frame.origin.x = 0;
        frame.origin.y = MAX(0, (self.bounds.size.height - frame.size.height)/2);
        _networkLabel.frame = frame;
    }

    if (_directoryServerLabel)
    {
        //  reset margins
        leftMargin = rightMargin = 0;

        CGRect frame = _directoryServerLabel.frame;

        if (_networkLabel)
        {
            leftMargin += _networkLabel.frame.size.width + kInterItemsSpaceHorizontal;
        }
        if (_disclosureView)
        {
            rightMargin += _disclosureView.frame.size.width + kInterItemsSpaceHorizontal;
        }

        frame.origin.x = leftMargin;
        frame.origin.y = MAX(0, (self.bounds.size.height - frame.size.height)/2);
        frame.size.width = self.bounds.size.width - leftMargin - rightMargin;
        _directoryServerLabel.frame = frame;
    }

    if (_disclosureView)
    {
        //  reset margins
        leftMargin = rightMargin = 0;

        CGRect frame = _disclosureView.frame;
        frame.origin.x = self.bounds.size.width - frame.size.width - rightMargin;
        frame.origin.y = MAX(0, (self.bounds.size.height - frame.size.height)/2);
        _disclosureView.frame = frame;
    }
}

@end
