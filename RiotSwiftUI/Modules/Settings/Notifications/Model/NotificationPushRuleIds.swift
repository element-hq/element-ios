//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// The push rule ids used in notification settings and the static rule definitions.
enum NotificationPushRuleId: String {
    case suppressBots = ".m.rule.suppress_notices"
    case inviteMe = ".m.rule.invite_for_me"
    case containDisplayName = ".m.rule.contains_display_name"
    case tombstone = ".m.rule.tombstone"
    case roomNotif = ".m.rule.roomnotif"
    case containUserName = ".m.rule.contains_user_name"
    case call = ".m.rule.call"
    case oneToOneEncryptedRoom = ".m.rule.encrypted_room_one_to_one"
    case oneToOneRoom = ".m.rule.room_one_to_one"
    case allOtherMessages = ".m.rule.message"
    case encrypted = ".m.rule.encrypted"
    case keywords = "_keywords"
    // poll started event
    case pollStart = ".m.rule.poll_start"
    case msc3930pollStart = ".org.matrix.msc3930.rule.poll_start"
    // poll started event (one to one)
    case oneToOnePollStart = ".m.rule.poll_start_one_to_one"
    case msc3930oneToOnePollStart = ".org.matrix.msc3930.rule.poll_start_one_to_one"
    // poll ended event
    case pollEnd = ".m.rule.poll_end"
    case msc3930pollEnd = ".org.matrix.msc3930.rule.poll_end"
    // poll ended event (one to one)
    case oneToOnePollEnd = ".m.rule.poll_end_one_to_one"
    case msc3930oneToOnePollEnd = ".org.matrix.msc3930.rule.poll_end_one_to_one"
}

extension NotificationPushRuleId: Identifiable {
    var id: String {
        rawValue
    }
}

extension NotificationPushRuleId {
    var title: String {
        switch self {
        case .suppressBots:
            return VectorL10n.settingsMessagesByABot
        case .inviteMe:
            return VectorL10n.settingsRoomInvitations
        case .containDisplayName:
            return VectorL10n.settingsMessagesContainingDisplayName
        case .tombstone:
            return VectorL10n.settingsRoomUpgrades
        case .roomNotif:
            return VectorL10n.settingsMessagesContainingAtRoom
        case .containUserName:
            return VectorL10n.settingsMessagesContainingUserName
        case .call:
            return VectorL10n.settingsCallInvitations
        case .oneToOneEncryptedRoom:
            return VectorL10n.settingsEncryptedDirectMessages
        case .oneToOneRoom:
            return VectorL10n.settingsDirectMessages
        case .allOtherMessages:
            return VectorL10n.settingsGroupMessages
        case .encrypted:
            return VectorL10n.settingsEncryptedGroupMessages
        case .keywords:
            return VectorL10n.settingsMessagesContainingKeywords
        case .pollStart, .msc3930pollStart, .oneToOnePollStart, .msc3930oneToOnePollStart, .pollEnd, .msc3930pollEnd, .oneToOnePollEnd, .msc3930oneToOnePollEnd:
            // They don't need to be rendered on the UI
            return ""
        }
    }
    
    var syncedRules: [NotificationPushRuleId] {
        switch self {
        case .oneToOneRoom:
            return [.oneToOnePollStart, .msc3930oneToOnePollStart, .oneToOnePollEnd, .msc3930oneToOnePollEnd]
        case .allOtherMessages:
            return [.pollStart, .msc3930pollStart, .pollEnd, .msc3930pollEnd]
        default:
            return []
        }
    }
}
