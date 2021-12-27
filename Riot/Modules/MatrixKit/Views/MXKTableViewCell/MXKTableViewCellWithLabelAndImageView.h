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
 'MXKTableViewCellWithLabelAndImageView' inherits 'MXKTableViewCell' class.
 It constains a 'UILabel' and a 'UIImageView' vertically centered.
 */
@interface MXKTableViewCellWithLabelAndImageView : MXKTableViewCell

@property (strong, nonatomic) IBOutlet UILabel *mxkLabel;
@property (strong, nonatomic) IBOutlet UIImageView *mxkImageView;

/**
 Leading/Trailing constraints define here spacing to nearest neighbor (no relative to margin)
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkLabelLeadingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkImageViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkImageViewTrailingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkImageViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mxkImageViewHeightConstraint;

/**
 The image view display box type ('MXKTableViewCellDisplayBoxTypeDefault' by default)
 */
@property (nonatomic) MXKTableViewCellDisplayBoxType mxkImageViewDisplayBoxType;

@end
