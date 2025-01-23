//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

typealias UpdateRoomNotificationStateCompletion = () -> Void
typealias RoomNotificationStateCallback = (RoomNotificationState) -> Void

protocol RoomNotificationSettingsServiceType {
    func observeNotificationState(listener: @escaping RoomNotificationStateCallback)
    func update(state: RoomNotificationState, completion: @escaping UpdateRoomNotificationStateCompletion)
    var notificationState: RoomNotificationState { get }
}
