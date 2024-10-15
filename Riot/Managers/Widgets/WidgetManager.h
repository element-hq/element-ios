/*
Copyright 2019-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

#import <MatrixSDK/MatrixSDK.h>

#import "Widget.h"
#import "WidgetConstants.h"

@class WidgetManagerConfig;

/**
 Posted when a widget has been created, updated or disabled.
 The notification object is the `Widget` instance.
 */
FOUNDATION_EXPORT NSString *const kWidgetManagerDidUpdateWidgetNotification;

/**
 `WidgetManager` NSError domain and codes.
 */
FOUNDATION_EXPORT NSString *const WidgetManagerErrorDomain;

typedef enum : NSUInteger
{
    WidgetManagerErrorCodeNotEnoughPower,
    WidgetManagerErrorCodeCreationFailed,
    WidgetManagerErrorCodeNoIntegrationsServerConfigured,
    WidgetManagerErrorCodeDisabledIntegrationsServer,
    WidgetManagerErrorCodeFailedToConnectToIntegrationsServer,
    WidgetManagerErrorCodeTermsNotSigned,
    WidgetManagerErrorCodeUnavailableJitsiURL
}
WidgetManagerErrorCode;

FOUNDATION_EXPORT NSString *const WidgetManagerErrorOpenIdTokenKey;

/**
 The `WidgetManager` helps to handle modular widgets.
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
- (NSArray<Widget*> *)widgetsInRoom:(MXRoom*)room withRoomState:(MXRoomState*)roomState;

/**
 List all active widgets of a given type in a room.

 @param widgetTypes the types of widget to search. Nil means all types.
 @param room the room to check.
 @return a list of widgets.
 */
- (NSArray<Widget*> *)widgetsOfTypes:(NSArray<NSString*>*)widgetTypes inRoom:(MXRoom*)room withRoomState:(MXRoomState*)roomState;

/**
 List all active widgets of a given type in a room, excluding some types.

 @param notWidgetTypes the types of widget to not consider. Nil means all types.
 @param room the room to check.
 @return a list of widgets.
 */
- (NSArray<Widget*> *)widgetsNotOfTypes:(NSArray<NSString*>*)notWidgetTypes inRoom:(MXRoom*)room withRoomState:(MXRoomState*)roomState;

/**
 List all widgets of an account.

 @param mxSession the session of the user account.
 @return a list of widgets.
 */
- (NSArray<Widget*> *)userWidgets:(MXSession*)mxSession;

/**
 List all widgets of a given type of an account.

 @param mxSession the session of the user account.
 @param widgetTypes the types of widget to search. Nil means all types.
 @return a list of widgets.
 */
- (NSArray<Widget*> *)userWidgets:(MXSession*)mxSession ofTypes:(NSArray<NSString*>*)widgetTypes;

/**
 Add a modular widget to a room.

 @param widgetId the id of the widget.
 @param widgetContent the widget content.
 @param room the room to create the widget to.

 @param success A block object called when the operation succeeds. It provides the newly added widget.
 @param failure A block object called when the operation fails.

 @return a MXHTTPOperation instance.
 */
- (MXHTTPOperation *)createWidget:(NSString*)widgetId
                      withContent:(NSDictionary<NSString*, NSObject*>*)widgetContent
                           inRoom:(MXRoom*)room
                          success:(void (^)(Widget *widget))success
                          failure:(void (^)(NSError *error))failure;

/**
 Add a jitsi conference widget to a room.

 @param room the room to create the widget to.
 @param video the conference type

 @param success A block object called when the operation succeeds. It provides the newly added widget.
 @param failure A block object called when the operation fails.

 @return a MXHTTPOperation instance.
 */
- (MXHTTPOperation *)createJitsiWidgetInRoom:(MXRoom*)room
                                   withVideo:(BOOL)video
                                     success:(void (^)(Widget *jitsiWidget))success
                                     failure:(void (^)(NSError *error))failure;

/**
 Close/Disable a widget in a room.

 @param widgetId the id of the widget to close.
 @param room the room the widget is in.

 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.

 @return a MXHTTPOperation instance.
 */
- (MXHTTPOperation *)closeWidget:(NSString*)widgetId inRoom:(MXRoom*)room
                         success:(void (^)(void))success
                         failure:(void (^)(NSError *error))failure;


/**
 Add/remove matrix session.
 
 Registering session allows to generate `kWidgetManagerDidUpdateWidgetNotification` notifications.
 
 @param mxSession the session to add/remove.
 */
- (void)addMatrixSession:(MXSession*)mxSession;
- (void)removeMatrixSession:(MXSession*)mxSession;

/**
 Delete the data associated with an user.
 
@param userId the id of the user.
 */
- (void)deleteDataForUser:(NSString*)userId;

#pragma mark - Modular interface

/**
 Get the integration manager configuration for a user.

 @param userId the user id.
 @return the integration manager configuration.
 */
- (WidgetManagerConfig*)configForUser:(NSString*)userId;

/**
 Store the integration manager configuration for a user.

 @param config the integration manager configuration.
 @param userId the user id.
 */
- (void)setConfig:(WidgetManagerConfig*)config forUser:(NSString*)userId;

/**
 Check if the user has URLs for an integration manager configured.

 @param userId the user id.
 @return YES if they have URLs for an integration manager.
 */
- (BOOL)hasIntegrationManagerForUser:(NSString*)userId;

/**
 Make sure there is a scalar token for the given Matrix session.
 
 If no token was gotten and stored before, the operation will make http requests
 to get one.

 @param mxSession the session to check.
 @param validate if it is cached, check its validity on the scalar server.
 
 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (MXHTTPOperation *)getScalarTokenForMXSession:(MXSession*)mxSession
                                       validate:(BOOL)validate
                                        success:(void (^)(NSString *scalarToken))success
                                        failure:(void (^)(NSError *error))failure;

/**
 Returns true if specified url is a scalar URL, typically https://scalar.vector.im/api

 @param urlString the URL to check.
 @param userId the user id.
 @return YES if specified URL is a scalar URL.
 */
- (BOOL)isScalarUrl:(NSString*)urlString forUser:(NSString*)userId;

@end
