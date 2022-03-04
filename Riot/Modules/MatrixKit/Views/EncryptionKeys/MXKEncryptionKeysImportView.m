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
