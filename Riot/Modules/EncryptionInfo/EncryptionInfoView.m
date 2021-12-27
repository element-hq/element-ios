/*
 Copyright 2016 OpenMarket Ltd
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

#import "EncryptionInfoView.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@interface EncryptionInfoView() <KeyVerificationCoordinatorBridgePresenterDelegate>
{
    KeyVerificationCoordinatorBridgePresenter *keyVerificationCoordinatorBridgePresenter;
}

@end

@implementation EncryptionInfoView

#pragma mark - Override MXKView

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    self.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    self.textView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.defaultTextColor = ThemeService.shared.theme.textPrimaryColor;
    self.cancelButton.tintColor = ThemeService.shared.theme.tintColor;
    self.verifyButton.tintColor = ThemeService.shared.theme.tintColor;
    self.blockButton.tintColor = ThemeService.shared.theme.tintColor;
    self.confirmVerifyButton.tintColor = ThemeService.shared.theme.tintColor;
}

- (void)displayLegacyVerificationScreen
{
    [super onButtonPressed:self.verifyButton];
}

- (void)onButtonPressed:(id)sender
{
    UIViewController *rootViewController = [AppDelegate theDelegate].window.rootViewController;
    if (sender == self.verifyButton && self.mxDeviceInfo.trustLevel.localVerificationStatus != MXDeviceVerified
        && self.mxDeviceInfo
        && rootViewController)
    {
        // Redirect to the interactive device verification flow
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:self.mxSession];
        keyVerificationCoordinatorBridgePresenter.delegate = self;

        // Show it on the root view controller
        [keyVerificationCoordinatorBridgePresenter presentFrom:rootViewController otherUserId:self.mxDeviceInfo.userId otherDeviceId:self.mxDeviceInfo.deviceId animated:YES];
    }
    else
    {
        [super onButtonPressed:sender];
    }
}

- (void)keyVerificationCoordinatorBridgePresenterDelegateDidComplete:(KeyVerificationCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter otherUserId:(NSString * _Nonnull)otherUserId otherDeviceId:(NSString * _Nonnull)otherDeviceId
{
    [self dismissKeyVerificationCoordinatorBridgePresenter];
}

- (void)keyVerificationCoordinatorBridgePresenterDelegateDidCancel:(KeyVerificationCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    [self dismissKeyVerificationCoordinatorBridgePresenter];
}

- (void)dismissKeyVerificationCoordinatorBridgePresenter
{
    [keyVerificationCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    keyVerificationCoordinatorBridgePresenter = nil;
    
    // Eject like MXKEncryptionInfoView does
    [self removeFromSuperview];
}

@end
