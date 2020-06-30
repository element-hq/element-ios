/*
 Copyright 2014 OpenMarket Ltd
 Copyright 2020 Vector Creations Ltd

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

#import <Foundation/Foundation.h>
#import <PushKit/PushKit.h>
#import <UserNotifications/UserNotifications.h>

@class MXSession;
@protocol PushNotificationServiceDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface PushNotificationService : NSObject <PKPushRegistryDelegate, UNUserNotificationCenterDelegate>

/**
 Is push really registered.
 */
@property (nonatomic, assign, readonly) BOOL isPushRegistered;

/**
 Delegate object.
 */
@property (nonatomic, weak) id<PushNotificationServiceDelegate> delegate;

/**
 Perform registration for user notification settings.
 */
- (void)registerUserNotificationSettings;

/**
 Perform registration for remote notifications.

 @param completion the block to be executed when registration finished.
 */
- (void)registerForRemoteNotificationsWithCompletion:(nullable void (^)(NSError *))completion;

/**
 Perform deregistration for remote notifications.
 */
- (void)deregisterRemoteNotifications;

/**
 Method to be called when the application enters foreground. Flushs all the pending notifications.
 */
- (void)applicationWillEnterForeground;

/**
 Add Matrix session to be handled for incoming pushes.

 @param mxSession Matrix session.
 */
- (void)addMatrixSession:(MXSession *)mxSession;

/**
 Remove Matrix session to incoming push handling.

 @param mxSession Matrix session.
 */
- (void)removeMatrixSession:(MXSession *)mxSession;

/**
 Enable local notifications for the passed Matrix session.

 @param mxSession Matrix session.
 */
- (void)enableLocalNotificationsFromMatrixSession:(MXSession*)mxSession;

/**
 Disable local notifications for the passed Matrix session.

 @param mxSession Matrix session.
 */
- (void)disableLocalNotificationsFromMatrixSession:(MXSession*)mxSession;

/**
 Handle state changes for a Matrix session, when in background. If this method called when the application is not in background, it has no effect.

 @param mxSession Matrix session.
 */
- (void)handleSessionStateChangesInBackgroundFor:(MXSession *)mxSession;

/**
 Remove delivered notifications for a given room id except call notifications

 @param roomId Room identifier
 @param completion Completion to be called when operation finished.
 */
- (void)removeDeliveredNotificationsWithRoomId:(NSString*)roomId completion:(nullable void (^)(void))completion;

@end


@protocol PushNotificationServiceDelegate <NSObject>

@optional

/**
 Will be called when it's a good idea to update application badge number.

 @param pushNotificationService PushNotificationService object.
 */
- (void)pushNotificationServiceShouldRefreshApplicationBadgeNumber:(PushNotificationService *)pushNotificationService;

/**
 Will be called when the user interacts with a notification, which will be led the user to navigate to a specific room.

 @param pushNotificationService PushNotificationService object.
 @param roomId Room identifier to be navigated.
 */
- (void)pushNotificationService:(PushNotificationService *)pushNotificationService
     shouldNavigateToRoomWithId:(NSString *)roomId;

@end;

NS_ASSUME_NONNULL_END
