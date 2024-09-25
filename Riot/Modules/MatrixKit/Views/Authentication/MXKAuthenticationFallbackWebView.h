/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <MatrixSDK/MatrixSDK.h>
#import <WebKit/WebKit.h>

@interface MXKAuthenticationFallbackWebView : WKWebView <WKNavigationDelegate>

/**
 Open authentication fallback page into the webview.
 
 @param fallbackPage the fallback page hosted by a homeserver.
 @param success the block called when the user has been successfully logged in or registered.
 */
- (void)openFallbackPage:(NSString*)fallbackPage success:(void (^)(MXLoginResponse *loginResponse))success;

@end
