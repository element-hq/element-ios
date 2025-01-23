// 
// Copyright 2024 New Vector Ltd.
// Copyright 2021 The Matrix.org Foundation C.I.C
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#ifndef MXKViewControllerActivityHandling_h
#define MXKViewControllerActivityHandling_h

/**
 `MXKViewControllerActivityHandling` defines a protocol to handle requirements for
 all matrixKit view controllers and table view controllers.
 
 It manages the following points:
 - stop/start activity indicator according to the state of the associated matrix sessions.
 */
@protocol MXKViewControllerActivityHandling <NSObject>

/**
 Activity indicator view.
 By default this activity indicator is centered inside the view controller view. It automatically
 starts if `shouldShowActivityIndicator `returns true for the session.
 It is stopped on other states.
 Set nil to disable activity indicator animation.
 */
@property (nonatomic) UIActivityIndicatorView *activityIndicator;

/**
 A view controller may choose to implement a completely custom activity indicator (e.g. shared toast notification),
 
 In this case the default `activityIndicator` will be hidden, and the view controller is responsible for overriding
 `startActivityIndicator` and `stopActivityIndicator` methods to show / hide the custom activity indicator.
 */
@property (nonatomic, readonly) BOOL providesCustomActivityIndicator;

/**
 Bring the activity indicator to the front and start it.
 */
- (void)startActivityIndicator;

/**
 Stop the activity indicator if all conditions are satisfied.
 */
- (void)stopActivityIndicator;

@end

#endif /* MXKViewControllerActivityHandling_h */
