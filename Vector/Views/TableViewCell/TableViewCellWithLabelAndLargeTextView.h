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

@interface TableViewCellWithLabelAndLargeTextView : MXKTableViewCell
{
@protected
    UIView *inputAccessoryView;
}

@property (strong, nonatomic) IBOutlet UILabel *mxkLabel;
@property (strong, nonatomic) IBOutlet UITextView *mxkTextView;

/**
 The custom accessory view associated with the text field. This view is
 actually used to retrieve the keyboard view. Indeed the keyboard view is the superview of
 the accessory view when the text field become the first responder.
 */
@property (readonly) UIView *inputAccessoryView;

@end