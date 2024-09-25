/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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

