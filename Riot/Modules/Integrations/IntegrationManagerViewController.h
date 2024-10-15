/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
