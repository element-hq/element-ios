/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKEncryptionKeysImportView.h"

#import "MXKViewController.h"
#import "NSBundle+MatrixKit.h"

#import <MatrixSDK/MatrixSDK.h>

#import "MXKSwiftHeader.h"

@interface MXKEncryptionKeysImportView ()
{
    MXSession *mxSession;
}

@end

@implementation MXKEncryptionKeysImportView

- (instancetype)initWithMatrixSession:(MXSession *)matrixSession
{
    self = [super init];
    if (self)
    {
        mxSession = matrixSession;
        
        _alertController = [UIAlertController alertControllerWithTitle:[VectorL10n e2eImportRoomKeys] message:[VectorL10n e2eImportPrompt] preferredStyle:UIAlertControllerStyleAlert];
    }
    return self;
}

- (void)showInViewController:(MXKViewController*)mxkViewController toImportKeys:(NSURL*)fileURL onComplete:(void(^)(void))onComplete
{
    __weak typeof(self) weakSelf = self;

    // Finalise the dialog
    [_alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.secureTextEntry = YES;
         textField.placeholder = [VectorL10n e2ePassphraseEnter];
         [textField resignFirstResponder];
     }];
    
    [_alertController addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               onComplete();
                                                           }
                                                           
                                                       }]];
    
    [_alertController addAction:[UIAlertAction actionWithTitle:[VectorL10n e2eImport]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               
                                                               // Retrieve the password
                                                               UITextField *textField = [self.alertController textFields].firstObject;
                                                               NSString *password = textField.text;
                                                               
                                                               // Start the import process
                                                               [mxkViewController startActivityIndicator];
                                                               [self->mxSession.crypto importRoomKeys:[NSData dataWithContentsOfURL:fileURL] withPassword:password success:^(NSUInteger total, NSUInteger imported) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       [mxkViewController stopActivityIndicator];
                                                                       onComplete();
                                                                   }
                                                                   
                                                               } failure:^(NSError *error) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       [mxkViewController stopActivityIndicator];
                                                                       
                                                                       // TODO: i18n the error
                                                                       UIAlertController *otherAlert = [UIAlertController alertControllerWithTitle:[VectorL10n error] message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                                                                       
                                                                       [otherAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                                           
                                                                           if (weakSelf)
                                                                           {
                                                                               onComplete();
                                                                           }
                                                                           
                                                                       }]];
                                                                       
                                                                       [mxkViewController presentViewController:otherAlert animated:YES completion:nil];                                                                       
                                                                   }
                                                                   
                                                               }];
                                                           }
                                                           
                                                       }]];

    // And show it
    [mxkViewController presentViewController:_alertController animated:YES completion:nil];
}

@end
