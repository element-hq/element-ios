// File created from ScreenTemplate
// $ createScreen.sh CreateRoom/EnterNewRoomDetails EnterNewRoomDetails
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol EnterNewRoomDetailsCoordinatorDelegate: AnyObject {
    func enterNewRoomDetailsCoordinator(_ coordinator: EnterNewRoomDetailsCoordinatorType, didCreateNewRoom room: MXRoom)
    func enterNewRoomDetailsCoordinatorDidCancel(_ coordinator: EnterNewRoomDetailsCoordinatorType)
}

/// `EnterNewRoomDetailsCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol EnterNewRoomDetailsCoordinatorType: Coordinator, Presentable {
    var delegate: EnterNewRoomDetailsCoordinatorDelegate? { get }
}
