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

#import "RiotDesignValues.h"

#import "NBPhoneNumberUtil.h"

@implementation TableViewCellWithPhoneNumberTextField

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.mxkLabel.textColor = kRiotPrimaryTextColor;
    self.mxkTextField.textColor = kRiotPrimaryTextColor;
    
    _isoCountryCodeLabel.textColor = kRiotPrimaryTextColor;
}

- (void)setIsoCountryCode:(NSString *)isoCountryCode
{
    _isoCountryCode = isoCountryCode;
    
    NSNumber *callingCode = [[NBPhoneNumberUtil sharedInstance] getCountryCodeForRegion:isoCountryCode];
    
    self.mxkLabel.text = [NSString stringWithFormat:@"+%@", callingCode.stringValue];
    
    self.isoCountryCodeLabel.text = isoCountryCode;
}

@end
