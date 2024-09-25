/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

protocol SettingsKeyBackupViewModelViewDelegate: AnyObject {
    func settingsKeyBackupViewModel(_ viewModel: SettingsKeyBackupViewModelType, didUpdateViewState viewState: SettingsKeyBackupViewState)
    func settingsKeyBackupViewModel(_ viewModel: SettingsKeyBackupViewModelType, didUpdateNetworkRequestViewState networkRequestViewSate: SettingsKeyBackupNetworkRequestViewState)

    func settingsKeyBackupViewModelShowKeyBackupSetup(_ viewModel: SettingsKeyBackupViewModelType)
    func settingsKeyBackup(_ viewModel: SettingsKeyBackupViewModelType, showKeyBackupRecover keyBackupVersion: MXKeyBackupVersion)
    func settingsKeyBackup(_ viewModel: SettingsKeyBackupViewModelType, showKeyBackupDeleteConfirm keyBackupVersion: MXKeyBackupVersion)
}

protocol SettingsKeyBackupViewModelType {

    var viewDelegate: SettingsKeyBackupViewModelViewDelegate? { get set }

    func process(viewAction: SettingsKeyBackupViewAction)
}
