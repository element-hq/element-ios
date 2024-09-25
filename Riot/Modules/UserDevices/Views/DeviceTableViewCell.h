/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
