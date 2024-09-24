// File created from ScreenTemplate
// $ createScreen.sh Room/NotificationSettings RoomNotificationSettings
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol RoomNotificationSettingsViewStateType {
    var saving: Bool { get }
    var roomEncrypted: Bool { get }
    var notificationOptions: [RoomNotificationState] { get }
    var notificationState: RoomNotificationState { get }
    var avatarData: AvatarProtocol? { get }
    var displayName: String? { get }
}
