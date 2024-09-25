/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

/**
 `MXKView` is a base class used to add some functionalities to the UIView class.
 */
@interface MXKView : UIView

/**
 Customize the rendering of the view and its subviews (Do nothing by default).
 This method is called automatically when the view is initialized or loaded from an Interface Builder archive (or nib file).
 
 Override this method to customize the view instance at the application level.
 It may be used to handle different rendering themes. In this case this method should be called whenever the theme has changed.
 */
- (void)customizeViewRendering;

@end

