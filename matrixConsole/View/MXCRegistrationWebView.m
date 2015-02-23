/*
 Copyright 2015 OpenMarket Ltd

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

#import "MXCRegistrationWebView.h"

// Generic method to make a bridge between JS and the UIWebView
NSString *kMXCJavascriptSendObjectMessage = @"var sendObjectMessage = function(parameters) {   \
    var iframe = document.createElement('iframe');                              \
    iframe.setAttribute('src', 'js:' + JSON.stringify(parameters));             \
                                                                                \
    document.documentElement.appendChild(iframe);                               \
    iframe.parentNode.removeChild(iframe);                                      \
    iframe = null;                                                              \
    };";

// The function the fallback page calls when the registration is complete
NSString *kMXCJavascriptOnRegistered = @"window.matrixRegistration.onRegistered = function(homeserverUrl, userId, accessToken) {   \
    sendObjectMessage({                 \
        'action': 'onRegistered',       \
        'homeServer': homeserverUrl,    \
        'userId': userId,               \
        'accessToken': accessToken      \
    });";

@interface MXCRegistrationWebView () {
    // The block called when the registration is successful
    void (^onSuccess)(MXCredentials *);
}
@end

@implementation MXCRegistrationWebView

- (void)openFallbackPage:(NSString *)fallbackPage success:(void (^)(MXCredentials *))success {
    onSuccess = success;
    [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:fallbackPage]]];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [self stringByEvaluatingJavaScriptFromString:kMXCJavascriptSendObjectMessage];
    [self stringByEvaluatingJavaScriptFromString:kMXCJavascriptOnRegistered];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

    NSString *urlString = [[request URL] absoluteString];

    if ([urlString hasPrefix:@"js:"]) {
        // Listen only to scheme of the JS-UIWebView bridge
        NSString *jsonString = [[[urlString componentsSeparatedByString:@"js:"] lastObject]  stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

        NSError *error;
        NSDictionary *parameters = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers
                                                          error:&error];

        if (!error) {
            if ([@"onRegistered" isEqualToString:parameters[@"onRegistered"]]) {
                // Translate the JS registration event to MXCredentials
                MXCredentials *credentials = [[MXCredentials alloc] initWithHomeServer:parameters[@"homeServer"] userId:parameters[@"userId"] accessToken:parameters[@"accessToken"]];

                onSuccess(credentials);
            }
        }
        return NO;
    }

    return YES;
}

@end
