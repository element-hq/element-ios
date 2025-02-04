//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

/// View data for DeviceAvatarView
struct DeviceAvatarViewData: Hashable {
    let deviceType: DeviceType
    /// The current state of verification for the session.
    let verificationState: UserSessionInfo.VerificationState
    
    /// The name of the shield image to show for the device.
    var verificationImageName: String {
        switch verificationState {
        case .verified:
            return Asset.Images.userSessionVerified.name
        case .unverified, .permanentlyUnverified:
            return Asset.Images.userSessionUnverified.name
        case .unknown:
            return Asset.Images.userSessionVerificationUnknown.name
        }
    }
}
