/*
 Copyright 2021 New Vector Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

protocol SettingsSecureBackupViewModelViewDelegate: AnyObject {
    func settingsSecureBackupViewModel(_ viewModel: SettingsSecureBackupViewModelType, didUpdateViewState viewState: SettingsSecureBackupViewState)
    func settingsSecureBackupViewModel(_ viewModel: SettingsSecureBackupViewModelType, didUpdateNetworkRequestViewState networkRequestViewSate: SettingsSecureBackupNetworkRequestViewState)
    
    func settingsSecureBackupViewModelShowSecureBackupReset(_ viewModel: SettingsSecureBackupViewModelType)

    func settingsSecureBackupViewModelShowKeyBackupCreate(_ viewModel: SettingsSecureBackupViewModelType)
    func settingsSecureBackupViewModel(_ viewModel: SettingsSecureBackupViewModelType, showKeyBackupRecover keyBackupVersion: MXKeyBackupVersion)
    func settingsSecureBackupViewModel(_ viewModel: SettingsSecureBackupViewModelType, showKeyBackupDeleteConfirm keyBackupVersion: MXKeyBackupVersion)
}

protocol SettingsSecureBackupViewModelType {

    var viewDelegate: SettingsSecureBackupViewModelViewDelegate? { get set }

    func process(viewAction: SettingsSecureBackupViewAction)
}
