/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

/**
 'MXKCollectionViewCell' class is used to define custom UICollectionViewCell.
 Each 'MXKCollectionViewCell-inherited' class has its own 'reuseIdentifier'.
 */
@interface MXKCollectionViewCell : UICollectionViewCell

/**
 Returns the `UINib` object initialized for the cell.
 
 @return The initialized `UINib` object or `nil` if there were errors during
 initialization or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 The default reuseIdentifier of the 'MXKCollectionViewCell-inherited' class.
 */
+ (NSString*)defaultReuseIdentifier;

/**
 Customize the rendering of the collection view cell and its subviews (Do nothing by default).
 This method is called when the view is initialized or prepared for reuse.
 
 Override this method to customize the collection view cell at the application level.
 */
- (void)customizeCollectionViewCellRendering;

@end
