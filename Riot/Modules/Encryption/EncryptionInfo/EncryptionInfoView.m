/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
