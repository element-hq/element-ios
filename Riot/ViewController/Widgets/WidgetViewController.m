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

#import "WidgetViewController.h"

#import "AppDelegate.h"

NSString *const kJavascriptSendResponseToModular = @"riotIOS.sendResponse('%@', %@);";

@interface WidgetViewController ()
{
    Widget  *widget;
}

@end

@implementation WidgetViewController

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

    webView.scalesPageToFit = NO;
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

#pragma mark - UIWebViewDelegate

-(void)webViewDidFinishLoad:(UIWebView *)theWebView
{
    [self enableDebug];

    // Setup js code
    NSString *path = [[NSBundle mainBundle] pathForResource:@"postMessageAPI" ofType:@"js"];
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

    NSLog(@"[WidgetVC] didFailLoadWithError: %@", errorDescription);

    [self stopActivityIndicator];
    [self showErrorAsAlert:error];
}

#pragma mark - postMessage API

- (void)onMessage:(NSDictionary*)JSData
{
    // @TODO
    NSDictionary *eventData;
    MXJSONModelSetDictionary(eventData, JSData[@"event.data"]);
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
    NSLog(@"[WidgetVC] sendError: Action %@ failed with message: %@", eventData[@"action"], message);

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

@end
