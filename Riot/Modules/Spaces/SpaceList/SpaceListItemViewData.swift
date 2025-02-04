// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// SpaceListViewCell view data
struct SpaceListItemViewData {
    let spaceId: String
    let title: String?
    let avatarViewData: AvatarViewDataProtocol
    let isInvite: Bool
    let notificationCount: UInt
    let highlightedNotificationCount: UInt
}
