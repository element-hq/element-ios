// File created from ScreenTemplate
// $ createScreen.sh Room/NotificationSettings RoomNotificationSettings
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
/// RoomNotificationSettingsViewController view actions exposed to view model
enum RoomNotificationSettingsViewAction {
    case load
    case selectNotificationState(RoomNotificationState)
    case save
    case cancel
}
