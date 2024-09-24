// File created from FlowTemplate
// $ createRootCoordinator.sh CreateRoom CreateRoom EnterNewRoomDetails
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol CreateRoomCoordinatorDelegate: AnyObject {
    func createRoomCoordinator(_ coordinator: CreateRoomCoordinatorType, didCreateNewRoom room: MXRoom)
    func createRoomCoordinator(_ coordinator: CreateRoomCoordinatorType, didAddRoomsWithIds roomIds: [String])
    func createRoomCoordinatorDidCancel(_ coordinator: CreateRoomCoordinatorType)
}

/// `CreateRoomCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol CreateRoomCoordinatorType: Coordinator, Presentable {
    var delegate: CreateRoomCoordinatorDelegate? { get }
    var parentSpace: MXSpace? { get }
}
