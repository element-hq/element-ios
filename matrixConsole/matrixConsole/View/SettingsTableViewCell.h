/*
 Copyright 2014 OpenMarket Ltd
 
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

#import <UIKit/UIKit.h>

@interface SettingsTableViewCell : UITableViewCell
@end

@interface SettingsCellWithSwitch : SettingsTableViewCell
@property (strong, nonatomic) IBOutlet UILabel *settingLabel;
@property (strong, nonatomic) IBOutlet UISwitch *settingSwitch;
@end

@interface SettingsCellWithTextView : SettingsTableViewCell
@property (strong, nonatomic) IBOutlet UITextView *settingTextView;
@end

@interface SettingsCellWithLabelAndTextField : SettingsTableViewCell
@property (strong, nonatomic) IBOutlet UILabel *settingLabel;
@property (strong, nonatomic) IBOutlet UITextField *settingTextField;
@end

@interface SettingsCellWithLabelAndSlider : SettingsTableViewCell
@property (strong, nonatomic) IBOutlet UILabel *settingLabel;
@property (strong, nonatomic) IBOutlet UISlider *settingSlider;
@end

@interface SettingsCellWithTextFieldAndButton : SettingsTableViewCell
@property (strong, nonatomic) IBOutlet UITextField *settingTextField;
@property (strong, nonatomic) IBOutlet UIButton *settingButton;
@end