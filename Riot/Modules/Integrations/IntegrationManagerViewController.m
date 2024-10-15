/*
Copyright 2019-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "IntegrationManagerViewController.h"

#import "WidgetManager.h"

#import "GeneratedInterface-Swift.h"

NSString *const kIntegrationManagerMainScreen = nil;
NSString *const kIntegrationManagerAddIntegrationScreen = @"add_integ";


@interface IntegrationManagerViewController () <ServiceTermsModalCoordinatorBridgePresenterDelegate>
{
    MXSession *mxSession;
    NSString *roomId;
    NSString *screen;
    NSString *widgetId;
    NSString *scalarToken;

    MXHTTPOperation *operation;
}

@property (nonatomic, strong) ServiceTermsModalCoordinatorBridgePresenter *serviceTermsModalCoordinatorBridgePresenter;
@property (nonatomic) BOOL isViewAppearedOnce;

@end

@implementation IntegrationManagerViewController

- (instancetype)initForMXSession:(MXSession *)theMXSession inRoom:(NSString *)theRoomId screen:(NSString *)theScreen widgetId:(NSString *)theWidgetId
{
    self = [super init];
    if (self)
    {
        mxSession = theMXSession;
        roomId = theRoomId;
        screen = theScreen;
        widgetId = theWidgetId;
    }
    return self;
}

+ (NSString*)screenForWidget:(NSString*)widgetType
{
    return [NSString stringWithFormat:@"type_%@", widgetType];
}

- (void)destroy
{
    [super destroy];

    [operation cancel];
    operation = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.isViewAppearedOnce)
    {
        self.isViewAppearedOnce = YES;
        [self loadData];
    }
}

- (void)loadData
{
    RiotSharedSettings *sharedSettings = [[RiotSharedSettings alloc] initWithSession:mxSession];
    if (!sharedSettings.hasIntegrationProvisioningEnabled)
    {
        [self showDisabledIntegrationManagerError];
        return;
    }

    if (!self.URL && !operation)
    {
        [self startActivityIndicator];

        // Make sure we have a scalar token
        MXWeakify(self);
        operation = [[WidgetManager sharedManager] getScalarTokenForMXSession:mxSession validate:YES  success:^(NSString *theScalarToken) {
            MXStrongifyAndReturnIfNil(self);

            self->operation = nil;
            self->scalarToken = theScalarToken;

            // Launch the webview on the right modular webapp page
            self.URL = [self interfaceUrl];

        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);

            MXLogDebug(@"[IntegraionManagerVS] Cannot open due to missing scalar token. Error: %@", error);

            self->operation = nil;
            [self stopActivityIndicator];

            if ([error.domain isEqualToString:WidgetManagerErrorDomain]
                && error.code == WidgetManagerErrorCodeTermsNotSigned)
            {
                [self presentTerms];
            }
            else
            {
                [self withdrawViewControllerAnimated:YES completion:^{
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                }];
            }
        }];
    }
}

#pragma mark - Private methods

/**
 Build the URL to use in the Modular interface webapp.
 */
- (NSString *)interfaceUrl
{
    NSMutableString *url;

    NSString *integrationsUiUrl = [[WidgetManager sharedManager] configForUser:mxSession.myUser.userId].uiUrl;

    if (scalarToken)
    {
        url = [NSMutableString stringWithFormat:@"%@?scalar_token=%@&room_id=%@",
               integrationsUiUrl,
               [MXTools encodeURIComponent:scalarToken],
               [MXTools encodeURIComponent:roomId]
               ];

        if (screen)
        {
            [url appendString:@"&screen="];
            [url appendString:[MXTools encodeURIComponent:screen]];
        }

        if (widgetId)
        {
            [url appendString:@"&integ_id="];
            [url appendString:[MXTools encodeURIComponent:widgetId]];
        }
    }
    
    return url;
}

#pragma mark - Modular postMessage API implementation

- (void)onPostMessageRequest:(NSString*)requestId data:(NSDictionary*)requestData
{
    NSString *roomIdInEvent, *userId, *action;

    MXJSONModelSetString(roomIdInEvent, requestData[@"room_id"]);
    MXJSONModelSetString(userId, requestData[@"user_id"]);
    MXJSONModelSetString(action, requestData[@"action"]);

    if ([action isEqualToString:@"close_scalar"])
    {
        [self withdrawViewControllerAnimated:YES completion:nil];
        return;
    }

    if (!roomIdInEvent)
    {
        // These APIs don't require roomId
        // Get and set user widgets (not associated with a specific room)
        // If roomId is specified, it must be validated, so room-based widgets agreed
        // handled further down.
        if ([@"set_widget" isEqualToString:action])
        {
            [self setWidget:requestId data:requestData];
            return;
        }
        else if ([@"get_widgets" isEqualToString:action])
        {
            [self getWidgets:requestId data:requestData];
            return;
        }
        else
        {
            [self sendError:[VectorL10n widgetIntegrationMissingRoomId] toRequest:requestId];
            return;
        }
    }

    if (![roomIdInEvent isEqualToString:roomId])
    {
        [self sendError:[VectorL10n widgetIntegrationRoomNotVisible:roomIdInEvent] toRequest:requestId];
        return;
    }

    // Get and set room-based widgets
    if ([@"set_widget" isEqualToString:action])
    {
        [self setWidget:requestId data:requestData];
        return;
    }
    else if ([@"get_widgets" isEqualToString:action])
    {
        [self getWidgets:requestId data:requestData];
        return;
    }

    // These APIs don't require userId
    if ([@"join_rules_state" isEqualToString:action])
    {
        [self getJoinRules:requestId data:requestData];
        return;
    }
    else if ([@"set_plumbing_state" isEqualToString:action])
    {
        [self setPlumbingState:requestId data:requestData];
        return;
    }
    else if ([@"get_membership_count" isEqualToString:action])
    {
        [self getMembershipCount:requestId data:requestData];
        return;
    }
    else if ([@"get_room_enc_state" isEqualToString:action])
    {
        [self getRoomEncState:requestId data:requestData];
        return;
    }
    else if ([@"can_send_event" isEqualToString:action])
    {
        [self canSendEvent:requestId data:requestData];
        return;
    }


    if (!userId)
    {
        [self sendError:[VectorL10n widgetIntegrationMissingUserId] toRequest:requestId];
        return;
    }

    if ([@"membership_state" isEqualToString:action])
    {
        [self getMembershipState:userId request:requestId data:requestData];
    }
    else if ([@"invite" isEqualToString:action])
    {
        [self inviteUser:userId request:requestId data:requestData];
    }
    else if ([@"bot_options" isEqualToString:action])
    {
        [self getBotOptions:userId request:requestId data:requestData];
    }
    else if ([@"set_bot_options" isEqualToString:action])
    {
        [self setBotOptions:userId request:requestId data:requestData];
    }
    else if ([@"set_bot_power" isEqualToString:action])
    {
        [self setBotPower:userId request:requestId data:requestData];
    }
    else
    {
        MXLogDebug(@"[IntegrationManagerViewControllerVC] Unhandled postMessage event with action %@: %@", action, requestData);
    }
}

#pragma mark - Private methods

- (void)roomCheckForRequest:(NSString*)requestId data:(NSDictionary*)requestData onComplete:(void (^)(MXRoom *room, MXRoomState *roomState))onComplete
{
    MXRoom *room = [mxSession roomWithRoomId:roomId];
    if (room)
    {
        [room state:^(MXRoomState *roomState) {
            onComplete(room, roomState);
        }];
    }
    else
    {
        [self sendError:[VectorL10n widgetIntegrationRoomNotRecognised] toRequest:requestId];
    }
}

- (void)inviteUser:(NSString*)userId request:(NSString*)requestId data:(NSDictionary*)requestData
{
    MXLogDebug(@"[IntegrationManagerVC] Received request to invite %@ into room %@.", userId, roomId);

    [self roomCheckForRequest:requestId data:requestData onComplete:^(MXRoom *room, MXRoomState *roomState) {

        MXRoomMember *member = [roomState.members memberWithUserId:userId];
        if (member && member.membership == MXMembershipJoin)
        {
            [self sendNSObjectResponse:@{
                                         @"success": @(YES)
                                         }
                               toRequest:requestId];
        }
        else
        {
            MXWeakify(self);
            [room inviteUser:userId success:^{
                MXStrongifyAndReturnIfNil(self);

                [self sendNSObjectResponse:@{
                                             @"success": @(YES)
                                             }
                                 toRequest:requestId];

            } failure:^(NSError *error) {
                MXStrongifyAndReturnIfNil(self);

                [self sendError:[VectorL10n widgetIntegrationNeedToBeAbleToInvite] toRequest:requestId];
            }];
        }
    }];
}

- (void)setWidget:(NSString*)requestId data:(NSDictionary*)requestData
{
    MXLogDebug(@"[IntegrationManagerVC] Received request to set widget");

    NSString *widget_id, *widgetType, *widgetUrl;
    NSString *widgetName; // optional
    NSDictionary *widgetData ; // optional
    BOOL userWidget = NO;

    MXJSONModelSetString(widget_id, requestData[@"widget_id"]);
    MXJSONModelSetString(widgetType, requestData[@"type"]);
    MXJSONModelSetString(widgetUrl, requestData[@"url"]);
    MXJSONModelSetString(widgetName, requestData[@"name"]);
    MXJSONModelSetDictionary(widgetData, requestData[@"data"]);
    MXJSONModelSetBoolean(userWidget, requestData[@"userWidget"]);

    if (!widget_id)
    {
        [self sendError:[VectorL10n widgetIntegrationUnableToCreate] toRequest:requestId];
        return;
    }

    if (!widgetType)
    {
        [self sendError:[VectorL10n widgetIntegrationUnableToCreate] toRequest:requestId];
        return;
    }

    NSMutableDictionary *widgetEventContent = [NSMutableDictionary dictionary];
    if (widgetUrl)
    {
        widgetEventContent[@"type"] = widgetType;
        widgetEventContent[@"url"] = widgetUrl;

        if (widgetName)
        {
            widgetEventContent[@"name"] = widgetName;
        }
        if (widgetData)
        {
            widgetEventContent[@"data"] = widgetData;
        }
    }
    // else this is a deletion

    __weak __typeof__(self) weakSelf = self;

    if (userWidget)
    {
        // Update the user account data
        NSMutableDictionary *userWidgets = [NSMutableDictionary dictionaryWithDictionary:[mxSession.accountData accountDataForEventType:kMXAccountDataTypeUserWidgets]];

        // Delete existing widget with ID
        [userWidgets removeObjectForKey:widget_id];

        // Add new widget / update
        if (widgetUrl)
        {
            userWidgets[widget_id] = @{
                                      @"content": widgetEventContent,
                                      @"sender": mxSession.myUser.userId,
                                      @"state_key": widget_id,
                                      @"type": kWidgetMatrixEventTypeString,
                                      @"id": widget_id,
                                      };
        }

        [mxSession setAccountData:userWidgets forType:kMXAccountDataTypeUserWidgets success:^{

            typeof(self) self = weakSelf;
            if (self)
            {
                [self sendNSObjectResponse:@{
                                             @"success": @(YES)
                                             }
                                 toRequest:requestId];
            }
        } failure:^(NSError *error) {

            typeof(self) self = weakSelf;
            if (self)
            {
                [self sendError:[VectorL10n widgetIntegrationUnableToCreate] toRequest:requestId];
            }
        }];
    }
    else
    {
        // Room widget
        [self roomCheckForRequest:requestId data:requestData onComplete:^(MXRoom *room, MXRoomState *roomState) {

            // TODO: Move to kWidgetMatrixEventTypeString ("m.widget") type but when?
            [room sendStateEventOfType:kWidgetModularEventTypeString
                               content:widgetEventContent
                              stateKey:widget_id
                               success:^(NSString *eventId) {

                                   typeof(self) self = weakSelf;
                                   if (self)
                                   {
                                       [self sendNSObjectResponse:@{
                                                                    @"success": @(YES)
                                                                    }
                                                        toRequest:requestId];
                                   }
                               }
                               failure:^(NSError *error) {

                                   typeof(self) self = weakSelf;
                                   if (self)
                                   {
                                       [self sendError:[VectorL10n widgetIntegrationFailedToSendRequest] toRequest:requestId];
                                   }
                               }];
        }];
    }
}

- (void)getWidgets:(NSString*)requestId data:(NSDictionary*)requestData
{
    MXWeakify(self);
    [self roomCheckForRequest:requestId data:requestData onComplete:^(MXRoom *room, MXRoomState *roomState) {
        MXStrongifyAndReturnIfNil(self);

        NSMutableArray<NSDictionary*> *widgetStateEvents = [NSMutableArray array];

        NSArray<Widget*> *widgets = [[WidgetManager sharedManager] widgetsInRoom:room withRoomState:roomState];
        for (Widget *widget in widgets)
        {
            [widgetStateEvents addObject:widget.widgetEvent.JSONDictionary];
        }

        // Add user widgets (not linked to a specific room)
        for (Widget *widget in [[WidgetManager sharedManager] userWidgets:self->mxSession])
        {
            [widgetStateEvents addObject:widget.widgetEvent.JSONDictionary];
        }

        [self sendNSObjectResponse:widgetStateEvents toRequest:requestId];
    }];
}

- (void)getRoomEncState:(NSString*)requestId data:(NSDictionary*)requestData
{
    [self roomCheckForRequest:requestId data:requestData onComplete:^(MXRoom *room, MXRoomState *roomState) {
        [self sendBoolResponse:room.summary.isEncrypted toRequest:requestId];
    }];
}

- (void)canSendEvent:(NSString*)requestId data:(NSDictionary*)requestData
{
    MXWeakify(self);
    [self roomCheckForRequest:requestId data:requestData onComplete:^(MXRoom *room, MXRoomState *roomState) {
        MXStrongifyAndReturnIfNil(self);

        NSString *eventType;
        BOOL isState = NO;

        if (room.summary.membership != MXMembershipJoin)
        {
            [self sendError:[VectorL10n widgetIntegrationMustBeInRoom] toRequest:requestId];
            return;
        }

        MXJSONModelSetString(eventType, requestData[@"event_type"]);
        MXJSONModelSetBoolean(isState, requestData[@"is_state"]);

        MXRoomPowerLevels *powerLevels = roomState.powerLevels;
        NSInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:self->mxSession.myUser.userId];

        BOOL canSend = NO;

        if (isState)
        {
            canSend = (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:eventType]);
        }
        else
        {
            canSend = (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsMessage:eventType]);
        }

        if (canSend)
        {
            [self sendBoolResponse:YES toRequest:requestId];
        }
        else
        {
            [self sendError:[VectorL10n widgetIntegrationNoPermissionInRoom] toRequest:requestId];
        }

    }];
}

- (void)getMembershipState:(NSString*)userId request:(NSString*)requestId data:(NSDictionary*)requestData
{
    MXLogDebug(@"[IntegrationManagerVC] membership_state of %@ in room %@ requested.", userId, roomId);

    [self roomCheckForRequest:requestId data:requestData onComplete:^(MXRoom *room, MXRoomState *roomState) {
        MXRoomMember *member = [roomState.members memberWithUserId:userId];
        [self sendNSObjectResponse:member.originalEvent.content toRequest:requestId];
    }];
}

- (void)getJoinRules:(NSString*)requestId data:(NSDictionary*)requestData
{
    MXLogDebug(@"[IntegrationManagerVC] join_rules of %@ requested.", roomId);

    [self roomCheckForRequest:requestId data:requestData onComplete:^(MXRoom *room, MXRoomState *roomState) {
        MXEvent *event = [roomState stateEventsWithType:kMXEventTypeStringRoomJoinRules].lastObject;
        [self sendNSObjectResponse:event.JSONDictionary toRequest:requestId];
    }];
}

- (void)setPlumbingState:(NSString*)requestId data:(NSDictionary*)requestData
{
    MXLogDebug(@"[IntegrationManagerVC] Received request to set plumbing state to status %@ in room %@.", requestData[@"status"], roomId);

    [self roomCheckForRequest:requestId data:requestData onComplete:^(MXRoom *room, MXRoomState *roomState) {
        NSString *status;
        MXJSONModelSetString(status, requestData[@"status"]);

        if (status)
        {
            __weak __typeof__(self) weakSelf = self;

            [room sendStateEventOfType:kMXEventTypeStringRoomPlumbing
                               content:@{
                                         @"status": status
                                         }
                              stateKey:nil
                               success:^(NSString *eventId) {

                                   typeof(self) self = weakSelf;
                                   if (self)
                                   {
                                       [self sendNSObjectResponse:@{
                                                                    @"success": @(YES)
                                                                    }
                                                        toRequest:requestId];
                                   }
                               }
                               failure:^(NSError *error) {

                                   typeof(self) self = weakSelf;
                                   if (self)
                                   {
                                       [self sendError:[VectorL10n widgetIntegrationFailedToSendRequest] toRequest:requestId];
                                   }
                               }];
        }
        else
        {
            MXLogDebug(@"[IntegrationManagerVC] setPlumbingState. Error: Plumbing state status should be a string.");
        }

    }];
}

- (void)getBotOptions:(NSString*)userId request:(NSString*)requestId data:(NSDictionary*)requestData
{
    MXLogDebug(@"[IntegrationManagerVC] Received request to get options for bot %@ in room %@", userId, roomId);

    [self roomCheckForRequest:requestId data:requestData onComplete:^(MXRoom *room, MXRoomState *roomState) {
        NSString *stateKey = [NSString stringWithFormat:@"_%@", userId];

        NSArray<MXEvent*> *stateEvents = [roomState stateEventsWithType:kMXEventTypeStringRoomBotOptions];

        MXEvent *botOptionsEvent;

        for (MXEvent *stateEvent in stateEvents)
        {
            if ([stateEvent.stateKey isEqualToString:stateKey])
            {
                if (!botOptionsEvent || stateEvent.ageLocalTs > botOptionsEvent.ageLocalTs)
                {
                    botOptionsEvent = stateEvent;
                }
            }
        }

        [self sendNSObjectResponse:botOptionsEvent.JSONDictionary toRequest:requestId];

    }];
}

- (void)setBotOptions:(NSString*)userId request:(NSString*)requestId data:(NSDictionary*)requestData
{
    MXLogDebug(@"[IntegrationManagerVC] Received request to set options for bot %@ in room %@", userId, roomId);

    [self roomCheckForRequest:requestId data:requestData onComplete:^(MXRoom *room, MXRoomState *roomState) {
        NSDictionary *content;
        MXJSONModelSetDictionary(content, requestData[@"content"]);

        if (content)
        {
            __weak __typeof__(self) weakSelf = self;

            NSString *stateKey = [NSString stringWithFormat:@"_%@", userId];

            [room sendStateEventOfType:kMXEventTypeStringRoomBotOptions
                               content:content
                              stateKey:stateKey
                               success:^(NSString *eventId) {

                                   typeof(self) self = weakSelf;
                                   if (self)
                                   {
                                       [self sendNSObjectResponse:@{
                                                                    @"success": @(YES)
                                                                    }
                                                        toRequest:requestId];
                                   }
                               }
                               failure:^(NSError *error) {

                                   typeof(self) self = weakSelf;
                                   if (self)
                                   {
                                       [self sendError:[VectorL10n widgetIntegrationFailedToSendRequest] toRequest:requestId];
                                   }
                               }];
        }
        else
        {
            MXLogDebug(@"[IntegrationManagerVC] setBotOptions. Error: options should be a dict.");
        }
    }];
}

- (void)setBotPower:(NSString*)userId request:(NSString*)requestId data:(NSDictionary*)requestData
{
    MXLogDebug(@"[IntegrationManagerVC] Received request to set power level to %@ for bot %@ in room %@.", requestData[@"level"], userId, roomId);

    [self roomCheckForRequest:requestId data:requestData onComplete:^(MXRoom *room, MXRoomState *roomState) {
        NSInteger level = -1;
        MXJSONModelSetInteger(level, requestData[@"level"]);

        if (level >= 0)
        {
            __weak __typeof__(self) weakSelf = self;

            [room setPowerLevelOfUserWithUserID:userId powerLevel:level success:^{

                typeof(self) self = weakSelf;
                if (self)
                {
                    [self sendNSObjectResponse:@{
                                                 @"success": @(YES)
                                                 }
                                     toRequest:requestId];
                }

            } failure:^(NSError *error) {

                typeof(self) self = weakSelf;
                if (self)
                {
                    [self sendError:[VectorL10n widgetIntegrationFailedToSendRequest] toRequest:requestId];
                }
            }];
        }
        else
        {
            MXLogDebug(@"[IntegrationManagerVC] setBotPower. Power level must be positive integer.");
            [self sendError:[VectorL10n widgetIntegrationPositivePowerLevel] toRequest:requestId];
        }
    }];
}

- (void)getMembershipCount:(NSString*)requestId data:(NSDictionary*)requestData
{
    [self roomCheckForRequest:requestId data:requestData onComplete:^(MXRoom *room, MXRoomState *roomState) {
        NSUInteger membershipCount = room.summary.membersCount.joined;
        [self sendIntegerResponse:membershipCount toRequest:requestId];
    }];
}


#pragma mark - Widget Permission

- (void)checkWidgetPermissionWithCompletion:(void (^)(BOOL granted))completion
{
    // The integration manager widget has its own terms
    completion(YES);
}


#pragma mark - Disabled Integrations

- (void)showDisabledIntegrationManagerError
{
    NSString *message = [VectorL10n widgetIntegrationManagerDisabled];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [self withdrawViewControllerAnimated:YES completion:nil];
                                            }]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Service terms

- (void)presentTerms
{
    WidgetManagerConfig *config =  [[WidgetManager sharedManager] configForUser:mxSession.myUser.userId];

    MXLogDebug(@"[IntegrationManagerVC] presentTerms for %@", config.baseUrl);

    ServiceTermsModalCoordinatorBridgePresenter *serviceTermsModalCoordinatorBridgePresenter = [[ServiceTermsModalCoordinatorBridgePresenter alloc] initWithSession:mxSession baseUrl:config.baseUrl
                                                                                                                                                        serviceType:MXServiceTypeIntegrationManager
                                                                                                                                                        accessToken:config.scalarToken];

    serviceTermsModalCoordinatorBridgePresenter.delegate = self;

    [serviceTermsModalCoordinatorBridgePresenter presentFrom:self animated:YES];
    self.serviceTermsModalCoordinatorBridgePresenter = serviceTermsModalCoordinatorBridgePresenter;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidAccept:(ServiceTermsModalCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        [self loadData];
    }];
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidDecline:(ServiceTermsModalCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter session:(MXSession * _Nonnull)session
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        [self withdrawViewControllerAnimated:YES completion:nil];
    }];
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidClose:(ServiceTermsModalCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

@end
