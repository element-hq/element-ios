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

#import "PushNotificationService.h"

#import <MatrixKit/MatrixKit.h>

#import "Riot-Swift.h"

@interface PushNotificationService()

@property (nonatomic, nullable, copy) void (^registrationForRemoteNotificationsCompletion)(NSError *);

@end

@implementation PushNotificationService

#pragma mark - Public Methods

- (void)registerUserNotificationSettings
{
    NSLog(@"[PushNotificationService][Push] registerUserNotificationSettings: isPushRegistered: %@", @(_isPushRegistered));

    if (!_isPushRegistered)
    {
        UNTextInputNotificationAction *quickReply = [UNTextInputNotificationAction
                                                     actionWithIdentifier:@"inline-reply"
                                                     title:NSLocalizedStringFromTable(@"room_message_short_placeholder", @"Vector", nil)
                                                     options:UNNotificationActionOptionAuthenticationRequired
                                                     ];

        UNNotificationCategory *quickReplyCategory = [UNNotificationCategory
                                                      categoryWithIdentifier:@"QUICK_REPLY"
                                                      actions:@[quickReply]
                                                      intentIdentifiers:@[]
                                                      options:UNNotificationCategoryOptionNone];

        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center setNotificationCategories:[[NSSet alloc] initWithArray:@[quickReplyCategory]]];
        [center setDelegate:self];

        UNAuthorizationOptions authorizationOptions = (UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge);

        [center requestAuthorizationWithOptions:authorizationOptions
                              completionHandler:^(BOOL granted, NSError *error)
         { // code here is equivalent to self:application:didRegisterUserNotificationSettings:
             if (granted)
             {
                 [self registerForRemoteNotificationsWithCompletion:nil];
             }
             else
             {
                 // Clear existing token
                 [self clearPushNotificationToken];
             }
         }];
    }
}

- (void)registerForRemoteNotificationsWithCompletion:(nullable void (^)(NSError *))completion
{
    self.registrationForRemoteNotificationsCompletion = completion;

    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    });
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    MXKAccountManager* accountManager = [MXKAccountManager sharedManager];
    [accountManager setApnsDeviceToken:deviceToken];
    //  remove PushKit pusher if exists
    if (accountManager.pushDeviceToken)
    {
        [accountManager setPushDeviceToken:nil withPushOptions:nil];
    }
    // Sanity check: Make sure the Pushkit push token is deleted
    NSParameterAssert(!accountManager.isPushAvailable);
    NSParameterAssert(!accountManager.pushDeviceToken);

    _isPushRegistered = YES;

    if (self.registrationForRemoteNotificationsCompletion)
    {
        self.registrationForRemoteNotificationsCompletion(nil);
        self.registrationForRemoteNotificationsCompletion = nil;
    }
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [self clearPushNotificationToken];

    if (self.registrationForRemoteNotificationsCompletion)
    {
        self.registrationForRemoteNotificationsCompletion(error);
        self.registrationForRemoteNotificationsCompletion = nil;
    }
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo
              fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"[PushNotificationService][Push] didReceiveRemoteNotification: applicationState: %tu - payload: %@", [UIApplication sharedApplication].applicationState, userInfo);

    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)deregisterRemoteNotifications
{
    _isPushRegistered = NO;
}

- (void)applicationWillEnterForeground
{
    [[UNUserNotificationCenter currentNotificationCenter] removeUnwantedNotifications];
}

#pragma mark - UNUserNotificationCenterDelegate

// iOS 10+, see application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler
{
    UNNotification *notification = response.notification;
    UNNotificationContent *content = notification.request.content;
    NSString *actionIdentifier = [response actionIdentifier];
    NSString *roomId = content.userInfo[@"room_id"];

    if ([actionIdentifier isEqualToString:@"inline-reply"])
    {
        if ([response isKindOfClass:[UNTextInputNotificationResponse class]])
        {
            UNTextInputNotificationResponse *textInputNotificationResponse = (UNTextInputNotificationResponse *)response;
            NSString *responseText = [textInputNotificationResponse userText];

            [self handleNotificationInlineReplyForRoomId:roomId withResponseText:responseText success:^(NSString *eventId) {
                completionHandler();
            } failure:^(NSError *error) {

                UNMutableNotificationContent *failureNotificationContent = [[UNMutableNotificationContent alloc] init];
                failureNotificationContent.userInfo = content.userInfo;
                failureNotificationContent.body = NSLocalizedStringFromTable(@"room_event_failed_to_send", @"Vector", nil);
                failureNotificationContent.threadIdentifier = roomId;

                NSString *uuid = [[NSUUID UUID] UUIDString];
                UNNotificationRequest *failureNotificationRequest = [UNNotificationRequest requestWithIdentifier:uuid
                                                                                                         content:failureNotificationContent
                                                                                                         trigger:nil];

                [center addNotificationRequest:failureNotificationRequest withCompletionHandler:nil];
                NSLog(@"[PushNotificationService][Push] didReceiveNotificationResponse: error sending text message: %@", error);

                completionHandler();
            }];
        }
        else
        {
            NSLog(@"[PushNotificationService][Push] didReceiveNotificationResponse: error, expect a response of type UNTextInputNotificationResponse");
            completionHandler();
        }
    }
    else if ([actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier])
    {
        [self notifyNavigateToRoomById:roomId];
        completionHandler();
    }
    else
    {
        NSLog(@"[PushNotificationService][Push] didReceiveNotificationResponse: unhandled identifier %@", actionIdentifier);
        completionHandler();
    }
}

#pragma mark - Other Methods

- (void)handleNotificationInlineReplyForRoomId:(NSString*)roomId
                              withResponseText:(NSString*)responseText
                                       success:(void(^)(NSString *eventId))success
                                       failure:(void(^)(NSError *error))failure
{
    if (!roomId.length)
    {
        failure(nil);
        return;
    }

    NSArray* mxAccounts = [MXKAccountManager sharedManager].activeAccounts;

    __block MXKRoomDataSourceManager* manager;
    dispatch_group_t group = dispatch_group_create();

    for (MXKAccount* account in mxAccounts)
    {
        void(^storeDataReadyBlock)(void) = ^{
            MXRoom* room = [account.mxSession roomWithRoomId:roomId];
            if (room)
            {
                manager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:account.mxSession];
            }
        };
        
        if (account.mxSession.state >= MXSessionStateStoreDataReady)
        {
            storeDataReadyBlock();
            if (manager)
            {
                break;
            }
        }
        else
        {
            dispatch_group_enter(group);
            
            //  wait for session state to be store data ready
            id sessionStateObserver = nil;
            sessionStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:account.mxSession queue:nil usingBlock:^(NSNotification * _Nonnull note) {
                if (manager)
                {
                    [[NSNotificationCenter defaultCenter] removeObserver:sessionStateObserver];
                    return;
                }
                
                if (account.mxSession.state >= MXSessionStateStoreDataReady)
                {
                    [[NSNotificationCenter defaultCenter] removeObserver:sessionStateObserver];
                    storeDataReadyBlock();
                    dispatch_group_leave(group);
                }
            }];
        }
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (manager == nil)
        {
            NSLog(@"[PushNotificationService][Push] didReceiveNotificationResponse: room with id %@ not found", roomId);
            failure(nil);
        }
        else
        {
            [manager roomDataSourceForRoom:roomId create:YES onComplete:^(MXKRoomDataSource *roomDataSource) {
                if (responseText != nil && responseText.length != 0)
                {
                    NSLog(@"[PushNotificationService][Push] didReceiveNotificationResponse: sending message to room: %@", roomId);
                    [roomDataSource sendTextMessage:responseText success:^(NSString* eventId) {
                        success(eventId);
                    } failure:^(NSError* error) {
                        failure(error);
                    }];
                }
                else
                {
                    failure(nil);
                }
            }];
        }
    });
}

- (void)clearPushNotificationToken
{
    NSLog(@"[PushNotificationService][Push] clearPushNotificationToken: Clear existing token");

    // XXX: The following code has been commented to avoid automatic deactivation of push notifications
    // There may be a race condition here where the clear happens after the update of the new push token.
    // We have no evidence of this. This is a safety measure.

    // Clear existing token
    //MXKAccountManager* accountManager = [MXKAccountManager sharedManager];
    //[accountManager setPushDeviceToken:nil withPushOptions:nil];
}

// Remove delivred notifications for a given room id except call notifications
- (void)removeDeliveredNotificationsWithRoomId:(NSString*)roomId completion:(dispatch_block_t)completion
{
    NSLog(@"[PushNotificationService][Push] removeDeliveredNotificationsWithRoomId: Remove potential delivered notifications for room id: %@", roomId);

    NSMutableArray<NSString*> *notificationRequestIdentifiersToRemove = [NSMutableArray new];

    UNUserNotificationCenter *notificationCenter = [UNUserNotificationCenter currentNotificationCenter];

    [notificationCenter getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> * _Nonnull notifications) {

        for (UNNotification *notification in notifications)
        {
            NSString *threadIdentifier = notification.request.content.threadIdentifier;

            if ([threadIdentifier isEqualToString:roomId])
            {
                [notificationRequestIdentifiersToRemove addObject:notification.request.identifier];
            }
        }

        [notificationCenter removeDeliveredNotificationsWithIdentifiers:notificationRequestIdentifiersToRemove];

        if (completion)
        {
            completion();
        }
    }];
}

#pragma mark - Delegate Notifiers

- (void)notifyNavigateToRoomById:(NSString *)roomId
{
    if ([_delegate respondsToSelector:@selector(pushNotificationService:shouldNavigateToRoomWithId:)])
    {
        [_delegate pushNotificationService:self shouldNavigateToRoomWithId:roomId];
    }
}

@end
