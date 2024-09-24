// File created from ScreenTemplate
// $ createScreen.sh Room/NotificationSettings RoomNotificationSettings
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol RoomNotificationSettingsCoordinatorDelegate: AnyObject {
    func roomNotificationSettingsCoordinatorDidComplete(_ coordinator: RoomNotificationSettingsCoordinatorType)
    func roomNotificationSettingsCoordinatorDidCancel(_ coordinator: RoomNotificationSettingsCoordinatorType)
}

/// `RoomNotificationSettingsCoordinatorType` is a protocol describing a Coordinator that handles changes to the room navigation settings navigation flow.
protocol RoomNotificationSettingsCoordinatorType: Coordinator, Presentable {
    var delegate: RoomNotificationSettingsCoordinatorDelegate? { get }
}
