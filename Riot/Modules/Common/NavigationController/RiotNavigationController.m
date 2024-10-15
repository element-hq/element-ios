/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

@import MatrixSDK;

#import "RiotNavigationController.h"

@implementation RiotNavigationController

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.topViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.topViewController;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (self.isLockedToPortraitOnPhone && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        return UIInterfaceOrientationMaskPortrait;
    }
    
    if (self.topViewController)
    {
        return self.topViewController.supportedInterfaceOrientations;
    }
    return [super supportedInterfaceOrientations];
}

- (BOOL)shouldAutorotate
{
    if (self.topViewController)
    {
        return self.topViewController.shouldAutorotate;
    }
    return [super shouldAutorotate];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if (self.topViewController)
    {
        return self.topViewController.preferredInterfaceOrientationForPresentation;
    }
    return [super preferredInterfaceOrientationForPresentation];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([self.viewControllers indexOfObject:viewController] != NSNotFound)
    {
        MXLogDebug(@"[RiotNavigationController] pushViewController: is pushing same view controller %@\n%@", viewController, [NSThread callStackSymbols]);
        return;
    }
    [super pushViewController:viewController animated:animated];
}


- (instancetype)initWithIsLockedToPortraitOnPhone:(BOOL)isLockedToPortraitOnPhone
{
    self = [super init];
    if (self) {
        self.isLockedToPortraitOnPhone = isLockedToPortraitOnPhone;
    }
    return self;
}

@end
