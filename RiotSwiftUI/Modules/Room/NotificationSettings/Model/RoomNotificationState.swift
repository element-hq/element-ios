//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum RoomNotificationState: Int {
    case all
    case mentionsAndKeywordsOnly
    case mute
}

extension RoomNotificationState: CaseIterable { }

extension RoomNotificationState: Identifiable {
    var id: Int { rawValue }
}

extension RoomNotificationState {
    var title: String {
        switch self {
        case .all:
            return VectorL10n.roomNotifsSettingsAllMessages
        case .mentionsAndKeywordsOnly:
            return VectorL10n.roomNotifsSettingsMentionsAndKeywords
        case .mute:
            return VectorL10n.roomNotifsSettingsNone
        }
    }
}
