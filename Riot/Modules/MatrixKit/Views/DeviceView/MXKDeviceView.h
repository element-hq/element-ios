/*
 Copyright 2016 OpenMarket Ltd
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

