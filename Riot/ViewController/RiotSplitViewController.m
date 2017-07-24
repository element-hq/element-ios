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

#import "RiotSplitViewController.h"

@implementation RiotSplitViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.collapsed)
    {
        // Look for the view controller displayed at the top.
        UIViewController *topViewController = self.viewControllers.firstObject;
        
        while ([topViewController isKindOfClass:[UINavigationController class]])
        {
            topViewController = ((UINavigationController*)topViewController).topViewController;
        }
        
        if (topViewController)
        {
            return [topViewController preferredStatusBarStyle];
        }
    }
    
    // Keep the default UISplitViewController style.
    return [super preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden
{
    if (self.collapsed)
    {
        // Look for the view controller displayed at the top.
        UIViewController *topViewController = self.viewControllers.firstObject;
        
        while ([topViewController isKindOfClass:[UINavigationController class]])
        {
            topViewController = ((UINavigationController*)topViewController).topViewController;
        }
        
        if (topViewController)
        {
            return [topViewController prefersStatusBarHidden];
        }
    }
    
    // Keep the default UISplitViewController mode.
    return [super prefersStatusBarHidden];
}

@end
