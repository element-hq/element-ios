// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/ExploreRoom ShowSpaceExploreRoom
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SpaceExploreRoomViewController view actions exposed to view model
enum SpaceExploreRoomViewAction {
    case reloadData
    case loadData
    case complete(_ selectedItem: SpaceExploreRoomListItemViewData, _ sourceView: UIView?)
    case searchChanged(_ text: String?)
    case joinOpenedSpace
    case cancel
    case addRoom
    case inviteTo(_ item: SpaceExploreRoomListItemViewData)
    case revertSuggestion(_ item: SpaceExploreRoomListItemViewData)
    case settings(_ item: SpaceExploreRoomListItemViewData)
    case removeChild(_ item: SpaceExploreRoomListItemViewData)
    case join(_ item: SpaceExploreRoomListItemViewData)
}
