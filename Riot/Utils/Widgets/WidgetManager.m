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

#import "WidgetManager.h"

#pragma mark - Contants

NSString *const kWidgetEventTypeString = @"im.vector.modular.widgets";
NSString *const kWidgetTypeJitsi = @"jitsi";

NSString *const kWidgetManagerDidUpdateWidgetNotification = @"kWidgetManagerDidUpdateWidgetNotification";

NSString *const WidgetManagerErrorDomain = @"WidgetManagerErrorDomain";

@interface WidgetManager ()
{
    // MXSession kind of hash -> Listener for matrix events for widgets.
    // There is one per matrix session
    NSMutableDictionary<NSString*, id> *widgetEventListener;

    // Success blocks of widgets being created
    // MXSession kind of hash -> (Widget id -> `createWidget:` success block).
    NSMutableDictionary<NSString*,
        NSMutableDictionary<NSString*, void (^)(Widget *widget)>*> *successBlockForWidgetCreation;

    // Failure blocks of widgets being created
    // MXSession kind of hash -> (Widget id -> `createWidget:` failure block).
    NSMutableDictionary<NSString*,
        NSMutableDictionary<NSString*, void (^)(NSError *error)>*> *failureBlockForWidgetCreation;
}

@end

@implementation WidgetManager

+ (instancetype)sharedManager
{
    static WidgetManager *sharedManager = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedManager = [[WidgetManager alloc] init];
    });

    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        widgetEventListener = [NSMutableDictionary dictionary];
        successBlockForWidgetCreation = [NSMutableDictionary dictionary];
        failureBlockForWidgetCreation = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSArray<Widget *> *)widgetsInRoom:(MXRoom *)room
{
    return [self widgetsOfTypes:nil inRoom:room];
}

- (NSArray<Widget *> *)widgetsOfTypes:(NSArray<NSString *> *)widgetTypes inRoom:(MXRoom *)room
{
    // Widget id -> widget
    NSMutableDictionary <NSString*, Widget *> *widgets = [NSMutableDictionary dictionary];

    // Get all im.vector.modular.widgets state events in the room
    NSMutableArray<MXEvent*> *widgetEvents = [NSMutableArray arrayWithArray:[room.state stateEventsWithType:kWidgetEventTypeString]];

    // There can be several im.vector.modular.widgets state events for a same widget but
    // only the last one must be considered.

    // Order widgetEvents with the last event first
    [widgetEvents sortUsingComparator:^NSComparisonResult(MXEvent *event1, MXEvent *event2) {

         NSComparisonResult result = NSOrderedAscending;
         if (event2.originServerTs > event1.originServerTs)
         {
             result = NSOrderedDescending;
         }
         else if (event2.originServerTs == event1.originServerTs)
         {
             result = NSOrderedSame;
         }

         return result;
     }];

    // Create each widget from its lastest im.vector.modular.widgets state event
    for (MXEvent *widgetEvent in widgetEvents)
    {
        // Filter widget types if required
        if (widgetTypes)
        {
            NSString *widgetType;
            MXJSONModelSetString(widgetType, widgetEvent.content[@"type"]);

            if (widgetType && NSNotFound == [widgetTypes indexOfObject:widgetType])
            {
                continue;
            }
        }

        // widgetEvent.stateKey = widget id
        if (!widgets[widgetEvent.stateKey])
        {
            Widget *widget = [[Widget alloc] initWithWidgetEvent:widgetEvent inMatrixSession:room.mxSession];
            if (widget)
            {
                widgets[widget.widgetId] = widget;
            }
        }
    }

    // Return active widgets only
    NSMutableArray<Widget *> *activeWidgets = [NSMutableArray array];
    for (Widget *widget in widgets.allValues)
    {
        if (widget.isActive)
        {
            [activeWidgets addObject:widget];
        }
    }

    return activeWidgets;
}

- (MXHTTPOperation *)createWidget:(NSString*)widgetId
                      withContent:(NSDictionary<NSString*, NSObject*>*)widgetContent
                           inRoom:(MXRoom*)room
                          success:(void (^)(Widget *widget))success
                          failure:(void (^)(NSError *error))failure
{
    NSError *permissionError = [self checkWidgetPermissionInRoom:room];
    if (permissionError)
    {
        if (failure)
        {
            failure(permissionError);
        }
        return nil;
    }

    // Send a state event with the widget data
    // TODO: This API will be shortly replaced by a pure scalar API
    return [room sendStateEventOfType:kWidgetEventTypeString
                              content:widgetContent
                             stateKey:widgetId
                              success:nil failure:failure];
}


- (MXHTTPOperation *)createJitsiWidgetInRoom:(MXRoom*)room
                                   withVideo:(BOOL)video
                                     success:(void (^)(Widget *jitsiWidget))success
                                     failure:(void (^)(NSError *error))failure
{
    // Build data for a jitsi widget
    NSString *widgetId = [NSString stringWithFormat:@"%@_%@_%@", kWidgetTypeJitsi, room.mxSession.myUser.userId, @((uint64_t)([[NSDate date] timeIntervalSince1970] * 1000))];

    // Create a random enough jitsi conference id
    // Note: the jitsi server automatically creates conference when the conference
    // id does not exist yet
    NSString *widgetSessionId = [[[[NSProcessInfo processInfo] globallyUniqueString] substringToIndex:7] lowercaseString];
    NSString *confId = [room.roomId substringWithRange:NSMakeRange(1, [room.roomId rangeOfString:@":"].location - 1)];
    confId = [confId stringByAppendingString:widgetSessionId];

    // TODO: This url may come from scalar API
    // Note: this url can be used as is inside a web container (like iframe for Riot-web)
    // Riot-iOS does not directly use it but extracts params from it (see `[JitsiViewController openWidget:withVideo:]`)
    NSString *url = [NSString stringWithFormat:@"https://scalar-staging.riot.im/scalar/api/widgets/jitsi.html?confId=%@&isAudioConf=%@&displayName=$matrix_display_name&avatarUrl=$matrix_avatar_url&email=$matrix_user_id@", confId, video ? @"false" : @"true"];

    NSString *hash = [NSString stringWithFormat:@"%p", room.mxSession];
    successBlockForWidgetCreation[hash][widgetId] = success;
    failureBlockForWidgetCreation[hash][widgetId] = failure;

    return [self createWidget:widgetId
                  withContent:@{
                                @"url": url,
                                @"type": kWidgetTypeJitsi,
                                @"data": @{
                                        @"widgetSessionId": widgetSessionId
                                        }
                                }
                       inRoom:room
                      success:success
                      failure:failure];
}

- (MXHTTPOperation *)closeWidget:(NSString *)widgetId inRoom:(MXRoom *)room success:(void (^)())success failure:(void (^)(NSError *))failure
{
    NSError *permissionError = [self checkWidgetPermissionInRoom:room];
    if (permissionError)
    {
        if (failure)
        {
            failure(permissionError);
        }
        return nil;
    }

    // Send a state event with an empty content to disable the widget
    // TODO: This API will be shortly replaced by a pure scalar API
    return [room sendStateEventOfType:kWidgetEventTypeString
                              content:@{}
                             stateKey:widgetId
                              success:^(NSString *eventId)
            {
                if (success)
                {
                    success();
                }
            } failure:failure];
}

/**
 Check user's power for widgets management in a room.
 
 @param room the room to check.
 @return an NSError if the user cannot act on widgets in this room. Else, nil.
 */
- (NSError *)checkWidgetPermissionInRoom:(MXRoom *)room
{
    NSError *error;

    // Check user's power in the room
    MXRoomPowerLevels *powerLevels = room.state.powerLevels;
    NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:room.mxSession.myUser.userId];

    // The user must be able to send state events to manage widgets
    if (oneSelfPowerLevel < powerLevels.stateDefault)
    {
        error = [NSError errorWithDomain:WidgetManagerErrorDomain
                                             code:WidgetManagerErrorCodeNotEnoughPower
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"widget_no_power_to_manage", @"Vector", nil)
                                                    }];
    }

    return error;
}

- (void)addMatrixSession:(MXSession *)mxSession
{
     __weak __typeof__(self) weakSelf = self;

    NSString *hash = [NSString stringWithFormat:@"%p", mxSession];

    id listener = [mxSession listenToEventsOfTypes:@[kWidgetEventTypeString] onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {

        typeof(self) self = weakSelf;

        if (self && direction == MXTimelineDirectionForwards)
        {
            // stateKey = widgetId
            NSString *widgetId = event.stateKey;

            NSLog(@"[WidgetManager] New widget detected: %@ in %@", widgetId, event.roomId);

            Widget *widget = [[Widget alloc] initWithWidgetEvent:event inMatrixSession:mxSession];
            if (widget)
            {
                // If it is a widget we have just created, indicate its creation is complete
                if (self->successBlockForWidgetCreation[hash][widgetId])
                {
                    self->successBlockForWidgetCreation[hash][widgetId](widget);
                }

                // Broadcast the generic notification
                [[NSNotificationCenter defaultCenter] postNotificationName:kWidgetManagerDidUpdateWidgetNotification object:widget];
            }
            else
            {
                NSLog(@"[WidgetManager] Cannot decode new widget - event: %@", event);

                if (self->failureBlockForWidgetCreation[hash][widgetId])
                {
                    // If it is a widget we have just created, indicate its creation has failed somehow
                    NSError *error = [NSError errorWithDomain:WidgetManagerErrorDomain
                                                         code:WidgetManagerErrorCodeCreationFailed
                                                     userInfo:@{
                                                                NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"widget_creation_failure", @"Vector", nil)
                                                                }];

                    self->failureBlockForWidgetCreation[hash][widgetId](error);
                }
            }

            [self->successBlockForWidgetCreation[hash] removeObjectForKey:widgetId];
            [self->failureBlockForWidgetCreation[hash] removeObjectForKey:widgetId];
        }
    }];

    widgetEventListener[hash] = listener;
    successBlockForWidgetCreation[hash] = [NSMutableDictionary dictionary];
    failureBlockForWidgetCreation[hash] = [NSMutableDictionary dictionary];
}

- (void)removeMatrixSession:(MXSession *)mxSession
{
    // mxSession.myUser.userId and mxSession.matrixRestClient.credentials.userId may be nil here
    // So, use a kind of hash value instead
    NSString *hash = [NSString stringWithFormat:@"%p", mxSession];
    id listener = widgetEventListener[hash];

    [mxSession removeListener:listener];

    [widgetEventListener removeObjectForKey:hash];
    [successBlockForWidgetCreation removeObjectForKey:hash];
    [failureBlockForWidgetCreation removeObjectForKey:hash];
}

@end
