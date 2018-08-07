/*
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

#import "IntegrationManagerViewController.h"

#import "WidgetManager.h"

NSString *const kIntegrationManagerMainScreen = nil;
NSString *const kIntegrationManagerAddIntegrationScreen = @"add_integ";


@interface IntegrationManagerViewController ()
{
    MXSession *mxSession;
    NSString *roomId;
    NSString *screen;
    NSString *widgetId;
    NSString *scalarToken;

    MXHTTPOperation *operation;
}

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

    if (!self.URL && !operation)
    {
        [self startActivityIndicator];

        // Make sure we have a scalar token
        MXWeakify(self);
        operation = [[WidgetManager sharedManager] getScalarTokenForMXSession:mxSession success:^(NSString *theScalarToken) {
            MXStrongifyAndReturnIfNil(self);

            self->operation = nil;
            self->scalarToken = theScalarToken;

            // Launch the webview on the right modular webapp page
            self.URL = [self interfaceUrl];

        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);

            self->operation = nil;
            [self stopActivityIndicator];
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

    if (scalarToken)
    {
        url = [NSMutableString stringWithFormat:@"%@?scalar_token=%@&room_id=%@",
               [[NSUserDefaults standardUserDefaults] objectForKey:@"integrationsUiUrl"],
               [scalarToken stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
               [roomId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
               ];

        if (screen)
        {
            [url appendString:@"&screen="];
            [url appendString:[screen stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }

        if (widgetId)
        {
            [url appendString:@"&integ_id="];
            [url appendString:[widgetId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
            [self sendLocalisedError:@"widget_integration_missing_room_id" toRequest:requestId];
            return;
        }
    }

    if (![roomIdInEvent isEqualToString:roomId])
    {
        [self sendError:[NSString stringWithFormat:NSLocalizedStringFromTable(@"widget_integration_room_not_visible", @"Vector", nil), roomIdInEvent] toRequest:requestId];
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
        [self sendLocalisedError:@"widget_integration_missing_user_id" toRequest:requestId];
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
        NSLog(@"[IntegrationManagerViewControllerVC] Unhandled postMessage event with action %@: %@", action, requestData);
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
        [self sendLocalisedError:@"widget_integration_room_not_recognised" toRequest:requestId];
    }
}

- (void)inviteUser:(NSString*)userId request:(NSString*)requestId data:(NSDictionary*)requestData
{
    NSLog(@"[IntegrationManagerVC] Received request to invite %@ into room %@.", userId, roomId);

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

                [self sendLocalisedError:@"widget_integration_need_to_be_able_to_invite" toRequest:requestId];
            }];
        }
    }];
}

- (void)setWidget:(NSString*)requestId data:(NSDictionary*)requestData
{
    NSLog(@"[IntegrationManagerVC] Received request to set widget");

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
        [self sendLocalisedError:@"widget_integration_unable_to_create" toRequest:requestId]; // new Error("Missing required widget fields."));
        return;
    }

    if (!widgetType)
    {
        [self sendLocalisedError:@"widget_integration_unable_to_create" toRequest:requestId];
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
                [self sendLocalisedError:@"widget_integration_unable_to_create" toRequest:requestId];
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
                                       [self sendLocalisedError:@"widget_integration_failed_to_send_request" toRequest:requestId];
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
            [self sendLocalisedError:@"widget_integration_must_be_in_room" toRequest:requestId];
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
            [self sendLocalisedError:@"widget_integration_no_permission_in_room" toRequest:requestId];
        }

    }];
}

- (void)getMembershipState:(NSString*)userId request:(NSString*)requestId data:(NSDictionary*)requestData
{
    NSLog(@"[IntegrationManagerVC] membership_state of %@ in room %@ requested.", userId, roomId);

    [self roomCheckForRequest:requestId data:requestData onComplete:^(MXRoom *room, MXRoomState *roomState) {
        MXRoomMember *member = [roomState.members memberWithUserId:userId];
        [self sendNSObjectResponse:member.originalEvent.content toRequest:requestId];
    }];
}

- (void)getJoinRules:(NSString*)requestId data:(NSDictionary*)requestData
{
    NSLog(@"[IntegrationManagerVC] join_rules of %@ requested.", roomId);

    [self roomCheckForRequest:requestId data:requestData onComplete:^(MXRoom *room, MXRoomState *roomState) {
        MXEvent *event = [roomState stateEventsWithType:kMXEventTypeStringRoomJoinRules].lastObject;
        [self sendNSObjectResponse:event.JSONDictionary toRequest:requestId];
    }];
}

- (void)setPlumbingState:(NSString*)requestId data:(NSDictionary*)requestData
{
    NSLog(@"[IntegrationManagerVC] Received request to set plumbing state to status %@ in room %@.", requestData[@"status"], roomId);

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
                                       [self sendLocalisedError:@"widget_integration_failed_to_send_request" toRequest:requestId];
                                   }
                               }];
        }
        else
        {
            NSLog(@"[IntegrationManagerVC] setPlumbingState. Error: Plumbing state status should be a string.");
        }

    }];
}

- (void)getBotOptions:(NSString*)userId request:(NSString*)requestId data:(NSDictionary*)requestData
{
    NSLog(@"[IntegrationManagerVC] Received request to get options for bot %@ in room %@", userId, roomId);

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
    NSLog(@"[IntegrationManagerVC] Received request to set options for bot %@ in room %@", userId, roomId);

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
                                       [self sendLocalisedError:@"widget_integration_failed_to_send_request" toRequest:requestId];
                                   }
                               }];
        }
        else
        {
            NSLog(@"[IntegrationManagerVC] setBotOptions. Error: options should be a dict.");
        }
    }];
}

- (void)setBotPower:(NSString*)userId request:(NSString*)requestId data:(NSDictionary*)requestData
{
    NSLog(@"[IntegrationManagerVC] Received request to set power level to %@ for bot %@ in room %@.", requestData[@"level"], userId, roomId);

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
                    [self sendLocalisedError:@"widget_integration_failed_to_send_request" toRequest:requestId];
                }
            }];
        }
        else
        {
            NSLog(@"[IntegrationManagerVC] setBotPower. Power level must be positive integer.");
            [self sendLocalisedError:@"widget_integration_positive_power_level" toRequest:requestId];
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

@end
