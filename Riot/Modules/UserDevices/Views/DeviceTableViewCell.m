/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "DeviceTableViewCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "MXRoom+Riot.h"

#define DEVICE_TABLEVIEW_ROW_CELL_HEIGHT_WITHOUT_LABEL_HEIGHT 59

@implementation DeviceTableViewCell

#pragma mark - Class methods

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.deviceName.textColor = ThemeService.shared.theme.textPrimaryColor;
    
    [self.verifyButton.layer setCornerRadius:5];
    self.verifyButton.clipsToBounds = YES;
    self.verifyButton.backgroundColor = ThemeService.shared.theme.tintColor;
    
    [self.blockButton.layer setCornerRadius:5];
    self.blockButton.clipsToBounds = YES;
    self.blockButton.backgroundColor = ThemeService.shared.theme.tintColor;
}

- (void)render:(MXDeviceInfo *)deviceInfo
{
    _deviceInfo = deviceInfo;
    
    self.deviceName.numberOfLines = 0;
    self.deviceName.text = (deviceInfo.displayName.length ? [NSString stringWithFormat:@"%@ (%@)", deviceInfo.displayName, deviceInfo.deviceId] : [NSString stringWithFormat:@"(%@)", deviceInfo.deviceId]);
    
    switch (deviceInfo.trustLevel.localVerificationStatus)
    {
        case MXDeviceUnknown:
        case MXDeviceUnverified:
        {
            self.deviceStatus.image = AssetImages.e2eWarning.image;
            
            [_verifyButton setTitle:[VectorL10n roomEventEncryptionInfoVerify] forState:UIControlStateNormal];
            [_verifyButton setTitle:[VectorL10n roomEventEncryptionInfoVerify] forState:UIControlStateHighlighted];
            [_blockButton setTitle:[VectorL10n roomEventEncryptionInfoBlock] forState:UIControlStateNormal];
            [_blockButton setTitle:[VectorL10n roomEventEncryptionInfoBlock] forState:UIControlStateHighlighted];
            break;
        }
        case MXDeviceVerified:
        {
            self.deviceStatus.image = AssetSharedImages.e2eVerified.image;
            
            [_verifyButton setTitle:[VectorL10n roomEventEncryptionInfoUnverify] forState:UIControlStateNormal];
            [_verifyButton setTitle:[VectorL10n roomEventEncryptionInfoUnverify] forState:UIControlStateHighlighted];
            [_blockButton setTitle:[VectorL10n roomEventEncryptionInfoBlock] forState:UIControlStateNormal];
            [_blockButton setTitle:[VectorL10n roomEventEncryptionInfoBlock] forState:UIControlStateHighlighted];
            
            break;
        }
        case MXDeviceBlocked:
        {
            self.deviceStatus.image = AssetImages.e2eBlocked.image;
            
            [_verifyButton setTitle:[VectorL10n roomEventEncryptionInfoVerify] forState:UIControlStateNormal];
            [_verifyButton setTitle:[VectorL10n roomEventEncryptionInfoVerify] forState:UIControlStateHighlighted];
            [_blockButton setTitle:[VectorL10n roomEventEncryptionInfoUnblock] forState:UIControlStateNormal];
            [_blockButton setTitle:[VectorL10n roomEventEncryptionInfoUnblock] forState:UIControlStateHighlighted];
            
            break;
        }
        default:
            break;
    }
}

+ (CGFloat)cellHeightWithDeviceInfo:(MXDeviceInfo*)deviceInfo andCellWidth:(CGFloat)width
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 50)];
    label.numberOfLines = 0;
    label.text = (deviceInfo.displayName.length ? [NSString stringWithFormat:@"%@ (%@)", deviceInfo.displayName, deviceInfo.deviceId] : [NSString stringWithFormat:@"(%@)", deviceInfo.deviceId]);
    [label sizeToFit];
    
    return label.frame.size.height + DEVICE_TABLEVIEW_ROW_CELL_HEIGHT_WITHOUT_LABEL_HEIGHT;
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender
{
    if (self.delegate)
    {
        MXDeviceVerification verificationStatus;
        
        if (sender == _verifyButton)
        {
            verificationStatus = ((_deviceInfo.trustLevel.localVerificationStatus == MXDeviceVerified) ? MXDeviceUnverified : MXDeviceVerified);
        }
        else if (sender == _blockButton)
        {
            verificationStatus = ((_deviceInfo.trustLevel.localVerificationStatus == MXDeviceBlocked) ? MXDeviceUnverified : MXDeviceBlocked);
        }
        else
        {
            // Unexpected case
            MXLogDebug(@"[DeviceTableViewCell] Invalid button pressed.");
            return;
        }
        
        [self.delegate deviceTableViewCell:self updateDeviceVerification:verificationStatus];
    }
}

@end
