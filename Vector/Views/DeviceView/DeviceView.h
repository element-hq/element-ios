/*
 Copyright 2016 OpenMarket Ltd
 
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

@class DeviceView;
@protocol DeviceViewDelegate <NSObject>

/**
 Tells the delegate that a MXKAlert must be presented.
 
 @param deviceView the device view.
 @param alert the alert to present.
 */
- (void)deviceView:(DeviceView*)deviceView presentMXKAlert:(MXKAlert*)alert;

@optional

/**
 Tells the delegate that the device was updated (renamed, removed...).
 
 @param deviceView the device view.
 */
- (void)deviceViewDidUpdate:(DeviceView*)deviceView;

@end

@interface DeviceView : UIView <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *renameButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

/**
 Initialize a device view to display the information of a user's device.
 */
- (instancetype)initWithDevice:(MXDevice*)device andMatrixSession:(MXSession*)session;

/**
 The delegate.
 */
@property (nonatomic) id<DeviceViewDelegate> delegate;

@end

