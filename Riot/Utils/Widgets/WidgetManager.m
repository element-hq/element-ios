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

@interface WidgetManager ()
{
    // UserId -> Listener for matrix events for widgets.
    // There is one per matrix session.
    NSMutableDictionary<NSString*, id> *widgetEventListener;
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
    }
    return self;
}

- (NSArray<Widget *> *)widgetsInRoom:(MXRoom *)room
{
    NSMutableArray<Widget *> *widgets = [NSMutableArray array];

    // TODO: stateEventWithType should return an array
    MXEvent *widgetEvent = [room.state stateEventWithType:kWidgetEventTypeString];

    if (widgetEvent)
    {
        Widget *widget = [[Widget alloc] initWithWidgetEvent:widgetEvent inMatrixSession:room.mxSession];

        if (widget.isActive)
        {
            [widgets addObject:widget];
        }
    }

    return widgets;
}

- (void)addMatrixSession:(MXSession *)mxSession
{
    id listener = [mxSession listenToEventsOfTypes:@[kWidgetEventTypeString] onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {

        if (direction == MXTimelineDirectionForwards)
        {
            // @TODO
            NSLog(@"event : %@", event);
        }
    }];

    widgetEventListener[mxSession.matrixRestClient.credentials.userId] = listener;
}

- (void)removeMatrixSession:(MXSession *)mxSession
{
    id listener = widgetEventListener[mxSession.myUser.userId];

    [mxSession removeListener:listener];

    [widgetEventListener removeObjectForKey:mxSession.matrixRestClient.credentials.userId];
}

@end
