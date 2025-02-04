// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 The Matrix.org Foundation C.I.C
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#import <UIKit/UIKit.h>
#import "MXKViewControllerActivityHandling.h"

NS_ASSUME_NONNULL_BEGIN

@interface MXKActivityHandlingViewController : UIViewController<MXKViewControllerActivityHandling>

/// A subclass can override this method to block `stopActivityIndicator` if there are still activities in progress
- (BOOL)canStopActivityIndicator;

@end

NS_ASSUME_NONNULL_END
