/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "MXKTableViewCell.h"

/**
 'MXKTableViewCellWithLabelAndTextField' inherits 'MXKTableViewCell' class.
 It constains a 'UILabel' and a 'UITextField' vertically centered.
 */
@interface MXKTableViewCellWithLabelAndTextField : MXKTableViewCell <UITextFieldDelegate>
{
@protected
    UIView *inputAccessoryView;
}

@property (strong, nonatomic) IBOutlet UILabel *mxkLabel;
@property (strong, nonatomic) IBOutlet UITextField *mxkTextField;

/**
 The custom accessory view associated with the text field. This view is
 actually used to retrieve the keyboard view. Indeed the keyboard view is the superview of
 the accessory view when the text field become the first responder.
 */
@property (readonly) UIView *inputAccessoryView;

/**
 Leading/Trailing constraints define here spacing to nearest neighbor (no relative to margin)
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelMinWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkTextFieldLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkTextFieldTrailingConstraint;

@end