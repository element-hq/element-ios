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

#import <MatrixSDK/MatrixSDK.h>

#import "MatrixKit.h"

/**
 The `DeviceTableViewCell` cell displays the information on a device.
 */

@class DeviceTableViewCell;
@protocol DeviceTableViewCellDelegate <NSObject>

/**
 Tells the delegate that the device state must be updated.
 
 @param deviceTableViewCell the device table view cell.
 @param verificationStatus the requested verification status.
 */
- (void)deviceTableViewCell:(DeviceTableViewCell*)deviceTableViewCell updateDeviceVerification:(MXDeviceVerification)verificationStatus;

@end

@interface DeviceTableViewCell : MXKTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *deviceName;
@property (weak, nonatomic) IBOutlet UIImageView *deviceStatus;

@property (weak, nonatomic) IBOutlet UIButton *verifyButton;
@property (weak, nonatomic) IBOutlet UIButton *blockButton;

@property (readonly) MXDeviceInfo *deviceInfo;

/**
 The delegate.
 */
@property (nonatomic) id<DeviceTableViewCellDelegate> delegate;

/**
 Update the information displayed by the cell.
 
 @param deviceInfo the device to render.
 */
- (void)render:(MXDeviceInfo *)deviceInfo;

/**
 Get the cell height for a given device information.

 @param deviceInfo the device information.
 @param width the extimated cell width.
 @return the cell height.
 */
+ (CGFloat)cellHeightWithDeviceInfo:(MXDeviceInfo*)deviceInfo andCellWidth:(CGFloat)width;

@end
