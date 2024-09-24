// File created from FlowTemplate
// $ createRootCoordinator.sh Room2 RoomInfo RoomInfoList
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import MatrixSDK

protocol RoomInfoCoordinatorDelegate: AnyObject {
    func roomInfoCoordinatorDidComplete(_ coordinator: RoomInfoCoordinatorType)
    func roomInfoCoordinator(_ coordinator: RoomInfoCoordinatorType, didRequestMentionForMember member: MXRoomMember)
    func roomInfoCoordinatorDidLeaveRoom(_ coordinator: RoomInfoCoordinatorType)
    func roomInfoCoordinator(_ coordinator: RoomInfoCoordinatorType, didReplaceRoomWithReplacementId roomId: String)
    func roomInfoCoordinator(_ coordinator: RoomInfoCoordinatorType, viewEventInTimeline event: MXEvent)
    func roomInfoCoordinatorDidRequestReportRoom(_ coordinator: RoomInfoCoordinatorType)
}

/// `RoomInfoCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol RoomInfoCoordinatorType: Coordinator, Presentable {
    var delegate: RoomInfoCoordinatorDelegate? { get }
}
