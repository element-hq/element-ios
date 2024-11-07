/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKAuthInputsEmailCodeBasedView.h"

#import "NSBundle+MatrixKit.h"

#import "MXKSwiftHeader.h"

@implementation MXKAuthInputsEmailCodeBasedView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKAuthInputsEmailCodeBasedView class])
                          bundle:[NSBundle bundleForClass:[MXKAuthInputsEmailCodeBasedView class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _userLoginTextField.placeholder = [VectorL10n loginUserIdPlaceholder];
    _emailAndTokenTextField.placeholder = [VectorL10n loginEmailPlaceholder];
    _promptEmailTokenLabel.text = [VectorL10n loginPromptEmailToken];
    
    _displayNameTextField.placeholder = [VectorL10n loginDisplayNamePlaceholder];
}

#pragma mark -

- (BOOL)setAuthSession:(MXAuthenticationSession *)authSession withAuthType:(MXKAuthenticationType)authType;
{
    if (type == MXKAuthenticationTypeLogin || type == MXKAuthenticationTypeRegister)
    {
        // Validate first the provided session
        MXAuthenticationSession *validSession = [self validateAuthenticationSession:authSession];
        
        if ([super setAuthSession:validSession withAuthType:authType])
        {
            // Set initial layout
            self.userLoginTextField.hidden = NO;
            self.promptEmailTokenLabel.hidden = YES;
            
            if (type == MXKAuthenticationTypeLogin)
            {
                self.emailAndTokenTextField.returnKeyType = UIReturnKeyDone;
                self.displayNameTextField.hidden = YES;
                
                self.viewHeightConstraint.constant = self.displayNameTextField.frame.origin.y;
            }
            else
            {
                self.emailAndTokenTextField.returnKeyType = UIReturnKeyNext;
                self.displayNameTextField.hidden = NO;
                
                self.viewHeightConstraint.constant = 122;
            }
            
            return YES;
        }
    }
    
    return NO;
}

- (NSString*)validateParameters
{
    NSString *errorMsg = [super validateParameters];
    
    if (!errorMsg)
    {
        if (!self.areAllRequiredFieldsSet)
        {
            errorMsg = [VectorL10n loginInvalidParam];
        }
    }
    
    return errorMsg;
}

- (BOOL)areAllRequiredFieldsSet
{
    BOOL ret = [super areAllRequiredFieldsSet];
    
    // Check required fields //FIXME what are required fields in this authentication flow?
    ret = (ret && self.userLoginTextField.text.length && self.emailAndTokenTextField.text.length);
    
    return ret;
}

- (void)dismissKeyboard
{
    [self.userLoginTextField resignFirstResponder];
    [self.emailAndTokenTextField resignFirstResponder];
    [self.displayNameTextField resignFirstResponder];
    
    [super dismissKeyboard];
}

- (void)nextStep
{
    // Consider here the email token has been requested with success
    [super nextStep];
    
    self.userLoginTextField.hidden = YES;
    self.promptEmailTokenLabel.hidden = NO;
    self.emailAndTokenTextField.placeholder = nil;
    self.emailAndTokenTextField.returnKeyType = UIReturnKeyDone;
    
    self.displayNameTextField.hidden = YES;
}

- (NSString*)userId
{
    return self.userLoginTextField.text;
}

#pragma mark UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if (textField.returnKeyType == UIReturnKeyDone)
    {
        // "Done" key has been pressed
        [textField resignFirstResponder];
        
        // Launch authentication now
        [self.delegate authInputsViewDidPressDoneKey:self];
    }
    else
    {
        //"Next" key has been pressed
        if (textField == self.userLoginTextField)
        {
            [self.emailAndTokenTextField becomeFirstResponder];
        }
        else if (textField == self.emailAndTokenTextField)
        {
            [self.displayNameTextField becomeFirstResponder];
        }
    }
    
    return YES;
}

#pragma mark -

- (MXAuthenticationSession*)validateAuthenticationSession:(MXAuthenticationSession*)authSession
{
    // Check whether at least one of the listed flow is supported.
    BOOL isSupported = NO;
    
    for (MXLoginFlow *loginFlow in authSession.flows)
    {
        // Check whether flow type is defined
        if ([loginFlow.type isEqualToString:kMXLoginFlowTypeEmailCode])
        {
            isSupported = YES;
            break;
        }
        else if (loginFlow.stages.count == 1 && [loginFlow.stages.firstObject isEqualToString:kMXLoginFlowTypeEmailCode])
        {
            isSupported = YES;
            break;
        }
    }
    
    if (isSupported)
    {
        if (authSession.flows.count == 1)
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
            updatedAuthSession.flows = @[[MXLoginFlow modelFromJSON:@{@"stages":@[kMXLoginFlowTypeEmailCode]}]];
            return updatedAuthSession;
        }
    }
    
    return nil;
}

@end
