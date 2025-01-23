// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum DiscussionType {
    case directMessage
    case multipleDirectMessage
    case room(topic: String?, canInvitePeople: Bool)
}

struct RoomCreationIntroViewData {
    let dicussionType: DiscussionType
    let roomDisplayName: String
    let avatarViewData: RoomAvatarViewData
}
