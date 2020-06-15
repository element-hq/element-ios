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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@class MXSession;
@class MXEvent;
@class MXPushRule;
@class MXKAccount;
@protocol PushNotificationServiceDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface PushNotificationService : NSObject <UNUserNotificationCenterDelegate>

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

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
              fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

/**
 Perform deregistration for remote notifications.
 */
- (void)deregisterRemoteNotifications;

/**
 Method to be called when the application enters foreground. Flushs all the pending notifications.
 */
- (void)applicationWillEnterForeground;

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
 Will be called when the user interacts with a notification, which will be led the user to navigate to a specific room.

 @param pushNotificationService PushNotificationService object.
 @param roomId Room identifier to be navigated.
 @param eventId Event identifier to be navigated around.
 */
- (void)pushNotificationService:(PushNotificationService *)pushNotificationService
     shouldNavigateToRoomWithId:(NSString *)roomId;

@end;

NS_ASSUME_NONNULL_END
