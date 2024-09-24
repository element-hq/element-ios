// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/ExploreRoom ShowSpaceExploreRoom
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SpaceExploreRoomViewController view state
enum SpaceExploreRoomViewState {
    case loading
    case spaceNameFound(_ spaceName: String)
    case loaded(_ children: [SpaceExploreRoomListItemViewData], _ hasMore: Bool)
    case canJoin(Bool)
    case emptySpace
    case emptyFilterResult
    case error(Error)
}
