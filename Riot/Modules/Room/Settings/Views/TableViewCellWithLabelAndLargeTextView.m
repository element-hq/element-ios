/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "TableViewCellWithLabelAndLargeTextView.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@implementation TableViewCellWithLabelAndLargeTextView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Adjust text view
    // Remove the container inset: this operation impacts only the vertical margin.
    // Reset textContainer.lineFragmentPadding to remove horizontal margin.
    _textView.textContainerInset = UIEdgeInsetsZero;
    _textView.textContainer.lineFragmentPadding = 0;
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    _label.textColor = ThemeService.shared.theme.textPrimaryColor;
    _textView.textColor = ThemeService.shared.theme.textPrimaryColor;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat cellWidth = self.contentView.frame.size.width;
    
    CGRect frame = _label.frame;
    CGFloat minTextViewPosX = frame.origin.x + frame.size.width + _labelTrailingMinConstraint.constant;
    
    CGFloat maxTextViewWidth = cellWidth - minTextViewPosX - _textViewTrailingConstraint.constant;
    
    if (_textView.isEditable && _textView.isFirstResponder)
    {
        // Use the full available width when the field is edited
        _textViewWidthConstraint.constant = maxTextViewWidth;
    }
    else
    {
        // Adjust the text view width to display it on the right side of the cell
        CGSize size = _textView.frame.size;
        size.width = maxTextViewWidth;
        
        size = [_textView sizeThatFits:size];
        
        _textViewWidthConstraint.constant = size.width;
    }
}

#pragma mark -

- (void)textViewDidBeginEditing:(UITextView *)textView;
{
    [self setNeedsLayout];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self setNeedsLayout];
}

@end
