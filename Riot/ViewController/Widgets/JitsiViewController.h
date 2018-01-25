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

@protocol JitsiViewControllerDelegate;

/**
 The `JitsiViewController` is a VC for specifically handling a jitsi widget using the
 jitsi-meet iOS SDK instead of displaying it in a webview like other modular widgets.
 
 https://github.com/jitsi/jitsi-meet/tree/master/ios
 */
@interface JitsiViewController : MXKViewController <JitsiMeetViewDelegate>

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
 Make jitsi-meet iOS SDK open the jitsi conference indicated by a jitsi widget.
 
 @param widget the jitsi widget.
 @param video to indicate voice or video call.

 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)openWidget:(Widget*)widget withVideo:(BOOL)video
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure;

/**
 Hang up the jitsi conference call in progress.
 */
- (void)hangup;

/**
 The jitsi widget displayed by this `JitsiViewController`.
 */
@property (nonatomic, readonly) Widget *widget;

/**
 The delegate for the view controller.
 */
@property (nonatomic) id<JitsiViewControllerDelegate> delegate;

#pragma mark - Xib attributes

// The jitsi-meet SDK view
@property (weak, nonatomic) IBOutlet JitsiMeetView *jitsiMeetView;
@property (weak, nonatomic) IBOutlet UIButton *backToAppButton;

@end


/**
 Delegate for `JitsiViewController` object
 */
@protocol JitsiViewControllerDelegate <NSObject>

/**
 Tells the delegate to dismiss the jitsi view controller.

 @param jitsiViewController the jitsi view controller.
 @param completion the block to execute at the end of the operation.
 */
- (void)jitsiViewController:(JitsiViewController *)jitsiViewController dismissViewJitsiController:(void (^)())completion;

/**
 Tells the delegate to put the jitsi view controller in background.

 @param jitsiViewController the jitsi view controller.
 @param completion the block to execute at the end of the operation.
 */
- (void)jitsiViewController:(JitsiViewController *)jitsiViewController goBackToApp:(void (^)())completion;

@end
