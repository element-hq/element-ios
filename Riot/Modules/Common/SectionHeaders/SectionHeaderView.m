/*
Copyright 2024 New Vector Ltd.
Copyright 2020 Vector Creations Ltd
Copyright 2014 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "SectionHeaderView.h"

#import "GeneratedInterface-Swift.h"

static const CGFloat kInterItemsSpaceHorizontal = 8.0;

@implementation SectionHeaderView

+ (NSString*)defaultReuseIdentifier
{
    return NSStringFromClass([self class]);
}

- (void)setMinimumLeftInset:(CGFloat)minimumLeftInset
{
    _minimumLeftInset = minimumLeftInset;
    [self setNeedsLayout];
}

- (void)setMinimumRightInset:(CGFloat)minimumRightInset
{
    _minimumRightInset = minimumRightInset;
    [self setNeedsLayout];
}

- (void)setTopViewHeight:(CGFloat)topViewHeight
{
    _topViewHeight = topViewHeight;
    [self setNeedsLayout];
}

- (void)setTopPadding:(CGFloat)topPadding
{
    _topPadding = topPadding;
    [self setNeedsLayout];
}

- (void)setTopSpanningView:(UIView *)topSpanningView
{
    //  remove old one
    [_topSpanningView removeFromSuperview];
    _topSpanningView = topSpanningView;
    if (_topSpanningView)
    {
        //  add new one
        [self.contentView addSubview:_topSpanningView];
    }
    [self setNeedsLayout];
}

- (void)setHeaderLabel:(UILabel *)headerLabel
{
    //  remove old one
    [_headerLabel removeFromSuperview];
    _headerLabel = headerLabel;
    if (_headerLabel)
    {
        //  add new one
        [self.contentView addSubview:_headerLabel];
    }
    [self setNeedsLayout];
}

- (void)setAccessoryView:(UIView *)accessoryView
{
    //  remove old one
    [_accessoryView removeFromSuperview];
    _accessoryView = accessoryView;
    if (_accessoryView)
    {
        //  add new one
        [self.contentView addSubview:_accessoryView];
    }
    [self setNeedsLayout];
}

- (void)setRightAccessoryView:(UIView *)rightAccessoryView
{
    //  remove old one
    [_rightAccessoryView removeFromSuperview];
    _rightAccessoryView = rightAccessoryView;
    if (_rightAccessoryView)
    {
        //  add new one
        [self.contentView addSubview:_rightAccessoryView];
    }
    [self setNeedsLayout];
}

- (void)setBottomView:(UIView *)bottomView
{
    //  remove old one
    [_bottomView removeFromSuperview];
    _bottomView = bottomView;
    if (_bottomView)
    {
        //  add new one
        [self.contentView addSubview:_bottomView];
    }
    [self setNeedsLayout];
}

- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithReuseIdentifier:reuseIdentifier])
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _minimumLeftInset = 16;
    _minimumRightInset = 16;
    _topViewHeight = 30;
}

- (void)prepareForReuse
{
    [self.contentView vc_removeAllSubviews];
    [super prepareForReuse];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat _leftInset = 0.0, _rightInset = 0.0;

    CGFloat leftMargin = _minimumLeftInset;
    CGFloat rightMargin = _minimumRightInset;

    if (_topSpanningView)
    {
        CGRect frame = self.contentView.bounds;
        frame.origin.y += _topPadding;
        frame.size.height = _topViewHeight;
        _topSpanningView.frame = frame;
    }

    if (_headerLabel)
    {
        CGRect frame = _headerLabel.frame;
        frame.origin.x = leftMargin;
        if (_accessoryView)
        {
            rightMargin += _accessoryView.frame.size.width + kInterItemsSpaceHorizontal;
        }
        if (_rightAccessoryView)
        {
            rightMargin += _rightAccessoryView.frame.size.width + kInterItemsSpaceHorizontal;
        }
        if (_bottomView)
        {
            //  set header label top
            frame.origin.y = (_topViewHeight - frame.size.height)/2;
        }
        else
        {
            //  center header label vertically
            frame.origin.y = MAX(0, (self.contentView.bounds.size.height - frame.size.height)/2);
        }
        frame.size.width = MIN(self.contentView.bounds.size.width - leftMargin - rightMargin,
                               [_headerLabel sizeThatFits:self.frame.size].width);
        frame.origin.y += _topPadding;
        _headerLabel.frame = frame;
    }

    if (_accessoryView)
    {
        //  reset margins
        leftMargin = MAX(_leftInset, 20);
        rightMargin = MAX(_rightInset, 20);

        CGRect frame = _accessoryView.frame;
        if(_headerLabel)
        {
            frame.origin.x = leftMargin + _headerLabel.frame.size.width + kInterItemsSpaceHorizontal;
        }
        else
        {
            frame.origin.x = leftMargin;
        }
        frame.origin.y = MAX(0, (_topViewHeight - frame.size.height)/2);
        frame.origin.y += _topPadding;
        _accessoryView.frame = frame;
    }

    if (_rightAccessoryView)
    {
        //  reset margins
        leftMargin = MAX(_leftInset, 20);
        rightMargin = MAX(_rightInset, 20);

        CGRect frame = _rightAccessoryView.frame;
        frame.origin.x = self.contentView.bounds.size.width - frame.size.width - rightMargin;
        frame.origin.y = MAX(0, (_topViewHeight - frame.size.height)/2);
        frame.origin.y += _topPadding;
        _rightAccessoryView.frame = frame;
    }

    if (_bottomView)
    {
        //  reset margins
        leftMargin = MAX(_leftInset, 16);
        rightMargin = MAX(_rightInset, 16);

        CGRect frame = _bottomView.frame;
        frame.origin.x = leftMargin;
        frame.origin.y = CGRectGetMaxY(_headerLabel.frame);
        frame.size.width = self.contentView.bounds.size.width - leftMargin - rightMargin;
        frame.size.height = self.contentView.bounds.size.height - frame.origin.y;
        _bottomView.frame = frame;
    }
}

@end
