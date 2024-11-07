/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
