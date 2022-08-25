/*
 Copyright 2019 New Vector Ltd

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

final class SettingsKeyBackupViewModel: SettingsKeyBackupViewModelType {
    // MARK: - Properties

    weak var viewDelegate: SettingsKeyBackupViewModelViewDelegate?

    // MARK: Private

    private let keyBackup: MXKeyBackup

    init(keyBackup: MXKeyBackup) {
        self.keyBackup = keyBackup
        registerKeyBackupVersionDidChangeStateNotification()
    }

    private func registerKeyBackupVersionDidChangeStateNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyBackupDidStateChange), name: NSNotification.Name.mxKeyBackupDidStateChange, object: keyBackup)
    }

    @objc private func keyBackupDidStateChange() {
        checkKeyBackupState()
    }

    func process(viewAction: SettingsKeyBackupViewAction) {
        guard let viewDelegate = viewDelegate else {
            return
        }

        switch viewAction {
        case .load:
            viewDelegate.settingsKeyBackupViewModel(self, didUpdateViewState: .checkingBackup)
            checkKeyBackupState()
        case .create:
            viewDelegate.settingsKeyBackupViewModelShowKeyBackupSetup(self)
        case .restore(let keyBackupVersion):
            viewDelegate.settingsKeyBackup(self, showKeyBackupRecover: keyBackupVersion)
        case .confirmDelete(let keyBackupVersion):
            viewDelegate.settingsKeyBackup(self, showKeyBackupDeleteConfirm: keyBackupVersion)
        case .delete(let keyBackupVersion):
            deleteKeyBackupVersion(keyBackupVersion)
        }
    }

    // MARK: - Private

    private func checkKeyBackupState() {
        // Check homeserver update in background
        keyBackup.forceRefresh(nil, failure: nil)

        if let keyBackupVersion = keyBackup.keyBackupVersion {
            keyBackup.trust(for: keyBackupVersion, onComplete: { [weak self] keyBackupVersionTrust in

                guard let sself = self else {
                    return
                }

                sself.computeState(withBackupVersionTrust: keyBackupVersionTrust)
            })
        } else {
            computeState()
        }
    }

    private func computeState(withBackupVersionTrust keyBackupVersionTrust: MXKeyBackupVersionTrust? = nil) {
        var viewState: SettingsKeyBackupViewState?
        switch keyBackup.state {
        case MXKeyBackupStateUnknown,
             MXKeyBackupStateCheckingBackUpOnHomeserver:
            viewState = .checkingBackup

        case MXKeyBackupStateDisabled, MXKeyBackupStateEnabling:
            viewState = .noBackup

        case MXKeyBackupStateNotTrusted:
            guard let keyBackupVersion = keyBackup.keyBackupVersion, let keyBackupVersionTrust = keyBackupVersionTrust else {
                return
            }
            viewState = .backupNotTrusted(keyBackupVersion, keyBackupVersionTrust)

        case MXKeyBackupStateReadyToBackUp:
            guard let keyBackupVersion = keyBackup.keyBackupVersion, let keyBackupVersionTrust = keyBackupVersionTrust else {
                return
            }
            viewState = .backup(keyBackupVersion, keyBackupVersionTrust)

        case MXKeyBackupStateWillBackUp, MXKeyBackupStateBackingUp:
            guard let keyBackupVersion = keyBackup.keyBackupVersion, let keyBackupVersionTrust = keyBackupVersionTrust else {
                return
            }

            // Get the backup progress before updating the state
            keyBackup.backupProgress { [weak self] progress in
                guard let sself = self else {
                    return
                }

                sself.viewDelegate?.settingsKeyBackupViewModel(sself, didUpdateViewState: .backupAndRunning(keyBackupVersion, keyBackupVersionTrust, progress))
            }
        default:
            break
        }

        if let vviewState = viewState {
            viewDelegate?.settingsKeyBackupViewModel(self, didUpdateViewState: vviewState)
        }
    }

    private func deleteKeyBackupVersion(_ keyBackupVersion: MXKeyBackupVersion) {
        guard let keyBackupVersionVersion = keyBackupVersion.version else {
            return
        }

        viewDelegate?.settingsKeyBackupViewModel(self, didUpdateNetworkRequestViewState: .loading)

        keyBackup.deleteVersion(keyBackupVersionVersion, success: { [weak self] () in
            guard let sself = self else {
                return
            }
            sself.viewDelegate?.settingsKeyBackupViewModel(sself, didUpdateNetworkRequestViewState: .loaded)

        }, failure: { [weak self] error in
            guard let sself = self else {
                return
            }
            sself.viewDelegate?.settingsKeyBackupViewModel(sself, didUpdateNetworkRequestViewState: .error(error))
        })
    }
}
