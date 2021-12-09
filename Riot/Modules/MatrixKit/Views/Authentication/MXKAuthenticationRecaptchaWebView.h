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
