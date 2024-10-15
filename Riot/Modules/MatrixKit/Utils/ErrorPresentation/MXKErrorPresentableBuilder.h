/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

@import Foundation;

#import "MXKErrorPresentable.h"

/**
 `MXKErrorPresentableBuilder` enable to create error to present on screen.
 */
@interface MXKErrorPresentableBuilder : NSObject

/**
 Build a displayable error from a NSError.
 
 @param error an NSError.
 @return Return nil in case of network request cancellation error otherwise return a presentable error from NSError informations.
 */
- (id <MXKErrorPresentable>)errorPresentableFromError:(NSError*)error;

/**
 Build a common displayable error. Generic error message to present as fallback when error explanation can't be user friendly.
 
 @return Common default error.
 */
- (id <MXKErrorPresentable>)commonErrorPresentable;

@end
