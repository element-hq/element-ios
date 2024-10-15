/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
