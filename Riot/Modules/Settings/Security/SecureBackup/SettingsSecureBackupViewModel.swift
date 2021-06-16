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

final class SettingsSecureBackupViewModel: SettingsSecureBackupViewModelType {

    // MARK: - Properties
    weak var viewDelegate: SettingsSecureBackupViewModelViewDelegate?

    // MARK: Private
    private let recoveryService: MXRecoveryService
    private let keyBackup: MXKeyBackup

    init(recoveryService: MXRecoveryService, keyBackup: MXKeyBackup) {
        self.recoveryService = recoveryService
        self.keyBackup = keyBackup
        self.registerKeyBackupVersionDidChangeStateNotification()
    }

    private func registerKeyBackupVersionDidChangeStateNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyBackupDidStateChange), name: NSNotification.Name.mxKeyBackupDidStateChange, object: self.keyBackup)
    }

    @objc private func keyBackupDidStateChange() {
        self.checkKeyBackupState()
    }

    func process(viewAction: SettingsSecureBackupViewAction) {
        guard let viewDelegate = self.viewDelegate else {
            return
        }

        switch viewAction {
        case .load:
            viewDelegate.settingsSecureBackupViewModel(self, didUpdateViewState: .checkingBackup)
            self.checkKeyBackupState()
        case .resetSecureBackup,
             .createSecureBackup: // The implement supports both
            viewDelegate.settingsSecureBackupViewModelShowSecureBackupReset(self)
        case .createKeyBackup:
            viewDelegate.settingsSecureBackupViewModelShowKeyBackupCreate(self)
        case .restoreFromKeyBackup(let keyBackupVersion):
            viewDelegate.settingsSecureBackupViewModel(self, showKeyBackupRecover: keyBackupVersion)
        case .confirmDeleteKeyBackup(let keyBackupVersion):
            viewDelegate.settingsSecureBackupViewModel(self, showKeyBackupDeleteConfirm: keyBackupVersion)
        case .deleteKeyBackup(let keyBackupVersion):
            self.deleteKeyBackupVersion(keyBackupVersion)
        }
    }

    // MARK: - Private
    private func checkKeyBackupState() {

        // Check homeserver update in background
        self.keyBackup.forceRefresh(nil, failure: nil)

        if let keyBackupVersion = self.keyBackup.keyBackupVersion {

            self.keyBackup.trust(for: keyBackupVersion, onComplete: { [weak self] (keyBackupVersionTrust) in

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
        
        // We want to have a secure backup before having a key backup
        if recoveryService.hasRecovery() == false {
            self.viewDelegate?.settingsSecureBackupViewModel(self, didUpdateViewState: .noSecureBackup)
            return
        }

        var viewState: SettingsSecureBackupViewState?
        switch self.keyBackup.state {

        case MXKeyBackupStateUnknown,
             MXKeyBackupStateCheckingBackUpOnHomeserver:
            viewState = .checkingBackup

        case MXKeyBackupStateDisabled, MXKeyBackupStateEnabling:
            viewState = .noKeyBackup

        case MXKeyBackupStateNotTrusted:
            guard let keyBackupVersion = self.keyBackup.keyBackupVersion, let keyBackupVersionTrust = keyBackupVersionTrust else {
                return
            }
            viewState = .keyBackupNotTrusted(keyBackupVersion, keyBackupVersionTrust)

        case MXKeyBackupStateReadyToBackUp:
            guard let keyBackupVersion = self.keyBackup.keyBackupVersion, let keyBackupVersionTrust = keyBackupVersionTrust else {
                return
            }
            viewState = .keyBackup(keyBackupVersion, keyBackupVersionTrust)

        case MXKeyBackupStateWillBackUp, MXKeyBackupStateBackingUp:
            guard let keyBackupVersion = self.keyBackup.keyBackupVersion, let keyBackupVersionTrust = keyBackupVersionTrust else {
                return
            }

            // Get the backup progress before updating the state
            self.keyBackup.backupProgress { [weak self] (progress) in
                guard let sself = self else {
                    return
                }

                sself.viewDelegate?.settingsSecureBackupViewModel(sself, didUpdateViewState: .keyBackupAndRunning(keyBackupVersion, keyBackupVersionTrust, progress))
            }
        default:
            break
        }

        if let vviewState = viewState {
            self.viewDelegate?.settingsSecureBackupViewModel(self, didUpdateViewState: vviewState)
        }
    }

    private func deleteKeyBackupVersion(_ keyBackupVersion: MXKeyBackupVersion) {
        guard let keyBackupVersionVersion = keyBackupVersion.version  else {
            return
        }

        self.viewDelegate?.settingsSecureBackupViewModel(self, didUpdateNetworkRequestViewState: .loading)

        self.keyBackup.deleteVersion(keyBackupVersionVersion, success: { [weak self] () in
            guard let sself = self else {
                return
            }
            sself.viewDelegate?.settingsSecureBackupViewModel(sself, didUpdateNetworkRequestViewState: .loaded)

            }, failure: { [weak self] error in
                guard let sself = self else {
                    return
                }
                sself.viewDelegate?.settingsSecureBackupViewModel(sself, didUpdateNetworkRequestViewState: .error(error))
        })
    }
}
