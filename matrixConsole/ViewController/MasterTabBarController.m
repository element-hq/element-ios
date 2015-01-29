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

#import "MasterTabBarController.h"
#import "MatrixSDKHandler.h"

#import "RecentsViewController.h"

@interface MasterTabBarController () {
    UINavigationController *recentsNavigationController;
    RecentsViewController  *recentsViewController;
    
    UIImagePickerController *mediaPicker;
}

@end

@implementation MasterTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // To simplify navigation into the app, we retrieve here the navigation controller and the view controller related
    // to the recents list in Recents Tab.
    // Note: UISplitViewController is not supported on iPhone for iOS < 8.0
    UIViewController* recents = [self.viewControllers objectAtIndex:TABBAR_RECENTS_INDEX];
    recentsNavigationController = nil;
    if ([recents isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *splitViewController = (UISplitViewController *)recents;
        recentsNavigationController = [splitViewController.viewControllers objectAtIndex:0];
    } else if ([recents isKindOfClass:[UINavigationController class]]) {
        recentsNavigationController = (UINavigationController*)recents;
    }
    
    if (recentsNavigationController) {
        for (UIViewController *viewController in recentsNavigationController.viewControllers) {
            if ([viewController isKindOfClass:[RecentsViewController class]]) {
                recentsViewController = (RecentsViewController*)viewController;
            }
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([MatrixSDKHandler sharedHandler].status == MatrixSDKHandlerStatusLoggedOut) {
        [self showLoginScreen];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    recentsNavigationController = nil;
    recentsViewController = nil;
    
    [self dismissMediaPicker];
}

#pragma mark -

- (void)restoreInitialDisplay {
    // Dismiss potential media picker
    if (mediaPicker) {
        if (mediaPicker.delegate && [mediaPicker.delegate respondsToSelector:@selector(imagePickerControllerDidCancel:)]) {
            [mediaPicker.delegate imagePickerControllerDidCancel:mediaPicker];
        } else {
            [self dismissMediaPicker];
        }
    }
    
    [self popRoomViewControllerAnimated:NO];
}

#pragma mark -

- (void)showLoginScreen {
    [self restoreInitialDisplay];
    
    [self performSegueWithIdentifier:@"showLogin" sender:self];
}

- (void)showRoomCreationForm {
    // Switch in Home Tab
    [self setSelectedIndex:TABBAR_HOME_INDEX];
}

- (void)showRoom:(NSString*)roomId {
    [self restoreInitialDisplay];
    
    // Switch on Recents Tab
    [self setSelectedIndex:TABBAR_RECENTS_INDEX];
    
    // Select room to display its details (dispatch this action in order to let TabBarController end its refresh)
    dispatch_async(dispatch_get_main_queue(), ^{
        recentsViewController.preSelectedRoomId = roomId;
    });
}

- (void)popRoomViewControllerAnimated:(BOOL)animated {
    // Force back to recents list if room details is displayed in Recents Tab
    if (recentsViewController) {
        [recentsNavigationController popToViewController:recentsViewController animated:animated];
        // Release the current selected room
        recentsViewController.preSelectedRoomId = nil;
    }
}

- (BOOL)isPresentingMediaPicker {
    return nil != mediaPicker;
}

- (void)presentMediaPicker:(UIImagePickerController*)aMediaPicker {
    [self dismissMediaPicker];
    [self presentViewController:aMediaPicker animated:YES completion:^{
        mediaPicker = aMediaPicker;
    }];
}
- (void)dismissMediaPicker {
    if (mediaPicker) {
        [self dismissViewControllerAnimated:NO completion:nil];
        mediaPicker.delegate = nil;
        mediaPicker = nil;
    }
}

- (void)setVisibleRoomId:(NSString *)aVisibleRoomId {
    [[MatrixSDKHandler sharedHandler] allowRoomPushes:aVisibleRoomId];
    _visibleRoomId = aVisibleRoomId;
}

@end
