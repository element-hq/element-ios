/*
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

#import "MXKTableViewHeaderFooterView.h"

/**
 'MXKTableViewHeaderFooterWithLabel' inherits 'MXKTableViewHeaderFooterView' class.
 It constains a 'UILabel' vertically centered in which the dymanic fonts is enabled.
 The height of this header is dynamically adapted to its content.
 */
@interface MXKTableViewHeaderFooterWithLabel : MXKTableViewHeaderFooterView

@property (strong, nonatomic) IBOutlet UIView  *mxkContentView;
@property (strong, nonatomic) IBOutlet UILabel *mxkLabel;

/**
 The following constraints are defined between the label and the content view (no relative to margin)
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelBottomConstraint;

@end
