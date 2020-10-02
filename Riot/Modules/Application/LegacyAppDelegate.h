/*
 Copyright 2014 OpenMarket Ltd
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

#import <UIKit/UIKit.h>
#import <MatrixKit/MatrixKit.h>

#import "MasterTabBarController.h"
#import "JitsiViewController.h"

#import "RageShakeManager.h"
#import "Analytics.h"

#import "ThemeService.h"
#import "UniversalLink.h"

@protocol Configurable;
@protocol LegacyAppDelegateDelegate;

#pragma mark - Notifications
/**
 Posted when the user taps the clock status bar.
 */
extern NSString *const kAppDelegateDidTapStatusBarNotification;

/**
 Posted when the property 'isOffline' has changed. This property is related to the network reachability status.
 */
extern NSString *const kAppDelegateNetworkStatusDidChangeNotification;

extern NSString *const AppDelegateDidValidateEmailNotification;
extern NSString *const AppDelegateDidValidateEmailNotificationSIDKey;
extern NSString *const AppDelegateDidValidateEmailNotificationClientSecretKey;

/**
 Posted when the property 'lastHandledUniversalLink' has changed. Notification object and userInfo will be nil.
 */
extern NSString *const AppDelegateUniversalLinkDidChangeNotification;

@interface LegacyAppDelegate : UIResponder <UIApplicationDelegate, MXKCallViewControllerDelegate, UISplitViewControllerDelegate, UINavigationControllerDelegate, JitsiViewControllerDelegate>
{
    // background sync management
    void (^_completionHandler)(UIBackgroundFetchResult);
}

@property (weak, nonatomic) id<LegacyAppDelegateDelegate> delegate;

/**
 Application main view controller
 */
@property (nonatomic, readonly) MasterTabBarController *masterTabBarController;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UIAlertController *errorNotification;

@property (strong, nonatomic) NSString *appVersion;
@property (strong, nonatomic) NSString *build;

@property (nonatomic) BOOL isAppForeground;
@property (nonatomic) BOOL isOffline;

/**
 Last navigated room's identifier from a push notification.
 */
// TODO: This property is introduced to fix #3672. Remove it when a better solution revealed to the problem.
@property (nonatomic, copy) NSString *lastNavigatedRoomIdFromPush;


/**
 Let the AppDelegate handle and display self verification requests.
 Default is YES.
 */
@property (nonatomic) BOOL handleSelfVerificationRequest;

/**
 The navigation controller of the master view controller of the main split view controller.
 */
@property (nonatomic, readonly) UINavigationController *masterNavigationController;
/**
 The navigation controller of the detail view controller of the main split view controller (may be nil).
 */
@property (nonatomic, readonly) UINavigationController *secondaryNavigationController;

// Associated matrix sessions (empty by default).
@property (nonatomic, readonly) NSArray *mxSessions;

// Current selected room id. nil if no room is presently visible.
@property (strong, nonatomic) NSString *visibleRoomId;

/**
 Last handled universal link (url will be formatted for several hash keys).
 */
@property (nonatomic, readonly) UniversalLink *lastHandledUniversalLink;

// New message sound id.
@property (nonatomic, readonly) SystemSoundID messageSound;

// Build Settings
@property (nonatomic, readonly) id<Configurable> configuration;

+ (instancetype)theDelegate;

#pragma mark - Push Notifications

/**
 Perform registration for remote notifications.

 @param completion the block to be executed when registration finished.
 */
- (void)registerForRemoteNotificationsWithCompletion:(void (^)(NSError *))completion;

#pragma mark - Application layout handling

- (void)restoreInitialDisplay:(void (^)(void))completion;

/**
 Replace the secondary view controller of the split view controller (if any) with the default empty details view controller.
 */
- (void)restoreEmptyDetailsViewController;

- (UIAlertController*)showErrorAsAlert:(NSError*)error;
- (UIAlertController*)showAlertWithTitle:(NSString*)title message:(NSString*)message;

#pragma mark - Matrix Sessions handling

// Add a matrix session.
- (void)addMatrixSession:(MXSession*)mxSession;

// Remove a matrix session.
- (void)removeMatrixSession:(MXSession*)mxSession;

// Mark all messages as read in the running matrix sessions.
- (void)markAllMessagesAsRead;

// Reload all running matrix sessions
- (void)reloadMatrixSessions:(BOOL)clearCache;

/**
 Log out all the accounts after asking for a potential confirmation.
 Show the authentication screen on successful logout.

 @param askConfirmation tell whether a confirmation is required before logging out.
 @param completion the block to execute at the end of the operation.
 */
- (void)logoutWithConfirmation:(BOOL)askConfirmation completion:(void (^)(BOOL isLoggedOut))completion;

/**
 Log out all the accounts without confirmation.
 Show the authentication screen on successful logout.

 @param sendLogoutRequest Indicate whether send logout request to homeserver.
 @param completion the block to execute at the end of the operation.
 */
- (void)logoutSendingRequestServer:(BOOL)sendLogoutServerRequest
                        completion:(void (^)(BOOL isLoggedOut))completion;

/**
 Present incoming key verification request to accept.

 @param incomingKeyVerificationRequest The incoming key verification request.
 @param The matrix session.
 @return Indicate NO if the key verification screen could not be presented.
 */
- (BOOL)presentIncomingKeyVerificationRequest:(MXKeyVerificationRequest*)incomingKeyVerificationRequest
                                    inSession:(MXSession*)session;

- (BOOL)presentUserVerificationForRoomMember:(MXRoomMember*)roomMember session:(MXSession*)mxSession;

- (BOOL)presentCompleteSecurityForSession:(MXSession*)mxSession;

- (void)configureCallManagerIfRequiredForSession:(MXSession *)mxSession;

- (void)authenticationDidComplete;

#pragma mark - Matrix Accounts handling

- (void)selectMatrixAccount:(void (^)(MXKAccount *selectedAccount))onSelection;

#pragma mark - Matrix Room handling

// Show a room and jump to the given event if event id is not nil otherwise go to last messages.
- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession restoreInitialDisplay:(BOOL)restoreInitialDisplay completion:(void (^)(void))completion;

- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession restoreInitialDisplay:(BOOL)restoreInitialDisplay;

- (void)showRoom:(NSString*)roomId andEventId:(NSString*)eventId withMatrixSession:(MXSession*)mxSession;

// Creates a new direct chat with the provided user id
- (void)createDirectChatWithUserId:(NSString*)userId completion:(void (^)(void))completion;

// Reopen an existing direct room with this userId or creates a new one (if it doesn't exist)
- (void)startDirectChatWithUserId:(NSString*)userId completion:(void (^)(void))completion;

/**
 Process the fragment part of a vector.im link.

 @param fragment the fragment part of the universal link.
 @return YES in case of processing success.
 */
- (BOOL)handleUniversalLinkFragment:(NSString*)fragment;

#pragma mark - Jitsi call

/**
 Open the Jitsi view controller from a widget.

 @param jitsiWidget the jitsi widget.
 @param video to indicate voice or video call.
 */
- (void)displayJitsiViewControllerWithWidget:(Widget*)jitsiWidget andVideo:(BOOL)video;

/**
 The current Jitsi view controller being displayed.
 */
@property (nonatomic, readonly) JitsiViewController *jitsiViewController;

#pragma mark - Call status handling

/**
 Call status window displayed when user goes back to app during a call.
 */
@property (nonatomic, readonly) UIWindow* callStatusBarWindow;
@property (nonatomic, readonly) UIButton* callStatusBarButton;

#pragma mark - App version management

/**
 Check for app version related informations to display
*/
- (void)checkAppVersion;

@end

@protocol LegacyAppDelegateDelegate <NSObject>

- (void)legacyAppDelegate:(LegacyAppDelegate*)legacyAppDelegate wantsToPopToHomeViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void)legacyAppDelegateRestoreEmptyDetailsViewController:(LegacyAppDelegate*)legacyAppDelegate;

@end
