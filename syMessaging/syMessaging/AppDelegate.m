/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "AppDelegate.h"
#import "RoomViewController.h"
#import "MatrixHandler.h"

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

@implementation AppDelegate

#pragma mark -

+ (AppDelegate*)theDelegate {
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}
#pragma mark -

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    if ([self.window.rootViewController isKindOfClass:[UITabBarController class]])
    {
        self.tabBarController = (UITabBarController*)self.window.rootViewController;
        self.tabBarController.delegate = self;
        
        // By default the "Contacts" tab is focussed
        [self.tabBarController setSelectedIndex:TABBAR_HOME_INDEX];
        
        UIViewController* recents = [self.tabBarController.viewControllers objectAtIndex:TABBAR_RECENTS_INDEX];
        if ([recents isKindOfClass:[UISplitViewController class]]) {
            UISplitViewController *splitViewController = (UISplitViewController *)recents;
            UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
            navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
            splitViewController.delegate = self;
        }
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Internal methods

- (UIAlertView*)showErrorAsAlert:(NSError*)error
{
    NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
    if (!title)
    {
        title = @"Error";
    }
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
    
    return alert;
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[RoomViewController class]] && ([(RoomViewController *)[(UINavigationController *)secondaryViewController topViewController] detailItem] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}

@end
