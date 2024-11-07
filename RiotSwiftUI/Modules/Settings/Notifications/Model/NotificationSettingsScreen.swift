//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// The notification settings screen definitions, used when calling the coordinator.
@objc enum NotificationSettingsScreen: Int {
    case defaultNotifications
    case mentionsAndKeywords
    case other
}

extension NotificationSettingsScreen: CaseIterable { }

extension NotificationSettingsScreen: Identifiable {
    var id: Int { rawValue }
}

extension NotificationSettingsScreen {
    /// Defines which rules are handled by each of the screens.
    var pushRules: [NotificationPushRuleId] {
        switch self {
        case .defaultNotifications:
            return [.oneToOneRoom, .allOtherMessages, .oneToOneEncryptedRoom, .encrypted]
        case .mentionsAndKeywords:
            return [.containDisplayName, .containUserName, .roomNotif, .keywords]
        case .other:
            return [.inviteMe, .call, .suppressBots, .tombstone]
        }
    }
}
