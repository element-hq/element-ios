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
