/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "WidgetViewController.h"

#import "IntegrationManagerViewController.h"
#import "GeneratedInterface-Swift.h"

NSString *const kJavascriptSendResponseToPostMessageAPI = @"riotIOS.sendResponse('%@', %@);";

@interface WidgetViewController () <ServiceTermsModalCoordinatorBridgePresenterDelegate>

@property (nonatomic, strong) ServiceTermsModalCoordinatorBridgePresenter *serviceTermsModalCoordinatorBridgePresenter;
@property (nonatomic, strong) NSString *widgetUrl;

@property (nonatomic, strong) SlidingModalPresenter *slidingModalPresenter;

@end

@implementation WidgetViewController
@synthesize widget;

- (instancetype)initWithUrl:(NSString*)widgetUrl forWidget:(Widget*)theWidget
{
    // The opening of the url is delayed in viewWillAppear where we will check
    // the widget permission
    self = [super initWithURL:nil];
    if (self)
    {
        self.widgetUrl = widgetUrl;
        widget = theWidget;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    webView.scrollView.bounces = NO;

    // Disable opacity so that the webview background uses the current interface theme
    webView.opaque = NO;

    if (widget)
    {
        self.navigationItem.title = widget.name ? widget.name : widget.type;

        UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:AssetImages.roomContextMenuMore.image style:UIBarButtonItemStylePlain target:self action:@selector(onMenuButtonPressed:)];
        self.navigationItem.rightBarButtonItem = menuButton;
    }
    
    self.slidingModalPresenter = [SlidingModalPresenter new];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Check widget permission before opening the widget
    [self checkWidgetPermissionWithCompletion:^(BOOL granted) {
                
        [self.slidingModalPresenter dismissWithAnimated:YES completion:nil];
        
        if (granted)
        {
            self.URL = self.widgetUrl;
        }
        else
        {
            [self withdrawViewControllerAnimated:YES completion:nil];
        }
    }];
}

- (void)reloadWidget
{
    self.URL = self.widgetUrl;
}

- (BOOL)hasUserEnoughPowerToManageCurrentWidget
{
    BOOL hasUserEnoughPower = NO;

    MXSession *session = widget.mxSession;
    MXRoom *room = [session roomWithRoomId:self.widget.roomId];
    MXRoomState *roomState = room.dangerousSyncState;
    if (roomState)
    {
        // Check user's power in the room
        MXRoomPowerLevels *powerLevels = roomState.powerLevels;
        NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:session.myUser.userId];

        // The user must be able to send state events to manage widgets
        if (oneSelfPowerLevel >= powerLevels.stateDefault)
        {
            hasUserEnoughPower = YES;
        }
    }
    
    return hasUserEnoughPower;
}

- (void)removeCurrentWidget
{
    WidgetManager *widgetManager = [WidgetManager sharedManager];

    MXRoom *room = [self.widget.mxSession roomWithRoomId:self.widget.roomId];
    NSString *widgetId = self.widget.widgetId;
    if (room && widgetId)
    {
        [widgetManager closeWidget:widgetId inRoom:room success:^{
        } failure:^(NSError *error) {
            MXLogDebug(@"[WidgetVC] removeCurrentWidget failed. Error: %@", error);
        }];
    }
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
            title = [VectorL10n error];
        }
    }

    __weak __typeof__(self) weakSelf = self;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {

                                                typeof(self) self = weakSelf;

                                                if (self)
                                                {
                                                    // Leave this widget VC
                                                    [self withdrawViewControllerAnimated:YES completion:nil];
                                                }

                                            }]];

    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - Widget Permission

- (void)checkWidgetPermissionWithCompletion:(void (^)(BOOL granted))completion
{
    MXSession *session = widget.mxSession;

    if ([widget.widgetEvent.sender isEqualToString:session.myUser.userId])
    {
        // No need of more permission check if the user created the widget
        completion(YES);
        return;
    }

    // Check permission in user Riot settings
    __block RiotSharedSettings *sharedSettings = [[RiotSharedSettings alloc] initWithSession:session];

    WidgetPermission permission = [sharedSettings permissionFor:widget];
    if (permission == WidgetPermissionGranted)
    {
        completion(YES);
    }
    else
    {
        // Note: ask permission again if the user previously declined it
        [self askPermissionWithCompletion:^(BOOL granted) {
            // Update the settings in user account data in parallel
            [sharedSettings setPermission:granted ? WidgetPermissionGranted : WidgetPermissionDeclined
                                      for:self.widget
                                           success:^
             {
                 sharedSettings = nil;
             }
                                           failure:^(NSError * _Nullable error)
             {
                MXLogDebug(@"[WidgetVC] setPermissionForWidget failed. Error: %@", error);
                 sharedSettings = nil;
             }];

            completion(granted);
        }];
    }
}

- (void)askPermissionWithCompletion:(void (^)(BOOL granted))completion
{
    NSString *widgetCreatorUserId = self.widget.widgetEvent.sender ?: [VectorL10n roomParticipantsUnknown];
    
    MXSession *session = widget.mxSession;
    MXRoom *room = [session roomWithRoomId:self.widget.widgetEvent.roomId];
    MXRoomState *roomState = room.dangerousSyncState;
    MXRoomMember *widgetCreatorRoomMember = [roomState.members memberWithUserId:widgetCreatorUserId];
    
    NSString *widgetDomain = @"";
    
    if (widget.url)
    {
        NSString *host = [[NSURL alloc] initWithString:widget.url].host;
        if (host)
        {
            widgetDomain = host;
        }
    }
    
    MXMediaManager *mediaManager = widget.mxSession.mediaManager;
    NSString *widgetCreatorDisplayName = widgetCreatorRoomMember.displayname;
    NSString *widgetCreatorAvatarURL = widgetCreatorRoomMember.avatarUrl;
    
    NSArray<NSString*> *permissionStrings = @[
                                              [VectorL10n roomWidgetPermissionDisplayNamePermission],
                                              [VectorL10n roomWidgetPermissionAvatarUrlPermission],
                                              [VectorL10n roomWidgetPermissionUserIdPermission],
                                              [VectorL10n roomWidgetPermissionThemePermission],
                                              [VectorL10n roomWidgetPermissionWidgetIdPermission],
                                              [VectorL10n roomWidgetPermissionRoomIdPermission]
                                            ];
    
    
    WidgetPermissionViewModel *widgetPermissionViewModel = [[WidgetPermissionViewModel alloc] initWithCreatorUserId:widgetCreatorUserId
                                                                                                 creatorDisplayName:widgetCreatorDisplayName creatorAvatarUrl:widgetCreatorAvatarURL widgetDomain:widgetDomain
                                                                                                    isWebviewWidget:YES
                                                                                                  widgetPermissions:permissionStrings
                                                                                                       mediaManager:mediaManager];
    
    
    WidgetPermissionViewController *widgetPermissionViewController = [WidgetPermissionViewController instantiateWith:widgetPermissionViewModel];
    
    widgetPermissionViewController.didTapContinueButton = ^{
        completion(YES);
    };
    
    widgetPermissionViewController.didTapCloseButton = ^{
        completion(NO);
    };
        
    
    [self.slidingModalPresenter present:widgetPermissionViewController from:self animated:YES completion:nil];
}

- (void)revokePermissionForCurrentWidget
{
    MXSession *session = widget.mxSession;
    __block RiotSharedSettings *sharedSettings = [[RiotSharedSettings alloc] initWithSession:session];

    [sharedSettings setPermission:WidgetPermissionDeclined for:widget success:^{
        sharedSettings = nil;
    } failure:^(NSError * _Nullable error) {
        MXLogDebug(@"[WidgetVC] revokePermissionForCurrentWidget failed. Error: %@", error);
        sharedSettings = nil;
    }];
}


#pragma mark - Contextual Menu

- (IBAction)onMenuButtonPressed:(id)sender
{
    [self showMenu];
}

-(void)showMenu
{
    MXSession *session = widget.mxSession;

    UIAlertController *menu = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [menu addAction:[UIAlertAction actionWithTitle:[VectorL10n widgetMenuRefresh]
                                             style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action)
                     {
                         [self reloadWidget];
                     }]];

    NSURL *url = [NSURL URLWithString:self.widgetUrl];
    if (url && [[UIApplication sharedApplication] canOpenURL:url])
    {
        [menu addAction:[UIAlertAction actionWithTitle:[VectorL10n widgetMenuOpenOutside]
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action)
                         {
                             [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                             }];
                         }]];
    }

    if (![widget.widgetEvent.sender isEqualToString:session.myUser.userId])
    {
        [menu addAction:[UIAlertAction actionWithTitle:[VectorL10n widgetMenuRevokePermission]
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action)
                         {
                             [self revokePermissionForCurrentWidget];
                             [self withdrawViewControllerAnimated:YES completion:nil];
                         }]];
    }

    if ([self hasUserEnoughPowerToManageCurrentWidget])
    {
        [menu addAction:[UIAlertAction actionWithTitle:[VectorL10n widgetMenuRemove]
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action)
                         {
                             [self removeCurrentWidget];
                             [self withdrawViewControllerAnimated:YES completion:nil];
                         }]];
    }

    [menu addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                    style:UIAlertActionStyleCancel
                                                  handler:^(UIAlertAction * action) {
                                                  }]];

    [self presentViewController:menu animated:YES completion:nil];
}


#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self enableDebug];

    // Setup js code
    NSString *path = [[NSBundle mainBundle] pathForResource:@"postMessageAPI" ofType:@"js"];
    NSString *js = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [webView evaluateJavaScript:js completionHandler:nil];

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
                                                    NSLocalizedDescriptionKey : [VectorL10n networkOfflinePrompt]
                                                    }];
        [self showErrorAsAlert:error];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSString *urlString = navigationAction.request.URL.absoluteString;

    // TODO: We should use the WebKit PostMessage API and the
    // `didReceiveScriptMessage` delegate to manage the JS<->Native bridge
    if ([urlString hasPrefix:@"js:"])
    {
        // Listen only to the scheme of the JS<->Native bridge
        NSString *jsonString = [[[urlString componentsSeparatedByString:@"js:"] lastObject] stringByRemovingPercentEncoding];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

        NSError *error;
        NSDictionary *parameters = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers
                                                                     error:&error];
        if (!error)
        {
            // Retrieve the js event payload data
            NSDictionary *eventData;
            MXJSONModelSetDictionary(eventData, parameters[@"event.data"]);

            NSString *requestId;
            MXJSONModelSetString(requestId, eventData[@"_id"]);

            if (requestId)
            {
                [self onPostMessageRequest:requestId data:eventData];
            }
            else
            {
                MXLogDebug(@"[WidgetVC] shouldStartLoadWithRequest: ERROR: Missing request id in postMessage API %@", parameters);
            }
        }

        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    if (navigationAction.navigationType == WKNavigationTypeLinkActivated)
    {
        NSURL *linkURL = navigationAction.request.URL;
        
        // Open links outside the app
        [[UIApplication sharedApplication] vc_open:linkURL completionHandler:^(BOOL success) {
            if (!success)
            {
                MXLogDebug(@"[WidgetVC] webView:decidePolicyForNavigationAction:decisionHandler fail to open external link: %@", linkURL);
            }
        }];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    // Filter out the users's scalar token
    NSString *errorDescription = error.description;
    errorDescription = [self stringByReplacingScalarTokenInString:errorDescription byScalarToken:@"..."];

    MXLogDebug(@"[WidgetVC] didFailLoadWithError: %@", errorDescription);

    [self stopActivityIndicator];
    [self showErrorAsAlert:error];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {

    if ([navigationResponse.response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse * response = (NSHTTPURLResponse *)navigationResponse.response;
        if (response.statusCode != 200)
        {
            MXLogDebug(@"[WidgetVC] decidePolicyForNavigationResponse: statusCode: %@", @(response.statusCode));
        }

        if (response.statusCode == 403 && [[WidgetManager sharedManager] isScalarUrl:self.URL forUser:self.widget.mxSession.myUser.userId])
        {
            [self fixScalarToken];
        }
    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}

#pragma mark - postMessage API

- (void)onPostMessageRequest:(NSString*)requestId data:(NSDictionary*)requestData
{
    NSString *action;
    MXJSONModelSetString(action, requestData[@"action"]);

    if ([@"m.sticker" isEqualToString:action])
    {
        // Extract the sticker event content and send it as is

        // The key should be "data" according to https://docs.google.com/document/d/1uPF7XWY_dXTKVKV7jZQ2KmsI19wn9-kFRgQ1tFQP7wQ/edit?usp=sharing
        // TODO: Fix it once spec is finalised
        NSDictionary *widgetData;
        NSDictionary *stickerContent;
        MXJSONModelSetDictionary(widgetData, requestData[@"widgetData"]);
        if (widgetData)
        {
            MXJSONModelSetDictionary(stickerContent, widgetData[@"content"]);
        }

        if (stickerContent)
        {
            // Let the data source manage the sending cycle
            [_roomDataSource sendEventOfType:kMXEventTypeStringSticker content:stickerContent success:nil failure:nil];
        }
        else
        {
            MXLogDebug(@"[WidgetVC] onPostMessageRequest: ERROR: Invalid content for m.sticker: %@", requestData);
        }

        // Consider we are done with the sticker picker widget
        [self withdrawViewControllerAnimated:YES completion:nil];
    }
    else if ([@"integration_manager_open" isEqualToString:action])
    {
        NSDictionary *widgetData;
        NSString *integType, *integId;
        MXJSONModelSetDictionary(widgetData, requestData[@"widgetData"]);
        if (widgetData)
        {
            MXJSONModelSetString(integType, widgetData[@"integType"]);
            MXJSONModelSetString(integId, widgetData[@"integId"]);
        }

        if (integType && integId)
        {
            // Open the integration manager requested page
            IntegrationManagerViewController *modularVC = [[IntegrationManagerViewController alloc]
                                                           initForMXSession:self.roomDataSource.mxSession
                                                           inRoom:self.roomDataSource.roomId
                                                           screen:[IntegrationManagerViewController screenForWidget:integType]
                                                           widgetId:integId];

            [self presentViewController:modularVC animated:NO completion:nil];
        }
        else
        {
            MXLogDebug(@"[WidgetVC] onPostMessageRequest: ERROR: Invalid content for integration_manager_open: %@", requestData);
        }
    }
    else
    {
        MXLogDebug(@"[WidgetVC] onPostMessageRequest: ERROR: Unsupported action: %@: %@", action, requestData);
    }
}

- (void)sendBoolResponse:(BOOL)response toRequest:(NSString*)requestId
{
    // Convert BOOL to "true" or "false"
    NSString *js = [NSString stringWithFormat:kJavascriptSendResponseToPostMessageAPI,
                    requestId,
                    response ? @"true" : @"false"];

    [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)sendIntegerResponse:(NSUInteger)response toRequest:(NSString*)requestId
{
    NSString *js = [NSString stringWithFormat:kJavascriptSendResponseToPostMessageAPI,
                    requestId,
                    @(response)];

    [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)sendNSObjectResponse:(NSObject*)response toRequest:(NSString*)requestId
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

    NSString *js = [NSString stringWithFormat:kJavascriptSendResponseToPostMessageAPI,
                    requestId,
                    jsString];

    [webView evaluateJavaScript:js completionHandler:nil];
}

- (void)sendError:(NSString*)message toRequest:(NSString*)requestId
{
    MXLogDebug(@"[WidgetVC] sendError: Action %@ failed with message: %@", requestId, message);

    // TODO: JS has an additional optional parameter: nestedError
    [self sendNSObjectResponse:@{
                                 @"error": @{
                                         @"message": message
                                         }
                                 }
                       toRequest:requestId];
}

#pragma mark - Private methods

- (NSString *)stringByReplacingScalarTokenInString:(NSString*)string byScalarToken:(NSString*)scalarToken
{
    if (!string)
    {
        return nil;
    }

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"scalar_token=\\w*"
                                                                           options:NSRegularExpressionCaseInsensitive error:nil];
    return [regex stringByReplacingMatchesInString:string
                                           options:0
                                             range:NSMakeRange(0, string.length)
                                      withTemplate:[NSString stringWithFormat:@"scalar_token=%@", scalarToken]];
}

/**
 Reset the scalar token used in the webview URL.
 */
- (void)fixScalarToken
{
    MXLogDebug(@"[WidgetVC] fixScalarToken");

    self->webView.hidden = YES;

    // Get a fresh new scalar token
    [WidgetManager.sharedManager deleteDataForUser:widget.mxSession.myUser.userId];

    MXWeakify(self);
    [WidgetManager.sharedManager getScalarTokenForMXSession:widget.mxSession validate:NO success:^(NSString *scalarToken) {
        MXStrongifyAndReturnIfNil(self);

        MXLogDebug(@"[WidgetVC] fixScalarToken: DONE");
        [self loadDataWithScalarToken:scalarToken];

    } failure:^(NSError *error) {
        MXLogDebug(@"[WidgetVC] fixScalarToken: Error: %@", error);

        if ([error.domain isEqualToString:WidgetManagerErrorDomain]
            && error.code == WidgetManagerErrorCodeTermsNotSigned)
        {
            [self presentTerms];
        }
        else
        {
            [self showErrorAsAlert:error];
        }
    }];
}

- (void)loadDataWithScalarToken:(NSString*)scalarToken
{
    self.URL = [self stringByReplacingScalarTokenInString:self.URL byScalarToken:scalarToken];

    self->webView.hidden = NO;
}



#pragma mark - Service terms

- (void)presentTerms
{
    if (self.serviceTermsModalCoordinatorBridgePresenter)
    {
        return;
    }
    
    WidgetManagerConfig *config =  [[WidgetManager sharedManager] configForUser:widget.mxSession.myUser.userId];

    MXLogDebug(@"[WidgetVC] presentTerms for %@", config.baseUrl);

    ServiceTermsModalCoordinatorBridgePresenter *serviceTermsModalCoordinatorBridgePresenter = [[ServiceTermsModalCoordinatorBridgePresenter alloc] initWithSession:widget.mxSession baseUrl:config.baseUrl
                                                                                                                                                        serviceType:MXServiceTypeIntegrationManager
                                                                                                                                                        accessToken:config.scalarToken];
    serviceTermsModalCoordinatorBridgePresenter.delegate = self;

    [serviceTermsModalCoordinatorBridgePresenter presentFrom:self animated:YES];
    self.serviceTermsModalCoordinatorBridgePresenter = serviceTermsModalCoordinatorBridgePresenter;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidAccept:(ServiceTermsModalCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    MXWeakify(self);
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        MXStrongifyAndReturnIfNil(self);

        WidgetManagerConfig *config = [[WidgetManager sharedManager] configForUser:self->widget.mxSession.myUser.userId];
        [self loadDataWithScalarToken:config.scalarToken];
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
