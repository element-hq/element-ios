/*
 Copyright 2014 OpenMarket Ltd
 Copyright 2020 Vector Creations Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "SectionHeaderView.h"

static const CGFloat kInterItemsSpaceHorizontal = 8.0;

@implementation SectionHeaderView

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

- (void)setTopSpanningView:(UIView *)topSpanningView
{
    _topSpanningView = topSpanningView;
    [self setNeedsLayout];
}

- (void)setHeaderLabel:(UILabel *)headerLabel
{
    _headerLabel = headerLabel;
    [self setNeedsLayout];
}

- (void)setAccessoryView:(UIView *)accessoryView
{
    _accessoryView = accessoryView;
    [self setNeedsLayout];
}

- (void)setBottomView:(UIView *)bottomView
{
    _bottomView = bottomView;
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

- (void)setup
{
    _minimumLeftInset = 20;
    _minimumRightInset = 16;
    _topViewHeight = 30;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat _leftInset = 0.0, _rightInset = 0.0;
    
    _leftInset += self.safeAreaInsets.left;
    _rightInset += self.safeAreaInsets.right;

    CGFloat leftMargin = MAX(_leftInset, _minimumLeftInset);
    CGFloat rightMargin = MAX(_rightInset, _minimumRightInset);

    if (_topSpanningView)
    {
        CGRect frame = self.bounds;
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
        if (_bottomView)
        {
            //  set header label top
            frame.origin.y = (_topViewHeight - frame.size.height)/2;
        }
        else
        {
            //  center header label vertically
            frame.origin.y = MAX(0, (self.bounds.size.height - frame.size.height)/2);
        }
        frame.size.width = self.bounds.size.width - leftMargin - rightMargin;
        _headerLabel.frame = frame;
    }

    if (_accessoryView)
    {
        //  reset margins
        leftMargin = MAX(_leftInset, 20);
        rightMargin = MAX(_rightInset, 20);

        CGRect frame = _accessoryView.frame;
        frame.origin.x = self.bounds.size.width - frame.size.width - rightMargin;
        frame.origin.y = MAX(0, (_topViewHeight - frame.size.height)/2);
        _accessoryView.frame = frame;
    }

    if (_bottomView)
    {
        //  reset margins
        leftMargin = MAX(_leftInset, 20);
        rightMargin = MAX(_rightInset, 20);

        CGRect frame = _bottomView.frame;
        frame.origin.x = leftMargin;
        frame.origin.y = CGRectGetMaxY(_headerLabel.frame);
        frame.size.width = self.bounds.size.width - leftMargin - rightMargin;
        frame.size.height = self.bounds.size.height - frame.origin.y;
        _bottomView.frame = frame;
    }
}

@end
