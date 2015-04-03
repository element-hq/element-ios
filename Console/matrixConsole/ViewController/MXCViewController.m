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
#import "MXCViewController.h"

#import "RageShakableUIResponder.h"

@interface MXCViewController () {
    id mxcViewControllerReachabilityObserver;
}
@end

@implementation MXCViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [RageShakableUIResponder cancel:self];
    
    if (self.navigationController) {
        // The navigation bar tintColor depends on reachability status - Register reachability observer
        __weak typeof(self) weakSelf = self;
        mxcViewControllerReachabilityObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingReachabilityDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
            [weakSelf onReachabilityStatusChange];
        }];
        // Force update
        [self onReachabilityStatusChange];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:mxcViewControllerReachabilityObserver];
    [RageShakableUIResponder cancel:self];
}

#pragma mark - Reachability monitoring

- (void)onReachabilityStatusChange {
    // Retrieve the current reachability status
    AFNetworkReachabilityManager *reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    AFNetworkReachabilityStatus status = reachabilityManager.networkReachabilityStatus;
    
    // Retrieve the main navigation controller if the current view controller is embedded inside a split view controller.
    UINavigationController *mainNavigationController = nil;
    if (self.splitViewController) {
        mainNavigationController = self.navigationController;
        UIViewController *parentViewController = self.parentViewController;
        while (parentViewController) {
            if (parentViewController.navigationController) {
                mainNavigationController = parentViewController.navigationController;
                parentViewController = parentViewController.parentViewController;
            } else {
                break;
            }
        }
    }
    
    // Update navigationBar tintColor
    if (status == AFNetworkReachabilityStatusNotReachable) {
        self.navigationController.navigationBar.barTintColor = [UIColor redColor];
        if (mainNavigationController) {
            mainNavigationController.navigationBar.barTintColor = [UIColor redColor];
        }
    } else if (status == AFNetworkReachabilityStatusReachableViaWiFi || status == AFNetworkReachabilityStatusReachableViaWWAN) {
        self.navigationController.navigationBar.barTintColor = nil;
        if (mainNavigationController) {
            mainNavigationController.navigationBar.barTintColor = nil;
        }
    }
}

#pragma mark - Rage shake handling

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        [RageShakableUIResponder startShaking:self];
    }
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    [self motionEnded:motion withEvent:event];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        [RageShakableUIResponder stopShaking:self];
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

@end


