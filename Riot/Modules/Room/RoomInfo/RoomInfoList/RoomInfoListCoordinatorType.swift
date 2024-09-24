// File created from ScreenTemplate
// $ createScreen.sh Room2/RoomInfo RoomInfoList
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol RoomInfoListCoordinatorDelegate: AnyObject {
    func roomInfoListCoordinator(_ coordinator: RoomInfoListCoordinatorType, wantsToNavigateTo target: RoomInfoListTarget)
    func roomInfoListCoordinatorDidCancel(_ coordinator: RoomInfoListCoordinatorType)
    func roomInfoListCoordinatorDidLeaveRoom(_ coordinator: RoomInfoListCoordinatorType)
    func roomInfoListCoordinatorDidRequestReportRoom(_ coordinator: RoomInfoListCoordinatorType)
}

/// `RoomInfoListCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol RoomInfoListCoordinatorType: Coordinator, Presentable {
    var delegate: RoomInfoListCoordinatorDelegate? { get }
}
