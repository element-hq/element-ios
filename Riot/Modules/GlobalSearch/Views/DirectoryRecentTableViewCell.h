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

#import "MatrixKit.h"

@class PublicRoomsDirectoryDataSource;

/**
 The `DirectoryRecentTableViewCell` cell displays information about the search on the public
 rooms directory.
 
 It acts as a button to go into the public rooms directory screen.
 */
@interface DirectoryRecentTableViewCell : MXKTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *chevronImageView;

/**
 Update the information displayed by the cell.

 @param publicRoomsDirectoryDataSource the data to render.
 */
- (void)render:(PublicRoomsDirectoryDataSource *)publicRoomsDirectoryDataSource;

/**
 Get the cell height.

 @return the cell height.
 */
+ (CGFloat)cellHeight;

@end
