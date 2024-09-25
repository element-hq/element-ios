/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKAuthenticationFallbackWebView.h"

// Generic method to make a bridge between JS and the WKWebView
NSString *kMXKJavascriptSendObjectMessage = @"window.sendObjectMessage = function(parameters) {   \
var iframe = document.createElement('iframe');                              \
iframe.setAttribute('src', 'js:' + JSON.stringify(parameters));             \
\
document.documentElement.appendChild(iframe);                               \
iframe.parentNode.removeChild(iframe);                                      \
iframe = null;                                                              \
};";

// The function the fallback page calls when the registration is complete
NSString *kMXKJavascriptOnRegistered = @"window.matrixRegistration.onRegistered = function(homeserverUrl, userId, accessToken) {   \
sendObjectMessage({  \
'action': 'onRegistered',           \
'homeServer': homeserverUrl,        \
'userId': userId,                   \
'accessToken': accessToken          \
});                                     \
};";

// The function the fallback page calls when the login is complete
NSString *kMXKJavascriptOnLogin = @"window.matrixLogin.onLogin = function(response) {   \
sendObjectMessage({  \
'action': 'onLogin',           \
'response': response        \
});                                     \
};";

@interface MXKAuthenticationFallbackWebView ()
{
    // The block called when the login or the registration is successful
    void (^onSuccess)(MXLoginResponse *);
    
    // Activity indicator
    UIActivityIndicatorView *activityIndicator;
}
@end

@implementation MXKAuthenticationFallbackWebView

- (void)dealloc
{
    if (activityIndicator)
    {
        [activityIndicator removeFromSuperview];
        activityIndicator = nil;
    }
}

- (void)openFallbackPage:(NSString *)fallbackPage success:(void (^)(MXLoginResponse *))success
{
    self.navigationDelegate = self;
    
    onSuccess = success;
    
    // Add activity indicator
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.center = self.center;
    [self addSubview:activityIndicator];
    [activityIndicator startAnimating];

    // Delete cookies to launch login process from scratch
    for(NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
    {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    
    [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:fallbackPage]]];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if (activityIndicator)
    {
        [activityIndicator stopAnimating];
        [activityIndicator removeFromSuperview];
        activityIndicator = nil;
    }
    
    [self evaluateJavaScript:kMXKJavascriptSendObjectMessage completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        
    }];
    [self evaluateJavaScript:kMXKJavascriptOnRegistered completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        
    }];
    [self evaluateJavaScript:kMXKJavascriptOnLogin completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        
    }];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    MXLogDebug(@"[MXKAuthenticationFallbackWebView] decidePolicyForNavigationAction");
    
    NSString *urlString = navigationAction.request.URL.absoluteString;
    
    if ([urlString hasPrefix:@"js:"])
    {
        //  do not log urlString, it may have an access token
        MXLogDebug(@"[MXKAuthenticationFallbackWebView] URL has js: prefix");
        
        // Listen only to scheme of the JS-WKWebView bridge
        NSString *jsonString = [[[urlString componentsSeparatedByString:@"js:"] lastObject]  stringByRemovingPercentEncoding];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error;
        NSDictionary *parameters = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers
                                                                     error:&error];
        
        if (error)
        {
            MXLogDebug(@"[MXKAuthenticationFallbackWebView] Error when parsing json: %@", error);
        }
        else
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
                
                MXLogDebug(@"[MXKAuthenticationFallbackWebView] Registered on homeserver: %@", loginResponse.homeserver);

                // Sanity check
                if (loginResponse.homeserver.length && loginResponse.userId.length && loginResponse.accessToken.length)
                {
                    MXLogDebug(@"[MXKAuthenticationFallbackWebView] Call success block");
                    // And inform the client
                    onSuccess(loginResponse);
                }
            }
            else if ([@"onLogin" isEqualToString:parameters[@"action"]])
            {
                // Translate the JS login event to MXLoginResponse
                MXLoginResponse *loginResponse;
                MXJSONModelSetMXJSONModel(loginResponse, MXLoginResponse, parameters[@"response"]);

                MXLogDebug(@"[MXKAuthenticationFallbackWebView] Logged in on homeserver: %@", loginResponse.homeserver);
                
                // Sanity check
                if (loginResponse.homeserver.length && loginResponse.userId.length && loginResponse.accessToken.length)
                {
                    MXLogDebug(@"[MXKAuthenticationFallbackWebView] Call success block");
                    // And inform the client
                    onSuccess(loginResponse);
                }
            }
        }
        
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
