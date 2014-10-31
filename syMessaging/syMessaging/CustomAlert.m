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

#import "CustomAlert.h"

#import <objc/runtime.h>

@interface CustomAlert()
{
    // alert is kind of UIAlertController for IOS 8 and later, in other cases it's kind of UIAlertView or UIActionSheet.
    id alert;
    UIViewController* parentViewController;
    
    NSMutableArray *actions; // use only for iOS < 8
}
@end

@implementation CustomAlert

- (void)dealloc {
    // iOS < 8
    if ([alert isKindOfClass:[UIActionSheet class]] || [alert isKindOfClass:[UIAlertView class]]) {
        // Dismiss here AlertView or ActionSheet (if any) because its delegate is deallocated
        [self dismiss:NO];
    }
    
    alert = nil;
    parentViewController = nil;
    actions = nil;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message style:(CustomAlertStyle)style {
    if (self = [super init]) {
        // Check iOS version
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
            alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:(UIAlertControllerStyle)style];
        } else {
            // Use legacy objects
            if (style == CustomAlertStyleActionSheet) {
                alert = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            } else {
                alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
            }
            
            self.cancelButtonIndex = -1;
        }
    }
    return self;
}


- (NSInteger)addActionWithTitle:(NSString *)title style:(CustomAlertActionStyle)style handler:(blockCustomAlert_onClick)handler {
    NSInteger index = 0;
    if ([alert isKindOfClass:[UIAlertController class]]) {
        index = [(UIAlertController *)alert actions].count;
        UIAlertAction* action = [UIAlertAction actionWithTitle:title
                                                         style:(UIAlertActionStyle)style
                                                       handler:^(UIAlertAction * action) {
                                                           if (handler) {
                                                               handler(self);
                                                           }
                                                       }];
        
        [(UIAlertController *)alert addAction:action];
    } else if ([alert isKindOfClass:[UIActionSheet class]]) {
        if (actions == nil) {
            actions = [NSMutableArray array];
        }
        index = [(UIActionSheet *)alert addButtonWithTitle:title];
        if (handler) {
            [actions addObject:handler];
        } else {
            [actions addObject:[NSNull null]];
        }
    } else if ([alert isKindOfClass:[UIAlertView class]]) {
        if (actions == nil) {
            actions = [NSMutableArray array];
        }
        index = [(UIAlertView *)alert addButtonWithTitle:title];
        if (handler) {
            [actions addObject:handler];
        } else {
            [actions addObject:[NSNull null]];
        }
    }
    return index;
}

- (void)addTextFieldWithConfigurationHandler:(blockCustomAlert_textFieldHandler)configurationHandler {
    if ([alert isKindOfClass:[UIAlertController class]]) {
        [(UIAlertController *)alert addTextFieldWithConfigurationHandler:configurationHandler];
    } else if ([alert isKindOfClass:[UIAlertView class]]) {
        UIAlertView *alertView = (UIAlertView *)alert;
        // Check the current style
        if (alertView.alertViewStyle == UIAlertViewStyleDefault) {
            // Add the first text fields
            alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            
            // Store the callback
            UITextField *textField = [alertView textFieldAtIndex:0];
            objc_setAssociatedObject(textField, "configurationHandler", [configurationHandler copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        } else if (alertView.alertViewStyle != UIAlertViewStyleLoginAndPasswordInput) {
            // Add a second text field
            alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
            
            // Store the callback
            UITextField *textField = [alertView textFieldAtIndex:1];
            objc_setAssociatedObject(textField, "configurationHandler", [configurationHandler copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        // CAUTION 1: only 2 text fields are supported fro iOS < 8
        // CAUTION 2: alert style "UIAlertViewStyleSecureTextInput" is not supported, use the configurationHandler to handle secure text field
    }
}

- (void)showInViewController:(UIViewController*)viewController {
    if ([alert isKindOfClass:[UIAlertController class]]) {
        if (viewController) {
            parentViewController = viewController;
            [viewController presentViewController:(UIAlertController *)alert animated:YES completion:nil];
        }
    } else if ([alert isKindOfClass:[UIActionSheet class]]) {
        [(UIActionSheet *)alert showInView:[[UIApplication sharedApplication] keyWindow]];
    } else if ([alert isKindOfClass:[UIAlertView class]]) {
        UIAlertView *alertView = (UIAlertView *)alert;
        if (alertView.alertViewStyle != UIAlertViewStyleDefault) {
            // Call here textField handlers
            UITextField *textField = [alertView textFieldAtIndex:0];
            blockCustomAlert_textFieldHandler configurationHandler = objc_getAssociatedObject(self, "configurationHandler");
            if (configurationHandler) {
                configurationHandler (textField);
            }
            if (alertView.alertViewStyle == UIAlertViewStyleLoginAndPasswordInput) {
                textField = [alertView textFieldAtIndex:1];
                blockCustomAlert_textFieldHandler configurationHandler = objc_getAssociatedObject(self, "configurationHandler");
                if (configurationHandler) {
                    configurationHandler (textField);
                }
            }
        }
        [alertView show];
    }
}

- (void)dismiss:(BOOL)animated {
    if ([alert isKindOfClass:[UIAlertController class]]) {
        [parentViewController dismissViewControllerAnimated:animated completion:nil];
    } else if ([alert isKindOfClass:[UIActionSheet class]]) {
        [((UIActionSheet *)alert) dismissWithClickedButtonIndex:self.cancelButtonIndex animated:animated];
    } else if ([alert isKindOfClass:[UIAlertView class]]) {
        [((UIAlertView *)alert) dismissWithClickedButtonIndex:self.cancelButtonIndex animated:animated];
    }
    alert = nil;
}

- (UITextField *)textFieldAtIndex:(NSInteger)textFieldIndex{
    if ([alert isKindOfClass:[UIAlertController class]]) {
        return [((UIAlertController*)alert).textFields objectAtIndex:textFieldIndex];
    } else if ([alert isKindOfClass:[UIAlertView class]]) {
        return [((UIAlertView*)alert) textFieldAtIndex:textFieldIndex];
    }
    return nil;
}

#pragma mark - UIAlertViewDelegate (iOS < 8)

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // Retrieve the callback
    blockCustomAlert_onClick block = [actions objectAtIndex:buttonIndex];
    if ([block isEqual:[NSNull null]] == NO) {
        // And call it
        block(self);
    }
    alert = nil;
}

#pragma mark - UIActionSheetDelegate (iOS < 8)

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Retrieve the callback
    blockCustomAlert_onClick block = [actions objectAtIndex:buttonIndex];
    if ([block isEqual:[NSNull null]] == NO) {
        // And call it
        block(self);
    }
    alert = nil;
}

@end
