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

#import <PushKit/PushKit.h>

@interface PushNotificationService()<PKPushRegistryDelegate>
{
    /**
     Matrix session observer used to detect new opened sessions.
     */
    id matrixSessionStateObserver;
}

@property (nonatomic, nullable, copy) void (^registrationForRemoteNotificationsCompletion)(NSError *);
@property (nonatomic, strong) PKPushRegistry *pushRegistry;
@property (nonatomic, strong) PushNotificationManager *pushNotificationManager;

/// Should PushNotificationService receive VoIP pushes
@property (nonatomic, assign) BOOL shouldReceiveVoIPPushes;

@end

@implementation PushNotificationService

- (instancetype)initWithPushNotificationManager:(PushNotificationManager *)pushNotificationManager
{
    if (self = [super init])
    {
        self.pushNotificationManager = pushNotificationManager;
        _pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
        self.shouldReceiveVoIPPushes = YES;
    }
    return self;
}

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
    
    if (!_pushNotificationManager.pushKitToken)
    {
        [self configurePushKit];
    }

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
    self.shouldReceiveVoIPPushes = NO;
}

- (void)applicationWillResignActive
{
    [[UNUserNotificationCenter currentNotificationCenter] removeUnwantedNotifications];
    [[UNUserNotificationCenter currentNotificationCenter] removeCallNotificationsFor:nil];
}

- (void)applicationDidEnterBackground
{
    if (_pushNotificationManager.pushKitToken)
    {
        self.shouldReceiveVoIPPushes = YES;
    }
}

- (void)applicationDidBecomeActive
{
    [[UNUserNotificationCenter currentNotificationCenter] removeUnwantedNotifications];
    [[UNUserNotificationCenter currentNotificationCenter] removeCallNotificationsFor:nil];
    if (_pushNotificationManager.pushKitToken)
    {
        self.shouldReceiveVoIPPushes = NO;
    }
}

#pragma mark - Private Methods

- (void)setShouldReceiveVoIPPushes:(BOOL)shouldReceiveVoIPPushes
{
    _shouldReceiveVoIPPushes = shouldReceiveVoIPPushes;
    
    if (_shouldReceiveVoIPPushes && _pushNotificationManager.pushKitToken)
    {
        MXSession *session = [AppDelegate theDelegate].mxSessions.firstObject;
        if (session.state >= MXSessionStateStoreDataReady)
        {
            [self configurePushKit];
        }
        else
        {
            //  add an observer for session state
            matrixSessionStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                MXSession *mxSession = (MXSession*)notif.object;
                
                if ([[AppDelegate theDelegate].mxSessions containsObject:mxSession]
                    && mxSession.state >= MXSessionStateStoreDataReady
                    && self->_shouldReceiveVoIPPushes)
                {
                    [self configurePushKit];
                    [[NSNotificationCenter defaultCenter] removeObserver:self->matrixSessionStateObserver];
                    self->matrixSessionStateObserver = nil;
                }
            }];
        }
    }
    else
    {
        _pushRegistry.delegate = nil;
    }
}

- (void)configurePushKit
{
    _pushRegistry.delegate = self;
    _pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)launchBackgroundSync
{
    // Launch a background sync for all existing matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        // Check the current session state
        if (account.mxSession.state == MXSessionStatePaused)
        {
            NSLog(@"[PushNotificationService] launchBackgroundSync");
            __weak typeof(self) weakSelf = self;

            [account backgroundSync:20000 success:^{
                
                // Sanity check
                if (!weakSelf)
                {
                    return;
                }
                
                [[UNUserNotificationCenter currentNotificationCenter] removeUnwantedNotifications];
                [[UNUserNotificationCenter currentNotificationCenter] removeCallNotificationsFor:nil];
                NSLog(@"[PushNotificationService] launchBackgroundSync: the background sync succeeds");
            } failure:^(NSError *error) {
                
                NSLog(@"[PushNotificationService] launchBackgroundSync: the background sync failed. Error: %@ (%@).", error.domain, @(error.code));
            }];
        }
    }
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

#pragma mark - PKPushRegistryDelegate

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)pushCredentials forType:(PKPushType)type
{
    NSLog(@"[PushNotificationService] did update PushKit credentials");
    _pushNotificationManager.pushKitToken = pushCredentials.token;
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
    {
        self.shouldReceiveVoIPPushes = NO;
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void (^)(void))completion
{
    NSLog(@"[PushNotificationService] did receive PushKit push with payload: %@", payload.dictionaryPayload);
    
    NSString *roomId = payload.dictionaryPayload[@"room_id"];
    NSString *eventId = payload.dictionaryPayload[@"event_id"];
    
    [[UNUserNotificationCenter currentNotificationCenter] removeUnwantedNotifications];
    [[UNUserNotificationCenter currentNotificationCenter] removeCallNotificationsFor:roomId];
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        NSLog(@"[PushNotificationService] application is in bg");
        
        if (@available(iOS 13.0, *))
        {
            //  for iOS 13, we'll just report the incoming call in the same runloop. It means we cannot call an async API here.
            MXEvent *lastCallInvite = _pushNotificationManager.lastCallInvite;
            //  remove event
            _pushNotificationManager.lastCallInvite = nil;
            MXSession *session = [AppDelegate theDelegate].mxSessions.firstObject;
            //  when we have a VoIP push while the application is killed, session.callManager will not be ready yet. Configure it.
            [[AppDelegate theDelegate] configureCallManagerIfRequiredForSession:session];
            
            if (lastCallInvite.isEncrypted)
            {
                [session decryptEvent:lastCallInvite inTimeline:nil];
            }
            
            NSLog(@"[PushNotificationService] lastCallInvite: %@", lastCallInvite);
            
            if ([lastCallInvite.eventId isEqualToString:eventId])
            {
                SEL handleCallInvite = NSSelectorFromString(@"handleCallInvite:");
                if ([session.callManager respondsToSelector:handleCallInvite])
                {
                    [session.callManager performSelector:handleCallInvite withObject:lastCallInvite];
                }
                MXCall *call = [session.callManager callWithCallId:lastCallInvite.content[@"call_id"]];
                if (call)
                {
                    [session.callManager.callKitAdapter reportIncomingCall:call];
                    NSLog(@"[PushNotificationService] Reporting new call in room %@ for the event: %@", roomId, eventId);
                }
                else
                {
                    NSLog(@"[PushNotificationService] Error on call object on room %@ for the event: %@", roomId, eventId);
                }
            }
            else
            {
                //  It's a serious error. There is nothing to avoid iOS to kill us here.
                NSLog(@"[PushNotificationService] iOS 13 and in bg, but we don't have the last callInvite event for the event %@. There is something wrong.", eventId);
            }
        }
        else
        {
            //  below iOS 13, we can call an async API. After background sync, we'll hopefully fetch the call invite and report a new call to the CallKit.
            [self launchBackgroundSync];
        }
    }
    else
    {
        NSLog(@"[PushNotificationService] application is not in bg. There is something wrong.");
    }
    
    completion();
}

@end
