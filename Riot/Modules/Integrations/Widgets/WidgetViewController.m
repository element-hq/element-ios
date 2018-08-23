/*
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd

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

#import "WidgetViewController.h"

#import "AppDelegate.h"
#import "IntegrationManagerViewController.h"

NSString *const kJavascriptSendResponseToPostMessageAPI = @"riotIOS.sendResponse('%@', %@);";

@interface WidgetViewController ()

@end

@implementation WidgetViewController
@synthesize widget;

- (instancetype)initWithUrl:(NSString*)widgetUrl forWidget:(Widget*)theWidget
{
    self = [super initWithURL:widgetUrl];
    if (self)
    {
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
                                                    // Leave this widget VC
                                                    [self withdrawViewControllerAnimated:YES completion:nil];
                                                }

                                            }]];

    [self presentViewController:alert animated:YES completion:nil];
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
                                                    NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"network_offline_prompt", @"Vector", nil)
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
                NSLog(@"[WidgetVC] shouldStartLoadWithRequest: ERROR: Missing request id in postMessage API %@", parameters);
            }
        }

        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    if (navigationAction.navigationType == WKNavigationTypeLinkActivated)
    {
        // Open links outside the app
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    // Filter out the users's scalar token
    NSString *errorDescription = error.description;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"scalar_token=\\w*"
                                                                           options:NSRegularExpressionCaseInsensitive error:nil];
    errorDescription = [regex stringByReplacingMatchesInString:errorDescription
                                                       options:0
                                                         range:NSMakeRange(0, errorDescription.length)
                                                  withTemplate:@"scalar_token=..."];

    NSLog(@"[WidgetVC] didFailLoadWithError: %@", errorDescription);

    [self stopActivityIndicator];
    [self showErrorAsAlert:error];
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
            NSLog(@"[WidgetVC] onPostMessageRequest: ERROR: Invalid content for m.sticker: %@", requestData);
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
            NSLog(@"[WidgetVC] onPostMessageRequest: ERROR: Invalid content for integration_manager_open: %@", requestData);
        }
    }
    else
    {
        NSLog(@"[WidgetVC] onPostMessageRequest: ERROR: Unsupported action: %@: %@", action, requestData);
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
    NSLog(@"[WidgetVC] sendError: Action %@ failed with message: %@", requestId, message);

    // TODO: JS has an additional optional parameter: nestedError
    [self sendNSObjectResponse:@{
                                 @"error": @{
                                         @"message": message
                                         }
                                 }
                       toRequest:requestId];
}

- (void)sendLocalisedError:(NSString*)errorKey toRequest:(NSString*)requestId
{
    [self sendError:NSLocalizedStringFromTable(errorKey, @"Vector", nil) toRequest:requestId];
}

@end
