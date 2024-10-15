/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCell.h"

/**
 'MXKTableViewCellWithLabelTextFieldAndButton' inherits 'MXKTableViewCell' class.
 It constains a 'UILabel' on the first line. The second line is composed with a 'UITextField' and a 'UIButton'
 vertically aligned.
 */
@interface MXKTableViewCellWithLabelTextFieldAndButton : MXKTableViewCell <UITextFieldDelegate>
{
@protected
    UIView *inputAccessoryView;
}

@property (strong, nonatomic) IBOutlet UILabel *mxkLabel;
@property (strong, nonatomic) IBOutlet UITextField *mxkTextField;
@property (strong, nonatomic) IBOutlet UIButton *mxkButton;

/**
 The custom accessory view associated with the text field. This view is
 actually used to retrieve the keyboard view. Indeed the keyboard view is the superview of
 the accessory view when the text field become the first responder.
 */
@property (readonly) UIView *inputAccessoryView;

/**
 Leading/Trailing constraints define here spacing to nearest neighbor (no relative to margin)
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelTrailingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkTextFieldLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkTextFieldTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkTextFieldBottomConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkButtonLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkButtonTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkButtonMinWidthConstraint;

- (IBAction)textFieldEditingChanged:(id)sender;

@end
