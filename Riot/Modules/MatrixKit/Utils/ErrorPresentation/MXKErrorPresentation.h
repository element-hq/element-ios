/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

@import Foundation;
@import UIKit;

#import "MXKErrorPresentable.h"

/**
 `MXKErrorPresentation` describe an error display handler for presenting error from a view controller.
 */
@protocol MXKErrorPresentation

- (void)presentErrorFromViewController:(UIViewController*)viewController
                                 title:(NSString*)title
                               message:(NSString*)message
                              animated:(BOOL)animated
                               handler:(void (^)(void))handler;

- (void)presentErrorFromViewController:(UIViewController*)viewController
                              forError:(NSError*)error
                              animated:(BOOL)animated
                               handler:(void (^)(void))handler;

- (void)presentGenericErrorFromViewController:(UIViewController*)viewController
                                     animated:(BOOL)animated
                                      handler:(void (^)(void))handler;

@required

- (void)presentErrorFromViewController:(UIViewController*)viewController
                   forErrorPresentable:(id<MXKErrorPresentable>)errorPresentable
                              animated:(BOOL)animated
                               handler:(void (^)(void))handler;

@end
