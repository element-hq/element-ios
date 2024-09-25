/*
Copyright 2019-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "WidgetManager.h"

#import "GeneratedInterface-Swift.h"
#import "JitsiWidgetData.h"
#import "MXSession+Riot.h"

#pragma mark - Contants

NSString *const kWidgetManagerDidUpdateWidgetNotification = @"kWidgetManagerDidUpdateWidgetNotification";

NSString *const WidgetManagerErrorDomain = @"WidgetManagerErrorDomain";

@interface WidgetManager ()
{
    // MXSession kind of hash -> Listener for matrix events for widgets.
    // There is one per matrix session
    NSMutableDictionary<NSString*, id> *widgetEventListener;

    // Success blocks of widgets being created
    // MXSession kind of hash -> (Widget id -> `createWidget:` success block).
    NSMutableDictionary<NSString*,
        NSMutableDictionary<NSString*, void (^)(Widget *widget)>*> *successBlockForWidgetCreation;

    // Failure blocks of widgets being created
    // MXSession kind of hash -> (Widget id -> `createWidget:` failure block).
    NSMutableDictionary<NSString*,
        NSMutableDictionary<NSString*, void (^)(NSError *error)>*> *failureBlockForWidgetCreation;

    // User id -> scalar token
    NSMutableDictionary<NSString*, WidgetManagerConfig*> *configs;

    // User id -> MXSession
    NSMutableDictionary<NSString*, MXSession*> *matrixSessions;
}

@end

@implementation WidgetManager

+ (instancetype)sharedManager
{
    static WidgetManager *sharedManager = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedManager = [[WidgetManager alloc] init];
    });

    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        matrixSessions = [NSMutableDictionary dictionary];
        widgetEventListener = [NSMutableDictionary dictionary];
        successBlockForWidgetCreation = [NSMutableDictionary dictionary];
        failureBlockForWidgetCreation = [NSMutableDictionary dictionary];

        [self loadConfigs];
    }
    return self;
}

- (NSArray<Widget *> *)widgetsInRoom:(MXRoom*)room withRoomState:(MXRoomState*)roomState
{
    return [self widgetsOfTypes:nil inRoom:room withRoomState:roomState];
}

- (NSArray<Widget*> *)widgetsOfTypes:(NSArray<NSString*>*)widgetTypes inRoom:(MXRoom*)room withRoomState:(MXRoomState*)roomState
{
    return [self widgetsOfTypes:widgetTypes butNotTypesOf:nil inRoom:room withRoomState:roomState];
}

- (NSArray<Widget*> *)widgetsNotOfTypes:(NSArray<NSString*>*)notWidgetTypes inRoom:(MXRoom*)room withRoomState:(MXRoomState*)roomState;
{
    return [self widgetsOfTypes:nil butNotTypesOf:notWidgetTypes inRoom:room withRoomState:roomState];
}

- (NSArray<Widget*> *)widgetsOfTypes:(NSArray<NSString*>*)widgetTypes butNotTypesOf:(NSArray<NSString*>*)notWidgetTypes inRoom:(MXRoom*)room withRoomState:(MXRoomState*)roomState;
{
    // Widget id -> widget
    NSMutableDictionary <NSString*, Widget *> *widgets = [NSMutableDictionary dictionary];

    // Get all widgets state events in the room
    NSMutableArray<MXEvent*> *widgetEvents = [NSMutableArray arrayWithArray:[roomState stateEventsWithType:kWidgetMatrixEventTypeString]];
    [widgetEvents addObjectsFromArray:[roomState stateEventsWithType:kWidgetModularEventTypeString]];

    // There can be several widgets state events for a same widget but
    // only the last one must be considered.

    // Order widgetEvents with the last event first
    [widgetEvents sortUsingComparator:^NSComparisonResult(MXEvent *event1, MXEvent *event2) {

         NSComparisonResult result = NSOrderedAscending;
         if (event2.originServerTs > event1.originServerTs)
         {
             result = NSOrderedDescending;
         }
         else if (event2.originServerTs == event1.originServerTs)
         {
             result = NSOrderedSame;
         }

         return result;
     }];

    // Create each widget from its lastest widgets state event
    for (MXEvent *widgetEvent in widgetEvents)
    {
        // Filter widget types if required
        if (widgetTypes || notWidgetTypes)
        {
            NSString *widgetType;
            MXJSONModelSetString(widgetType, widgetEvent.content[@"type"]);

            if (widgetType)
            {
                if (widgetTypes && NSNotFound == [widgetTypes indexOfObject:widgetType])
                {
                    continue;
                }
                if (notWidgetTypes && NSNotFound != [notWidgetTypes indexOfObject:widgetType])
                {
                     continue;
                }
            }
        }

        // widgetEvent.stateKey = widget id
        if (!widgets[widgetEvent.stateKey])
        {
            Widget *widget = [[Widget alloc] initWithWidgetEvent:widgetEvent inMatrixSession:room.mxSession];
            if (widget)
            {
                widgets[widget.widgetId] = widget;
            }
        }
    }

    // Return active widgets only
    NSMutableArray<Widget *> *activeWidgets = [NSMutableArray array];
    for (Widget *widget in widgets.allValues)
    {
        if (widget.isActive)
        {
            [activeWidgets addObject:widget];
        }
    }

    return activeWidgets;
}

- (NSArray<Widget*> *)userWidgets:(MXSession*)mxSession
{
    return [self userWidgets:mxSession ofTypes:nil];
}

- (NSArray<Widget*> *)userWidgets:(MXSession*)mxSession ofTypes:(NSArray<NSString*>*)widgetTypes
{
    // Get all widgets in the user account data
    NSMutableArray<Widget *> *userWidgets = [NSMutableArray array];
    for (NSDictionary *widgetEventContent in [mxSession.accountData accountDataForEventType:kMXAccountDataTypeUserWidgets].allValues)
    {
        if (![widgetEventContent isKindOfClass:NSDictionary.class])
        {
            MXLogDebug(@"[WidgetManager] userWidgets: ERROR: invalid user widget format: %@", widgetEventContent);
            continue;
        }

        // Patch: Modular used a malformed key: "stateKey" instead of "state_key"
        // TODO: To remove once fixed server side
        NSDictionary *widgetEventContentFixed = widgetEventContent;
        if (!widgetEventContent[@"state_key"] && widgetEventContent[@"stateKey"])
        {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:widgetEventContent];
            dict[@"state_key"] = widgetEventContent[@"stateKey"];
            widgetEventContentFixed = dict;
        }

        MXEvent *widgetEvent = [MXEvent modelFromJSON:widgetEventContentFixed];
        if (widgetEvent
            && (!widgetTypes || [widgetTypes containsObject:widgetEvent.content[@"type"]]))
        {
            Widget *widget = [[Widget alloc] initWithWidgetEvent:widgetEvent inMatrixSession:mxSession];
            if (widget)
            {
                [userWidgets addObject:widget];
            }
        }
    }

    return userWidgets;
}

- (MXHTTPOperation *)createWidget:(NSString*)widgetId
                      withContent:(NSDictionary<NSString*, NSObject*>*)widgetContent
                           inRoom:(MXRoom*)room
                          success:(void (^)(Widget *widget))success
                          failure:(void (^)(NSError *error))failure
{
    // Create an empty operation that will be mutated later
    MXHTTPOperation *operation = [[MXHTTPOperation alloc] init];

    MXWeakify(self);
    [self checkWidgetPermissionInRoom:room success:^{
        MXStrongifyAndReturnIfNil(self);

        NSString *hash = [NSString stringWithFormat:@"%p", room.mxSession];
        self->successBlockForWidgetCreation[hash][widgetId] = success;
        self->failureBlockForWidgetCreation[hash][widgetId] = failure;

        // Send a state event with the widget data
        // TODO: This API will be shortly replaced by a pure modular API
        // TODO: Move to kWidgetMatrixEventTypeString ("m.widget") type but when?
        MXHTTPOperation *operation2 = [room sendStateEventOfType:kWidgetModularEventTypeString
                                                         content:widgetContent
                                                        stateKey:widgetId
                                                         success:nil failure:failure];
        
        [operation mutateTo:operation2];

    } failure:^(NSError *error) {
        if (failure)
        {
            failure(error);
        }
    }];

    return operation;
}

- (MXHTTPOperation *)createJitsiWidgetInRoom:(MXRoom*)room
                                   withVideo:(BOOL)video
                                     success:(void (^)(Widget *jitsiWidget))success
                                     failure:(void (^)(NSError *error))failure
{
    MXHTTPOperation *operation = [MXHTTPOperation new];
    
    NSString *userId = room.mxSession.myUser.userId;
    WidgetManagerConfig *config = [self configForUser:userId];
    if (!config.hasUrls)
    {
        MXLogDebug(@"[WidgetManager] createJitsiWidgetInRoom: Error: no integration manager API URL for user %@", userId);
        failure(self.errorForNonConfiguredIntegrationManager);
        return nil;
    }

    RiotSharedSettings *sharedSettings = [[RiotSharedSettings alloc] initWithSession:room.mxSession];
    if (!sharedSettings.hasIntegrationProvisioningEnabled)
    {
        MXLogDebug(@"[WidgetManager] createJitsiWidgetInRoom: Error: Disabled integration manager for user %@", userId);
        failure(self.errorForDisabledIntegrationManager);
        return nil;
    }
    
    // Build data for a jitsi widget
    // Riot-Web still uses V1 type
    NSString *widgetId = [NSString stringWithFormat:@"%@_%@_%@", kWidgetTypeJitsiV1, room.mxSession.myUser.userId, @((uint64_t)([[NSDate date] timeIntervalSince1970] * 1000))];
    
    NSURL *preferredJitsiServerUrl = [room.mxSession vc_homeserverConfiguration].jitsi.serverURL;
    
    if (!preferredJitsiServerUrl)
    {
        MXLogDebug(@"[WidgetManager] createJitsiWidgetInRoom: Error: No Jitsi server URL provided");
        failure(self.errorForUnavailableJitsiURL);
        return nil;
    }

    JitsiService *jitsiService = JitsiService.shared;
    
    operation = [jitsiService createJitsiWidgetContentWithJitsiServerURL:preferredJitsiServerUrl roomID:room.roomId isAudioOnly:!video success:^(NSDictionary * _Nonnull widgetContent) {
        
        MXHTTPOperation *operation2 = [self createWidget:widgetId
                                             withContent:widgetContent
                                                  inRoom:room
                                                 success:success
                                                 failure:failure];
        
        [operation mutateTo:operation2];
        
    } failure:^(NSError * _Nonnull error) {
        if (failure)
        {
            failure(error);
        }
    }];
    
    return operation;
}

- (MXHTTPOperation *)closeWidget:(NSString *)widgetId inRoom:(MXRoom *)room success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    // Create an empty operation that will be mutated later
    MXHTTPOperation *operation = [[MXHTTPOperation alloc] init];

    [self checkWidgetPermissionInRoom:room success:^{
        
        // Send a state event with an empty content to disable the widget
        // TODO: This API will be shortly replaced by a pure modular API
        // TODO: Move to kWidgetMatrixEventTypeString ("m.widget") type but when?
        MXHTTPOperation *operation2 = [room sendStateEventOfType:kWidgetModularEventTypeString
                                  content:@{}
                                 stateKey:widgetId
                                  success:^(NSString *eventId)
                {
                    if (success)
                    {
                        success();
                    }
                } failure:failure];
        
        [operation mutateTo:operation2];

    } failure:^(NSError *error) {
        if (failure)
        {
            failure(error);
        }
    }];

    return operation;
}

/**
 Check user's power for widgets management in a room.
 
 @param room the room to check.
 */
- (void)checkWidgetPermissionInRoom:(MXRoom *)room success:(dispatch_block_t)success  failure:(void (^)(NSError *))failure
{
    [room state:^(MXRoomState *roomState) {

        NSError *error;

        // Check user's power in the room
        MXRoomPowerLevels *powerLevels = roomState.powerLevels;
        NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:room.mxSession.myUser.userId];

        // The user must be able to send state events to manage widgets
        if (oneSelfPowerLevel < powerLevels.stateDefault)
        {
            error = [NSError errorWithDomain:WidgetManagerErrorDomain
                                        code:WidgetManagerErrorCodeNotEnoughPower
                                    userInfo:@{
                                               NSLocalizedDescriptionKey: [VectorL10n widgetNoPowerToManage]
                                               }];
        }

        if (error)
        {
            failure(error);
        }
        else
        {
            success();
        }
    }];
}

- (void)addMatrixSession:(MXSession *)mxSession
{
     __weak __typeof__(self) weakSelf = self;

    matrixSessions[mxSession.matrixRestClient.credentials.userId] = mxSession;

    NSString *hash = [NSString stringWithFormat:@"%p", mxSession];

    id listener = [mxSession listenToEventsOfTypes:@[kWidgetMatrixEventTypeString, kWidgetModularEventTypeString] onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {

        typeof(self) self = weakSelf;

        if (self && direction == MXTimelineDirectionForwards)
        {
            // stateKey = widgetId
            NSString *widgetId = event.stateKey;
            if (!widgetId)
            {
                MXLogDebug(@"[WidgetManager] Error: New widget detected with no id in %@: %@", event.roomId, event.JSONDictionary);
                return;
            }

            MXLogDebug(@"[WidgetManager] New widget detected: %@ in %@", widgetId, event.roomId);

            Widget *widget = [[Widget alloc] initWithWidgetEvent:event inMatrixSession:mxSession];
            if (widget)
            {
                // If it is a widget we have just created, indicate its creation is complete
                if (self->successBlockForWidgetCreation[hash][widgetId])
                {
                    self->successBlockForWidgetCreation[hash][widgetId](widget);
                }

                // Broadcast the generic notification
                [[NSNotificationCenter defaultCenter] postNotificationName:kWidgetManagerDidUpdateWidgetNotification object:widget];
                // End jitsi call if a active call exists and widget has been updated to not be active
                if ([[AppDelegate theDelegate].callPresenter.jitsiVC.widget.widgetId isEqualToString: widget.widgetId] &&
                     [[AppDelegate theDelegate].callPresenter.jitsiVC.widget.roomId isEqualToString: event.roomId] &&
                     !widget.isActive)
                {
                    [[AppDelegate theDelegate].callPresenter endActiveJitsiCall];
                }
            }
            else
            {
                MXLogDebug(@"[WidgetManager] Cannot decode new widget - event: %@", event);

                if (self->failureBlockForWidgetCreation[hash][widgetId])
                {
                    // If it is a widget we have just created, indicate its creation has failed somehow
                    NSError *error = [NSError errorWithDomain:WidgetManagerErrorDomain
                                                         code:WidgetManagerErrorCodeCreationFailed
                                                     userInfo:@{
                                                                NSLocalizedDescriptionKey: [VectorL10n widgetCreationFailure]
                                                                }];

                    self->failureBlockForWidgetCreation[hash][widgetId](error);
                }
            }

            [self->successBlockForWidgetCreation[hash] removeObjectForKey:widgetId];
            [self->failureBlockForWidgetCreation[hash] removeObjectForKey:widgetId];
        }
    }];

    widgetEventListener[hash] = listener;
    successBlockForWidgetCreation[hash] = [NSMutableDictionary dictionary];
    failureBlockForWidgetCreation[hash] = [NSMutableDictionary dictionary];
}

- (void)removeMatrixSession:(MXSession *)mxSession
{
    // Remove by value in a dict
    for (NSString *key in [matrixSessions allKeysForObject:mxSession])
    {
        [matrixSessions removeObjectForKey:key];
    }

    // mxSession.myUser.userId and mxSession.matrixRestClient.credentials.userId may be nil here
    // So, use a kind of hash value instead
    NSString *hash = [NSString stringWithFormat:@"%p", mxSession];
    id listener = widgetEventListener[hash];

    [mxSession removeListener:listener];

    [widgetEventListener removeObjectForKey:hash];
    [successBlockForWidgetCreation removeObjectForKey:hash];
    [failureBlockForWidgetCreation removeObjectForKey:hash];
}

- (MXSession*)matrixSessionForUser:(NSString*)userId
{
    return matrixSessions[userId];
}

- (void)deleteDataForUser:(NSString *)userId
{
    [configs removeObjectForKey:userId];
    [self saveConfigs];
}

#pragma mark - User integrations configuration

- (WidgetManagerConfig*)createWidgetManagerConfigForUser:(NSString*)userId
{
    WidgetManagerConfig *config;

    MXSession *session = [self matrixSessionForUser:userId];

    // Find the integrations settings for the user

    // First, look at matrix account
    // TODO in another user story
    
    // Then, try to the homeserver configuration
    MXWellknownIntegrationsManager *integrationsManager = session.homeserverWellknown.integrations.managers.firstObject;
    if (integrationsManager)
    {
        config = [[WidgetManagerConfig alloc] initWithApiUrl:integrationsManager.apiUrl uiUrl:integrationsManager.uiUrl];
    }
    else
    {
        // Fallback on app settings
        config = [self createWidgetManagerConfigWithAppSettings];
    }

    return config;
}

- (WidgetManagerConfig*)createWidgetManagerConfigWithAppSettings
{
    return [[WidgetManagerConfig alloc] initWithApiUrl:BuildSettings.integrationsRestApiUrlString
                                                 uiUrl:BuildSettings.integrationsUiUrlString];
}

#pragma mark - Modular interface

- (WidgetManagerConfig*)configForUser:(NSString*)userId
{
    // Return a default config by default
    return configs[userId] ? configs[userId] : [self createWidgetManagerConfigForUser:userId];
}

- (BOOL)hasIntegrationManagerForUser:(NSString*)userId
{
    return [self configForUser:userId].hasUrls;
}

- (void)setConfig:(WidgetManagerConfig*)config forUser:(NSString*)userId
{
    configs[userId] = config;
    [self saveConfigs];
}


- (MXHTTPOperation *)getScalarTokenForMXSession:(MXSession*)mxSession
                                       validate:(BOOL)validate
                                        success:(void (^)(NSString *scalarToken))success
                                        failure:(void (^)(NSError *error))failure;
{
    MXHTTPOperation *operation;

    __block NSString *scalarToken = [self scalarTokenForMXSession:mxSession];
    if (scalarToken)
    {
        if (!validate)
        {
            success(scalarToken);
        }
        else
        {
            operation = [self validateScalarToken:scalarToken forMXSession:mxSession complete:^(BOOL valid) {

                if (valid)
                {
                    success(scalarToken);
                }
                else
                {
                    MXLogDebug(@"[WidgetManager] getScalarTokenForMXSession: Invalid stored token. Need to register for a new token");
                    MXHTTPOperation *operation2 = [self registerForScalarToken:mxSession success:success failure:failure];
                    [operation mutateTo:operation2];
                }

            } failure:failure];
        }
    }
    else
    {
        MXLogDebug(@"[WidgetManager] getScalarTokenForMXSession: Need to register for a token");
        operation = [self registerForScalarToken:mxSession success:success failure:failure];
    }

    return operation;
}

- (MXHTTPOperation *)registerForScalarToken:(MXSession*)mxSession
                                    success:(void (^)(NSString *scalarToken))success
                                    failure:(void (^)(NSError *error))failure
{
    MXHTTPOperation *operation;
    NSString *userId = mxSession.myUser.userId;

    MXLogDebug(@"[WidgetManager] registerForScalarToken");

    WidgetManagerConfig *config = [self configForUser:userId];
    if (!config.hasUrls)
    {
        MXLogDebug(@"[WidgetManager] registerForScalarToken: Error: no integration manager API URL for user %@", mxSession.myUser.userId);
        failure(self.errorForNonConfiguredIntegrationManager);
        return nil;
    }

    MXWeakify(self);
    operation = [mxSession.matrixRestClient openIdToken:^(MXOpenIdToken *tokenObject) {
        MXStrongifyAndReturnIfNil(self);

        // Exchange the token for a scalar token
        __block MXHTTPClient *httpClient = [[MXHTTPClient alloc] initWithBaseURL:config.apiUrl andOnUnrecognizedCertificateBlock:nil];

        MXHTTPOperation *operation2 =
        [httpClient requestWithMethod:@"POST"
                                 path:@"register?v=1.1"
                           parameters:tokenObject.JSONDictionary
                              success:^(NSDictionary *JSONResponse)
         {
             httpClient = nil;

             NSString *scalarToken;
             MXJSONModelSetString(scalarToken, JSONResponse[@"scalar_token"])

             config.scalarToken = scalarToken;
             self->configs[userId] = config;
             [self saveConfigs];
             
             // Validate it (this mostly checks to see if the IM needs us to agree to some terms)
             MXHTTPOperation *operation3 = [self validateScalarToken:scalarToken forMXSession:mxSession complete:^(BOOL valid) {

                 if (success)
                 {
                     success(scalarToken);
                 }

             } failure:failure];

             [operation mutateTo:operation3];

         } failure:^(NSError *error) {
             httpClient = nil;

             MXLogDebug(@"[WidgetManager] registerForScalarToken: Failed to register. Error: %@", error);

             if (failure)
             {
                 // Specialise the error
                 NSError *error = [NSError errorWithDomain:WidgetManagerErrorDomain
                                                      code:WidgetManagerErrorCodeFailedToConnectToIntegrationsServer
                                                  userInfo:@{
                                                             NSLocalizedDescriptionKey: [VectorL10n widgetIntegrationsServerFailedToConnect]
                                                             }];

                 failure(error);
             }
         }];

        [operation mutateTo:operation2];

    } failure:^(NSError *error) {
        MXLogDebug(@"[WidgetManager] registerForScalarToken. Error in openIdToken request");

        if (failure)
        {
            failure(error);
        }
    }];

    return operation;
}

- (MXHTTPOperation *)validateScalarToken:(NSString*)scalarToken forMXSession:(MXSession*)mxSession
                                complete:(void (^)(BOOL valid))complete
                                 failure:(void (^)(NSError *error))failure
{
    NSString *userId = mxSession.myUser.userId;

    WidgetManagerConfig *config = [self configForUser:userId];
    if (!config.hasUrls)
    {
        MXLogDebug(@"[WidgetManager] validateScalarToken: Error: no integration manager API URL for user %@", mxSession.myUser.userId);
        failure(self.errorForNonConfiguredIntegrationManager);
        return nil;
    }

    __block MXHTTPClient *httpClient = [[MXHTTPClient alloc] initWithBaseURL:config.apiUrl andOnUnrecognizedCertificateBlock:nil];

    return [httpClient requestWithMethod:@"GET"
                                    path:[NSString stringWithFormat:@"account?v=1.1&scalar_token=%@", scalarToken]
                              parameters:nil
                                 success:^(NSDictionary *JSONResponse) {
                                     httpClient = nil;

                                     NSString *userId;
                                     MXJSONModelSetString(userId, JSONResponse[@"user_id"])

                                     if ([userId isEqualToString:mxSession.myUser.userId])
                                     {
                                         complete(YES);
                                     }
                                     else
                                     {
                                         MXLogDebug(@"[WidgetManager] validateScalarToken. Unexpected modular/account response: %@", JSONResponse);
                                         complete(NO);
                                     }

                                 } failure:^(NSError *error) {
                                     httpClient = nil;

                                     NSHTTPURLResponse *urlResponse = [MXHTTPOperation urlResponseFromError:error];

                                     MXLogDebug(@"[WidgetManager] validateScalarToken. Error in modular/account request. statusCode: %@", @(urlResponse.statusCode));

                                     MXError *mxError = [[MXError alloc] initWithNSError:error];
                                     if ([mxError.errcode isEqualToString:kMXErrCodeStringTermsNotSigned])
                                     {
                                         MXLogDebug(@"[WidgetManager] validateScalarToke. Error: Need to accept terms");
                                         NSError *termsNotSignedError = [NSError errorWithDomain:WidgetManagerErrorDomain
                                                                                            code:WidgetManagerErrorCodeTermsNotSigned
                                                                                        userInfo:@{
                                                                                                NSLocalizedDescriptionKey:error.userInfo[NSLocalizedDescriptionKey]
                                                                                                   }];

                                         failure(termsNotSignedError);
                                     }
                                     else if (urlResponse &&  urlResponse.statusCode / 100 != 2)
                                     {
                                         complete(NO);
                                     }
                                     else if (failure)
                                     {
                                         failure(error);
                                     }
                                 }];
}

- (BOOL)isScalarUrl:(NSString *)urlString forUser:(NSString*)userId
{
    BOOL isScalarUrl = NO;

    // TODO: Do we need to add `integrationsWidgetsUrls` to `WidgetManagerConfig`?
    NSArray<NSString*> *scalarUrlStrings = BuildSettings.integrationsScalarWidgetsPaths;
    if (scalarUrlStrings.count == 0)
    {
        NSString *apiUrl = [self configForUser:userId].apiUrl;
        if (apiUrl)
        {
            scalarUrlStrings = @[apiUrl];
        }
    }

    for (NSString *scalarUrlString in scalarUrlStrings)
    {
        if ([urlString hasPrefix:scalarUrlString])
        {
            isScalarUrl = YES;
            break;
        }
    }

    return isScalarUrl;
}

#pragma mark - Private methods

- (NSString *)scalarTokenForMXSession:(MXSession *)mxSession
{
    return configs[mxSession.myUser.userId].scalarToken;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (void)loadConfigs
{
    NSUserDefaults *userDefaults = [MXKAppSettings standardAppSettings].sharedUserDefaults;

    NSDictionary<NSString*, NSString*> *scalarTokens = [userDefaults objectForKey:@"scalarTokens"];
    if (scalarTokens)
    {
        // Manage migration to WidgetManagerConfig
        configs = [NSMutableDictionary dictionary];
        for (NSString *userId in scalarTokens)
        {
            NSString *scalarToken = scalarTokens[userId];

            MXLogDebug(@"[WidgetManager] migrate scalarTokens to integrationManagerConfigs for %@", userId);

            WidgetManagerConfig *config = [self createWidgetManagerConfigWithAppSettings];
            config.scalarToken = scalarToken;

            configs[userId] = config;
        }

        [self saveConfigs];
        [userDefaults removeObjectForKey:@"scalarTokens"];
    }
    else
    {
        NSData *configsData = [userDefaults objectForKey:@"integrationManagerConfigs"];
        if (configsData)
        {
            // We need to map the config class name since the bundle name was updated otherwise unarchiving crashes.
            [NSKeyedUnarchiver setClass:WidgetManagerConfig.class forClassName:@"Riot.WidgetManagerConfig"];
            configs = [NSMutableDictionary dictionaryWithDictionary:[NSKeyedUnarchiver unarchiveObjectWithData:configsData]];
        }

        if (!configs)
        {
            configs = [NSMutableDictionary dictionary];
        }
    }
}

- (void)saveConfigs
{
    NSUserDefaults *userDefaults = [MXKAppSettings standardAppSettings].sharedUserDefaults;
    [userDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:configs]
                     forKey:@"integrationManagerConfigs"];
}
#pragma clang diagnostic pop


#pragma mark - Errors

- (NSError*)errorForNonConfiguredIntegrationManager
{
    return [NSError errorWithDomain:WidgetManagerErrorDomain
                               code:WidgetManagerErrorCodeNoIntegrationsServerConfigured
                           userInfo:@{NSLocalizedDescriptionKey: [VectorL10n widgetNoIntegrationsServerConfigured]}];
}

- (NSError*)errorForDisabledIntegrationManager
{
    return [NSError errorWithDomain:WidgetManagerErrorDomain
                               code:WidgetManagerErrorCodeDisabledIntegrationsServer
                           userInfo:@{NSLocalizedDescriptionKey: [VectorL10n widgetIntegrationManagerDisabled]}];
}

- (NSError*)errorForUnavailableJitsiURL
{
    return [NSError errorWithDomain:WidgetManagerErrorDomain
                               code:WidgetManagerErrorCodeUnavailableJitsiURL
                           userInfo:@{NSLocalizedDescriptionKey: VectorL10n.callJitsiUnableToStart}];
}

@end
