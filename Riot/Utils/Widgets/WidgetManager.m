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

NSString *const kMXKWidgetManagerDidUpdateWidgetNotification = @"kMXKWidgetManagerDidUpdateWidgetNotification";

@interface WidgetManager ()
{
    // MXSession kind of hash -> Listener for matrix events for widgets.
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

    // Create each widget with its lastest im.vector.modular.widgets state event
    for (MXEvent *widgetEvent in widgetEvents)
    {
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

- (void)addMatrixSession:(MXSession *)mxSession
{
    id listener = [mxSession listenToEventsOfTypes:@[kWidgetEventTypeString] onEvent:^(MXEvent *event, MXTimelineDirection direction, id customObject) {

        if (direction == MXTimelineDirectionForwards)
        {
            Widget *widget = [[Widget alloc] initWithWidgetEvent:event inMatrixSession:mxSession];
            if (widget)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKWidgetManagerDidUpdateWidgetNotification object:widget];
            }
        }
    }];

    NSString *hash = [NSString stringWithFormat:@"%p", mxSession];
    widgetEventListener[hash] = listener;
}

- (void)removeMatrixSession:(MXSession *)mxSession
{
    // mxSession.myUser.userId and mxSession.matrixRestClient.credentials.userId may be nil here
    // So, use a kind of hash value instead
    NSString *hash = [NSString stringWithFormat:@"%p", mxSession];
    id listener = widgetEventListener[hash];

    [mxSession removeListener:listener];

    [widgetEventListener removeObjectForKey:hash];
}

@end
