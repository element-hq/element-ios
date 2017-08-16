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

#import "Widget.h"

/**
 The type of matrix event used for scalar widgets.
 */
FOUNDATION_EXPORT NSString *const kWidgetEventTypeString;

/**
 Known types widgets.
 */
FOUNDATION_EXPORT NSString *const kWidgetTypeJitsi;

/**
 Posted when a widget has been created, updated or removed.
 */
extern NSString *const kMXKWidgetManagerDidUpdateWidgetNotification;


/**
 The `WidgetManager` helps to handle scalar widgets.
 */
@interface WidgetManager : NSObject

/**
 Returns the shared widget manager.

 @return the shared widget manager.
 */
+ (instancetype)sharedManager;

/**
 List all active widgets in a room.
 
 @param room the room to check.
 @return a list of widgets.
 */
- (NSArray<Widget*> *)widgetsInRoom:(MXRoom*)room;

/**
 List all active widgets of a given type in a room.

 @param widgetType the types of widget to search.
 @param room the room to check.
 @return a list of widgets.
 */
- (NSArray<Widget*> *)widgetsOfTypes:(NSArray<NSString*>*)widgetTypes inRoom:(MXRoom*)room;

/**
 Add/remove matrix session.
 
 Registering session allows to generate `kMXKWidgetManagerDidUpdateWidgetNotification` notifications.
 
 @param mxSession the session to add/remove.
 */
- (void)addMatrixSession:(MXSession*)mxSession;
- (void)removeMatrixSession:(MXSession*)mxSession;

@end
