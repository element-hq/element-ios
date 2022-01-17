/*
 Copyright 2017 Vector Creations Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
