// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objc protocol RoomContextActionServiceDelegate {
    func roomContextActionService(_ service: RoomContextActionServiceProtocol, updateActivityIndicator isActive: Bool)
    func roomContextActionService(_ service: RoomContextActionServiceProtocol, presentAlert alertController: UIAlertController)
    func roomContextActionService(_ service: RoomContextActionServiceProtocol, showRoomNotificationSettingsForRoomWithId roomId: String)
    func roomContextActionServiceDidJoinRoom(_ service: RoomContextActionServiceProtocol)
    func roomContextActionServiceDidLeaveRoom(_ service: RoomContextActionServiceProtocol)
    func roomContextActionServiceDidMarkRoom(_ service: RoomContextActionServiceProtocol)
}

/// `RoomContextActionServiceProtocol` classes are meant to be called by a `RoomActionProviderProtocol` instance so it provides the implementation of the menu actions.
@objc protocol RoomContextActionServiceProtocol {
    var delegate: RoomContextActionServiceDelegate? { get set }
    var roomId: String { get }
    var session: MXSession { get }
}
