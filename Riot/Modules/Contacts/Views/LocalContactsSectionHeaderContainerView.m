/*
Copyright 2024 New Vector Ltd.
Copyright 2020 Vector Creations Ltd
Copyright 2014 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "LocalContactsSectionHeaderContainerView.h"

static const CGFloat kInterItemsSpaceHorizontal = 8.0;

@implementation LocalContactsSectionHeaderContainerView

- (void)setCheckboxView:(UIView *)checkboxView
{
    _checkboxView = checkboxView;
    [self setNeedsLayout];
}

- (void)setCheckboxLabel:(UILabel *)checkboxLabel
{
    _checkboxLabel = checkboxLabel;
    [self setNeedsLayout];
}

- (void)setMaskView:(UIView *)maskView
{
    _maskView = maskView;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat leftMargin = 0;
    CGFloat rightMargin = 0;

    if (_checkboxView)
    {
        CGRect frame = _checkboxView.frame;
        frame.origin.x = 0;
        frame.origin.y = MAX(0, (self.bounds.size.height - frame.size.height)/2);
        _checkboxView.frame = frame;
    }

    if (_checkboxLabel)
    {
        CGRect frame = _checkboxLabel.frame;
        if (_checkboxView)
        {
            leftMargin += CGRectGetMaxX(_checkboxView.frame) + kInterItemsSpaceHorizontal;
        }
        frame.origin.x = leftMargin;
        frame.origin.y = MAX(0, (self.bounds.size.height - frame.size.height)/2);
        frame.size.width = self.bounds.size.width - leftMargin - rightMargin;
        _checkboxLabel.frame = frame;
    }

    if (_maskView)
    {
        _maskView.frame = self.bounds;
    }
}

@end
