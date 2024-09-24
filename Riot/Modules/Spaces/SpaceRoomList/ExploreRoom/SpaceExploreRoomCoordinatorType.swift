// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/ExploreRoom ShowSpaceExploreRoom
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SpaceExploreRoomCoordinatorDelegate: AnyObject {
    func spaceExploreRoomCoordinator(_ coordinator: SpaceExploreRoomCoordinatorType, didSelect item: SpaceExploreRoomListItemViewData, from sourceView: UIView?)
    func spaceExploreRoomCoordinatorDidCancel(_ coordinator: SpaceExploreRoomCoordinatorType)
    func spaceExploreRoomCoordinatorDidAddRoom(_ coordinator: SpaceExploreRoomCoordinatorType)
    func spaceExploreRoomCoordinator(_ coordinator: SpaceExploreRoomCoordinatorType, openSettingsOf item: SpaceExploreRoomListItemViewData)
    func spaceExploreRoomCoordinator(_ coordinator: SpaceExploreRoomCoordinatorType, inviteTo item: SpaceExploreRoomListItemViewData)
    func spaceExploreRoomCoordinator(_ coordinator: SpaceExploreRoomCoordinatorType, didJoin item: SpaceExploreRoomListItemViewData)
}

/// `SpaceExploreRoomCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol SpaceExploreRoomCoordinatorType: Coordinator, Presentable {
    var delegate: SpaceExploreRoomCoordinatorDelegate? { get }
}
