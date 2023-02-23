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

import DesignKit
import SwiftUI

/// View data for UserSessionCardView
struct UserSessionCardViewData {
    var id: String {
        sessionId
    }
    
    let sessionId: String
    
    let sessionName: String
    
    /// The verification state used to render the card with.
    let verificationState: UserSessionInfo.VerificationState
    
    let lastActivityDateString: String?
    
    var lastActivityIcon: String?
    
    let lastSeenIP: String?
    let lastSeenIPLocation: String?
    
    let deviceAvatarViewData: DeviceAvatarViewData
    
    /// Indicate if the current user session is shown and to adapt the layout
    let isCurrentSessionDisplayMode: Bool
    
    /// The name of the shield image to show the verification status.
    var verificationStatusImageName: String {
        switch verificationState {
        case .verified:
            return Asset.Images.userSessionVerified.name
        case .unverified, .permanentlyUnverified:
            return Asset.Images.userSessionUnverified.name
        case .unknown:
            return Asset.Images.userSessionVerificationUnknown.name
        }
    }
    
    /// The text to show alongside the verification shield image.
    var verificationStatusText: String {
        switch verificationState {
        case .verified:
            return VectorL10n.userSessionVerified
        case .unverified, .permanentlyUnverified:
            return VectorL10n.userSessionUnverified
        case .unknown:
            return VectorL10n.userSessionVerificationUnknown
        }
    }
    
    /// A key path to the theme colour to use for the verification status text.
    var verificationStatusColor: KeyPath<ColorSwiftUI, Color> {
        switch verificationState {
        case .verified:
            return \.accent
        case .unverified, .permanentlyUnverified:
            return \.alert
        case .unknown:
            return \.secondaryContent
        }
    }
    
    /// Further information to be shown to explain the verification state to the user.
    var verificationStatusAdditionalInfoText: String {
        switch verificationState {
        case .verified:
            return isCurrentSessionDisplayMode ? VectorL10n.userSessionVerifiedAdditionalInfo : VectorL10n.userOtherSessionVerifiedAdditionalInfo + " %@"
        case .unverified:
            return isCurrentSessionDisplayMode ? VectorL10n.userSessionUnverifiedAdditionalInfo : VectorL10n.userOtherSessionUnverifiedAdditionalInfo + " %@"
        case .permanentlyUnverified:
            return isCurrentSessionDisplayMode ? VectorL10n.userOtherSessionPermanentlyUnverifiedAdditionalInfo : VectorL10n.userOtherSessionPermanentlyUnverifiedAdditionalInfo + " %@"
        case .unknown:
            return VectorL10n.userSessionVerificationUnknownAdditionalInfo
        }
    }
    
    init(sessionId: String,
         sessionDisplayName: String?,
         deviceType: DeviceType,
         verificationState: UserSessionInfo.VerificationState,
         lastActivityTimestamp: TimeInterval?,
         lastSeenIP: String?,
         lastSeenIPLocation: String?,
         isCurrentSessionDisplayMode: Bool = false,
         isActive: Bool) {
        self.sessionId = sessionId
        sessionName = UserSessionNameFormatter.sessionName(deviceType: deviceType, sessionDisplayName: sessionDisplayName)
        self.verificationState = verificationState
        
        var lastActivityDateString: String?
        if let lastActivityTimestamp = lastActivityTimestamp {
            if isActive {
                lastActivityDateString = UserSessionLastActivityFormatter.lastActivityDateString(from: lastActivityTimestamp)
            } else {
                let dateString = InactiveUserSessionLastActivityFormatter.lastActivityDateString(from: lastActivityTimestamp)
                lastActivityDateString = VectorL10n.userInactiveSessionItemWithDate(dateString)
                lastActivityIcon = Asset.Images.userSessionListItemInactiveSession.name
            }
        }
        self.lastActivityDateString = lastActivityDateString
        self.lastSeenIP = lastSeenIP
        self.lastSeenIPLocation = lastSeenIPLocation
        deviceAvatarViewData = DeviceAvatarViewData(deviceType: deviceType, verificationState: verificationState)
        
        self.isCurrentSessionDisplayMode = isCurrentSessionDisplayMode
    }
}

extension UserSessionCardViewData {
    init(sessionInfo: UserSessionInfo) {
        self.init(sessionId: sessionInfo.id,
                  sessionDisplayName: sessionInfo.name,
                  deviceType: sessionInfo.deviceType,
                  verificationState: sessionInfo.verificationState,
                  lastActivityTimestamp: sessionInfo.lastSeenTimestamp,
                  lastSeenIP: sessionInfo.lastSeenIP,
                  lastSeenIPLocation: sessionInfo.lastSeenIPLocation,
                  isCurrentSessionDisplayMode: sessionInfo.isCurrent,
                  isActive: sessionInfo.isActive)
    }
}
