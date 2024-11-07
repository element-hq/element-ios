/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

@interface SecurityViewController : MXKTableViewController

+ (SecurityViewController*)instantiateWithMatrixSession:(MXSession*)matrixSession;

@end

