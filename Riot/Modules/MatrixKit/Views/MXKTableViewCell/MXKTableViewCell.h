/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

#import "MXKCellData.h"

/**
 List the display box types for the cell subviews.
 */
typedef enum : NSUInteger {
    /**
     By default the view display box is unchanged.
     */
    MXKTableViewCellDisplayBoxTypeDefault,
    /**
     Define a circle box based on the smaller size of the view frame, some portion of content may be clipped.
     */
    MXKTableViewCellDisplayBoxTypeCircle,
    /**
     Round the corner of the display box of the view.
     */
    MXKTableViewCellDisplayBoxTypeRoundedCorner
    
} MXKTableViewCellDisplayBoxType;

/**
 'MXKTableViewCell' class is used to define custom UITableViewCell.
 Each 'MXKTableViewCell-inherited' class has its own 'reuseIdentifier'.
 */
@interface MXKTableViewCell : UITableViewCell
{
@protected
    NSString *mxkReuseIdentifier;
}

/**
 Returns the `UINib` object initialized for the cell.
 
 @return The initialized `UINib` object or `nil` if there were errors during
 initialization or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 The default reuseIdentifier of the 'MXKTableViewCell-inherited' class.
 */
+ (NSString*)defaultReuseIdentifier;

/**
 Override [UITableViewCell initWithStyle:reuseIdentifier:] to load cell content from nib file (if any), 
 and handle reuse identifier.
 */
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

/**
 Customize the rendering of the table view cell and its subviews (Do nothing by default).
 This method is called when the view is initialized or prepared for reuse.
 
 Override this method to customize the table view cell at the application level.
 */
- (void)customizeTableViewCellRendering;

/**
 The current cell data displayed by the table view cell
 */
@property (weak, nonatomic, readonly) MXKCellData *mxkCellData;

@end
