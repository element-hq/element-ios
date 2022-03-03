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

#import "MXKEncryptionKeysExportView.h"

#import "MXKViewController.h"
#import "MXKRoomDataSource.h"
#import "NSBundle+MatrixKit.h"

#import <MatrixSDK/MatrixSDK.h>

#import "MXKSwiftHeader.h"

@interface MXKEncryptionKeysExportView ()
{
    MXSession *mxSession;
}

@end

@implementation MXKEncryptionKeysExportView

- (instancetype)initWithMatrixSession:(MXSession *)matrixSession
{
    self = [super init];
    if (self)
    {
        mxSession = matrixSession;
        _passphraseMinLength = 1;
        
        _alertController = [UIAlertController alertControllerWithTitle:[VectorL10n e2eExportRoomKeys] message:[VectorL10n e2eExportPrompt] preferredStyle:UIAlertControllerStyleAlert];
    }
    return self;
}


- (void)showInViewController:(MXKViewController *)mxkViewController toExportKeysToFile:(NSURL *)keyFile onComplete:(void (^)(BOOL success))onComplete
{
    [self showInUIViewController:mxkViewController toExportKeysToFile:keyFile onLoading:^(BOOL onLoading) {
        if (onLoading)
        {
            [mxkViewController startActivityIndicator];
        }
        else
        {
            [mxkViewController stopActivityIndicator];
        }
    } onComplete:onComplete];
}

- (void)showInUIViewController:(UIViewController*)viewController
            toExportKeysToFile:(NSURL*)keyFile
                     onLoading:(void(^)(BOOL onLoading))onLoading
                    onComplete:(void(^)(BOOL success))onComplete
{
    __weak typeof(self) weakSelf = self;

    // Finalise the dialog
    [_alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.secureTextEntry = YES;
        textField.placeholder = [VectorL10n e2ePassphraseCreate];
         [textField resignFirstResponder];
     }];

    [_alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.secureTextEntry = YES;
         textField.placeholder = [VectorL10n e2ePassphraseConfirm];
         [textField resignFirstResponder];
     }];

    [_alertController addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {

                                                           if (weakSelf)
                                                           {
                                                               onComplete(NO);
                                                           }

                                                       }]];

    [_alertController addAction:[UIAlertAction actionWithTitle:[VectorL10n e2eExport]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {

                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;

                                                               // Retrieve the password and confirmation
                                                               UITextField *textField = [self.alertController textFields].firstObject;
                                                               NSString *password = textField.text;

                                                               textField = [self.alertController textFields][1];
                                                               NSString *confirmation = textField.text;

                                                               // Check they are valid
                                                               if (password.length < self.passphraseMinLength || ![password isEqualToString:confirmation])
                                                               {
                                                                   NSString *error;
                                                                   if (!password.length)
                                                                   {
                                                                       error = [VectorL10n e2ePassphraseEmpty];
                                                                   }
                                                                   else if (password.length < self.passphraseMinLength)
                                                                   {
                                                                       error = [VectorL10n e2ePassphraseTooShort:self.passphraseMinLength];
                                                                   }
                                                                   else
                                                                   {
                                                                       error = [VectorL10n e2ePassphraseNotMatch];
                                                                   }

                                                                   UIAlertController *otherAlert = [UIAlertController alertControllerWithTitle:[VectorL10n error] message:error preferredStyle:UIAlertControllerStyleAlert];

                                                                   [otherAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {

                                                                       if (weakSelf)
                                                                       {
                                                                           onComplete(NO);
                                                                       }

                                                                   }]];

                                                                   [viewController presentViewController:otherAlert animated:YES completion:nil];
                                                               }
                                                               else
                                                               {
                                                                   // Start the export process
                                                                   onLoading(YES);

                                                                   [self->mxSession.crypto exportRoomKeysWithPassword:password success:^(NSData *keyFileData) {

                                                                       if (weakSelf)
                                                                       {
                                                                           onLoading(NO);

                                                                           // Write the result to the passed file
                                                                           [keyFileData writeToURL:keyFile atomically:YES];
                                                                           onComplete(YES);
                                                                       }

                                                                   } failure:^(NSError *error) {

                                                                       if (weakSelf)
                                                                       {
                                                                           onLoading(NO);

                                                                           // TODO: i18n the error
                                                                           UIAlertController *otherAlert = [UIAlertController alertControllerWithTitle:[VectorL10n error] message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];

                                                                           [otherAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {

                                                                               if (weakSelf)
                                                                               {
                                                                                   onComplete(NO);
                                                                               }

                                                                           }]];

                                                                           [viewController presentViewController:otherAlert animated:YES completion:nil];
                                                                       }
                                                                   }];
                                                               }
                                                           }

                                                       }]];



    // And show it
    [viewController presentViewController:_alertController animated:YES completion:nil];
}


@end

