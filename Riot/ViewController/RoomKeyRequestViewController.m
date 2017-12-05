/*
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

#import "RoomKeyRequestViewController.h"

#import "AppDelegate.h"
#import "EncryptionInfoView.h"

@interface RoomKeyRequestViewController ()
{
    void (^onComplete)();

    EncryptionInfoView *encryptionInfoView;

    BOOL wasNewDevice;
}
@end

@implementation RoomKeyRequestViewController

- (instancetype)initWithDeviceInfo:(MXDeviceInfo *)deviceInfo wasNewDevice:(BOOL)theWasNewDevice andMatrixSession:(MXSession *)session onComplete:(void (^)())onCompleteBlock
{
    self = [super init];
    if (self)
    {
        _mxSession = session;
        _device = deviceInfo;
        wasNewDevice = theWasNewDevice;
        onComplete = onCompleteBlock;
    }
    return self;
}

- (void)show
{
    // Show it modally on the root view controller
    UIViewController *rootViewController = [AppDelegate theDelegate].window.rootViewController;
    if (rootViewController)
    {
        NSString *title = NSLocalizedStringFromTable(@"e2e_room_key_request_title", @"Vector", nil);
        NSString *message;
        if (wasNewDevice)
        {
            message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"e2e_room_key_request_message_new_device", @"Vector", nil), _device.displayName];
        }
        else
        {
            message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"e2e_room_key_request_message", @"Vector", nil), _device.displayName];
        }

        _alertController = [UIAlertController alertControllerWithTitle:title
                                                               message:message
                                                        preferredStyle:UIAlertControllerStyleAlert];

        __weak typeof(self) weakSelf = self;

        [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"e2e_room_key_request_start_verification", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {

                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;

                                                                   self->_alertController = nil;
                                                                   [self showVerificationView];
                                                               }
                                                           }]];

        [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"e2e_room_key_request_share_without_verifying", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {

                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;

                                                                   self->_alertController = nil;

                                                                   // Accept the received requests from this device
                                                                   [self.mxSession.crypto acceptAllPendingKeyRequestsFromUser:self.device.userId andDevice:self.device.deviceId onComplete:^{

                                                                       onComplete();
                                                                   }];
                                                               }
                                                           }]];

        [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"e2e_room_key_request_ignore_request", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {

                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;

                                                                   self->_alertController = nil;

                                                                   // Ignore all pending requests from this device
                                                                   [self.mxSession.crypto ignoreAllPendingKeyRequestsFromUser:self.device.userId andDevice:self.device.deviceId onComplete:^{

                                                                       onComplete();
                                                                   }];
                                                               }
                                                           }]];

        [rootViewController presentViewController:_alertController animated:YES completion:nil];
    }
}

- (void)hide
{
    if (_alertController)
    {
        [_alertController dismissViewControllerAnimated:YES completion:nil];
        _alertController = nil;
    }

    if (encryptionInfoView)
    {
        [encryptionInfoView removeFromSuperview];
        encryptionInfoView = nil;
    }
}


- (void)showVerificationView
{
    // Show it modally on the root view controller
    UIViewController *rootViewController = [AppDelegate theDelegate].window.rootViewController;
    if (rootViewController)
    {
        encryptionInfoView = [[EncryptionInfoView alloc] initWithDeviceInfo:_device andMatrixSession:_mxSession];
        [encryptionInfoView onButtonPressed:encryptionInfoView.verifyButton];

        encryptionInfoView.delegate = self;

        // Add shadow on added view
        encryptionInfoView.layer.cornerRadius = 5;
        encryptionInfoView.layer.shadowOffset = CGSizeMake(0, 1);
        encryptionInfoView.layer.shadowOpacity = 0.5f;

        // Add the view and define edge constraints
        [rootViewController.view addSubview:encryptionInfoView];

        [rootViewController.view addConstraint:[NSLayoutConstraint constraintWithItem:encryptionInfoView
                                                                          attribute:NSLayoutAttributeTop
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:rootViewController.topLayoutGuide
                                                                          attribute:NSLayoutAttributeBottom
                                                                         multiplier:1.0f
                                                                           constant:10.0f]];

        [rootViewController.view addConstraint:[NSLayoutConstraint constraintWithItem:encryptionInfoView
                                                                          attribute:NSLayoutAttributeBottom
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:rootViewController.bottomLayoutGuide
                                                                          attribute:NSLayoutAttributeTop
                                                                         multiplier:1.0f
                                                                           constant:-10.0f]];

        [rootViewController.view addConstraint:[NSLayoutConstraint constraintWithItem:rootViewController.view
                                                                          attribute:NSLayoutAttributeLeading
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:encryptionInfoView
                                                                          attribute:NSLayoutAttributeLeading
                                                                         multiplier:1.0f
                                                                           constant:-10.0f]];

        [rootViewController.view addConstraint:[NSLayoutConstraint constraintWithItem:rootViewController.view
                                                                          attribute:NSLayoutAttributeTrailing
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:encryptionInfoView
                                                                          attribute:NSLayoutAttributeTrailing
                                                                         multiplier:1.0f
                                                                           constant:10.0f]];
        [rootViewController.view setNeedsUpdateConstraints];
    }
}

#pragma mark - MXKEncryptionInfoViewDelegate

- (void)encryptionInfoView:(MXKEncryptionInfoView *)theEncryptionInfoView didDeviceInfoVerifiedChange:(MXDeviceInfo *)deviceInfo
{
    encryptionInfoView = nil;

    if (deviceInfo.verified == MXDeviceVerified)
    {
        // Accept the received requests from this device
        // As the device is now verified, all other key requests will be automatically accepted.
        [self.mxSession.crypto acceptAllPendingKeyRequestsFromUser:self.device.userId andDevice:self.device.deviceId onComplete:^{

            onComplete();
        }];
    }
}

- (void)encryptionInfoViewDidClose:(MXKEncryptionInfoView *)theEncryptionInfoView
{
    encryptionInfoView = nil;

    // Come back to self.alertController - ie, reopen it
    [self show];
}

@end
