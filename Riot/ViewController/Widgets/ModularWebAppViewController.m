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

#import "ModularWebAppViewController.h"

#import "WidgetManager.h"

NSString *kJavascriptSendResponseToModular = @"riotIOS.sendResponse('%@', %@);";


@interface ModularWebAppViewController ()
{
    MXSession *mxSession;
    NSString *roomId;
    NSString *screen;
    NSString *widgetId;
    NSString *scalarToken;

    MXHTTPOperation *operation;
}

@end

@implementation ModularWebAppViewController

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
                [self stopActivityIndicator];

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

#pragma mark - UIWebViewDelegate

-(void)webViewDidFinishLoad:(UIWebView *)theWebView
{
    // Setup js code
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ModularWebApp" ofType:@"js"];
    NSString *js = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [webView stringByEvaluatingJavaScriptFromString:js];
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

        NSLog(@"++++ parameters: %@", parameters);

        if (!error)
        {
            NSDictionary *eventData;
            MXJSONModelSetDictionary(eventData, parameters[@"event.data"]);

            NSString *roomIdInEvent, *userId, *action;

            MXJSONModelSetString(roomIdInEvent, eventData[@"room_id"]);
            MXJSONModelSetString(userId, eventData[@"user_id"]);
            MXJSONModelSetString(action, eventData[@"action"]);

            if (!roomIdInEvent)
            {
                //sendError(event, _t('Missing room_id in request'));
                return NO;
            }

            if (![roomIdInEvent isEqualToString:roomId])
            {
                //sendError(event, _t('Room %(roomId)s not visible', {roomId: roomId}));
                return NO;
            }


            // These APIs don't require userId
            if ([@"join_rules_state" isEqualToString:action])
            {
                //getJoinRules(event, roomId);
            }
            else if ([@"set_plumbing_state" isEqualToString:action])
            {
                //setPlumbingState(event, roomId, event.data.status);
            }
            else if ([@"get_membership_count" isEqualToString:action])
            {
                //getMembershipCount(event, roomId);
            }
            else if ([@"set_widget" isEqualToString:action])
            {
                //setWidget(event, roomId);
            }
            else if ([@"get_widgets" isEqualToString:action])
            {
                //getWidgets(event, roomId);
            }
            else if ([@"can_send_event" isEqualToString:action])
            {
                [self canSendEvent:eventData];
                //canSendEvent(event, roomId);
            }


            if (!userId)
            {
                //sendError(event, _t('Missing user_id in request'));
                return NO;
            }

            if ([@"membership_state" isEqualToString:action])
            {
                //getMembershipState(event, roomId, userId);
            }
            else if ([@"invite" isEqualToString:action])
            {
                //inviteUser(event, roomId, userId);
            }
            else if ([@"bot_options" isEqualToString:action])
            {
                //botOptions(event, roomId, userId);
            }
            else if ([@"set_bot_options" isEqualToString:action])
            {
                //setBotOptions(event, roomId, userId);
            }
            else if ([@"set_bot_power" isEqualToString:action])
            {
                //setBotPower(event, roomId, userId, event.data.level);
            }
            else
            {
                NSLog(@"[ModularWebAppViewController] Unhandled postMessage event with action %@: %@", action, parameters);
            }
        }
        return NO;
    }
    return YES;
}

- (void)sendBoolResponse:(BOOL)response toEvent:(NSDictionary*)eventData
{
    NSString *js = [NSString stringWithFormat:kJavascriptSendResponseToModular,
                    eventData[@"_id"],
                    response ? @"true" : @"false"];

    [webView stringByEvaluatingJavaScriptFromString:js];
}

#pragma mark - Modular postMessage API

- (MXRoom *)roomCheckWithEvent:(NSDictionary*)eventData
{
    MXRoom *room = [mxSession roomWithRoomId:roomId];
    if (!room)
    {
        //sendError(event, _t('This room is not recognised.'));
    }

    return room;
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
            // sendError(event, _t('You are not in this room.'));
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
            //sendError(event, _t('You do not have permission to do that in this room.'));
        }
    }
}

@end
