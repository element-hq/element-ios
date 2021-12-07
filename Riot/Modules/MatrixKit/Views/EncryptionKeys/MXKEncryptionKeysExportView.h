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

@class MXSession, MXKViewController, MXKRoomDataSource;

/**
 `MXKEncryptionKeysExportView` is a dialog to export encryption keys from
 the user's crypto store.
 */
@interface MXKEncryptionKeysExportView : NSObject

/**
 The UIAlertController instance which handles the dialog.
 */
@property (nonatomic, readonly) UIAlertController *alertController;

/**
 The minimum length of the passphrase. 1 by default.
 */
@property (nonatomic) NSUInteger passphraseMinLength;

/**
 Create the `MXKEncryptionKeysExportView` instance.

 @param mxSession the mxSession to export keys from.
 @return the newly created MXKEncryptionKeysExportView instance.
 */
- (instancetype)initWithMatrixSession:(MXSession*)mxSession;

/**
 Show the dialog in a given view controller.

 @param mxkViewController the mxkViewController where to show the dialog.
 @param keyFile the path where to export keys to.
 @param onComplete a block called when the operation is done.
 */
- (void)showInViewController:(MXKViewController*)mxkViewController toExportKeysToFile:(NSURL*)keyFile onComplete:(void(^)(BOOL success))onComplete;


/**
 Show the dialog in a given view controller.

 @param viewController the UIViewController where to show the dialog.
 @param keyFile the path where to export keys to.
 @param onLoading a block called when to show a spinner.
 @param onComplete a block called when the operation is done.
 */
- (void)showInUIViewController:(UIViewController*)viewController
            toExportKeysToFile:(NSURL*)keyFile
                     onLoading:(void(^)(BOOL onLoading))onLoading
                    onComplete:(void(^)(BOOL success))onComplete;

@end

