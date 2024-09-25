/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

#import <MatrixSDK/MatrixSDK.h>

/**
 The `Widget` class represents modular widget information.
 */
@interface Widget : NSObject

/**
 The widget id.
 */
@property (nonatomic, readonly, nonnull) NSString *widgetId;

/**
 The widget type.

 Some types are defined in `WidgetManager.h`.
 Nil if the widget is no more active in the room.
 */
@property (nonatomic, readonly, nullable) NSString *type;

/**
 The raw widget url.

 This is the preformated version of the widget url containing parameters names.
 This is not a valid url. The url to use in a webview can be obtained with
 `[self widgetUrl:]`.
 */
@property (nonatomic, readonly, nullable) NSString *url;

/**
 The widget name.
 */
@property (nonatomic, readonly, nullable) NSString *name;

/**
 The widget additional data.
 */
@property (nonatomic, readonly, nullable) NSDictionary *data;

/**
 The widget event that is at the origin of the widget.
 */
@property (nonatomic, readonly, nonnull) MXEvent *widgetEvent;

/**
 The Matrix session where the widget is.
 */
@property (nonatomic, readonly, nonnull) MXSession *mxSession;

/**
 Indicate if the widget is still active.
 */
@property (nonatomic, readonly) BOOL isActive;

/**
 The room id of the widget.
 */
@property (nonatomic, readonly, nullable) NSString *roomId;

/**
 Create a Widget instance from a widget event.
 
 @param widgetEvent the state event representing a widget.
 @return the newly created instance.
 */
- (instancetype _Nullable )initWithWidgetEvent:(MXEvent* _Nonnull)widgetEvent inMatrixSession:(MXSession* _Nonnull)mxSession;

/**
 Build the url of the widget that can be opened in a webview.

 @param success A block object called when the operation succeeds. It provides the valid widget url.
 @param failure A block object called when the operation fails.

 @return a MXHTTPOperation instance.
 */
- (MXHTTPOperation * _Nullable)widgetUrl:(void (^_Nonnull)(NSString * _Nonnull widgetUrl))success
                                 failure:(void (^ _Nullable)(NSError * _Nonnull error))failure;

@end
