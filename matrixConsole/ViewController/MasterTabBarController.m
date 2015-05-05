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

#import "AppDelegate.h"

#import "HomeViewController.h"

#import "RecentsViewController.h"
#import "RecentListDataSource.h"

#import "ContactsViewController.h"

#import "SettingsViewController.h"

@interface MasterTabBarController () {
    HomeViewController *homeViewController;
    
    UINavigationController *recentsNavigationController;
    RecentsViewController  *recentsViewController;
    
    ContactsViewController *contactsViewController;
    
    SettingsViewController *settingsViewController;
    
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
    
    // Retrieve the home view controller
    UIViewController* home = [self.viewControllers objectAtIndex:TABBAR_HOME_INDEX];
    if ([home isKindOfClass:[UINavigationController class]]) {
        UINavigationController *homeNavigationController = (UINavigationController*)home;
        for (UIViewController *viewController in homeNavigationController.viewControllers) {
            if ([viewController isKindOfClass:[HomeViewController class]]) {
                homeViewController = (HomeViewController*)viewController;
            }
        }
    }
    
    // Retrieve the constacts view controller
    UIViewController* contacts = [self.viewControllers objectAtIndex:TABBAR_CONTACTS_INDEX];
    if ([contacts isKindOfClass:[UINavigationController class]]) {
        UINavigationController *contactsNavigationController = (UINavigationController*)contacts;
        for (UIViewController *viewController in contactsNavigationController.viewControllers) {
            if ([viewController isKindOfClass:[ContactsViewController class]]) {
                contactsViewController = (ContactsViewController*)viewController;
            }
        }
    }
    
    // Retrieve the settings view controller
    UIViewController* settings = [self.viewControllers objectAtIndex:TABBAR_SETTINGS_INDEX];
    if ([settings isKindOfClass:[UINavigationController class]]) {
        UINavigationController *settingsNavigationController = (UINavigationController*)settings;
        for (UIViewController *viewController in settingsNavigationController.viewControllers) {
            if ([viewController isKindOfClass:[SettingsViewController class]]) {
                settingsViewController = (SettingsViewController*)viewController;
            }
        }
    }
    
    // Sanity check
    NSAssert(homeViewController &&recentsViewController && contactsViewController && settingsViewController, @"Something wrong in Main.storyboard");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Check whether we're not logged in
    if (![MXKAccountManager sharedManager].accounts.count) {
        [self showAuthenticationScreen];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
    [[AppDelegate theDelegate] reloadMatrixSessions:NO];
}

- (void)dealloc {
    
    homeViewController = nil;
    recentsNavigationController = nil;
    recentsViewController = nil;
    contactsViewController = nil;
    settingsViewController = nil;
    
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

- (void)setMxSession:(MXSession *)mxSession {
    // Update home tab
    homeViewController.mxSession = mxSession;
    
    // List all the recents for the logged user
    MXKRecentListDataSource *recentlistDataSource = nil;
    if (mxSession) {
        recentlistDataSource = [[RecentListDataSource alloc] initWithMatrixSession:mxSession];
    }
    [recentsViewController displayList:recentlistDataSource];
    
    // Update contacts tab
    contactsViewController.mxSession = mxSession;
    
    // Update settings tab
    settingsViewController.mxSession = mxSession;
}

- (void)showAuthenticationScreen {
    
    [self restoreInitialDisplay];
    [self performSegueWithIdentifier:@"showAuth" sender:self];
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
        recentsViewController.selectedRoomId = roomId;
    });
}

- (void)popRoomViewControllerAnimated:(BOOL)animated {
    // Force back to recents list if room details is displayed in Recents Tab
    if (recentsViewController) {
        [recentsNavigationController popToViewController:recentsViewController animated:animated];
        // Release the current selected room
        recentsViewController.selectedRoomId = nil;
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
    
    // Presently only the first account is used
    // TODO GFO: handle multi-session
    MXKAccount *account = [[MXKAccountManager sharedManager].accounts firstObject];
    if (account) {
        // Enable inApp notification for this room
        [account updateNotificationListenerForRoomId:aVisibleRoomId ignore:NO];
    }
    
    
    _visibleRoomId = aVisibleRoomId;
}

@end
