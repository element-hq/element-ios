/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "WebViewViewController.h"

#import "WidgetManager.h"
#import "MatrixKit.h"

/**
 `WidgetViewController` displays widget within a webview.

 It also exposes a generic pipe, the postMessage API, to communicate with the
 content within the webview, ie the widget (matrix app).
 */
@interface WidgetViewController : WebViewViewController

/**
 The displayed widget.
 */
@property (nonatomic, readonly) Widget  *widget;

/**
 The room data source.
 Required if the widget needs to post messages.
 */
@property (nonatomic) MXKRoomDataSource *roomDataSource;

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

 @param requestId the id of the widget request.
 @param requestData the request data.
 */
- (void)onPostMessageRequest:(NSString*)requestId data:(NSDictionary*)requestData;

/**
 Send a boolean response to a request from the widget.

 @param response the response to send.
 @param requestId the id of the widget request.
 */
- (void)sendBoolResponse:(BOOL)response toRequest:(NSString*)requestId;

/**
 Send an integer response to a request from the widget.

 @param response the response to send.
 @param requestId the id of the widget request.
 */
- (void)sendIntegerResponse:(NSUInteger)response toRequest:(NSString*)requestId;

/**
 Send a serialiable object response to a request the widget.

 @param response the response to send.
 @param requestId the id of the widget request.
 */
- (void)sendNSObjectResponse:(NSObject*)response toRequest:(NSString*)requestId;

/**
 Send a message error to a request from the widget.

 @param message the error message.
 @param requestId the id of the widget request.
 */
- (void)sendError:(NSString*)message toRequest:(NSString*)requestId;

@end
