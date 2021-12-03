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

@protocol MXKEncryptionInfoViewDelegate;

/**
 MXKEncryptionInfoView class may be used to display the available information on a encrypted event.
 The event sender device may be verified, unverified, blocked or unblocked from this view.
 */
@interface MXKEncryptionInfoView : MXKView

/**
 The displayed event
 */
@property (nonatomic, readonly) MXEvent *mxEvent;

/**
 The matrix session.
 */
@property (nonatomic, readonly) MXSession *mxSession;

/**
 The event device info
 */
@property (nonatomic, readonly) MXDeviceInfo *mxDeviceInfo;

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *verifyButton;
@property (weak, nonatomic) IBOutlet UIButton *blockButton;
@property (weak, nonatomic) IBOutlet UIButton *confirmVerifyButton;

@property (nonatomic, weak) id<MXKEncryptionInfoViewDelegate> delegate;

/**
 Initialise an `MXKEncryptionInfoView` instance based on an encrypted event
 
 @param event the encrypted event.
 @param session the related matrix session.
 @return the newly created instance.
 */
- (instancetype)initWithEvent:(MXEvent*)event andMatrixSession:(MXSession*)session;

/**
 Initialise an `MXKEncryptionInfoView` instance based only on a device information.
 
 @param deviceInfo the device information.
 @param session the related matrix session.
 @return the newly created instance.
 */
- (instancetype)initWithDeviceInfo:(MXDeviceInfo*)deviceInfo andMatrixSession:(MXSession*)session;

/**
 The default text color in the text view. [UIColor blackColor] by default.
 */
@property (nonatomic) UIColor *defaultTextColor;

/**
 Action registered on 'UIControlEventTouchUpInside' event for each UIButton instance.
*/
- (IBAction)onButtonPressed:(id)sender;

@end


@protocol MXKEncryptionInfoViewDelegate <NSObject>

/**
 Called when the user changes the verified state of a device.
 
 @param encryptionInfoView the view.
 @param deviceInfo the device that has changed.
 */
- (void)encryptionInfoView:(MXKEncryptionInfoView*)encryptionInfoView didDeviceInfoVerifiedChange:(MXDeviceInfo*)deviceInfo;

@optional

/**
 Called when the user close the view without changing value.

 @param encryptionInfoView the view.
 */
- (void)encryptionInfoViewDidClose:(MXKEncryptionInfoView*)encryptionInfoView;

@end
