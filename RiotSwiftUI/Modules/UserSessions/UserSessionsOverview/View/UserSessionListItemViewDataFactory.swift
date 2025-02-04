//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct UserSessionListItemViewDataFactory {
    func create(from sessionInfo: UserSessionInfo,
                isSelected: Bool = false) -> UserSessionListItemViewData {
        let sessionName = UserSessionNameFormatter.sessionName(sessionId: sessionInfo.id,
                                                               sessionDisplayName: sessionInfo.name)
        let sessionDetails = buildSessionDetails(sessionInfo: sessionInfo)
        let deviceAvatarViewData = DeviceAvatarViewData(deviceType: sessionInfo.deviceType,
                                                        verificationState: sessionInfo.verificationState)
        return UserSessionListItemViewData(sessionId: sessionInfo.id,
                                           sessionName: sessionName,
                                           sessionDetails: sessionDetails,
                                           deviceAvatarViewData: deviceAvatarViewData,
                                           sessionDetailsIcon: getSessionDetailsIcon(isActive: sessionInfo.isActive),
                                           isSelected: isSelected,
                                           lastSeenIP: sessionInfo.lastSeenIP,
                                           lastSeenIPLocation: sessionInfo.lastSeenIPLocation)
    }
    
    private func buildSessionDetails(sessionInfo: UserSessionInfo) -> String {
        if sessionInfo.isActive {
            return activeSessionDetails(sessionInfo: sessionInfo)
        } else {
            return inactiveSessionDetails(sessionInfo: sessionInfo)
        }
    }
    
    private func inactiveSessionDetails(sessionInfo: UserSessionInfo) -> String {
        if let lastActivityDate = sessionInfo.lastSeenTimestamp {
            let lastActivityDateString = InactiveUserSessionLastActivityFormatter.lastActivityDateString(from: lastActivityDate)
            return VectorL10n.userInactiveSessionItemWithDate(lastActivityDateString)
        }
        return VectorL10n.userInactiveSessionItem
    }
    
    private func activeSessionDetails(sessionInfo: UserSessionInfo) -> String {
        // Start by creating the main part of the details string.
        
        var lastActivityDateString: String?
        if let lastActivityDate = sessionInfo.lastSeenTimestamp {
            lastActivityDateString = UserSessionLastActivityFormatter.lastActivityDateString(from: lastActivityDate)
        }
        var sessionDetailsString = ""
        if let lastActivityDateString = lastActivityDateString, lastActivityDateString.isEmpty == false {
            sessionDetailsString = VectorL10n.userSessionItemDetailsLastActivity(lastActivityDateString)
        }
        
        // Prepend the verification state if one is known.
        let sessionStatusText: String?
        switch sessionInfo.verificationState {
        case .verified:
            sessionStatusText = VectorL10n.userSessionVerifiedShort
        case .unverified, .permanentlyUnverified:
            sessionStatusText = VectorL10n.userSessionUnverifiedShort
        case .unknown:
            sessionStatusText = nil
        }
        
        if let sessionStatusText = sessionStatusText {
            if sessionDetailsString.isEmpty {
                sessionDetailsString = sessionStatusText
            } else {
                sessionDetailsString = VectorL10n.userSessionItemDetails(sessionStatusText, sessionDetailsString)
            }
        } else if sessionDetailsString.isEmpty {
            sessionDetailsString = VectorL10n.userSessionVerificationUnknownShort
        }
            
        return sessionDetailsString
    }
    
    private func getSessionDetailsIcon(isActive: Bool) -> String? {
        isActive ? nil : Asset.Images.userSessionListItemInactiveSession.name
    }
}
