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

#import "DeviceTableViewCell.h"

#import "RiotDesignValues.h"
#import "MXRoom+Riot.h"

#define DEVICE_TABLEVIEW_ROW_CELL_HEIGHT_WITHOUT_LABEL_HEIGHT 59

@implementation DeviceTableViewCell

#pragma mark - Class methods

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.deviceName.textColor = kRiotPrimaryTextColor;
    
    [self.verifyButton.layer setCornerRadius:5];
    self.verifyButton.clipsToBounds = YES;
    self.verifyButton.backgroundColor = kRiotColorGreen;
    
    [self.blockButton.layer setCornerRadius:5];
    self.blockButton.clipsToBounds = YES;
    self.blockButton.backgroundColor = kRiotColorGreen;
}

- (void)render:(MXDeviceInfo *)deviceInfo
{
    _deviceInfo = deviceInfo;
    
    self.deviceName.numberOfLines = 0;
    self.deviceName.text = (deviceInfo.displayName.length ? [NSString stringWithFormat:@"%@ (%@)", deviceInfo.displayName, deviceInfo.deviceId] : [NSString stringWithFormat:@"(%@)", deviceInfo.deviceId]);
    
    switch (deviceInfo.verified)
    {
        case MXDeviceUnknown:
        case MXDeviceUnverified:
        {
            self.deviceStatus.image = [UIImage imageNamed:@"e2e_warning"];
            
            [_verifyButton setTitle:[NSBundle mxk_localizedStringForKey:@"room_event_encryption_info_verify"] forState:UIControlStateNormal];
            [_verifyButton setTitle:[NSBundle mxk_localizedStringForKey:@"room_event_encryption_info_verify"] forState:UIControlStateHighlighted];
            [_blockButton setTitle:[NSBundle mxk_localizedStringForKey:@"room_event_encryption_info_block"] forState:UIControlStateNormal];
            [_blockButton setTitle:[NSBundle mxk_localizedStringForKey:@"room_event_encryption_info_block"] forState:UIControlStateHighlighted];
            break;
        }
        case MXDeviceVerified:
        {
            self.deviceStatus.image = [UIImage imageNamed:@"e2e_verified"];
            
            [_verifyButton setTitle:[NSBundle mxk_localizedStringForKey:@"room_event_encryption_info_unverify"] forState:UIControlStateNormal];
            [_verifyButton setTitle:[NSBundle mxk_localizedStringForKey:@"room_event_encryption_info_unverify"] forState:UIControlStateHighlighted];
            [_blockButton setTitle:[NSBundle mxk_localizedStringForKey:@"room_event_encryption_info_block"] forState:UIControlStateNormal];
            [_blockButton setTitle:[NSBundle mxk_localizedStringForKey:@"room_event_encryption_info_block"] forState:UIControlStateHighlighted];
            
            break;
        }
        case MXDeviceBlocked:
        {
            self.deviceStatus.image = [UIImage imageNamed:@"e2e_blocked"];
            
            [_verifyButton setTitle:[NSBundle mxk_localizedStringForKey:@"room_event_encryption_info_verify"] forState:UIControlStateNormal];
            [_verifyButton setTitle:[NSBundle mxk_localizedStringForKey:@"room_event_encryption_info_verify"] forState:UIControlStateHighlighted];
            [_blockButton setTitle:[NSBundle mxk_localizedStringForKey:@"room_event_encryption_info_unblock"] forState:UIControlStateNormal];
            [_blockButton setTitle:[NSBundle mxk_localizedStringForKey:@"room_event_encryption_info_unblock"] forState:UIControlStateHighlighted];
            
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
            verificationStatus = ((_deviceInfo.verified == MXDeviceVerified) ? MXDeviceUnverified : MXDeviceVerified);
        }
        else if (sender == _blockButton)
        {
            verificationStatus = ((_deviceInfo.verified == MXDeviceBlocked) ? MXDeviceUnverified : MXDeviceBlocked);
        }
        else
        {
            // Unexpected case
            NSLog(@"[DeviceTableViewCell] Invalid button pressed.");
            return;
        }
        
        [self.delegate deviceTableViewCell:self updateDeviceVerification:verificationStatus];
    }
}

@end
