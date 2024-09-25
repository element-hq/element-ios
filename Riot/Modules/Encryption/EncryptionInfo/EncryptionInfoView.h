/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 TODO: This view as it is implemented in this class must disappear.
 It should be part of the device verification flow (`DeviceVerificationCoordinator`).
 */
@interface EncryptionInfoView : MXKEncryptionInfoView

/**
 Open the legacy simple verification screen
 */
- (void)displayLegacyVerificationScreen;

@end

