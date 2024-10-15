/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <MatrixSDK/MatrixSDK.h>

#import "MXKView.h"

/**
 MXKDeviceView class may be used to display the information of a user's device.
 The displayed device may be renamed or removed.
 */

@class MXKDeviceView;
@protocol MXKDeviceViewDelegate <NSObject>

/**
 Tells the delegate that an alert must be presented.
 
 @param deviceView the device view.
 @param alert the alert to present.
 */
- (void)deviceView:(MXKDeviceView*)deviceView presentAlertController:(UIAlertController*)alert;

@optional

/**
 Tells the delegate to dismiss the device view.
 
 @param deviceView the device view.
 @param isUpdated tell whether the device was updated (renamed, removed...).
 */
- (void)dismissDeviceView:(MXKDeviceView*)deviceView didUpdate:(BOOL)isUpdated;

@end

@interface MXKDeviceView : MXKView <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *renameButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

/**
 Initialize a device view to display the information of a user's device.
 
 @param device a user's device.
 @param session the matrix session.
 @return the newly created instance.
 */
- (instancetype)initWithDevice:(MXDevice*)device andMatrixSession:(MXSession*)session;

/**
 The delegate.
 */
@property (nonatomic, weak) id<MXKDeviceViewDelegate> delegate;

/**
 The default text color in the text view. [UIColor blackColor] by default.
 */
@property (nonatomic) UIColor *defaultTextColor;

/**
 Action registered on 'UIControlEventTouchUpInside' event for each UIButton instance.
 */
- (IBAction)onButtonPressed:(id)sender;

@end

