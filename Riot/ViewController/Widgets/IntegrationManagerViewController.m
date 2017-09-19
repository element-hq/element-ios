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
#import "AppDelegate.h"

#import <JavaScriptCore/JavaScriptCore.h>

NSString *const kIntegrationManagerMainScreen = nil;
NSString *const kIntegrationManagerAddIntegrationScreen = @"add_integ";

NSString *const kJavascriptSendResponseToModular = @"riotIOS.sendResponse('%@', %@);";


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

- (void)destroy
{
    [super destroy];

    [operation cancel];
    operation = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    webView.scalesPageToFit = NO;
    webView.scrollView.bounces = NO;

    webView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!self.URL && !operation)
    {
        __weak __typeof__(self) weakSelf = self;

        [self startActivityIndicator];

        // Make sure we a scalar token
        operation = [[WidgetManager sharedManager] getScalarTokenForMXSession:mxSession success:^(NSString *theScalarToken) {

            typeof(self) self = weakSelf;

            if (self)
            {
                self->operation = nil;

                scalarToken = theScalarToken;

                // Launch the webview on the right modular webapp page
                self.URL = [self interfaceUrl];
            }

        } failure:^(NSError *error) {

            typeof(self) self = weakSelf;
            
            if (self)
            {
                self->operation = nil;
                [self stopActivityIndicator];
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

- (void)enableDebug
{
    // Setup console.log() -> NSLog() route
    JSContext *ctx = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    ctx[@"console"][@"log"] = ^(JSValue * msg) {
        NSLog(@"-- JavaScript: %@", msg);
    };

    // Redirect all console.* logging methods to console.log
    [webView stringByEvaluatingJavaScriptFromString:@"console.debug = console.log; console.info = console.log; console.warn = console.log; console.error = console.log;"];
}

- (void)showErrorAsAlert:(NSError*)error
{
    NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    if (!title)
    {
        if (msg)
        {
            title = msg;
            msg = nil;
        }
        else
        {
            title = [NSBundle mxk_localizedStringForKey:@"error"];
        }
    }

    __weak __typeof__(self) weakSelf = self;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {

                                                typeof(self) self = weakSelf;

                                                if (self)
                                                {
                                                    // Leave this Intergrations Manager VC
                                                    [self withdrawViewControllerAnimated:YES completion:nil];
                                                }

                                            }]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UIWebViewDelegate

-(void)webViewDidFinishLoad:(UIWebView *)theWebView
{
    [self enableDebug];

    // Setup js code
    NSString *path = [[NSBundle mainBundle] pathForResource:@"IntegrationManager" ofType:@"js"];
    NSString *js = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [webView stringByEvaluatingJavaScriptFromString:js];

    [self stopActivityIndicator];

    // Check connectivity
    if ([AppDelegate theDelegate].isOffline)
    {
        // The web page may be in the cache, so its loading will be successful
        // but we cannot go further, it often leads to a blank screen.
        // So, display an error so that the user can escape.
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                             code:NSURLErrorNotConnectedToInternet
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"network_offline_prompt", @"Vector", nil)
                                                    }];
        [self showErrorAsAlert:error];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *urlString = [[request URL] absoluteString];

    if ([urlString hasPrefix:@"js:"])
    {
        // Listen only to scheme of the JS-UIWebView bridge
        NSString *jsonString = [[[urlString componentsSeparatedByString:@"js:"] lastObject]  stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

        NSError *error;
        NSDictionary *parameters = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers
                                                                     error:&error];
        if (!error)
        {
            [self onMessage:parameters];
        }

        return NO;
    }

    if (navigationType == UIWebViewNavigationTypeLinkClicked )
    {
        // Open links outside the app
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }

    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // Filter out the users's scalar token
    NSString *errorDescription = error.description;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"scalar_token=\\w*"
                                                                           options:NSRegularExpressionCaseInsensitive error:nil];
    errorDescription = [regex stringByReplacingMatchesInString:errorDescription
                                                       options:0
                                                         range:NSMakeRange(0, errorDescription.length)
                                                  withTemplate:@"scalar_token=..."];

    NSLog(@"[IntegrationManagerVC] didFailLoadWithError: %@", errorDescription);

    [self stopActivityIndicator];
    [self showErrorAsAlert:error];
}

#pragma mark - Modular postMessage API

- (void)onMessage:(NSDictionary*)JSData
{
    NSDictionary *eventData;
    MXJSONModelSetDictionary(eventData, JSData[@"event.data"]);

    NSString *roomIdInEvent, *userId, *action;

    MXJSONModelSetString(roomIdInEvent, eventData[@"room_id"]);
    MXJSONModelSetString(userId, eventData[@"user_id"]);
    MXJSONModelSetString(action, eventData[@"action"]);

    if ([action isEqualToString:@"close_scalar"])
    {
        [self withdrawViewControllerAnimated:YES completion:nil];
        return;
    }

    if (!roomIdInEvent)
    {
        [self sendLocalisedError:@"widget_integration_missing_room_id" toEvent:eventData];
        return;
    }

    if (![roomIdInEvent isEqualToString:roomId])
    {
        [self sendError:[NSString stringWithFormat:NSLocalizedStringFromTable(@"widget_integration_room_not_visible", @"Vector", nil), roomIdInEvent] toEvent:eventData];
        return;
    }


    // These APIs don't require userId
    if ([@"join_rules_state" isEqualToString:action])
    {
        [self getJoinRules:eventData];
        return;
    }
    else if ([@"set_plumbing_state" isEqualToString:action])
    {
        [self setPlumbingState:eventData];
        return;
    }
    else if ([@"get_membership_count" isEqualToString:action])
    {
        [self getMembershipCount:eventData];
        return;
    }
    else if ([@"set_widget" isEqualToString:action])
    {
        [self setWidget:eventData];
        return;
    }
    else if ([@"get_widgets" isEqualToString:action])
    {
        [self getWidgets:eventData];
        return;
    }
    else if ([@"can_send_event" isEqualToString:action])
    {
        [self canSendEvent:eventData];
        return;
    }


    if (!userId)
    {
        [self sendLocalisedError:@"widget_integration_missing_user_id" toEvent:eventData];
        return;
    }

    if ([@"membership_state" isEqualToString:action])
    {
        [self getMembershipState:userId eventData:eventData];
    }
    else if ([@"invite" isEqualToString:action])
    {
        [self inviteUser:userId eventData:eventData];
    }
    else if ([@"bot_options" isEqualToString:action])
    {
        [self getBotOptions:userId eventData:eventData];
    }
    else if ([@"set_bot_options" isEqualToString:action])
    {
        [self setBotOptions:userId eventData:eventData];
    }
    else if ([@"set_bot_power" isEqualToString:action])
    {
        [self setBotPower:userId eventData:eventData];
    }
    else
    {
        NSLog(@"[IntegrationManagerViewControllerVC] Unhandled postMessage event with action %@: %@", action, JSData);
    }
}

- (void)sendBoolResponse:(BOOL)response toEvent:(NSDictionary*)eventData
{
    // Convert BOOL to "true" or "false"
    NSString *js = [NSString stringWithFormat:kJavascriptSendResponseToModular,
                    eventData[@"_id"],
                    response ? @"true" : @"false"];

    [webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)sendIntegerResponse:(NSUInteger)response toEvent:(NSDictionary*)eventData
{
    NSString *js = [NSString stringWithFormat:kJavascriptSendResponseToModular,
                    eventData[@"_id"],
                    @(response)];

    [webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)sendNSObjectResponse:(NSObject*)response toEvent:(NSDictionary*)eventData
{
    NSString *jsString;

    if (response)
    {
        // Convert response into a JS object through a JSON string
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:response
                                                           options:0
                                                             error:0];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        jsString = [NSString stringWithFormat:@"JSON.parse('%@')", jsonString];
    }
    else
    {
        jsString = @"null";
    }

    NSString *js = [NSString stringWithFormat:kJavascriptSendResponseToModular,
                    eventData[@"_id"],
                    jsString];

    [webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)sendError:(NSString*)message toEvent:(NSDictionary*)eventData
{
    NSLog(@"[IntegrationManagerVC] sendError: Action %@ failed with message: %@", eventData[@"action"], message);

    // TODO: JS has an additional optional parameter: nestedError
    [self sendNSObjectResponse:@{
                                 @"error": @{
                                         @"message": message
                                         }
                                 }
                       toEvent:eventData];
}

- (void)sendLocalisedError:(NSString*)errorKey toEvent:(NSDictionary*)eventData
{
    [self sendError:NSLocalizedStringFromTable(errorKey, @"Vector", nil) toEvent:eventData];
}

#pragma mark - Modular postMessage Implementation

- (MXRoom *)roomCheckWithEvent:(NSDictionary*)eventData
{
    MXRoom *room = [mxSession roomWithRoomId:roomId];
    if (!room)
    {
        [self sendLocalisedError:@"widget_integration_room_not_recognised" toEvent:eventData];
    }

    return room;
}

- (void)inviteUser:(NSString*)userId eventData:(NSDictionary*)eventData
{
    NSLog(@"[IntegrationManagerVC] Received request to invite %@ into room %@.", userId, roomId);

    MXRoom *room = [self roomCheckWithEvent:eventData];
    
    if (room)
    {
        MXRoomMember *member = [room.state memberWithUserId:userId];
        if (member && member.membership == MXMembershipJoin)
        {
            [self sendNSObjectResponse:@{
                                         @"success": @(YES)
                                         }
                               toEvent:eventData];
        }
        else
        {
            __weak __typeof__(self) weakSelf = self;

            [room inviteUser:userId success:^{

                typeof(self) self = weakSelf;
                if (self)
                {
                    [self sendNSObjectResponse:@{
                                                 @"success": @(YES)
                                                 }
                                       toEvent:eventData];
                }

            } failure:^(NSError *error) {

                typeof(self) self = weakSelf;
                if (self)
                {
                    [self sendLocalisedError:@"widget_integration_need_to_be_able_to_invite" toEvent:eventData];
                }
            }];
        }
    }
}

- (void)setWidget:(NSDictionary*)eventData
{
    NSLog(@"[IntegrationManagerVC] Received request to set widget in room %@.", roomId);

    MXRoom *room = [self roomCheckWithEvent:eventData];

    if (room)
    {
        NSString *widget_id, *widgetType, *widgetUrl;
        NSString *widgetName; // optional
        NSDictionary *widgetData ; // optional

        MXJSONModelSetString(widget_id, eventData[@"widget_id"]);
        MXJSONModelSetString(widgetType, eventData[@"type"]);
        MXJSONModelSetString(widgetUrl, eventData[@"url"]);
        MXJSONModelSetString(widgetName, eventData[@"name"]);
        MXJSONModelSetDictionary(widgetData, eventData[@"data"]);

        if (!widget_id)
        {
            [self sendLocalisedError:@"widget_integration_unable_to_create" toEvent:eventData]; // new Error("Missing required widget fields."));
            return;
        }

        NSMutableDictionary *widgetEventContent = [NSMutableDictionary dictionary];
        if (widgetUrl)
        {
            if (!widgetType)
            {
                [self sendLocalisedError:@"widget_integration_unable_to_create" toEvent:eventData];
                return;
            }

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

        __weak __typeof__(self) weakSelf = self;

        [room sendStateEventOfType:kWidgetEventTypeString
                           content:widgetEventContent
                          stateKey:widget_id
                           success:^(NSString *eventId) {

                               typeof(self) self = weakSelf;
                               if (self)
                               {
                                   [self sendNSObjectResponse:@{
                                                                @"success": @(YES)
                                                                }
                                                      toEvent:eventData];
                               }
                           }
                           failure:^(NSError *error) {

                               typeof(self) self = weakSelf;
                               if (self)
                               {
                                   [self sendLocalisedError:@"widget_integration_failed_to_send_request" toEvent:eventData];
                               }
                           }];
    }
}

- (void)getWidgets:(NSDictionary*)eventData
{
    MXRoom *room = [self roomCheckWithEvent:eventData];

    if (room)
    {
        NSArray<Widget*> *widgets = [[WidgetManager sharedManager] widgetsInRoom:room];

        NSMutableArray<NSDictionary*> *widgetStateEvents = [NSMutableArray arrayWithCapacity:widgets.count];

        for (Widget *widget in widgets)
        {
            [widgetStateEvents addObject:widget.widgetEvent.JSONDictionary];
        }

        [self sendNSObjectResponse:widgetStateEvents toEvent:eventData];
    }
}

- (void)canSendEvent:(NSDictionary*)eventData
{
    NSString *eventType;
    BOOL isState = NO;

    MXRoom *room = [self roomCheckWithEvent:eventData];

    if (room)
    {
        if (room.state.membership != MXMembershipJoin)
        {
            [self sendLocalisedError:@"widget_integration_must_be_in_room" toEvent:eventData];
            return;
        }

        MXJSONModelSetString(eventType, eventData[@"event_type"]);
        MXJSONModelSetBoolean(isState, eventData[@"is_state"]);

        MXRoomPowerLevels *powerLevels = room.state.powerLevels;
        NSInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:mxSession.myUser.userId];

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
            [self sendBoolResponse:YES toEvent:eventData];
        }
        else
        {
            [self sendLocalisedError:@"widget_integration_no_permission_in_room" toEvent:eventData];
        }
    }
}

- (void)getMembershipState:(NSString*)userId eventData:(NSDictionary*)eventData
{
    NSLog(@"[IntegrationManagerVC] membership_state of %@ in room %@ requested.", userId, roomId);

    MXRoom *room = [self roomCheckWithEvent:eventData];
    if (room)
    {
        MXRoomMember *member = [room.state memberWithUserId:userId];
        [self sendNSObjectResponse:member.originalEvent.content toEvent:eventData];
    }
}

- (void)getJoinRules:(NSDictionary*)eventData
{
    NSLog(@"[IntegrationManagerVC] join_rules of %@ requested.", roomId);

    MXRoom *room = [self roomCheckWithEvent:eventData];
    if (room)
    {
        MXEvent *event = [room.state stateEventsWithType:kMXEventTypeStringRoomJoinRules].lastObject;
        [self sendNSObjectResponse:event.JSONDictionary toEvent:eventData];
    }
}

- (void)setPlumbingState:(NSDictionary*)eventData
{
    NSLog(@"[IntegrationManagerVC] Received request to set plumbing state to status %@ in room %@.", eventData[@"status"], roomId);

    MXRoom *room = [self roomCheckWithEvent:eventData];
    if (room)
    {
        NSString *status;
        MXJSONModelSetString(status, eventData[@"status"]);

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
                                                          toEvent:eventData];
                                   }
                               }
                               failure:^(NSError *error) {

                                   typeof(self) self = weakSelf;
                                   if (self)
                                   {
                                       [self sendLocalisedError:@"widget_integration_failed_to_send_request" toEvent:eventData];
                                   }
                               }];
        }
        else
        {
            NSLog(@"[IntegrationManagerVC] setPlumbingState. Error: Plumbing state status should be a string.");
        }
    }
}

- (void)getBotOptions:(NSString*)userId eventData:(NSDictionary*)eventData
{
    NSLog(@"[IntegrationManagerVC] Received request to get options for bot %@ in room %@", userId, roomId);

    MXRoom *room = [self roomCheckWithEvent:eventData];
    if (room)
    {
        NSString *stateKey = [NSString stringWithFormat:@"_%@", userId];

        NSArray<MXEvent*> *stateEvents = [room.state stateEventsWithType:kMXEventTypeStringRoomBotOptions];

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

        [self sendNSObjectResponse:botOptionsEvent.JSONDictionary toEvent:eventData];
    }
}

- (void)setBotOptions:(NSString*)userId eventData:(NSDictionary*)eventData
{
    NSLog(@"[IntegrationManagerVC] Received request to set options for bot %@ in room %@", userId, roomId);

    MXRoom *room = [self roomCheckWithEvent:eventData];
    if (room)
    {
        NSDictionary *content;
        MXJSONModelSetDictionary(content, eventData[@"content"]);

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
                                                          toEvent:eventData];
                                   }
                               }
                               failure:^(NSError *error) {

                                   typeof(self) self = weakSelf;
                                   if (self)
                                   {
                                       [self sendLocalisedError:@"widget_integration_failed_to_send_request" toEvent:eventData];
                                   }
                               }];
        }
        else
        {
            NSLog(@"[IntegrationManagerVC] setBotOptions. Error: options should be a dict.");
        }
    }
}

- (void)setBotPower:(NSString*)userId eventData:(NSDictionary*)eventData
{
    NSLog(@"[IntegrationManagerVC] Received request to set power level to %@ for bot %@ in room %@.", eventData[@"level"], userId, roomId);

    MXRoom *room = [self roomCheckWithEvent:eventData];
    if (room)
    {
        NSInteger level = -1;
        MXJSONModelSetInteger(level, eventData[@"level"]);

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
                                       toEvent:eventData];
                }

            } failure:^(NSError *error) {

                typeof(self) self = weakSelf;
                if (self)
                {
                    [self sendLocalisedError:@"widget_integration_failed_to_send_request" toEvent:eventData];
                }
            }];
        }
        else
        {
            NSLog(@"[IntegrationManagerVC] setBotPower. Power level must be positive integer.");
            [self sendLocalisedError:@"widget_integration_positive_power_level" toEvent:eventData];
        }
    }
}

- (void)getMembershipCount:(NSDictionary*)eventData
{
    MXRoom *room = [self roomCheckWithEvent:eventData];
    if (room)
    {
        NSUInteger membershipCount = room.state.joinedMembers.count;
        [self sendIntegerResponse:membershipCount toEvent:eventData];
    }
}

@end
