// File created from ScreenTemplate
// $ createScreen.sh Settings/Notifications NotificationSettings
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol NotificationSettingsViewModelCoordinatorDelegate: AnyObject {
    func notificationSettingsViewModelDidComplete(_ viewModel: NotificationSettingsViewModelType)
}

/// Protocol describing the view model used by `NotificationSettingsViewController`
protocol NotificationSettingsViewModelType {
    var coordinatorDelegate: NotificationSettingsViewModelCoordinatorDelegate? { get set }
}
