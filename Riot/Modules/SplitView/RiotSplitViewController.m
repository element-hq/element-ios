/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RiotSplitViewController.h"

@implementation RiotSplitViewController

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.viewControllers.firstObject;
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.viewControllers.firstObject;
}

@end
