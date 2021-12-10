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

#import <UIKit/UIKit.h>

@class MXSession, MXKViewController;

/**
 `MXKEncryptionKeysImportView` is a dialog to import encryption keys into
 the user's crypto store.
 */
@interface MXKEncryptionKeysImportView : NSObject

/**
 The UIAlertController instance which handles the dialog.
 */
@property (nonatomic, readonly) UIAlertController *alertController;

/**
 Create the `MXKEncryptionKeysImportView` instance.

 @param mxSession the mxSession to import keys to.
 @return the newly created MXKEncryptionKeysImportView instance.
 */
- (instancetype)initWithMatrixSession:(MXSession*)mxSession;

/**
 Show the dialog in a given view controller.
 
 @param mxkViewController the mxkViewController where to show the dialog.
 @param fileURL the url of the keys file.
 @param onComplete a block called when the operation is done (whatever it succeeded or failed).
 */
- (void)showInViewController:(MXKViewController*)mxkViewController toImportKeys:(NSURL*)fileURL onComplete:(void(^)(void))onComplete;

@end
