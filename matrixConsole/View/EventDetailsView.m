/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "EventDetailsView.h"

#import "RoomMessageComponent.h"
#import "MatrixSDKHandler.h"

@implementation EventDetailsView

- (void)setEvent:(MXEvent *)event {
    _event = event;
    
    if (event) {
        NSMutableDictionary *eventDict = [NSMutableDictionary dictionaryWithDictionary:event.originalDictionary];
        // Remove local ids
        if ([event.eventId hasPrefix:kLocalEchoEventIdPrefix] || [event.eventId hasPrefix:kFailedEventIdPrefix]) {
            [eventDict removeObjectForKey:@"event_id"];
        }
        // Remove event type added by SDK
        [eventDict removeObjectForKey:@"event_type"];
        // Remove null values and empty dictionaries
        for (NSString *key in eventDict.allKeys) {
            if ([[eventDict objectForKey:key] isEqual:[NSNull null]]) {
                [eventDict removeObjectForKey:key];
            } else if ([[eventDict objectForKey:key] isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = [eventDict objectForKey:key];
                if (!dict.count) {
                    [eventDict removeObjectForKey:key];
                }
            }
        }
        
        // Set text view content
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:eventDict
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        _textView.text = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } else {
        _textView.text = nil;
    }
    
    // FIXME enable Redact button
    _redactButton.enabled = NO;
}

- (void)dealloc {
    _event = nil;
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender {
    if (sender == _redactButton) {
        // FIXME
        self.hidden = YES;
    } else if (sender == _closeButton) {
        self.hidden = YES;
    }
}

@end