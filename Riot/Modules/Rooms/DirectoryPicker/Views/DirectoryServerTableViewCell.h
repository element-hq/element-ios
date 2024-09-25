/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 The `DirectoryServerTableViewCell` cell displays a server .
 */
@interface DirectoryServerTableViewCell : MXKTableViewCell

@property (weak, nonatomic) IBOutlet MXKImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;

/**
 Update the information displayed by the cell.
 
 @param cellData the data to render.
 */
- (void)render:(id<MXKDirectoryServerCellDataStoring>)cellData;

/**
 Get the cell height.

 @return the cell height.
 */
+ (CGFloat)cellHeight;

@end
