/*
 Copyright 2018 New Vector Ltd

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

@class DecryptionFailureTracker;

@class Analytics;
@import MatrixSDK;

@interface DecryptionFailureTracker : NSObject

/**
 Returns the shared tracker.

 @return the shared tracker.
 */
+ (instancetype)sharedInstance;

/**
 The delegate object to receive analytics events.
 */
@property (nonatomic, weak) Analytics *delegate;

/**
 Report an event unable to decrypt.

 This error can be momentary. The DecryptionFailureTracker will check if it gets
 fixed. Else, it will generate a failure (@see `trackFailures`).

 @param event the event.
 @param roomState the room state when the event was received.
 @param userId my user id.
 */
- (void)reportUnableToDecryptErrorForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState myUser:(NSString*)userId;

/**
 Flush current data.
 */
- (void)dispatch;

@end
