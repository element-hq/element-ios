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

#import "MXKImageView.h"
#import "MXKAccount.h"

/**
 MXKAccountTableViewCell instance is a table view cell used to display a matrix user.
 */
@interface MXKAccountTableViewCell : MXKTableViewCell

/**
 The displayed account
 */
@property (nonatomic) MXKAccount* mxAccount;

/**
 The default account picture displayed when no picture is defined.
 */
@property (nonatomic) UIImage *picturePlaceholder;

@property (strong, nonatomic) IBOutlet MXKImageView* accountPicture;

@property (strong, nonatomic) IBOutlet UILabel* accountDisplayName;

@property (strong, nonatomic) IBOutlet UISwitch* accountSwitchToggle;

@end
