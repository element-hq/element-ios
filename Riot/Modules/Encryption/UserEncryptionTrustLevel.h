/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

@import Foundation;

/**
 UserEncryptionTrustLevel represents the user trust level in an encrypted room.
 */
typedef NS_ENUM(NSUInteger, UserEncryptionTrustLevel) {
    UserEncryptionTrustLevelTrusted,            // The user is verified and they have trusted all their devices
    UserEncryptionTrustLevelWarning,            // The user is verified but they have not trusted all their devices
    UserEncryptionTrustLevelNotVerified,        // The user is not verified yet
    UserEncryptionTrustLevelNoCrossSigning,     // The user has not bootstrapped cross-signing yet
    UserEncryptionTrustLevelNone,               // Crypto is not enabled. Should not happen
    UserEncryptionTrustLevelUnknown             // Computation in progress
};
