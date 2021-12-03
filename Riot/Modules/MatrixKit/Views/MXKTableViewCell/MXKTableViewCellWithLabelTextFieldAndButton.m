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
