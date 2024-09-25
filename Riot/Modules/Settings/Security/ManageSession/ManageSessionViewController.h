/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"


@interface ManageSessionViewController : MXKTableViewController

+ (ManageSessionViewController*)instantiateWithMatrixSession:(MXSession*)matrixSession andDevice:(MXDevice*)device;

@end

