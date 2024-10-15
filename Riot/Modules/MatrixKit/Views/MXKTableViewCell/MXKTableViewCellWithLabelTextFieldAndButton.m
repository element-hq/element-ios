/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCellWithLabelTextFieldAndButton.h"

@implementation MXKTableViewCellWithLabelTextFieldAndButton
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

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    // "Done" key has been pressed
    [self.mxkTextField resignFirstResponder];
    return YES;
}

#pragma mark - Action

- (IBAction)textFieldEditingChanged:(id)sender
{
    self.mxkButton.enabled = (self.mxkTextField.text.length != 0);
}


@end
