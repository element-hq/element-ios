/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

@import UIKit;

#import "MatrixKit.h"

#pragma mark - Types

@class DeactivateAccountViewController;

#pragma mark - Protocol

@protocol DeactivateAccountViewControllerDelegate <NSObject>

- (void)deactivateAccountViewControllerDidCancel:(DeactivateAccountViewController*)deactivateAccountViewController;
- (void)deactivateAccountViewControllerDidDeactivateWithSuccess:(DeactivateAccountViewController*)deactivateAccountViewController;

@end

#pragma mark - Interface

@interface DeactivateAccountViewController : MXKViewController

#pragma mark - Properties

@property (nonatomic, weak) id<DeactivateAccountViewControllerDelegate> delegate;

#pragma mark - Class Methods

+ (DeactivateAccountViewController*)instantiateWithMatrixSession:(MXSession*)matrixSession;

@end
