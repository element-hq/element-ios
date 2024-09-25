/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "UIAlertController+MatrixKit.h"

@implementation UIAlertController (MatrixKit)

- (void)mxk_setAccessibilityIdentifier:(NSString *)accessibilityIdentifier
{
    self.view.accessibilityIdentifier = accessibilityIdentifier;
    
    for (UIAlertAction *action in self.actions)
    {
        action.accessibilityLabel = [NSString stringWithFormat:@"%@Action%@", accessibilityIdentifier, action.title];
    }
    
    NSArray *textFieldArray = self.textFields;
    for (NSUInteger index = 0; index < textFieldArray.count; index++)
    {
        UITextField *textField = textFieldArray[index];
        textField.accessibilityIdentifier = [NSString stringWithFormat:@"%@TextField%tu", accessibilityIdentifier, index];
    }
}

@end
