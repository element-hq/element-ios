/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <MatrixSDK/MatrixSDK.h>

#import <WebKit/WebKit.h>

@interface MXKAuthenticationRecaptchaWebView : WKWebView

/**
 Open reCAPTCHA widget into a webview.
 
 @param siteKey the site key.
 @param homeServer the homeserver URL.
 @param callback the block called when the user has received reCAPTCHA response.
 */
- (void)openRecaptchaWidgetWithSiteKey:(NSString*)siteKey fromHomeServer:(NSString*)homeServer callback:(void (^)(NSString *response))callback;

@end
