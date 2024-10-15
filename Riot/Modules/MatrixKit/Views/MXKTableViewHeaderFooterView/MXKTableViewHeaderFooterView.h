/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

/**
 'MXKTableViewHeaderFooterView' class is used to define custom UITableViewHeaderFooterView (Either the header or footer for a section).
 Each 'MXKTableViewHeaderFooterView-inherited' class has its own 'reuseIdentifier'.
 */
@interface MXKTableViewHeaderFooterView : UITableViewHeaderFooterView
{
@protected
    NSString *mxkReuseIdentifier;
}

/**
 Returns the `UINib` object initialized for the header/footer view.
 
 @return The initialized `UINib` object or `nil` if there were errors during
 initialization or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 The default reuseIdentifier of the 'MXKTableViewHeaderFooterView-inherited' class.
 */
+ (NSString*)defaultReuseIdentifier;

/**
 Customize the rendering of the header/footer view and its subviews (Do nothing by default).
 This method is called when the view is initialized or prepared for reuse.
 
 Override this method to customize the view at the application level.
 */
- (void)customizeTableViewHeaderFooterViewRendering;

@end
