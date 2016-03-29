/*
 Copyright 2016 OpenMarket Ltd
 
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

#import "AuthInputsView.h"

#import "VectorDesignValues.h"

@implementation AuthInputsView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self)
                          bundle:[NSBundle bundleForClass:self]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _repeatPasswordTextField.placeholder = NSLocalizedStringFromTable(@"auth_repeat_password_placeholder", @"Vector", nil);
    _repeatPasswordTextField.textColor = kVectorTextColorBlack;
    
    self.userLoginTextField.placeholder = NSLocalizedStringFromTable(@"auth_user_id_placeholder", @"Vector", nil);
    self.userLoginTextField.textColor = kVectorTextColorBlack;
    
    self.passWordTextField.placeholder = NSLocalizedStringFromTable(@"auth_password_placeholder", @"Vector", nil);
    self.passWordTextField.textColor = kVectorTextColorBlack;
    
    self.emailTextField.placeholder = NSLocalizedStringFromTable(@"auth_email_placeholder", @"Vector", nil);
    self.emailTextField.textColor = kVectorTextColorBlack;
}

#pragma mark -

- (BOOL)setAuthSession:(MXAuthenticationSession *)authSession withAuthType:(MXKAuthenticationType)authType;
{
    // Validate first the provided session
    MXAuthenticationSession *validSession = [self validateAuthenticationSession:authSession];
    
    if ([super setAuthSession:validSession withAuthType:authType])
    {
        if (authType == MXKAuthenticationTypeLogin)
        {
            self.passWordTextField.returnKeyType = UIReturnKeyDone;
            
            self.userLoginTextField.placeholder = NSLocalizedStringFromTable(@"auth_user_id_placeholder", @"Vector", nil);
            
            self.userLoginContainerTopConstraint.constant = 0;
            self.passwordContainerTopConstraint.constant = 50;
            
            self.emailContainer.hidden = YES;
            self.repeatPasswordContainer.hidden = YES;
        }
        else
        {
            self.passWordTextField.returnKeyType = UIReturnKeyNext;
            
            self.userLoginTextField.placeholder = NSLocalizedStringFromTable(@"auth_user_name_placeholder", @"Vector", nil);
            
            self.userLoginContainerTopConstraint.constant = 50;
            self.passwordContainerTopConstraint.constant = 100;
            
            self.emailContainer.hidden = NO;
            self.repeatPasswordContainer.hidden = NO;
        }
        
        return YES;
    }
    
    return NO;
}

- (CGFloat)actualHeight
{
    return self.viewHeightConstraint.constant;
}

- (BOOL)areAllRequiredFieldsFilled
{
    if (self.isPasswordBasedFlowSupported)
    {
        if (type == MXKAuthenticationTypeLogin)
        {
            return (self.userLoginTextField.text.length && self.passWordTextField.text.length);
        }
        else
        {
            return (self.userLoginTextField.text.length && self.passWordTextField.text.length && self.repeatPasswordTextField.text.length);
        }
    }
    
    return (self.userLoginTextField.text.length && (!self.isEmailIdentityFlowRequired || self.emailTextField.text.length) && self.passWordTextField.text.length && self.repeatPasswordTextField.text.length);
}

- (void)dismissKeyboard
{
    [self.userLoginTextField resignFirstResponder];
    [self.passWordTextField resignFirstResponder];
    [self.emailTextField resignFirstResponder];
    [self.repeatPasswordTextField resignFirstResponder];
    
    [super dismissKeyboard];
}

#pragma mark UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if (textField.returnKeyType == UIReturnKeyDone)
    {
        // "Done" key has been pressed
        [textField resignFirstResponder];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(authInputsDoneKeyHasBeenPressed:)])
        {
            // Launch authentication now
            [self.delegate authInputsDoneKeyHasBeenPressed:self];
        }
    }
    else
    {
        //"Next" key has been pressed
        if (textField == self.emailTextField)
        {
            [self.userLoginTextField becomeFirstResponder];
        }
        else if (textField == self.userLoginTextField)
        {
            [self.passwordContainer becomeFirstResponder];
        }
        else if (textField == self.passWordTextField)
        {
            [self.repeatPasswordTextField becomeFirstResponder];
        }
    }
    
    return YES;
}

#pragma mark -

// Tell whether a flow type is supported or not by this view.
- (BOOL)isSupportedFlowType:(MXLoginFlowType)flowType
{
    if ([flowType isEqualToString:kMXLoginFlowTypePassword])
    {
        return YES;
    }
    else if ([flowType isEqualToString:kMXLoginFlowTypeEmailIdentity])
    {
        return YES;
    }
    else if ([flowType isEqualToString:kMXLoginFlowTypeRecaptcha])
    {
        return YES;
    }
    
    return NO;
}

- (MXAuthenticationSession*)validateAuthenticationSession:(MXAuthenticationSession*)authSession
{
    // Check whether the listed flows in this authentication session are supported
    NSMutableArray *supportedFlows = [NSMutableArray array];
    
    for (MXLoginFlow* flow in authSession.flows)
    {
        // Check whether flow type is defined (this type has been deprecated since C-S API v2)
        if (flow.type)
        {
            if ([self isSupportedFlowType:flow.type])
            {
                // Check here all stages
                BOOL isSupported = YES;
                if (flow.stages.count)
                {
                    for (NSString *stage in flow.stages)
                    {
                        if ([self isSupportedFlowType:stage] == NO)
                        {
                            NSLog(@"[AuthInputsView] %@: %@ stage is not supported.", (type == MXKAuthenticationTypeLogin ? @"login" : @"register"), stage);
                            isSupported = NO;
                            break;
                        }
                    }
                }
                else
                {
                    flow.stages = @[flow.type];
                }
                
                if (isSupported)
                {
                    [supportedFlows addObject:flow];
                }
            }
            else
            {
                NSLog(@"[AuthInputsView] %@: %@ stage is not supported.", (type == MXKAuthenticationTypeLogin ? @"login" : @"register"), flow.type);
            }
        }
        else
        {
            // Check here all stages
            BOOL isSupported = YES;
            if (flow.stages.count)
            {
                for (NSString *stage in flow.stages)
                {
                    if ([self isSupportedFlowType:stage] == NO)
                    {
                        NSLog(@"[AuthInputsView] %@: %@ stage is not supported.", (type == MXKAuthenticationTypeLogin ? @"login" : @"register"), stage);
                        isSupported = NO;
                        break;
                    }
                }
            }
            
            if (isSupported)
            {
                [supportedFlows addObject:flow];
            }
        }
    }
    
    if (supportedFlows.count)
    {
        if (supportedFlows.count == authSession.flows.count)
        {
            // Return the original session.
            return authSession;
        }
        else
        {
            // Keep only the supported flow.
            MXAuthenticationSession *updatedAuthSession = [[MXAuthenticationSession alloc] init];
            updatedAuthSession.session = authSession.session;
            updatedAuthSession.params = authSession.params;
            updatedAuthSession.flows = supportedFlows;
        }
    }
    
    return nil;
}

- (BOOL)isPasswordBasedFlowSupported
{
    if (session)
    {
        for (MXLoginFlow *loginFlow in session.flows)
        {
            if ([loginFlow.type isEqualToString:kMXLoginFlowTypePassword] || [loginFlow.stages indexOfObject:kMXLoginFlowTypePassword] != NSNotFound)
            {
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)isEmailIdentityFlowSupported
{
    if (session)
    {
        for (MXLoginFlow *loginFlow in session.flows)
        {
            if ([loginFlow.stages indexOfObject:kMXLoginFlowTypeEmailIdentity] != NSNotFound || [loginFlow.type isEqualToString:kMXLoginFlowTypeEmailIdentity])
            {
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)isEmailIdentityFlowRequired
{
    if (session && session.flows)
    {
        for (MXLoginFlow *loginFlow in session.flows)
        {
            if ([loginFlow.stages indexOfObject:kMXLoginFlowTypeEmailIdentity] == NSNotFound && ![loginFlow.type isEqualToString:kMXLoginFlowTypeEmailIdentity])
            {
                return NO;
            }
        }
        
        return YES;
    }
    
    return NO;
}

@end
