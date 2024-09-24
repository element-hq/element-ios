// File created from FlowTemplate
// $ createRootCoordinator.sh Rooms2 RoomsDirectory ShowDirectory
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol RoomsDirectoryCoordinatorDelegate: AnyObject {
    func roomsDirectoryCoordinator(_ coordinator: RoomsDirectoryCoordinatorType, didSelectRoom room: MXPublicRoom)
    func roomsDirectoryCoordinatorDidTapCreateNewRoom(_ coordinator: RoomsDirectoryCoordinatorType)
    func roomsDirectoryCoordinatorDidComplete(_ coordinator: RoomsDirectoryCoordinatorType)
    func roomsDirectoryCoordinator(_ coordinator: RoomsDirectoryCoordinatorType, didSelectRoomWithIdOrAlias roomIdOrAlias: String)
}

/// `RoomsDirectoryCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol RoomsDirectoryCoordinatorType: Coordinator, Presentable {
    var delegate: RoomsDirectoryCoordinatorDelegate? { get }
}
