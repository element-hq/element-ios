/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "TableViewCellWithPhoneNumberTextField.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "NBPhoneNumberUtil.h"

@implementation TableViewCellWithPhoneNumberTextField

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.mxkLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.mxkTextField.textColor = ThemeService.shared.theme.textSecondaryColor;
    self.mxkTextField.tintColor = ThemeService.shared.theme.tintColor;
    self.mxkTextField.backgroundColor = ThemeService.shared.theme.baseColor;
    
    _countryCodeButton.tintColor = ThemeService.shared.theme.textSecondaryColor;
    _isoCountryCodeLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
}

- (void)setIsoCountryCode:(NSString *)isoCountryCode
{
    _isoCountryCode = isoCountryCode;
    
    NSNumber *callingCode = [[NBPhoneNumberUtil sharedInstance] getCountryCodeForRegion:isoCountryCode];
    
    self.mxkLabel.text = [NSString stringWithFormat:@"+%@", callingCode.stringValue];
    
    self.isoCountryCodeLabel.text = isoCountryCode;
}

@end
