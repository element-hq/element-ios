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
#import "AppDelegate.h"

@interface EventDetailsView () {
    // Manage the reuse of the view whereas requests are still in progress
    NSUInteger redactionRequestCount;
    BOOL shouldKeepVisible;
}
@end

@implementation EventDetailsView

- (void)setEvent:(MXEvent *)event {
    _event = event;
    // Disable redact button by default
    _redactButton.enabled = NO;
    
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
                } else {
                    NSMutableDictionary *updatedDict = [NSMutableDictionary dictionaryWithDictionary:dict];
                    for (NSString *subKey in dict.allKeys) {
                        if ([[dict objectForKey:subKey] isEqual:[NSNull null]]) {
                            [updatedDict removeObjectForKey:subKey];
                        }
                    }
                    [eventDict setObject:updatedDict forKey:key];
                }
            }
        }
        
        // Set text view content
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:eventDict
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        _textView.text = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        // Check whether the user can redact this event
        if (!event.redactedBecause) {
            // Here the event has not been already redacted, check the user's power level
            MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
            MXRoom *mxRoom = [mxHandler.mxSession roomWithRoomId:event.roomId];
            if (mxRoom) {
                MXRoomPowerLevels *powerLevels = [mxRoom.state powerLevels];
                NSUInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:mxHandler.userId];
                if (powerLevels.redact) {
                    if (userPowerLevel >= powerLevels.redact) {
                        _redactButton.enabled = YES;
                    }
                } else if (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsMessage:kMXEventTypeStringRoomRedaction]) {
                    _redactButton.enabled = YES;
                }
            }
        }
    } else {
        _textView.text = nil;
    }
    
    // Hide potential activity indicator
    [_activityIndicator stopAnimating];
}

- (void)dealloc {
    _event = nil;
}

- (void)setHidden:(BOOL)hidden {
    if (hidden) {
        // The view will be hidden, release the event
        self.event = nil;
        shouldKeepVisible = NO;
    }
    else if (self.isHidden && redactionRequestCount) {
        // Here we will show a view which was hidden whereas at least a redaction request is in progress.
        // We must keep visible the view when the request(s) will answer.
        shouldKeepVisible = YES;
    }
    
    super.hidden = hidden;
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender {
    if (sender == _redactButton) {
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        MXRoom *mxRoom = [mxHandler.mxSession roomWithRoomId:_event.roomId];
        if (mxRoom) {
            [_activityIndicator startAnimating];
            redactionRequestCount++;
            shouldKeepVisible = NO;
            [mxRoom redactEvent:_event.eventId reason:nil success:^{
                [_activityIndicator stopAnimating];
                redactionRequestCount--;
                if (!shouldKeepVisible && !redactionRequestCount) {
                    self.hidden = YES;
                }
            } failure:^(NSError *error) {
                NSLog(@"Redact event failed: %@", error);
                // Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
                [_activityIndicator stopAnimating];
                redactionRequestCount--;
                if (!shouldKeepVisible && !redactionRequestCount) {
                    self.hidden = YES;
                }
            }];
        }
        
    } else if (sender == _closeButton) {
        self.hidden = YES;
    }
}

@end