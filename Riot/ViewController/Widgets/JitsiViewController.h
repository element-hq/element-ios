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

#import <MatrixKit/MatrixKit.h>

#import <JitsiMeet/JitsiMeet.h>

#import "WidgetManager.h"

/**
 The `JitsiViewController` is a specific VC for handling a jitsi widget using
 jitsi-meet iOS SDK instead of displaying it in a webview like other scalar widgets.
 
 https://github.com/jitsi/jitsi-meet/tree/master/ios
 
 */
@interface JitsiViewController : MXKViewController <JitsiMeetViewDelegate>

/**
 The jitsi-meet SDK view.
 */
@property (weak, nonatomic) IBOutlet JitsiMeetView *jitsiMeetView;

/**
 Returns the `UINib` object initialized for a `JitsiViewController`.

 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `JitsiViewController` object.

 @discussion This is the designated initializer for programmatic instantiation.

 @return An initialized `JitsiViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)jitsiViewController;

/**
 Make
 */
- (BOOL)openWidget:(Widget*)widget withVideo:(BOOL)video;

/**
 The jitsi widget displayed by this `JitsiViewController`.
 */
@property (nonatomic, readonly) Widget *widget;

@end
