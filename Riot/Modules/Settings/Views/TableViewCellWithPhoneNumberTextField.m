/*
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
