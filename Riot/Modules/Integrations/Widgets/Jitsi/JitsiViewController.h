/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

#import "WidgetManager.h"

@protocol JitsiViewControllerDelegate;

/**
 The `JitsiViewController` is a VC for specifically handling a jitsi widget using the
 jitsi-meet iOS SDK instead of displaying it in a webview like other modular widgets.
 
 https://github.com/jitsi/jitsi-meet/tree/master/ios
 */
@interface JitsiViewController : MXKViewController

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
           success:(void (^)(void))success
           failure:(void (^)(NSError *error))failure;

/**
 Set audio muted for the Jitsi call.
 */
- (void)setAudioMuted:(BOOL)muted;

/**
 Hang up the jitsi conference call in progress.
 */
- (void)hangup;

/**
 The jitsi widget displayed by this `JitsiViewController`.
 */
@property (nonatomic, readonly) Widget *widget;

/**
 Total duration of the call. In milliseconds.
 */
@property (nonatomic, readonly) NSUInteger callDuration;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<JitsiViewControllerDelegate> delegate;

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
- (void)jitsiViewController:(JitsiViewController *)jitsiViewController dismissViewJitsiController:(void (^)(void))completion;

/**
 Tells the delegate to put the jitsi view controller in background.

 @param jitsiViewController the jitsi view controller.
 @param completion the block to execute at the end of the operation.
 */
- (void)jitsiViewController:(JitsiViewController *)jitsiViewController goBackToApp:(void (^)(void))completion;

@end
