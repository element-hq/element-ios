/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
