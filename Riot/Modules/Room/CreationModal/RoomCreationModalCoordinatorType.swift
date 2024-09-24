// File created from FlowTemplate
// $ createRootCoordinator.sh Room RoomCreationModal RoomCreationEventsModal
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol RoomCreationModalCoordinatorDelegate: AnyObject {
    func roomCreationModalCoordinatorDidComplete(_ coordinator: RoomCreationModalCoordinatorType)
}

/// `RoomCreationModalCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol RoomCreationModalCoordinatorType: Coordinator, Presentable {
    var delegate: RoomCreationModalCoordinatorDelegate? { get }
}
