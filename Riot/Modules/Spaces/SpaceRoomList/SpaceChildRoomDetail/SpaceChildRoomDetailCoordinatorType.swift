// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/SpaceChildRoomDetail ShowSpaceChildRoomDetail
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SpaceChildRoomDetailCoordinatorDelegate: AnyObject {
    func spaceChildRoomDetailCoordinator(_ coordinator: SpaceChildRoomDetailCoordinatorType, didOpenRoomWith roomId: String)
    func spaceChildRoomDetailCoordinatorDidCancel(_ coordinator: SpaceChildRoomDetailCoordinatorType)
}

/// `SpaceChildRoomDetailCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol SpaceChildRoomDetailCoordinatorType: Coordinator, Presentable {
    var delegate: SpaceChildRoomDetailCoordinatorDelegate? { get }
}
