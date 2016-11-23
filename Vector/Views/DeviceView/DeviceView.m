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

#import "DeviceView.h"

#import "AppDelegate.h"

#import "VectorDesignValues.h"

static NSAttributedString *verticalWhitespace = nil;

@interface DeviceView ()
{
    /**
     The displayed device
     */
    MXDevice *mxDevice;
    
    /**
     The matrix session.
     */
    MXSession *mxSession;
    
    /**
     The current alert
     */
    MXKAlert *currentAlert;
}
@end

@implementation DeviceView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Add tap recognizer to discard the view on bg view tap
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBgViewTap:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.bgView addGestureRecognizer:tap];
    
    // Add shadow on event details view
    _containerView.layer.cornerRadius = 5;
    _containerView.layer.shadowOffset = CGSizeMake(0, 1);
    _containerView.layer.shadowOpacity = 0.5f;
    
    // Localize string
    [_cancelButton setTitle:[NSBundle mxk_localizedStringForKey:@"ok"] forState:UIControlStateNormal];
    [_cancelButton setTitle:[NSBundle mxk_localizedStringForKey:@"ok"] forState:UIControlStateHighlighted];
    
    [_renameButton setTitle:[NSBundle mxk_localizedStringForKey:@"rename"] forState:UIControlStateNormal];
    [_renameButton setTitle:[NSBundle mxk_localizedStringForKey:@"rename"] forState:UIControlStateHighlighted];
    
    [_deleteButton setTitle:[NSBundle mxk_localizedStringForKey:@"delete"] forState:UIControlStateNormal];
    [_deleteButton setTitle:[NSBundle mxk_localizedStringForKey:@"delete"] forState:UIControlStateHighlighted];
}

- (void)removeFromSuperview
{
    if (currentAlert)
    {
        [currentAlert dismiss:NO];
        currentAlert = nil;
    }
    
    [super removeFromSuperview];
}

- (instancetype)initWithDevice:(MXDevice*)device andMatrixSession:(MXSession*)session
{
    NSArray *nibViews = [[NSBundle bundleForClass:[DeviceView class]] loadNibNamed:NSStringFromClass([DeviceView class])
                                                                                      owner:nil
                                                                                    options:nil];
    self = nibViews.firstObject;
    if (self)
    {
        mxDevice = device;
        mxSession = session;
        
        [self setTranslatesAutoresizingMaskIntoConstraints: NO];
        
        if (mxDevice)
        {
            // Device information
            NSMutableAttributedString *deviceInformationString = [[NSMutableAttributedString alloc]
                                                           initWithString:NSLocalizedStringFromTable(@"device_details_title", @"Vector", nil)
                                                           attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                        NSFontAttributeName: [UIFont boldSystemFontOfSize:15]}];
            [deviceInformationString appendAttributedString:[DeviceView verticalWhitespace]];
            
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                      initWithString:NSLocalizedStringFromTable(@"device_details_name", @"Vector", nil)
                                                      attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                   NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                             initWithString:device.displayName.length ? device.displayName : @""
                                                             attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                          NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[DeviceView verticalWhitespace]];
            
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                      initWithString:NSLocalizedStringFromTable(@"device_details_identifier", @"Vector", nil)
                                                      attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                   NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                      initWithString:device.deviceId
                                                      attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                   NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[DeviceView verticalWhitespace]];
            
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                      initWithString:NSLocalizedStringFromTable(@"device_details_last_seen", @"Vector", nil)
                                                      attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                   NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
            
            NSDate *lastSeenDate = [NSDate dateWithTimeIntervalSince1970:device.lastSeenTs/1000];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0]]];
            [dateFormatter setDateStyle:NSDateFormatterShortStyle];
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
            [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            
            NSString *lastSeen = [NSString stringWithFormat:NSLocalizedStringFromTable(@"device_details_last_seen_format", @"Vector", nil), device.lastSeenIp, [dateFormatter stringFromDate:lastSeenDate]];
            
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                      initWithString:lastSeen
                                                      attributes:@{NSForegroundColorAttributeName : kVectorTextColorBlack,
                                                                   NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[DeviceView verticalWhitespace]];
            
            self.textView.attributedText = deviceInformationString;
        }
        else
        {
            _textView.text = nil;
        }
        
        // Hide potential activity indicator
        [_activityIndicator stopAnimating];
    }
    
    return self;
}

- (void)dealloc
{
    mxDevice = nil;
    mxSession = nil;
}

+ (NSAttributedString *)verticalWhitespace
{
    if (verticalWhitespace == nil)
    {
        verticalWhitespace = [[NSAttributedString alloc] initWithString:@"\n\n" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:4]}];
    }
    return verticalWhitespace;
}

#pragma mark - Actions

- (IBAction)onBgViewTap:(UITapGestureRecognizer*)sender
{
    [self removeFromSuperview];
}

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == _cancelButton)
    {
        [self removeFromSuperview];
    }
    else if (sender == _renameButton)
    {
        [self renameDevice];
    }
    else if (sender == _deleteButton)
    {
        [self deleteDevice];
    }
}

#pragma mark -

- (void)renameDevice
{
    if (!self.delegate)
    {
        // Ignore
        NSLog(@"[DeviceView] Rename device failed, delegate is missing");
        return;
    }
    
    [currentAlert dismiss:NO];
    
    __weak typeof(self) weakSelf = self;
    
    // Prompt the user to enter a device name.
    currentAlert = [[MXKAlert alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"device_details_rename_prompt_message", @"Vector", nil) style:MXKAlertStyleAlert];
    
    [currentAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        
        textField.secureTextEntry = NO;
        textField.placeholder = nil;
        textField.keyboardType = UIKeyboardTypeDefault;
        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            textField.text = strongSelf->mxDevice.displayName;
        }
    }];
    
    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        
        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;
        }
        
    }];
    
    [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        
        if (weakSelf)
        {
            UITextField *textField = [alert textFieldAtIndex:0];
            
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;
            
            [strongSelf.activityIndicator startAnimating];
            
            [strongSelf->mxSession.matrixRestClient setDeviceName:textField.text forDeviceId:strongSelf->mxDevice.deviceId success:^{
                
                if (weakSelf)
                {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    [strongSelf.activityIndicator stopAnimating];
                    
                    if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(deviceViewDidUpdate:)])
                    {
                        [strongSelf.delegate deviceViewDidUpdate:strongSelf];
                    }
                    
                    [strongSelf removeFromSuperview];
                }
                
            } failure:^(NSError *error) {
                
                // Notify user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
                
                if (weakSelf)
                {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    NSLog(@"[DeviceView] Rename device (%@) failed", strongSelf->mxDevice.deviceId);
                    
                    [strongSelf.activityIndicator stopAnimating];
                    [strongSelf removeFromSuperview];
                }
                
            }];
        }
    }];
    
    [self.delegate deviceView:self presentMXKAlert:currentAlert];
}

- (void)deleteDevice
{
    if (!self.delegate)
    {
        // Ignore
        NSLog(@"[DeviceView] Delete device failed, delegate is missing");
        return;
    }
    
    // Get an authentication session to prepare device deletion
    [self.activityIndicator startAnimating];
    
    [mxSession.matrixRestClient getSessionToDeleteDeviceByDeviceId:mxDevice.deviceId success:^(MXAuthenticationSession *authSession) {
        
        // Check whether the password based type is supported
        BOOL isPasswordBasedTypeSupported = NO;
        for (MXLoginFlow *loginFlow in authSession.flows)
        {
            if ([loginFlow.type isEqualToString:kMXLoginFlowTypePassword] || [loginFlow.stages indexOfObject:kMXLoginFlowTypePassword] != NSNotFound)
            {
                isPasswordBasedTypeSupported = YES;
                break;
            }
        }
        
        if (isPasswordBasedTypeSupported && authSession.session)
        {
            // Prompt for a password
            [currentAlert dismiss:NO];
            
            __weak typeof(self) weakSelf = self;
            
            // Prompt the user to enter a device name.
            currentAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"device_details_delete_prompt_title", @"Vector", nil)  message:NSLocalizedStringFromTable(@"device_details_delete_prompt_message", @"Vector", nil) style:MXKAlertStyleAlert];
            
            [currentAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                
                textField.secureTextEntry = YES;
                textField.placeholder = nil;
                textField.keyboardType = UIKeyboardTypeDefault;
            }];
            
            currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                
                if (weakSelf)
                {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->currentAlert = nil;
                    
                    [strongSelf.activityIndicator stopAnimating];
                }
                
            }];
            
            [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"submit"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                
                if (weakSelf)
                {
                    UITextField *textField = [alert textFieldAtIndex:0];
                    
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->currentAlert = nil;
                    
                    NSString *userId = strongSelf->mxSession.myUser.userId;
                    NSDictionary *authParams;
                    
                    // Sanity check
                    if (userId)
                    {
                        authParams = @{@"session":authSession.session,
                                       @"user": userId,
                                       @"password": textField.text,
                                       @"type": kMXLoginFlowTypePassword};

                    }
                    
                    [strongSelf->mxSession.matrixRestClient deleteDeviceByDeviceId:strongSelf->mxDevice.deviceId authParams:authParams success:^{
                        
                        if (weakSelf)
                        {
                            __strong __typeof(weakSelf)strongSelf = weakSelf;
                            
                            [strongSelf.activityIndicator stopAnimating];
                            
                            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(deviceViewDidUpdate:)])
                            {
                                [strongSelf.delegate deviceViewDidUpdate:strongSelf];
                            }
                            
                            [strongSelf removeFromSuperview];
                        }
                        
                    } failure:^(NSError *error) {
                        
                        // Notify user
                        [[AppDelegate theDelegate] showErrorAsAlert:error];
                        
                        if (weakSelf)
                        {
                            __strong __typeof(weakSelf)strongSelf = weakSelf;
                            
                            NSLog(@"[DeviceView] Delete device (%@) failed", strongSelf->mxDevice.deviceId);
                            
                            [strongSelf.activityIndicator stopAnimating];
                            [strongSelf removeFromSuperview];
                        }
                        
                    }];
                }
            }];
            
            [self.delegate deviceView:self presentMXKAlert:currentAlert];
        }
        else
        {
            NSLog(@"[DeviceView] Delete device (%@) failed, auth session flow type is not supported", mxDevice.deviceId);
            [self.activityIndicator stopAnimating];
        }
        
    } failure:^(NSError *error) {
        
        NSLog(@"[DeviceView] Delete device (%@) failed, unable to get auth session", mxDevice.deviceId);
        [self.activityIndicator stopAnimating];
        
        [[AppDelegate theDelegate] showErrorAsAlert:error];
    }];
}

@end