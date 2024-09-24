// File created from ScreenTemplate
// $ createScreen.sh Settings/Notifications NotificationSettings
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol NotificationSettingsCoordinatorDelegate: AnyObject {
    func notificationSettingsCoordinatorDidComplete(_ coordinator: NotificationSettingsCoordinatorType)
}

/// `NotificationSettingsCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol NotificationSettingsCoordinatorType: Coordinator, Presentable {
    var delegate: NotificationSettingsCoordinatorDelegate? { get }
}
