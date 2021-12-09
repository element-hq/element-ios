/*
 Copyright 2016 OpenMarket Ltd
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
