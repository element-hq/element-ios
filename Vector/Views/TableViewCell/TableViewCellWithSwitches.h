/*
 Copyright 2016 OpenMarket Ltd
 
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
 'TableViewCellWithSwitches' inherits 'MXKTableViewCell' class.
 It displays several switches in a UITableViewCell. Each switch has its own label.
 All switches have the same width and they are horizontally aligned inside the main container.
 They are vertically centered.
 */
@interface TableViewCellWithSwitches : MXKTableViewCell

@property (weak, nonatomic) IBOutlet UIView *mainContainer;

/**
 The number of switches
 */
@property (nonatomic) NSUInteger switchesNumber;

/**
 The current array of switches
 */
@property (nonatomic, readonly) NSArray *switches;

/**
 The current array of labels
 */
@property (nonatomic, readonly) NSArray *labels;

/**
 Leading/Trailing constraints define here spacing to nearest neighbor (no relative to margin)
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainContainerLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainContainerTrailingConstraint;

@end