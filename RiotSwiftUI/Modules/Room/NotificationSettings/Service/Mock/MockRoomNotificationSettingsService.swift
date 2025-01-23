//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class MockRoomNotificationSettingsService: RoomNotificationSettingsServiceType {
    static let example = MockRoomNotificationSettingsService(initialState: .all)
    
    var listener: RoomNotificationStateCallback?
    var notificationState: RoomNotificationState
    
    init(initialState: RoomNotificationState) {
        notificationState = initialState
    }
    
    func observeNotificationState(listener: @escaping RoomNotificationStateCallback) {
        self.listener = listener
    }
    
    func update(state: RoomNotificationState, completion: @escaping UpdateRoomNotificationStateCompletion) {
        notificationState = state
        completion()
        listener?(state)
    }
}
