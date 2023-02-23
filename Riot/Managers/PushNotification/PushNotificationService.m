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

#import <PushKit/PushKit.h>
#import "GeneratedInterface-Swift.h"

@interface PushNotificationService()<PKPushRegistryDelegate>

/**
Matrix session observer used to detect new opened sessions.
*/
@property (nonatomic, weak) id matrixSessionStateObserver;
@property (nonatomic, nullable, copy) void (^registrationForRemoteNotificationsCompletion)(NSError *);
@property (nonatomic, strong) PKPushRegistry *pushRegistry;
@property (nonatomic, strong) PushNotificationStore *pushNotificationStore;

/// Should PushNotificationService receive VoIP pushes
@property (nonatomic, assign) BOOL shouldReceiveVoIPPushes;

@end

@implementation PushNotificationService

- (instancetype)initWithPushNotificationStore:(PushNotificationStore *)pushNotificationStore
{
    if (self = [super init])
    {
        self.pushNotificationStore = pushNotificationStore;
        _pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
        self.shouldReceiveVoIPPushes = YES;
    }
    return self;
}

#pragma mark - Public Methods

- (void)registerUserNotificationSettings
{
    MXLogDebug(@"[PushNotificationService][Push] registerUserNotificationSettings: isPushRegistered: %@", @(_isPushRegistered));

    if (!_isPushRegistered)
    {
        UNTextInputNotificationAction *quickReply = [UNTextInputNotificationAction
                                                     actionWithIdentifier:@"inline-reply"
                                                     title:[VectorL10n roomMessageShortPlaceholder]
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
    MXLogDebug(@"[PushNotificationService][Push] didRegisterForRemoteNotificationsWithDeviceToken");
    
    MXKAccountManager* accountManager = [MXKAccountManager sharedManager];
    [accountManager setApnsDeviceToken:deviceToken];
    
    //  Resurrect old PushKit token to better kill it
    if (!accountManager.pushDeviceToken)
    {
        //  If we don't have the pushDeviceToken, we may have migrated it into the shared user defaults.
        NSString *pushDeviceToken = [MXKAppSettings.standardAppSettings.sharedUserDefaults objectForKey:@"pushDeviceToken"];
        if (pushDeviceToken)
        {
            MXLogDebug(@"[PushNotificationService][Push] didRegisterForRemoteNotificationsWithDeviceToken: Move PushKit token to user defaults");
            
            // Set the token in standard user defaults, as MXKAccount will read it from there when removing the pusher.
            // This will allow to remove the PushKit pusher in the next step
            [[NSUserDefaults standardUserDefaults] setObject:pushDeviceToken forKey:@"pushDeviceToken"];
            
            [MXKAppSettings.standardAppSettings.sharedUserDefaults removeObjectForKey:@"pushDeviceToken"];
            [MXKAppSettings.standardAppSettings.sharedUserDefaults removeObjectForKey:@"pushOptions"];
        }
    }
    
    //  If we already have pushDeviceToken or recovered it in above step, remove its PushKit pusher
    if (accountManager.pushDeviceToken)
    {
        MXLogDebug(@"[PushNotificationService][Push] didRegisterForRemoteNotificationsWithDeviceToken: A PushKit pusher still exists. Remove it");
        
        //  Attempt to remove PushKit pushers explicitly
        [self clearPushNotificationToken];
    }

    _isPushRegistered = YES;
    
    if (!_pushNotificationStore.pushKitToken)
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
    MXLogDebug(@"[PushNotificationService][Push] didReceiveRemoteNotification: applicationState: %tu - payload: %@", [UIApplication sharedApplication].applicationState, userInfo);

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
    if (_pushNotificationStore.pushKitToken)
    {
        self.shouldReceiveVoIPPushes = YES;
    }
}

- (void)applicationDidEnterBackground
{
    
}

- (void)applicationDidBecomeActive
{
    [[UNUserNotificationCenter currentNotificationCenter] removeUnwantedNotifications];
    [[UNUserNotificationCenter currentNotificationCenter] removeCallNotificationsFor:nil];
    if (_pushNotificationStore.pushKitToken)
    {
        self.shouldReceiveVoIPPushes = NO;
    }
}

- (void)checkPushKitPushersInSession:(MXSession*)session
{
    [session.matrixRestClient pushers:^(NSArray<MXPusher *> *pushers) {
        
        MXLogDebug(@"[PushNotificationService][Push] checkPushKitPushers: %@ has %@ pushers:", session.myUserId, @(pushers.count));
        
        for (MXPusher *pusher in pushers)
        {
            MXLogDebug(@"   - %@", pusher.appId);
            
            // We do not want anymore PushKit pushers the app used to use
            if ([pusher.appId isEqualToString:BuildSettings.pushKitAppIdProd]
                || [pusher.appId isEqualToString:BuildSettings.pushKitAppIdDev])
            {
                [self removePusher:pusher inSession:session];
            }
        }
    } failure:^(NSError *error) {
        MXLogDebug(@"[PushNotificationService][Push] checkPushKitPushers: Error: %@", error);
    }];
}


#pragma mark - Private Methods

- (void)setShouldReceiveVoIPPushes:(BOOL)shouldReceiveVoIPPushes
{
    _shouldReceiveVoIPPushes = shouldReceiveVoIPPushes;
    
    MXLogDebug(@"[PushNotificationService] setShouldReceiveVoIPPushes: %u", _shouldReceiveVoIPPushes)
    
    if (_shouldReceiveVoIPPushes && _pushNotificationStore.pushKitToken)
    {
        MXSession *session = [AppDelegate theDelegate].mxSessions.firstObject;
        if (session.state >= MXSessionStateStoreDataReady)
        {
            [self configurePushKit];
        }
        else
        {
            //  add an observer for session state
            MXWeakify(self);

            NSNotificationCenter * __weak notificationCenter = [NSNotificationCenter defaultCenter];
            self.matrixSessionStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                MXStrongifyAndReturnIfNil(self);
                MXSession *mxSession = (MXSession*)notif.object;
                
                if ([[AppDelegate theDelegate].mxSessions containsObject:mxSession]
                    && mxSession.state >= MXSessionStateStoreDataReady
                    && self->_shouldReceiveVoIPPushes)
                {
                    [self configurePushKit];
                    [notificationCenter removeObserver:self.matrixSessionStateObserver];
                }
            }];
        }
    }
    else
    {
        [self deconfigurePushKit];
    }
}

- (void)configurePushKit
{
    MXLogDebug(@"[PushNotificationService] configurePushKit")
    NSData* token = [_pushRegistry pushTokenForType:PKPushTypeVoIP];
    if (token) {
        // If the token is available, store it. This can happen if you sign out and back in.
        // i.e We are registered, but we have cleared it from the the store on logout and the
        // _pushRegistry lives through signin/signout as PushNotificationService is a singleton
        // on app delegate.
        _pushNotificationStore.pushKitToken = token;
        MXLogDebug(@"[PushNotificationService] configurePushKit: Restored pushKit token")
    }
    
    _pushRegistry.delegate = self;
    _pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)deconfigurePushKit
{
    MXLogDebug(@"[PushNotificationService] deconfigurePushKit")
    
    _pushRegistry.delegate = nil;
}

- (void)removePusher:(MXPusher*)pusher inSession:(MXSession*)session
{
    MXLogDebug(@"[PushNotificationService][Push] removePusher: %@", pusher.appId);
    
    // Shortcut MatrixKit and its complex logic and call directly the API
    [session.matrixRestClient setPusherWithPushkey:pusher.pushkey
                                              kind:[NSNull null]    // This is how we remove a pusher
                                             appId:pusher.appId
                                    appDisplayName:pusher.appDisplayName
                                 deviceDisplayName:pusher.deviceDisplayName
                                        profileTag:pusher.profileTag
                                              lang:pusher.lang
                                              data:pusher.data.JSONDictionary
                                            append:NO
                                           success:^{
        MXLogDebug(@"[PushNotificationService][Push] removePusher: Success");
        
        // Brute clean remaining MatrixKit data
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"pushDeviceToken"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"pushOptions"];
        
    } failure:^(NSError *error) {
        MXLogDebug(@"[PushNotificationService][Push] removePusher: Error: %@", error);
    }];
}


- (void)launchBackgroundSync
{
    // Launch a background sync for all existing matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        MXLogDebug(@"[PushNotificationService] launchBackgroundSync");

        [account backgroundSync:20000 success:^{
            [[UNUserNotificationCenter currentNotificationCenter] removeUnwantedNotifications];
            [[UNUserNotificationCenter currentNotificationCenter] removeCallNotificationsFor:nil];
            MXLogDebug(@"[PushNotificationService] launchBackgroundSync: the background sync succeeds");
        } failure:^(NSError *error) {
            MXLogDebug(@"[PushNotificationService] launchBackgroundSync: the background sync failed. Error: %@ (%@).", error.domain, @(error.code));
        }];
    }
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    NSDictionary *userInfo = notification.request.content.userInfo;
    if (RiotSettings.shared.showInAppNotifications || userInfo[Constants.userInfoKeyPresentNotificationOnForeground])
    {
        if (!userInfo[Constants.userInfoKeyPresentNotificationInRoom]
            && [[AppDelegate theDelegate].visibleRoomId isEqualToString:userInfo[@"room_id"]])
        {
            //  do not show the notification when we're in the notified room
            completionHandler(UNNotificationPresentationOptionNone);
        }
        else
        {
            completionHandler(UNNotificationPresentationOptionBadge
                              | UNNotificationPresentationOptionSound
                              | UNNotificationPresentationOptionBanner
                              | UNNotificationPresentationOptionList);
        }
    }
    else
    {
        completionHandler(UNNotificationPresentationOptionNone);
    }
}

// iOS 10+, see application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler
{
    UNNotification *notification = response.notification;
    UNNotificationContent *content = notification.request.content;
    NSString *actionIdentifier = [response actionIdentifier];
    NSString *roomId = content.userInfo[@"room_id"];
    NSString *threadId = content.userInfo[@"thread_id"];
    NSString *userId = content.userInfo[@"user_id"];

    if ([actionIdentifier isEqualToString:@"inline-reply"])
    {
        if ([response isKindOfClass:[UNTextInputNotificationResponse class]])
        {
            UNTextInputNotificationResponse *textInputNotificationResponse = (UNTextInputNotificationResponse *)response;
            NSString *responseText = [textInputNotificationResponse userText];

            [self handleNotificationInlineReplyForRoomId:roomId
                                                threadId:threadId
                                        withResponseText:responseText
                                                 success:^(NSString *eventId) {
                completionHandler();
            } failure:^(NSError *error) {

                UNMutableNotificationContent *failureNotificationContent = [[UNMutableNotificationContent alloc] init];
                failureNotificationContent.userInfo = content.userInfo;
                failureNotificationContent.body = [VectorL10n roomEventFailedToSend];
                failureNotificationContent.threadIdentifier = roomId;

                NSString *uuid = [[NSUUID UUID] UUIDString];
                UNNotificationRequest *failureNotificationRequest = [UNNotificationRequest requestWithIdentifier:uuid
                                                                                                         content:failureNotificationContent
                                                                                                         trigger:nil];

                [center addNotificationRequest:failureNotificationRequest withCompletionHandler:nil];
                MXLogDebug(@"[PushNotificationService][Push] didReceiveNotificationResponse: error sending text message: %@", error);

                completionHandler();
            }];
        }
        else
        {
            MXLogDebug(@"[PushNotificationService][Push] didReceiveNotificationResponse: error, expect a response of type UNTextInputNotificationResponse");
            completionHandler();
        }
    }
    else if ([actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier])
    {
        [self notifyNavigateToRoomById:roomId threadId:threadId sender:userId];
        completionHandler();
    }
    else
    {
        MXLogDebug(@"[PushNotificationService][Push] didReceiveNotificationResponse: unhandled identifier %@", actionIdentifier);
        completionHandler();
    }
}

#pragma mark - Other Methods

- (void)handleNotificationInlineReplyForRoomId:(NSString*)roomId
                                      threadId:(NSString*)threadId
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

    __block MXSession *mxSession;
    dispatch_group_t dispatchGroupSession = dispatch_group_create();

    for (MXKAccount* account in mxAccounts)
    {
        void(^storeDataReadyBlock)(void) = ^{
            MXRoom *room = [account.mxSession roomWithRoomId:roomId];
            if (room)
            {
                mxSession = account.mxSession;
            }
        };
        
        if (account.mxSession.state >= MXSessionStateStoreDataReady)
        {
            storeDataReadyBlock();
            if (mxSession)
            {
                break;
            }
        }
        else
        {
            dispatch_group_enter(dispatchGroupSession);
            
            //  wait for session state to be store data ready
            id sessionStateObserver = nil;
            sessionStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:account.mxSession queue:nil usingBlock:^(NSNotification * _Nonnull note) {
                if (mxSession)
                {
                    [[NSNotificationCenter defaultCenter] removeObserver:sessionStateObserver];
                    return;
                }
                
                if (account.mxSession.state >= MXSessionStateStoreDataReady)
                {
                    [[NSNotificationCenter defaultCenter] removeObserver:sessionStateObserver];
                    storeDataReadyBlock();
                    dispatch_group_leave(dispatchGroupSession);
                }
            }];
        }
    }
    
    dispatch_group_notify(dispatchGroupSession, dispatch_get_main_queue(), ^{
        if (mxSession == nil)
        {
            MXLogDebug(@"[PushNotificationService][Push] didReceiveNotificationResponse: room with id %@ not found", roomId);
            failure(nil);
        }
        else
        {
            //  initialize data source for a thread or a room
            __block MXKRoomDataSource *dataSource;
            dispatch_group_t dispatchGroupDataSource = dispatch_group_create();
            if (RiotSettings.shared.enableThreads && threadId)
            {
                dispatch_group_enter(dispatchGroupDataSource);
                [ThreadDataSource loadRoomDataSourceWithRoomId:roomId
                                                initialEventId:nil
                                                      threadId:threadId
                                              andMatrixSession:mxSession
                                                    onComplete:^(MXKRoomDataSource *threadDataSource) {
                    dataSource = threadDataSource;
                    dispatch_group_leave(dispatchGroupDataSource);
                }];
            }
            else
            {
                dispatch_group_enter(dispatchGroupDataSource);
                MXKRoomDataSourceManager *manager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:mxSession];
                [manager roomDataSourceForRoom:roomId create:YES onComplete:^(MXKRoomDataSource *roomDataSource) {
                    dataSource = roomDataSource;
                    dispatch_group_leave(dispatchGroupDataSource);
                }];
            }

            dispatch_group_notify(dispatchGroupDataSource, dispatch_get_main_queue(), ^{
                if (responseText != nil && responseText.length != 0)
                {
                    NSString *logForThread = threadId ? [NSString stringWithFormat:@", thread: %@", threadId] : nil;
                    MXLogDebug(@"[PushNotificationService][Push] didReceiveNotificationResponse: sending message to room: %@%@", roomId, logForThread);
                    [dataSource sendTextMessage:responseText success:^(NSString* eventId) {
                        success(eventId);
                    } failure:^(NSError* error) {
                        failure(error);
                    }];
                }
                else
                {
                    failure(nil);
                }
            });
        }
    });
}

- (void)clearPushNotificationToken
{
    MXLogDebug(@"[PushNotificationService][Push] clearPushNotificationToken: Clear existing token");
    
    // Clear existing pushkit token registered on the HS
    MXKAccountManager* accountManager = [MXKAccountManager sharedManager];
    [accountManager setPushDeviceToken:nil withPushOptions:nil];
}

// Remove delivred notifications for a given room id except call notifications
- (void)removeDeliveredNotificationsWithRoomId:(NSString*)roomId completion:(dispatch_block_t)completion
{
    MXLogDebug(@"[PushNotificationService][Push] removeDeliveredNotificationsWithRoomId: Remove potential delivered notifications for room id: %@", roomId);

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

- (void)notifyNavigateToRoomById:(NSString *)roomId threadId:(NSString *)threadId sender:(NSString *)userId
{
    if ([_delegate respondsToSelector:@selector(pushNotificationService:shouldNavigateToRoomWithId:threadId:sender:)])
    {
        [_delegate pushNotificationService:self shouldNavigateToRoomWithId:roomId threadId:threadId sender:userId];
    }
}

#pragma mark - PKPushRegistryDelegate

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)pushCredentials forType:(PKPushType)type
{
    MXLogDebug(@"[PushNotificationService] did update PushKit credentials");
    _pushNotificationStore.pushKitToken = pushCredentials.token;
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
    {
        self.shouldReceiveVoIPPushes = NO;
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void (^)(void))completion
{
    MXLogDebug(@"[PushNotificationService] didReceiveIncomingPushWithPayload: %@", payload.dictionaryPayload);
    
    NSString *roomId = payload.dictionaryPayload[@"room_id"];
    NSString *eventId = payload.dictionaryPayload[@"event_id"];
    
    [[UNUserNotificationCenter currentNotificationCenter] removeUnwantedNotifications];
    [[UNUserNotificationCenter currentNotificationCenter] removeCallNotificationsFor:roomId];
    
    if (@available(iOS 13.0, *))
    {
        //  for iOS 13, we'll just report the incoming call in the same runloop. It means we cannot call an async API here.
        MXEvent *callInvite = [_pushNotificationStore callInviteForEventId:eventId];
        //  remove event
        [_pushNotificationStore removeCallInviteWithEventId:eventId];
        MXSession *session = [AppDelegate theDelegate].mxSessions.firstObject;
        //  when we have a VoIP push while the application is killed, session.callManager will not be ready yet. Configure it.
        [[AppDelegate theDelegate] configureCallManagerIfRequiredForSession:session];
        
        MXLogDebug(@"[PushNotificationService] didReceiveIncomingPushWithPayload: iOS 13+, callInvite: %@", callInvite);
        
        if (callInvite)
        {
            //  We're using this dispatch_group to continue event stream after cache fully processed.
            dispatch_group_t dispatchGroup = dispatch_group_create();
            
            dispatch_group_enter(dispatchGroup);
            session.spaceService.graphUpdateEnabled = NO;
            //  Not continuing in completion block here, because PushKit mandates reporting a new call in the same run loop.
            //  'handleBackgroundSyncCacheIfRequiredWithCompletion' is processing to-device events synchronously.
            [session handleBackgroundSyncCacheIfRequiredWithCompletion:^{
                session.spaceService.graphUpdateEnabled = YES;
                dispatch_group_leave(dispatchGroup);
            }];
            
            if (callInvite.eventType == MXEventTypeCallInvite)
            {
                //  process the call invite synchronously
                [session.callManager handleCallEvent:callInvite];
                MXCallInviteEventContent *content = [MXCallInviteEventContent modelFromJSON:callInvite.content];
                MXCall *call = [session.callManager callWithCallId:content.callId];
                if (call)
                {
                    [session.callManager.callKitAdapter reportIncomingCall:call];
                    MXLogDebug(@"[PushNotificationService] didReceiveIncomingPushWithPayload: Reporting new call in room %@ for the event: %@", roomId, eventId);
                    
                    //  Wait for the sync response in cache to be processed for data integrity.
                    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
                        //  After reporting the call, we can continue async. Launch a background sync to handle call answers/declines on other devices of the user.
                        [self launchBackgroundSync];
                    });
                }
                else
                {
                    MXLogDebug(@"[PushNotificationService] didReceiveIncomingPushWithPayload: Error on call object on room %@ for the event: %@", roomId, eventId);
                }
            }
            else if ([callInvite.type isEqualToString:kWidgetMatrixEventTypeString] ||
                     [callInvite.type isEqualToString:kWidgetModularEventTypeString])
            {
                [[AppDelegate theDelegate].callPresenter processWidgetEvent:callInvite
                                                                  inSession:session];
            }
            else
            {
                //  It's a serious error. There is nothing to avoid iOS to kill us here.
                MXLogDebug(@"[PushNotificationService] didReceiveIncomingPushWithPayload: We have an unknown type of event for %@. There is something wrong.", eventId);
            }
        }
        else
        {
            //  It's a serious error. There is nothing to avoid iOS to kill us here.
            MXLogDebug(@"[PushNotificationService] didReceiveIncomingPushWithPayload: iOS 13+, but we don't have the callInvite event for the eventId: %@.", eventId);
        }
    }
    else
    {
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
        {
            //  below iOS 13, we don't have to report a call immediately.
            //  We can wait for a call invite from event stream and process.
            MXLogDebug(@"[PushNotificationService] didReceiveIncomingPushWithPayload: Below iOS 13 and active app. Do nothing.");
            completion();
            return;
        }
        
        //  below iOS 13, we can call an async API. After background sync, we'll hopefully fetch the call invite and report a new call to the CallKit.
        [self launchBackgroundSync];
    }
    
    completion();
}

@end
