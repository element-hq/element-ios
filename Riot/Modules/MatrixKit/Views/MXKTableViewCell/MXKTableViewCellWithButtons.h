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
 'MXKTableViewCellWithButtons' inherits 'MXKTableViewCell' class.
 It displays several buttons with the system style in a UITableViewCell. All buttons have the same width and they are horizontally aligned.
 They are vertically centered.
 */
@interface MXKTableViewCellWithButtons : MXKTableViewCell

/**
 The number of buttons
 */
@property (nonatomic) NSUInteger mxkButtonNumber;

/**
 The current array of buttons
 */
@property (nonatomic) NSArray *mxkButtons;

@end