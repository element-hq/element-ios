/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKAuthenticationRecaptchaWebView.h"
#import "ThemeService.h"

NSString *kMXKRecaptchaHTMLString = @"<html> \
<head> \
<meta name='viewport' content='initial-scale=1.0' /> \
<style>@media (prefers-color-scheme: dark) { body { background-color: #15191E; } }</style> \
<script type=\"text/javascript\"> \
var verifyCallback = function(response) { \
    /* Generic method to make a bridge between JS and the WKWebView*/ \
    var iframe = document.createElement('iframe'); \
    iframe.setAttribute('src', 'js:' + JSON.stringify({'action': 'verifyCallback', 'response': response})); \
 \
    document.documentElement.appendChild(iframe); \
    iframe.parentNode.removeChild(iframe); \
    iframe = null; \
}; \
var onloadCallback = function() { \
    grecaptcha.render('recaptcha_widget', { \
        'sitekey' : '%@', \
        'callback': verifyCallback, \
        'theme': '%@' \
    }); \
}; \
</script> \
</head> \
<body> \
    <div id=\"recaptcha_widget\"></div> \
    <script src=\"https://www.google.com/recaptcha/api.js?onload=onloadCallback&render=explicit\" async defer> \
    </script> \
</body> \
</html>";

@interface MXKAuthenticationRecaptchaWebView () <WKNavigationDelegate>
{
    // The block called when the reCAPTCHA response is received
    void (^onResponse)(NSString *);
    
    // Activity indicator
    UIActivityIndicatorView *activityIndicator;
}
@end

@implementation MXKAuthenticationRecaptchaWebView

- (void)dealloc
{
    if (activityIndicator)
    {
        [activityIndicator removeFromSuperview];
        activityIndicator = nil;
    }
}

- (void)openRecaptchaWidgetWithSiteKey:(NSString*)siteKey fromHomeServer:(NSString*)homeServer callback:(void (^)(NSString *response))callback
{
    self.navigationDelegate = self;
    
    onResponse = callback;
    
    // Add activity indicator
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.center = self.center;
    [self addSubview:activityIndicator];
    [activityIndicator startAnimating];
    
    NSString *theme = ThemeService.shared.isCurrentThemeDark ? @"dark" : @"light";
    
    NSString *htmlString = [NSString stringWithFormat:kMXKRecaptchaHTMLString, siteKey, theme];
    
    [self loadHTMLString:htmlString baseURL:[NSURL URLWithString:homeServer]];
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
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSString *urlString = navigationAction.request.URL.absoluteString;

    if ([urlString hasPrefix:@"js:"])
    {
        // Listen only to scheme of the JS-WKWebView bridge
        NSString *jsonString = [[[urlString componentsSeparatedByString:@"js:"] lastObject] stringByRemovingPercentEncoding];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

        NSError *error;
        NSDictionary *parameters = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers
                                                                     error:&error];

        if (!error)
        {
            if ([@"verifyCallback" isEqualToString:parameters[@"action"]])
            {
                // Transfer the reCAPTCHA response
                onResponse(parameters[@"response"]);
            }
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
