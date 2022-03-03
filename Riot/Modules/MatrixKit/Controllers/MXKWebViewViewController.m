/*
 Copyright 2016 OpenMarket Ltd
 Copyright 2018 New Vector Ltd
 Copyright 2019 The Matrix.org Foundation C.I.C

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

#import "MXKWebViewViewController.h"

#import "NSBundle+MatrixKit.h"

#import <JavaScriptCore/JavaScriptCore.h>

#import "MXKSwiftHeader.h"

NSString *const kMXKWebViewViewControllerPostMessageJSLog = @"jsLog";

// Override console.* logs methods to send WebKit postMessage events to native code.
// Note: this code has a minimal support of multiple parameters in console.log()
NSString *const kMXKWebViewViewControllerJavaScriptEnableLog =
@"console.debug = console.log; console.info = console.log; console.warn = console.log; console.error = console.log;" \
@"console.log = function() {" \
@"    var msg = arguments[0];" \
@"    for (var i = 1; i < arguments.length; i++) {" \
@"        msg += ' ' + arguments[i];" \
@"    }" \
@"    window.webkit.messageHandlers.%@.postMessage(msg);" \
@"};";

@interface MXKWebViewViewController ()
{
    BOOL enableDebug;

    //  Right buttons bar state before loading the webview
    NSArray<UIBarButtonItem *> *originalRightBarButtonItems;
}

@end

@implementation MXKWebViewViewController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        enableDebug = NO;
    }
    return self;
}

- (id)initWithURL:(NSString*)URL
{
    self = [self init];
    if (self)
    {
        _URL = URL;
    }
    return self;
}

- (id)initWithLocalHTMLFile:(NSString*)localHTMLFile
{
    self = [self init];
    if (self)
    {
        _localHTMLFile = localHTMLFile;
    }
    return self;
}

- (void)enableDebug
{
    // We can only call addScriptMessageHandler on a given message only once
    if (enableDebug)
    {
        return;
    }
    enableDebug = YES;

    // Redirect all console.* logging methods into a WebKit postMessage event with name "jsLog"
    [webView.configuration.userContentController addScriptMessageHandler:self name:kMXKWebViewViewControllerPostMessageJSLog];

    NSString *javaScriptString = [NSString stringWithFormat:kMXKWebViewViewControllerJavaScriptEnableLog, kMXKWebViewViewControllerPostMessageJSLog];

    [webView evaluateJavaScript:javaScriptString completionHandler:nil];
}

- (void)finalizeInit
{
    [super finalizeInit];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    originalRightBarButtonItems = self.navigationItem.rightBarButtonItems;
    
    // Init the webview
    webView = [[WKWebView alloc] initWithFrame:self.view.frame];
    webView.backgroundColor= [UIColor whiteColor];
    webView.navigationDelegate = self;
    webView.UIDelegate = self;

    [webView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:webView];
    
    // Force webview in full width (to handle auto-layout in case of screen rotation)
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:webView
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeLeading
                                                                     multiplier:1.0
                                                                       constant:0];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:webView
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.view
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1.0
                                                                        constant:0];
    // Force webview in full height
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:webView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.topLayoutGuide
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:0];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:webView
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.bottomLayoutGuide
                                                                        attribute:NSLayoutAttributeTop
                                                                       multiplier:1.0
                                                                         constant:0];
    #pragma clang diagnostic pop
    
    [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint, bottomConstraint]];
    
    backButton = [[UIBarButtonItem alloc] initWithTitle:[VectorL10n back] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    
    if (_URL.length)
    {
        self.URL = _URL;
    }
    else if (_localHTMLFile.length)
    {
        self.localHTMLFile = _localHTMLFile;
    }
}

- (void)destroy
{
    if (webView)
    {
        webView.navigationDelegate = nil;
        [webView stopLoading];
        [webView removeFromSuperview];
        webView = nil;
    }
    
    backButton = nil;
    
    _URL = nil;
    _localHTMLFile = nil;

    [super destroy];
}

- (void)dealloc
{
    [self destroy];
}

- (void)setURL:(NSString *)URL
{
    [webView stopLoading];
    
    _URL = URL;
    _localHTMLFile = nil;
    
    if (URL.length)
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
        [webView loadRequest:request];
    }
}

- (void)setLocalHTMLFile:(NSString *)localHTMLFile
{
    [webView stopLoading];
    
    _localHTMLFile = localHTMLFile;
    _URL = nil;
    
    if (localHTMLFile.length)
    {
        NSString* htmlString = [NSString stringWithContentsOfFile:localHTMLFile encoding:NSUTF8StringEncoding error:nil];
        [webView loadHTMLString:htmlString baseURL:nil];
    }
}

- (void)goBack
{
    if (webView.canGoBack)
    {
        [webView goBack];
    }
    else if (_localHTMLFile.length)
    {
        // Reload local html file
        self.localHTMLFile = _localHTMLFile;
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    // Handle back button visibility here
    BOOL canGoBack = webView.canGoBack;

    if (_localHTMLFile.length && !canGoBack)
    {
        // Check whether the current content is not the local html file
        canGoBack = (![webView.URL.absoluteString isEqualToString:@"about:blank"]);
    }

    if (canGoBack)
    {
        self.navigationItem.rightBarButtonItem = backButton;
    }
    else
    {
        // Reset the original state
        self.navigationItem.rightBarButtonItems = originalRightBarButtonItems;
    }
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
    
    // We handle here only the server trust authentication.
    // We fallback to the default logic for other cases.
    if (protectionSpace.authenticationMethod != NSURLAuthenticationMethodServerTrust || !protectionSpace.serverTrust)
    {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return;
    }
    
    SecTrustRef serverTrust = [protectionSpace serverTrust];
    
    // Check first whether there are some pinned certificates (certificate included in the bundle).
    NSArray *paths = [[NSBundle mainBundle] pathsForResourcesOfType:@"cer" inDirectory:@"."];
    if (paths.count)
    {
        NSMutableArray *pinnedCertificates = [NSMutableArray array];
        for (NSString *path in paths)
        {
            NSData *certificateData = [NSData dataWithContentsOfFile:path];
            [pinnedCertificates addObject:(__bridge_transfer id)SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificateData)];
        }
        // Only use these certificates to pin against, and do not trust the built-in anchor certificates.
        SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)pinnedCertificates);
    }
    else
    {
        // Check whether some certificates have been trusted by the user (self-signed certificates support).
        NSSet<NSData *> *certificates = [MXAllowedCertificates sharedInstance].certificates;
        if (certificates.count)
        {
            NSMutableArray *allowedCertificates = [NSMutableArray array];
            for (NSData *certificateData in certificates)
            {
                [allowedCertificates addObject:(__bridge_transfer id)SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificateData)];
            }
            // Add all the allowed certificates to the chain of trust
            SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)allowedCertificates);
            // Reenable trusting the built-in anchor certificates in addition to those passed in via the SecTrustSetAnchorCertificates API.
            SecTrustSetAnchorCertificatesOnly(serverTrust, false);
        }
    }
    
    // Re-evaluate the trust policy
    SecTrustResultType secresult = kSecTrustResultInvalid;
    if (SecTrustEvaluate(serverTrust, &secresult) != errSecSuccess)
    {
        // Reject the server auth if an error occurs
        completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
    }
    else
    {
        switch (secresult)
        {
            case kSecTrustResultUnspecified:    // The OS trusts this certificate implicitly.
            case kSecTrustResultProceed:        // The user explicitly told the OS to trust it.
            {
                NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
                break;
            }
                
            default:
            {
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
                break;
            }
        }
    }
}

#pragma mark - WKUIDelegate

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(nonnull WKWebViewConfiguration *)configuration forNavigationAction:(nonnull WKNavigationAction *)navigationAction windowFeatures:(nonnull WKWindowFeatures *)windowFeatures
{
    // Make sure we open links with `target="_blank"` within this webview
    if (!navigationAction.targetFrame.isMainFrame)
    {
        [webView loadRequest:navigationAction.request];
    }

    return nil;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name isEqualToString:kMXKWebViewViewControllerPostMessageJSLog])
    {
        MXLogDebug(@"-- JavaScript: %@", message.body);
    }
}

@end
