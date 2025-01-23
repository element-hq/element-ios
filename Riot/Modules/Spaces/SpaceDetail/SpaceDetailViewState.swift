// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct SpaceDetailLoadedParameters {
    let spaceId: String
    let displayName: String?
    let topic: String?
    let avatarUrl: String?
    let joinRule: MXRoomJoinRule?
    let membership: MXMembership
    let inviterId: String?
    let inviter: MXUser?
    let membersCount: UInt
}

/// SpaceDetailViewController view state
enum SpaceDetailViewState {
    case loading
    case loaded(_ paremeters: SpaceDetailLoadedParameters)
    case error(Error)
}
