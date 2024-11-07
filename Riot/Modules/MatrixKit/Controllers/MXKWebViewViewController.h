/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKViewController.h"
#import <WebKit/WebKit.h>

/**
 'MXKWebViewViewController' instance is used to display a webview.
 */
@interface MXKWebViewViewController : MXKViewController <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>
{
@protected
    /**
     The back button displayed as the right bar button item.
     */
    UIBarButtonItem *backButton;
    
@public
    /**
     The content of this screen is fully displayed by this webview
     */
    WKWebView *webView;
}

/**
 Init 'MXKWebViewViewController' instance with a web content url.
 
 @param URL the url to open
 */
- (id)initWithURL:(NSString*)URL;

/**
 Init 'MXKWebViewViewController' instance with a local HTML file path.
 
 @param localHTMLFile The path of the local HTML file.
 */
- (id)initWithLocalHTMLFile:(NSString*)localHTMLFile;

/**
 Route javascript logs to NSLog.
 */
- (void)enableDebug;

/**
 Define the web content url to open
 Don’t use this property to load local HTML files, instead use 'localHTMLFile'.
 */
@property (nonatomic) NSString *URL;

/**
 Define the local HTML file path to load
 */
@property (nonatomic) NSString *localHTMLFile;

@end
