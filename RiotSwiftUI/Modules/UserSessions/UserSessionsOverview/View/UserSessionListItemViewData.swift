//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

typealias SessionId = String

/// View data for UserSessionListItem
struct UserSessionListItemViewData: Identifiable, Hashable {
    var id: String {
        sessionId
    }
    
    let sessionId: SessionId
    let sessionName: String
    let sessionDetails: String
    let deviceAvatarViewData: DeviceAvatarViewData
    let sessionDetailsIcon: String?
    let isSelected: Bool
    let lastSeenIP: String?
    let lastSeenIPLocation: String?
}
