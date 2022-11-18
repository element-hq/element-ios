//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
