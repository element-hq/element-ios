// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 The Matrix.org Foundation C.I.C
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#import "MXSession+MatrixKit.h"

@implementation MXSession (MatrixKit)

- (BOOL)shouldShowActivityIndicator
{
    switch (self.state)
    {
        case MXSessionStateInitialised:
        case MXSessionStateProcessingBackgroundSyncCache:
        case MXSessionStateSyncInProgress:
            return YES;
        default:
            return NO;
    }
}

@end
