/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCellWithLabelAndTextField.h"

@implementation MXKTableViewCellWithLabelAndTextField
@synthesize inputAccessoryView;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Add an accessory view to the text view in order to retrieve keyboard view.
        inputAccessoryView = [[UIView alloc] initWithFrame:CGRectZero];
        _mxkTextField.inputAccessoryView = inputAccessoryView;
    }
    
    return self;
}

- (void)dealloc
{
    inputAccessoryView = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Fix the minimum width of the label in order to keep it visible when the textfield width is increasing.
    [_mxkLabel sizeToFit];
    _mxkLabelMinWidthConstraint.constant = _mxkLabel.frame.size.width;
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    // "Done" key has been pressed
    [self.mxkTextField resignFirstResponder];
    return YES;
}

@end
