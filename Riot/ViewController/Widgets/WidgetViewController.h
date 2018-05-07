/*
 Copyright 2017 Vector Creations Ltd

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

#import "WebViewViewController.h"

#import "WidgetManager.h"

/**
 `WidgetViewController` displays widget within a webview.

 It also exposes a generic pipe, the postMessage API, to communicate with the
 content within the webview, ie the widget (matrix app).
 */
@interface WidgetViewController : WebViewViewController

/**
 Init 'WidgetViewController' instance with a widget.

 @param widgetUrl the formatted widget url.
 @param widget the widget to open.
 */
- (instancetype)initWithUrl:(NSString*)widgetUrl forWidget:(Widget*)widget;

/**
 Display an alert over this controller.

 @param error the error to display.
 */
- (void)showErrorAsAlert:(NSError*)error;


#pragma mark - postMessage API

/**
 Callback called when the widget make a postMessage API request.

 This method can be overidden to implement a specific API between the matrix client
 and widget.

 @param @TODO
 */
- (void)onMessage:(NSDictionary*)JSData;

/**
 Send a boolean response to a request from the widget.

 @param response the response to send.
 @param @TODO
 */
- (void)sendBoolResponse:(BOOL)response toEvent:(NSDictionary*)eventData;

/**
 Send an integer response to a request from the widget.

 @param response the response to send.
 @param @TODO
 */
- (void)sendIntegerResponse:(NSUInteger)response toEvent:(NSDictionary*)eventData;

/**
 Send a serialiable object response to a request the widget.

 @param response the response to send.
 @param @TODO
 */
- (void)sendNSObjectResponse:(NSObject*)response toEvent:(NSDictionary*)eventData;

/**
 Send a message error to a request from the widget.

 @param message the error message.
 @param @TODO
 */
- (void)sendError:(NSString*)message toEvent:(NSDictionary*)eventData;

/**
 Send a localised message error to a request from the widget.

 @param errorKey the string id of the message error.
 @param @TODO
 */
- (void)sendLocalisedError:(NSString*)errorKey toEvent:(NSDictionary*)eventData;

@end
