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

#import "MXKCellRendering.h"
#import "MXKImageView.h"

/**
 Each `MXKSearchTableViewCell` instance displays a search result.
 */
@interface MXKSearchTableViewCell : MXKTableViewCell <MXKCellRendering>

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *message;
@property (weak, nonatomic) IBOutlet UILabel *date;

@property (weak, nonatomic) IBOutlet MXKImageView *attachmentImageView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImage;

@end
