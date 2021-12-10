/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "MXKTableViewCell.h"

/**
 MXPushRuleCreationTableViewCell instance is a table view cell used to create a new push rule.
 */
@interface MXKPushRuleCreationTableViewCell : MXKTableViewCell <UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

/**
 The category the created push rule will belongs to (MXPushRuleKindContent by default).
 */
@property (nonatomic) MXPushRuleKind mxPushRuleKind;

/**
 The related matrix session
 */
@property (nonatomic) MXSession* mxSession;

/**
 The graphics items
 */
@property (strong, nonatomic) IBOutlet UITextField* inputTextField;

@property (unsafe_unretained, nonatomic) IBOutlet UISegmentedControl *actionSegmentedControl;
@property (unsafe_unretained, nonatomic) IBOutlet UISwitch *soundSwitch;
@property (unsafe_unretained, nonatomic) IBOutlet UISwitch *highlightSwitch;

@property (strong, nonatomic) IBOutlet UIButton* addButton;

@property (strong, nonatomic) IBOutlet UIPickerView* roomPicker;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *roomPickerDoneButton;

/**
 Force dismiss keyboard.
 */
- (void)dismissKeyboard;

/**
 Action registered to handle text field editing change (UIControlEventEditingChanged).
 */
- (IBAction)textFieldEditingChanged:(id)sender;

/**
 Action registered on the following events:
 - 'UIControlEventTouchUpInside' for UIButton instances.
 - 'UIControlEventValueChanged' for UISwitch and UISegmentedControl instances.
 */
- (IBAction)onButtonPressed:(id)sender;

@end
