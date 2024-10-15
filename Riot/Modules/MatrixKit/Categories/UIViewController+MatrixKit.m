/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "UIViewController+MatrixKit.h"

@implementation UIViewController (MatrixKit)

- (UINavigationController *)mxk_mainNavigationController
{
    UINavigationController *mainNavigationController;

    if (self.splitViewController)
    {
        mainNavigationController = self.navigationController;
        UIViewController *parentViewController = self.parentViewController;
        while (parentViewController)
        {
            if (parentViewController.navigationController)
            {
                mainNavigationController = parentViewController.navigationController;
                parentViewController = parentViewController.parentViewController;
            }
            else
            {
                break;
            }
        }
    }

    return mainNavigationController;
}
@end
