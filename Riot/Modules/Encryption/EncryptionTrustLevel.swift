// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Object responsible for calculating user and room trust level
///
/// For legacy reasons, the trust of multiple items is represented as `Progress` object,
/// where `completedUnitCount` represents the number of trusted users / devices.
@objc class EncryptionTrustLevel: NSObject {
    struct TrustSummary {
        let totalCount: Int64
        let trustedCount: Int64
        let areAllTrusted: Bool
        
        init(progress: Progress) {
            totalCount = max(progress.totalUnitCount, progress.completedUnitCount)
            trustedCount = progress.completedUnitCount
            areAllTrusted = trustedCount == totalCount
        }
    }
    
    
    /// Calculate trust level for a single user given their cross-signing info
    @objc func userTrustLevel(
        crossSigning: MXCrossSigningInfo?,
        trustedDevicesProgress: Progress
    ) -> UserEncryptionTrustLevel {
        let devices = TrustSummary(progress: trustedDevicesProgress)
        
        // If we could cross-sign but we haven't, the user is simply not verified
        if let crossSigning, !crossSigning.trustLevel.isVerified {
            return .notVerified
        
        // If we cannot cross-sign the user (legacy behaviour) and have not signed
        // any devices manually, the user is not verified
        } else if crossSigning == nil && devices.trustedCount == 0 {
            return .notVerified
        }
        
        // In all other cases we check devices for trust level
        return devices.areAllTrusted ? .trusted : .warning
    }
    
    /// Calculate trust level for a room given trust level of users and their devices
    @objc func roomTrustLevel(summary: MXUsersTrustLevelSummary) -> RoomEncryptionTrustLevel {
        let users = TrustSummary(progress: summary.trustedUsersProgress)
        let devices = TrustSummary(progress: summary.trustedDevicesProgress)
        
        guard users.totalCount > 0 && users.areAllTrusted else {
            return .normal
        }
        return devices.areAllTrusted ? .trusted : .warning
    }
}
