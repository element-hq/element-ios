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

#import <Foundation/Foundation.h>

#import <MatrixSDK/MatrixSDK.h>

/**
 The `Widget` class represents scalar widget information.
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
 The widget url.
 
 Widgets are basically opened in a webview. `url` is the url the webview must use
 to render the widget.
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
@property (nonatomic, readonly, nonnull) NSString *roomId;

/**
 Create a Widget instance from a widget event.
 
 @param widgetEvent the state event representing a widget.
 @return the newly created instance.
 */
- (instancetype _Nullable )initWithWidgetEvent:(MXEvent* _Nonnull)widgetEvent inMatrixSession:(MXSession* _Nonnull)mxSession;

@end
