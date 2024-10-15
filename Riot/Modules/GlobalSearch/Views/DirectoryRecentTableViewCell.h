/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
