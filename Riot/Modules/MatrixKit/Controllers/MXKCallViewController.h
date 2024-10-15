/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import <MatrixSDK/MatrixSDK.h>

#import "MXKViewController.h"

#import "MXKImageView.h"

@class MXKCallViewController;

/**
 Delegate for `MXKCallViewController` object
 */
@protocol MXKCallViewControllerDelegate <NSObject>

/**
 Tells the delegate to dismiss the call view controller.
 This callback is called when the user wants to go back into the app during a call or when the call is ended.
 The delegate should check the state of the associated call to know the actual reason.
 
 @param callViewController the call view controller.
 @param completion the block to execute at the end of the operation.
 */
- (void)dismissCallViewController:(MXKCallViewController *)callViewController completion:(void (^)(void))completion;

/**
 Tells the delegate that user tapped on hold call.
 @param callViewController the call view controller.
 */
- (void)callViewControllerDidTapOnHoldCall:(MXKCallViewController *)callViewController;

@end

extern NSString *const kMXKCallViewControllerWillAppearNotification;
extern NSString *const kMXKCallViewControllerAppearedNotification;
extern NSString *const kMXKCallViewControllerWillDisappearNotification;
extern NSString *const kMXKCallViewControllerDisappearedNotification;
extern NSString *const kMXKCallViewControllerBackToAppNotification;

/**
 'MXKCallViewController' instance displays a call. Only one matrix session is supported by this view controller.
 */
@interface MXKCallViewController : MXKViewController <MXCallDelegate, AVAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet MXKImageView *backgroundImageView;

@property (weak, nonatomic, readonly) IBOutlet UIView *localPreviewContainerView;
@property (weak, nonatomic, readonly) IBOutlet UIView *localPreviewVideoView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *localPreviewActivityView;

@property (weak, nonatomic, readonly) IBOutlet UIView *onHoldCallContainerView;
@property (weak, nonatomic) IBOutlet MXKImageView *onHoldCallerImageView;

@property (weak, nonatomic, readonly) IBOutlet UIView *remotePreviewContainerView;

@property (weak, nonatomic) IBOutlet UIView *overlayContainerView;
@property (weak, nonatomic) IBOutlet UIView *callContainerView;
@property (weak, nonatomic) IBOutlet MXKImageView *callerImageView;
@property (weak, nonatomic) IBOutlet UIImageView *pausedIcon;
@property (weak, nonatomic) IBOutlet UILabel *callerNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *callStatusLabel;
@property (weak, nonatomic) IBOutlet UIButton *resumeButton;

@property (weak, nonatomic) IBOutlet UIView *callToolBar;
@property (weak, nonatomic) IBOutlet UIButton *rejectCallButton;
@property (weak, nonatomic) IBOutlet UIButton *answerCallButton;
@property (weak, nonatomic) IBOutlet UIButton *endCallButton;

@property (weak, nonatomic) IBOutlet UIView *callControlContainerView;
@property (weak, nonatomic) IBOutlet UIButton *speakerButton;
@property (weak, nonatomic) IBOutlet UIButton *audioMuteButton;
@property (weak, nonatomic) IBOutlet UIButton *videoMuteButton;
@property (weak, nonatomic) IBOutlet UIButton *moreButtonForVoice;
@property (weak, nonatomic) IBOutlet UIButton *moreButtonForVideo;

@property (weak, nonatomic) IBOutlet UIButton *backToAppButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraSwitchButton;

@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *localPreviewContainerViewLeadingConstraint;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *localPreviewContainerViewTopConstraint;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *localPreviewContainerViewHeightConstraint;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *localPreviewContainerViewWidthConstraint;

@property (weak, nonatomic) IBOutlet UIButton *transferButton;

/**
 The default picture displayed when no picture is available.
 */
@property (nonatomic) UIImage *picturePlaceholder;

/**
 The call status bar displayed on the top of the app during a call.
 */
@property (nonatomic, readonly) UIWindow *backToAppStatusWindow;

/**
 Flag whether this call screen is displaying an alert right now.
 */
@property (nonatomic, readonly, getter=isDisplayingAlert) BOOL displayingAlert;

/**
 The current call
 */
@property (nonatomic) MXCall *mxCall;

/**
 The current call on hold
 */
@property (nonatomic) MXCall *mxCallOnHold;

/**
 The current peer
 */
@property (nonatomic, readonly) MXUser *peer;

/**
 The current peer of the call on hold
 */
@property (nonatomic, readonly) MXUser *peerOnHold;

/**
 The delegate.
 */
@property (nonatomic, weak) id<MXKCallViewControllerDelegate> delegate;

/*
 Specifies whether a ringtone must be played on incoming call.
 It's important to set this value before you will set `mxCall` otherwise value of this property can has no effect.
 
 Defaults to YES.
 */
@property (nonatomic) BOOL playRingtone;

#pragma mark - Class methods

/**
 Returns the `UINib` object initialized for a `MXKCallViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `roomViewController` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKCallViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 
 @param call a MXCall instance.
 @return An initialized `MXKRoomViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)callViewController:(MXCall *)call;

/**
 Return an audio file url based on the provided name.
 
 @param soundName audio file name without extension.
 @return a NSURL instance.
 */
- (NSURL*)audioURLWithName:(NSString *)soundName;

/**
 Refresh the peer information in the call viewcontroller's view.
 */
- (void)updatePeerInfoDisplay;

/**
 Adjust the layout of the preview container.
 */
- (void)updateLocalPreviewLayout;

/**
 Show/Hide the overlay view.
 
 @param isShown tell whether the overlay is shown or not.
 */
- (void)showOverlayContainer:(BOOL)isShown;

/**
 Set up or teardown the promixity monitoring and enable/disable the idle timer according to call type, state & audio route.
 */
- (void)updateProximityAndSleep;

/**
 Prepare and return the optional view displayed during incoming call notification.
 Return nil by default
 
 Subclasses may override this method to provide appropriate for their app view.
 When this method is called peer and mxCall are valid so you can use them.
 */
- (UIView *)createIncomingCallView;

/**
 Action registered on the event 'UIControlEventTouchUpInside' for each UIButton instance.
 */
- (IBAction)onButtonPressed:(id)sender;

/**
 Default implementation presents an action sheet with proper options. Override to change the user interface.
 */
- (void)showAudioDeviceOptions;

/**
 Default implementation makes the button selected for loud speakers and external device options, non-selected for built-in device.
 */
- (void)configureSpeakerButton;

#pragma mark - DTMF

/**
 Default implementation does nothing. Override to show a dial pad and then use MXCall methods to send DTMF tones.
 */
- (void)openDialpad;

#pragma mark - Call Transfer

/**
 Default implementation does nothing. Override to show a contact selection screen and then use MXCallManager methods to start the transfer.
 */
- (void)openCallTransfer;

@end
