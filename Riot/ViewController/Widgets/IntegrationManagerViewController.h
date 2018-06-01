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

#import "WidgetViewController.h"

FOUNDATION_EXPORT NSString *const kIntegrationManagerMainScreen;
FOUNDATION_EXPORT NSString *const kIntegrationManagerAddIntegrationScreen;

/**
 `IntegrationManagerViewController` displays the Modular integration manager webapp
 into a webview.

 It reuses the postMessage API pipe defined in `WidgetViewController`.
 */
@interface IntegrationManagerViewController : WidgetViewController

/**
 Initialise with params for the Modular interface webapp.

 @param mxSession the session to use.
 @param roomId the room where to set up widgets.
 @param screen the screen to display in the Modular interface webapp. Can be nil.
 @param widgetId the id of the widget in case of widget configuration edition. Can be nil.
 */
- (instancetype)initForMXSession:(MXSession*)mxSession inRoom:(NSString*)roomId screen:(NSString*)screen widgetId:(NSString*)widgetId;

/**
 Get the integration manager settings screen for a given widget type.

 @param widgetType the widget type.
 @return the screen id for that widget type.
 */
+ (NSString*)screenForWidget:(NSString*)widgetType;

@end
