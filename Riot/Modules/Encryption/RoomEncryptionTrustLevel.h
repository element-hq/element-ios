// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

/**
 RoomEncryptionTrustLevel represents the trust level in an encrypted room.
 */
typedef NS_ENUM(NSUInteger, RoomEncryptionTrustLevel) {
    RoomEncryptionTrustLevelTrusted,
    RoomEncryptionTrustLevelWarning,
    RoomEncryptionTrustLevelNormal,
    RoomEncryptionTrustLevelUnknown
};
