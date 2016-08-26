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

#import <UIKit/UIKit.h>
#import <MatrixKit/MatrixKit.h>

// Google Analytics
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

#import "HomeViewController.h"

#pragma mark - Notifications
/**
 Posted when the user taps the clock status bar.
 */
extern NSString *const kAppDelegateDidTapStatusBarNotification;

/**
 Posted when the property 'isOffline' has changed. This property is related to the network reachability status.
 */
extern NSString *const kAppDelegateNetworkStatusDidChangeNotification;

@interface AppDelegate : UIResponder <UIApplicationDelegate, MXKCallViewControllerDelegate, UISplitViewControllerDelegate, UINavigationControllerDelegate>
{
    BOOL isAPNSRegistered;
    
    // background sync management
    void (^_completionHandler)(UIBackgroundFetchResult);
}

/**
 Application main view controller
 */
@property (nonatomic, readonly) HomeViewController *homeViewController;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) MXKAlert *errorNotification;

@property (strong, nonatomic) NSString *appVersion;
@property (strong, nonatomic) NSString *build;

@property (nonatomic) BOOL isAppForeground;
@property (nonatomic) BOOL isOffline;

@property (nonatomic, readonly) UINavigationController *homeNavigationController;
@property (nonatomic, readonly) UINavigationController *secondaryNavigationController;

// Associated matrix sessions (empty by default).
@property (nonatomic, readonly) NSArray *mxSessions;

// Current selected room id. nil if no room is presently visible.
@property (strong, nonatomic) NSString *visibleRoomId;

+ (AppDelegate*)theDelegate;

#pragma mark - Application layout handling

- (void)restoreInitialDisplay:(void (^)())completion;

- (MXKAlert*)showErrorAsAlert:(NSError*)error;

#pragma mark - Matrix Sessions handling

// Add a matrix session.
- (void)addMatrixSession:(MXSession*)mxSession;

// Remove a matrix session.
- (void)removeMatrixSession:(MXSession*)mxSession;

// Mark all messages as read in the running matrix sessions.
- (void)markAllMessagesAsRead;

// Reload all running matrix sessions
- (void)reloadMatrixSessions:(BOOL)clearCache;

- (void)logout;

#pragma mark - Matrix Accounts handling

- (void)selectMatrixAccount:(void (^)(MXKAccount *selectedAccount))onSelection;

#pragma mark - Crash reports handling

- (void)startGoogleAnalytics;
- (void)stopGoogleAnalytics;

#pragma mark - APNS methods

- (void)registerUserNotificationSettings;

#pragma mark - Matrix Room handling

- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession;

// Reopen an existing private OneToOne room with this userId or creates a new one (if it doesn't exist)
- (void)startPrivateOneToOneRoomWithUserId:(NSString*)userId completion:(void (^)(void))completion;

/**
 Process the fragment part of a vector.im link.
 
 @param fragment the fragment part of the universal link.
 @return YES in case of processing success.
 */
- (BOOL)handleUniversalLinkFragment:(NSString*)fragment;

#pragma mark - Call status handling

- (void)returnToCallView;

@end

