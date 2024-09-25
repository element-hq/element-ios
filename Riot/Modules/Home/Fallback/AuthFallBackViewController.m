/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "AuthFallBackViewController.h"
#import "GeneratedInterface-Swift.h"

// Generic method to make a bridge between JS and the WKWebView
NSString *FallBackViewControllerJavascriptSendObjectMessage = @"window.sendObjectMessage = function(parameters) {   \
    var iframe = document.createElement('iframe');                              \
    iframe.setAttribute('src', 'js:' + JSON.stringify(parameters));             \
    \
    document.documentElement.appendChild(iframe);                               \
    iframe.parentNode.removeChild(iframe);                                      \
    iframe = null;                                                              \
};";

// The function the fallback page calls when the registration is complete
NSString *FallBackViewControllerJavascriptOnRegistered = @"window.matrixRegistration.onRegistered = function(homeserverUrl, userId, accessToken) {   \
    sendObjectMessage({                     \
        'action': 'onRegistered',           \
        'homeServer': homeserverUrl,        \
        'userId': userId,                   \
        'accessToken': accessToken          \
    });                                     \
};";

// The function the fallback page calls when the login is complete
NSString *FallBackViewControllerJavascriptOnLogin = @"window.matrixLogin.onLogin = function(response) {   \
    sendObjectMessage({             \
        'action': 'onLogin',        \
        'response': response        \
    });                            \
};";

@interface AuthFallBackViewController ()

@end

@implementation AuthFallBackViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Catch js logs
    [self enableDebug];
    
    // Due to https://developers.googleblog.com/2016/08/modernizing-oauth-interactions-in-native-apps.html, we hack
    // the user agent to bypass the limitation of Google, as a quick fix (a proper solution will be to use the SSO SDK)
    webView.customUserAgent = @"Mozilla/5.0";

    [self clearCookies];
}

- (void)clearCookies
{
    // TODO: it would be better to do that at WKWebView init like below
    // but this code is part of the kit
    // WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    // config.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];
    // webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:config];

    WKWebsiteDataStore *dateStore = [WKWebsiteDataStore defaultDataStore];
    [dateStore fetchDataRecordsOfTypes:[WKWebsiteDataStore allWebsiteDataTypes]
                     completionHandler:^(NSArray<WKWebsiteDataRecord *> * __nonnull records)
     {
         for (WKWebsiteDataRecord *record  in records)
         {
             [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:record.dataTypes
                                                       forDataRecords:@[record]
                                                    completionHandler:^
              {
                 MXLogDebug(@"[AuthFallBackViewController] clearCookies: Cookies for %@ deleted successfully", record.displayName);
              }];
         }
     }];
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

    MXWeakify(self);

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                MXStrongifyAndReturnIfNil(self);

                                                if (self.delegate)
                                                {
                                                    [self.delegate authFallBackViewControllerDidClose:self];
                                                }

                                            }]];

    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [super webView:webView didFinishNavigation:navigation];

    // Set up JS <-> iOS bridge
    [webView evaluateJavaScript:FallBackViewControllerJavascriptSendObjectMessage completionHandler:nil];
    [webView evaluateJavaScript:FallBackViewControllerJavascriptOnRegistered completionHandler:nil];
    [webView evaluateJavaScript:FallBackViewControllerJavascriptOnLogin completionHandler:nil];

    // Check connectivity
    if ([AppDelegate theDelegate].isOffline)
    {
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
        // Listen only to scheme of the JS-WKWebView bridge
        NSString *jsonString = [[[urlString componentsSeparatedByString:@"js:"] lastObject]  stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

        NSError *error;
        NSDictionary *parameters = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers
                                                                     error:&error];

        if (!error)
        {
            if ([@"onRegistered" isEqualToString:parameters[@"action"]])
            {
                // Translate the JS registration event to MXLoginResponse
                // We cannot use [MXLoginResponse modelFromJSON:] because of https://github.com/matrix-org/synapse/issues/4756
                // Because of this issue, we cannot get the device_id allocated by the homeserver
                // TODO: Fix it once the homeserver issue is fixed (filed at https://github.com/vector-im/riot-meta/issues/273).
                MXLoginResponse *loginResponse = [MXLoginResponse new];
                loginResponse.homeserver = parameters[@"homeServer"];
                loginResponse.userId = parameters[@"userId"];
                loginResponse.accessToken = parameters[@"accessToken"];

                // Sanity check
                if (self.delegate
                    && loginResponse.homeserver.length && loginResponse.userId.length && loginResponse.accessToken.length)
                {
                    // And inform the client
                    [self.delegate authFallBackViewController:self didLoginWithLoginResponse:loginResponse];
                }
            }
            else if ([@"onLogin" isEqualToString:parameters[@"action"]])
            {
                // Translate the JS login event to MXLoginResponse
                MXLoginResponse *loginResponse;
                MXJSONModelSetMXJSONModel(loginResponse, MXLoginResponse, parameters[@"response"]);

                // Sanity check
                if (self.delegate
                    && loginResponse.homeserver.length && loginResponse.userId.length && loginResponse.accessToken.length)
                {
                    // And inform the client
                    [self.delegate authFallBackViewController:self didLoginWithLoginResponse:loginResponse];
                }
            }
        }
        
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
