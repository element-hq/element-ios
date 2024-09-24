// File created from ScreenTemplate
// $ createScreen.sh Modal2/RoomCreation RoomCreationEventsModal
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol RoomCreationEventsModalCoordinatorDelegate: AnyObject {
    func roomCreationEventsModalCoordinatorDidTapClose(_ coordinator: RoomCreationEventsModalCoordinatorType)
}

/// `RoomCreationEventsModalCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol RoomCreationEventsModalCoordinatorType: Coordinator, Presentable {
    var delegate: RoomCreationEventsModalCoordinatorDelegate? { get }
}
