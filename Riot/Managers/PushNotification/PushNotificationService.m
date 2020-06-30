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

#import "MXRoom+Riot.h"

#import "Riot-Swift.h"

@interface PushNotificationService()
{
    /**
     Cache for payloads received with incoming push notifications.
     The key is the event id. The value, the payload.
     */
    NSMutableDictionary <NSString*, NSDictionary*> *incomingPushPayloads;

    /**
     The list of the events which need to be notified at the end of the background sync.
     There is one list per MXSession.
     The key is an identifier of the MXSession. The value, an array of dictionaries (eventId, roomId... for each event).
     */
    NSMutableDictionary <NSNumber *, NSMutableArray <NSDictionary *> *> *eventsToNotify;

    /**
     The notification listener blocks.
     There is one block per MXSession.
     The key is an identifier of the MXSession. The value, the listener block.
     */
    NSMutableDictionary <NSNumber *, MXOnNotification> *notificationListenerBlocks;
}

@property (nonatomic, strong) PKPushRegistry *pushRegistry;

@property (nonatomic) NSMutableDictionary <NSNumber *, NSMutableArray <NSString *> *> *incomingPushEventIds;

@property (nonatomic, nullable, copy) void (^registrationForRemoteNotificationsCompletion)(NSError *);

@end

@implementation PushNotificationService

- (instancetype)init
{
    self = [super init];
    if (self) {
        eventsToNotify = [NSMutableDictionary dictionary];
        incomingPushPayloads = [NSMutableDictionary dictionary];
        notificationListenerBlocks = [NSMutableDictionary dictionary];
        _incomingPushEventIds = [NSMutableDictionary dictionary];
    }
    return self;
}

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
    self.pushRegistry = [[PKPushRegistry alloc] initWithQueue:nil];
    self.pushRegistry.delegate = self;
    self.pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];

    self.registrationForRemoteNotificationsCompletion = completion;
}

- (void)deregisterRemoteNotifications
{
    self.pushRegistry = nil;
    _isPushRegistered = NO;
}

- (void)applicationWillEnterForeground
{
    // Flush all the pending push notifications.
    for (NSMutableArray *array in self.incomingPushEventIds.allValues)
    {
        [array removeAllObjects];
    }
    [incomingPushPayloads removeAllObjects];
}

- (void)addMatrixSession:(MXSession *)mxSession
{
    // Add an array to handle incoming push
    self.incomingPushEventIds[@(mxSession.hash)] = [NSMutableArray array];
}

- (void)removeMatrixSession:(MXSession *)mxSession
{
    [self.incomingPushEventIds removeObjectForKey:@(mxSession.hash)];
}

- (void)enableLocalNotificationsFromMatrixSession:(MXSession*)mxSession
{
    // Prepare listener block.
    MXWeakify(self);
    MXOnNotification notificationListenerBlock = ^(MXEvent *event, MXRoomState *roomState, MXPushRule *rule) {
        MXStrongifyAndReturnIfNil(self);

        // Ignore this event if the app is not running in background.
        if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground)
        {
            return;
        }

        // If the app is doing an initial sync, ignore all events from which we
        // did not receive a notification from APNS/PushKit
        if (!mxSession.isEventStreamInitialised && !self->incomingPushPayloads[event.eventId])
        {
            NSLog(@"[PushNotificationService][Push] enableLocalNotificationsFromMatrixSession: Initial sync in progress. Ignore event %@", event.eventId);
            return;
        }

        // Sanity check
        if (event.eventId && event.roomId && rule)
        {
            NSLog(@"[PushNotificationService][Push] enableLocalNotificationsFromMatrixSession: got event %@ to notify", event.eventId);

            // Check whether this event corresponds to a pending push for this session.
            NSUInteger index = [self.incomingPushEventIds[@(mxSession.hash)] indexOfObject:event.eventId];
            if (index != NSNotFound)
            {
                // Remove it from the pending list.
                [self.incomingPushEventIds[@(mxSession.hash)] removeObjectAtIndex:index];
            }

            // Add it to the list of the events to notify.
            [self->eventsToNotify[@(mxSession.hash)] addObject:@{
                                                                 @"event_id": event.eventId,
                                                                 @"room_id": event.roomId,
                                                                 @"push_rule": rule
                                                                 }];
        }
        else
        {
            NSLog(@"[PushNotificationService][Push] enableLocalNotificationsFromMatrixSession: WARNING: wrong event to notify %@ %@ %@", event, event.roomId, rule);
        }
    };

    eventsToNotify[@(mxSession.hash)] = [NSMutableArray array];
    [mxSession.notificationCenter listenToNotifications:notificationListenerBlock];
    notificationListenerBlocks[@(mxSession.hash)] = notificationListenerBlock;
}

- (void)disableLocalNotificationsFromMatrixSession:(MXSession*)mxSession
{
    // Stop listening to notification of this session
    [mxSession.notificationCenter removeListener:notificationListenerBlocks[@(mxSession.hash)]];
    [notificationListenerBlocks removeObjectForKey:@(mxSession.hash)];
    [eventsToNotify removeObjectForKey:@(mxSession.hash)];
}

- (void)handleSessionStateChangesInBackgroundFor:(MXSession *)mxSession
{
    // Ignore this change if the app is not running in background.
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground)
    {
        return;
    }

    NSLog(@"[PushNotificationService][Push] MXSession state changed while in background. mxSession.state: %tu - incomingPushEventIds: %@", mxSession.state, self.incomingPushEventIds[@(mxSession.hash)]);

    if (mxSession.state == MXSessionStateRunning)
    {
        // Pause the session in background task
        NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
        for (MXKAccount *account in mxAccounts)
        {
            if (account.mxSession == mxSession)
            {
                [account pauseInBackgroundTask];

                // Trigger local notifcations (Indeed the app finishs here an initial sync in background, the user has missed some notifcations)
                [self handleLocalNotificationsForAccount:account];

                // Update app icon badge number
                [self notifyRefreshApplicationIconBadgeNumber];

                break;
            }
        }
    }
    else if (mxSession.state == MXSessionStatePaused)
    {
        // Check whether some push notifications are pending for this session.
        if (self.incomingPushEventIds[@(mxSession.hash)].count)
        {
            NSLog(@"[PushNotificationService][Push] relaunch a background sync for %tu kMXSessionStateDidChangeNotification pending incoming pushes", self.incomingPushEventIds[@(mxSession.hash)].count);
            [self launchBackgroundSync];
        }
    }
    else if (mxSession.state == MXSessionStateInitialSyncFailed)
    {
        // Display failure sync notifications for pending events if any
        if (self.incomingPushEventIds[@(mxSession.hash)].count)
        {
            NSLog(@"[PushNotificationService][Push] initial sync failed with %tu pending incoming pushes", self.incomingPushEventIds[@(mxSession.hash)].count);

            // Trigger limited local notifications when the sync with HS fails
            [self handleLimitedLocalNotifications:mxSession events:self.incomingPushEventIds[@(mxSession.hash)]];

            // Update app icon badge number
            [self notifyRefreshApplicationIconBadgeNumber];
        }
    }
}

#pragma mark - PKPushRegistryDelegate

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(PKPushType)type
{
    NSData *token = credentials.token;

    NSLog(@"[PushNotificationService][Push] didUpdatePushCredentials: Got Push token: %@. Type: %@", [MXKTools logForPushToken:token], type);

    MXKAccountManager* accountManager = [MXKAccountManager sharedManager];
    [accountManager setPushDeviceToken:token withPushOptions:@{@"format": @"event_id_only"}];

    _isPushRegistered = YES;

    if (self.registrationForRemoteNotificationsCompletion)
    {
        self.registrationForRemoteNotificationsCompletion(nil);
        self.registrationForRemoteNotificationsCompletion = nil;
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(PKPushType)type
{
    NSLog(@"[PushNotificationService][Push] didInvalidatePushTokenForType: Type: %@", type);

    [self clearPushNotificationToken];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type
{
    NSLog(@"[PushNotificationService][Push] didReceiveIncomingPushWithPayload: applicationState: %tu - type: %@ - payload: %@", [UIApplication sharedApplication].applicationState, payload.type, payload.dictionaryPayload);

    // Display local notifications only when the app is running in background.
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        NSLog(@"[PushNotificationService][Push] didReceiveIncomingPushWithPayload while app is in background");

        // Check whether an event id is provided.
        NSString *eventId = payload.dictionaryPayload[@"event_id"];
        if (eventId)
        {
            // Add this event identifier in the pending push array for each session.
            for (NSMutableArray *array in self.incomingPushEventIds.allValues)
            {
                [array addObject:eventId];
            }

            // Cache payload for further usage
            incomingPushPayloads[eventId] = payload.dictionaryPayload;
        }
        else
        {
            NSLog(@"[PushNotificationService][Push] didReceiveIncomingPushWithPayload - Unexpected payload %@", payload.dictionaryPayload);
        }

        // Trigger a background sync to handle notifications.
        [self launchBackgroundSync];
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

// iOS 10+, this is called when a notification is about to display in foreground.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
    NSLog(@"[PushNotificationService][Push] willPresentNotification: applicationState: %@", @([UIApplication sharedApplication].applicationState));

    completionHandler(UNNotificationPresentationOptionNone);
}

#pragma mark - Other Methods

- (void)launchBackgroundSync
{
    // Launch a background sync for all existing matrix sessions
    NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
    for (MXKAccount *account in mxAccounts)
    {
        // Check the current session state
        if (account.mxSession.state == MXSessionStatePaused)
        {
            NSLog(@"[PushNotificationService][Push] launchBackgroundSync");
            __weak typeof(self) weakSelf = self;

            NSMutableArray<NSString *> *incomingPushEventIds = self.incomingPushEventIds[@(account.mxSession.hash)];
            NSMutableArray<NSString *> *incomingPushEventIdsCopy = [incomingPushEventIds copy];

            // Flush all the pending push notifications for this session.
            [incomingPushEventIds removeAllObjects];

            [account backgroundSync:20000 success:^{

                // Sanity check
                if (!weakSelf)
                {
                    return;
                }
                typeof(self) self = weakSelf;

                NSLog(@"[PushNotificationService][Push] launchBackgroundSync: the background sync succeeds");

                // Trigger local notifcations
                [self handleLocalNotificationsForAccount:account];

                // Update app icon badge number
                [self notifyRefreshApplicationIconBadgeNumber];

            } failure:^(NSError *error) {

                NSLog(@"[PushNotificationService][Push] launchBackgroundSync: the background sync failed. Error: %@ (%@). incomingPushEventIdsCopy: %@ - self.incomingPushEventIds: %@", error.domain, @(error.code), incomingPushEventIdsCopy, incomingPushEventIds);

                // Trigger limited local notifications when the sync with HS fails
                [self handleLimitedLocalNotifications:account.mxSession events:incomingPushEventIdsCopy];

                // Update app icon badge number
                [self notifyRefreshApplicationIconBadgeNumber];

            }];
        }
    }
}

- (void)handleLocalNotificationsForAccount:(MXKAccount*)account
{
    NSString *userId = account.mxCredentials.userId;

    NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForAccount: %@", userId);
    NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForAccount: eventsToNotify: %@", eventsToNotify[@(account.mxSession.hash)]);
    NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForAccount: incomingPushEventIds: %@", self.incomingPushEventIds[@(account.mxSession.hash)]);

    __block NSUInteger scheduledNotifications = 0;

    // The call invite are handled here only when the callkit is not active.
    BOOL isCallKitActive = [MXCallKitAdapter callKitAvailable] && [MXKAppSettings standardAppSettings].isCallKitEnabled;

    NSMutableArray *eventsArray = eventsToNotify[@(account.mxSession.hash)];

    NSMutableArray<NSString*> *redactedEventIds = [NSMutableArray array];

    // Display a local notification for each event retrieved by the bg sync.
    for (NSUInteger index = 0; index < eventsArray.count; index++)
    {
        NSDictionary *eventDict = eventsArray[index];
        NSString *eventId = eventDict[@"event_id"];
        NSString *roomId = eventDict[@"room_id"];
        BOOL checkReadEvent = YES;
        MXEvent *event;

        if (eventId && roomId)
        {
            event = [account.mxSession.store eventWithEventId:eventId inRoom:roomId];
        }

        if (event)
        {
            if (event.isRedactedEvent)
            {
                // Collect redacted event ids to remove possible delivered redacted notifications
                [redactedEventIds addObject:eventId];
                continue;
            }

            // Consider here the call invites
            if (event.eventType == MXEventTypeCallInvite)
            {
                // Ignore call invite when callkit is active.
                if (isCallKitActive)
                {
                    NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForAccount: Skip call event. Event id: %@", eventId);
                    continue;
                }
                else
                {
                    // Retrieve the current call state from the call manager
                    MXCallInviteEventContent *callInviteEventContent = [MXCallInviteEventContent modelFromJSON:event.content];
                    MXCall *call = [account.mxSession.callManager callWithCallId:callInviteEventContent.callId];

                    if (call.state <= MXCallStateRinging)
                    {
                        // Keep display a local notification even if the event has been read on another device.
                        checkReadEvent = NO;
                    }
                }
            }

            if (checkReadEvent)
            {
                // Ignore event which has been read on another device.
                MXReceiptData *readReceipt = [account.mxSession.store getReceiptInRoom:roomId forUserId:userId];
                if (readReceipt)
                {
                    MXEvent *readReceiptEvent = [account.mxSession.store eventWithEventId:readReceipt.eventId inRoom:roomId];
                    if (event.originServerTs <= readReceiptEvent.originServerTs)
                    {
                        NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForAccount: Skip already read event. Event id: %@", eventId);
                        continue;
                    }
                }
            }

            // Prepare the local notification
            MXPushRule *rule = eventDict[@"push_rule"];

            [self notificationContentForEvent:event pushRule:rule inAccount:account onComplete:^(UNNotificationContent * _Nullable notificationContent) {

                if (notificationContent)
                {
                    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:eventId
                                                                                          content:notificationContent
                                                                                          trigger:nil];

                    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {

                        if (error)
                        {
                            NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForAccount: Fail to display notification for event %@ with error: %@", eventId, error);
                        }
                        else
                        {
                            NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForAccount: Display notification for event %@", eventId);
                        }
                    }];

                    scheduledNotifications++;
                }
                else
                {
                    NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForAccount: Skip event with empty generated content. Event id: %@", eventId);
                }
            }];
        }
    }

    // Remove possible pending and delivered notifications having a redacted event id
    if (redactedEventIds.count)
    {
        NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForAccount: Remove possible notification with redacted event ids: %@", redactedEventIds);

        [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:redactedEventIds];
        [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:redactedEventIds];
    }

    NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForAccount: Sent %tu local notifications for %tu events", scheduledNotifications, eventsArray.count);

    [eventsArray removeAllObjects];
}

- (NSString*)notificationSoundNameFromPushRule:(MXPushRule*)pushRule
{
    NSString *soundName;

    // Set sound name based on the value provided in action of MXPushRule
    for (MXPushRuleAction *action in pushRule.actions)
    {
        if (action.actionType == MXPushRuleActionTypeSetTweak)
        {
            if ([action.parameters[@"set_tweak"] isEqualToString:@"sound"])
            {
                soundName = action.parameters[@"value"];
                if ([soundName isEqualToString:@"default"])
                {
                    soundName = @"message.caf";
                }
            }
        }
    }

    return soundName;
}

- (NSString*)notificationCategoryIdentifierForEvent:(MXEvent*)event
{
    BOOL isNotificationContentShown = !event.isEncrypted || RiotSettings.shared.showDecryptedContentInNotifications;

    NSString *categoryIdentifier;

    if ((event.eventType == MXEventTypeRoomMessage || event.eventType == MXEventTypeRoomEncrypted) && isNotificationContentShown)
    {
        categoryIdentifier = @"QUICK_REPLY";
    }

    return categoryIdentifier;
}

- (NSDictionary*)notificationUserInfoForEvent:(MXEvent*)event andUserId:(NSString*)userId
{
    NSDictionary *notificationUserInfo = @{
                                           @"type": @"full",
                                           @"room_id": event.roomId,
                                           @"event_id": event.eventId,
                                           @"user_id": userId
                                           };
    return notificationUserInfo;
}

// iOS 10+, does the same thing as notificationBodyForEvent:pushRule:inAccount:onComplete:, except with more features
- (void)notificationContentForEvent:(MXEvent *)event pushRule:(MXPushRule *)rule inAccount:(MXKAccount *)account onComplete:(void (^)(UNNotificationContent * _Nullable notificationContent))onComplete;
{
    if (!event.content || !event.content.count)
    {
        NSLog(@"[PushNotificationService][Push] notificationContentForEvent: empty event content");
        onComplete (nil);
        return;
    }

    MXRoom *room = [account.mxSession roomWithRoomId:event.roomId];
    if (!room)
    {
        NSLog(@"[PushNotificationService][Push] notificationBodyForEvent: Unknown room");
        onComplete (nil);
        return;
    }

    [room state:^(MXRoomState *roomState) {

        NSString *notificationTitle;
        NSString *notificationBody;

        NSString *threadIdentifier = room.roomId;
        NSString *eventSenderName = [roomState.members memberName:event.sender];
        NSString *currentUserId = account.mxCredentials.userId;

        if (event.eventType == MXEventTypeRoomMessage || event.eventType == MXEventTypeRoomEncrypted)
        {
            if (room.isMentionsOnly)
            {
                // A local notification will be displayed only for highlighted notification.
                BOOL isHighlighted = NO;

                // Check whether is there an highlight tweak on it
                for (MXPushRuleAction *ruleAction in rule.actions)
                {
                    if (ruleAction.actionType == MXPushRuleActionTypeSetTweak)
                    {
                        if ([ruleAction.parameters[@"set_tweak"] isEqualToString:@"highlight"])
                        {
                            // Check the highlight tweak "value"
                            // If not present, highlight. Else check its value before highlighting
                            if (nil == ruleAction.parameters[@"value"] || YES == [ruleAction.parameters[@"value"] boolValue])
                            {
                                isHighlighted = YES;
                                break;
                            }
                        }
                    }
                }

                if (!isHighlighted)
                {
                    // Ignore this notif.
                    NSLog(@"[PushNotificationService][Push] notificationBodyForEvent: Ignore non highlighted notif in mentions only room");
                    onComplete(nil);
                    return;
                }
            }

            NSString *msgType = event.content[@"msgtype"];
            NSString *messageContent = event.content[@"body"];

            if (event.isEncrypted && !RiotSettings.shared.showDecryptedContentInNotifications)
            {
                // Hide the content
                msgType = nil;
            }

            NSString *roomDisplayName = room.summary.displayname;

            NSString *myUserId = account.mxSession.myUser.userId;
            BOOL isIncomingEvent = ![event.sender isEqualToString:myUserId];

            // Display the room name only if it is different than the sender name
            if (roomDisplayName.length && ![roomDisplayName isEqualToString:eventSenderName])
            {
                notificationTitle = [NSString localizedUserNotificationStringForKey:@"MSG_FROM_USER_IN_ROOM_TITLE" arguments:@[eventSenderName, roomDisplayName]];

                if ([msgType isEqualToString:@"m.text"])
                {
                    notificationBody = messageContent;
                }
                else if ([msgType isEqualToString:@"m.emote"])
                {
                    notificationBody = [NSString localizedUserNotificationStringForKey:@"ACTION_FROM_USER" arguments:@[eventSenderName, messageContent]];
                }
                else if ([msgType isEqualToString:@"m.image"])
                {
                    notificationBody = [NSString localizedUserNotificationStringForKey:@"IMAGE_FROM_USER" arguments:@[eventSenderName, messageContent]];
                }
                else if (room.isDirect && isIncomingEvent && [msgType isEqualToString:kMXMessageTypeKeyVerificationRequest])
                {
                    [account.mxSession.crypto.keyVerificationManager keyVerificationFromKeyVerificationEvent:event
                                                                                                     success:^(MXKeyVerification * _Nonnull keyVerification)
                     {
                         if (keyVerification && keyVerification.state == MXKeyVerificationRequestStatePending)
                         {
                             // TODO: Add accept and decline actions to notification
                             NSString *body = [NSString localizedUserNotificationStringForKey:@"KEY_VERIFICATION_REQUEST_FROM_USER" arguments:@[eventSenderName]];

                             UNNotificationContent *notificationContent = [self notificationContentWithTitle:notificationTitle
                                                                                                        body:body
                                                                                            threadIdentifier:threadIdentifier
                                                                                                      userId:currentUserId
                                                                                                       event:event
                                                                                                    pushRule:rule];

                             onComplete(notificationContent);
                         }

                     } failure:^(NSError * _Nonnull error) {
                         NSLog(@"[PushNotificationService][Push] notificationContentForEvent: failed to fetch key verification with error: %@", error);
                     }];
                }
                else
                {
                    // Encrypted messages falls here
                    notificationBody = [NSString localizedUserNotificationStringForKey:@"MSG_FROM_USER" arguments:@[eventSenderName]];
                }
            }
            else
            {
                notificationTitle = eventSenderName;

                if ([msgType isEqualToString:@"m.text"])
                {
                    notificationBody = messageContent;
                }
                else if ([msgType isEqualToString:@"m.emote"])
                {
                    notificationBody = [NSString localizedUserNotificationStringForKey:@"ACTION_FROM_USER" arguments:@[eventSenderName, messageContent]];
                }
                else if ([msgType isEqualToString:@"m.image"])
                {
                    notificationBody = [NSString localizedUserNotificationStringForKey:@"IMAGE_FROM_USER" arguments:@[eventSenderName, messageContent]];
                }
                else
                {
                    // Encrypted messages falls here
                    notificationBody = [NSString localizedUserNotificationStringForKey:@"MSG_FROM_USER" arguments:@[eventSenderName]];
                }
            }
        }
        else if (event.eventType == MXEventTypeCallInvite)
        {
            NSString *sdp = event.content[@"offer"][@"sdp"];
            BOOL isVideoCall = [sdp rangeOfString:@"m=video"].location != NSNotFound;

            if (!isVideoCall)
            {
                notificationBody = [NSString localizedUserNotificationStringForKey:@"VOICE_CALL_FROM_USER" arguments:@[eventSenderName]];
            }
            else
            {
                notificationBody = [NSString localizedUserNotificationStringForKey:@"VIDEO_CALL_FROM_USER" arguments:@[eventSenderName]];
            }

            // call notifications should stand out from normal messages, so we don't stack them
            threadIdentifier = nil;
        }
        else if (event.eventType == MXEventTypeRoomMember)
        {
            NSString *roomDisplayName = room.summary.displayname;

            if (roomDisplayName.length && ![roomDisplayName isEqualToString:eventSenderName])
            {
                notificationBody = [NSString localizedUserNotificationStringForKey:@"USER_INVITE_TO_NAMED_ROOM" arguments:@[eventSenderName, roomDisplayName]];
            }
            else
            {
                notificationBody = [NSString localizedUserNotificationStringForKey:@"USER_INVITE_TO_CHAT" arguments:@[eventSenderName]];
            }
        }
        else if (event.eventType == MXEventTypeSticker)
        {
            NSString *roomDisplayName = room.summary.displayname;

            if (roomDisplayName.length && ![roomDisplayName isEqualToString:eventSenderName])
            {
                notificationTitle = [NSString localizedUserNotificationStringForKey:@"MSG_FROM_USER_IN_ROOM_TITLE" arguments:@[eventSenderName, roomDisplayName]];
            }
            else
            {
                notificationTitle = eventSenderName;
            }

            notificationBody = [NSString localizedUserNotificationStringForKey:@"STICKER_FROM_USER" arguments:@[eventSenderName]];
        }

        if (notificationBody)
        {
            UNNotificationContent *notificationContent = [self notificationContentWithTitle:notificationTitle
                                                                                       body:notificationBody
                                                                           threadIdentifier:threadIdentifier
                                                                                     userId:currentUserId
                                                                                      event:event
                                                                                   pushRule:rule];

            onComplete(notificationContent);
        }
    }];
}

- (UNNotificationContent*)notificationContentWithTitle:(NSString*)title
                                                  body:(NSString*)body
                                      threadIdentifier:(NSString*)threadIdentifier
                                                userId:(NSString*)userId
                                                 event:(MXEvent*)event
                                              pushRule:(MXPushRule*)pushRule
{
    UNMutableNotificationContent *notificationContent = [[UNMutableNotificationContent alloc] init];

    NSDictionary *notificationUserInfo = [self notificationUserInfoForEvent:event andUserId:userId];
    NSString *notificationSoundName = [self notificationSoundNameFromPushRule:pushRule];
    NSString *categoryIdentifier = [self notificationCategoryIdentifierForEvent:event];

    notificationContent.title = title;
    notificationContent.body = body;
    notificationContent.threadIdentifier = threadIdentifier;
    notificationContent.userInfo = notificationUserInfo;
    notificationContent.categoryIdentifier = categoryIdentifier;

    if (notificationSoundName)
    {
        notificationContent.sound = [UNNotificationSound soundNamed:notificationSoundName];
    }

    return [notificationContent copy];
}

/**
 Display "limited" notifications for events the app was not able to get data
 (because of /sync failure).

 In this situation, we are only able to display "You received a message in %@".

 @param mxSession the matrix session where the /sync failed.
 @param events the list of events id we did not get data.
 */
- (void)handleLimitedLocalNotifications:(MXSession*)mxSession events:(NSArray<NSString *> *)events
{
    NSString *userId = mxSession.matrixRestClient.credentials.userId;

    NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForFailedSync: %@", userId);
    NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForFailedSync: eventsToNotify: %@", eventsToNotify[@(mxSession.hash)]);
    NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForFailedSync: incomingPushEventIds: %@", self.incomingPushEventIds[@(mxSession.hash)]);
    NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForFailedSync: events: %@", events);

    if (!events.count)
    {
        return;
    }

    for (NSString *eventId in events)
    {
        // Build notification user info
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                        @"type": @"limited",
                                                                                        @"event_id": eventId,
                                                                                        @"user_id": userId
                                                                                        }];

        // Add the room_id so that user will open the room when tapping on the notif
        NSDictionary *payload = incomingPushPayloads[eventId];
        NSString *roomId = payload[@"room_id"];
        if (roomId)
        {
            userInfo[@"room_id"] = roomId;
        }
        else
        {
            NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForFailedSync: room_id is missing for event %@ in payload %@", eventId, payload);
        }

        UNMutableNotificationContent *localNotificationContentForFailedSync = [[UNMutableNotificationContent alloc] init];
        localNotificationContentForFailedSync.userInfo = userInfo;
        localNotificationContentForFailedSync.body = [self limitedNotificationBodyForEvent:eventId inMatrixSession:mxSession];
        localNotificationContentForFailedSync.threadIdentifier = roomId;

        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:eventId content:localNotificationContentForFailedSync trigger:nil];

        NSLog(@"[PushNotificationService][Push] handleLocalNotificationsForFailedSync: Display notification for event %@", eventId);
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
    }
}

/**
 Build the body for the "limited" notification to display to the user.

 @param eventId the id of the event the app failed to get data.
 @param mxSession the matrix session where the /sync failed.
 @return the string to display in the local notification.
 */
- (nullable NSString *)limitedNotificationBodyForEvent:(NSString *)eventId inMatrixSession:(MXSession*)mxSession
{
    NSString *notificationBody;

    NSString *roomDisplayName;

    NSDictionary *payload = incomingPushPayloads[eventId];
    NSString *roomId = payload[@"room_id"];
    if (roomId)
    {
        MXRoomSummary *roomSummary = [mxSession roomSummaryWithRoomId:roomId];
        if (roomSummary)
        {
            roomDisplayName = roomSummary.displayname;
        }
    }

    if (roomDisplayName.length)
    {
        notificationBody = [NSString stringWithFormat:NSLocalizedString(@"SINGLE_UNREAD_IN_ROOM", nil), roomDisplayName];
    }
    else
    {
        notificationBody = NSLocalizedString(@"SINGLE_UNREAD", nil);
    }

    return notificationBody;
}

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

    MXKRoomDataSourceManager* manager;

    for (MXKAccount* account in mxAccounts)
    {
        MXRoom* room = [account.mxSession roomWithRoomId:roomId];
        if (room)
        {
            manager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:account.mxSession];
            if (manager)
            {
                break;
            }
        }
    }

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

- (void)notifyRefreshApplicationIconBadgeNumber
{
    if ([_delegate respondsToSelector:@selector(pushNotificationServiceShouldRefreshApplicationBadgeNumber:)])
    {
        [_delegate pushNotificationServiceShouldRefreshApplicationBadgeNumber:self];
    }
}

- (void)notifyNavigateToRoomById:(NSString *)roomId
{
    if ([_delegate respondsToSelector:@selector(pushNotificationService:shouldNavigateToRoomWithId:)])
    {
        [_delegate pushNotificationService:self shouldNavigateToRoomWithId:roomId];
    }
}

@end
