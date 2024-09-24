// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/SpaceChildRoomDetail ShowSpaceChildRoomDetail
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SpaceChildRoomDetailViewController view state
enum SpaceChildRoomDetailViewState {
    case loading
    case loaded(_ roomInfo: MXSpaceChildInfo, _ avatarViewData: AvatarViewData, _ isJoined: Bool)
    case error(Error)
}
