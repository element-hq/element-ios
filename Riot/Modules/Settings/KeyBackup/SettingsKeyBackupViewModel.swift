/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

final class SettingsKeyBackupViewModel: SettingsKeyBackupViewModelType {

    // MARK: - Properties
    weak var viewDelegate: SettingsKeyBackupViewModelViewDelegate?

    // MARK: Private
    private let keyBackup: MXKeyBackup

    init(keyBackup: MXKeyBackup) {
        self.keyBackup = keyBackup
        self.registerKeyBackupVersionDidChangeStateNotification()
    }

    private func registerKeyBackupVersionDidChangeStateNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyBackupDidStateChange), name: NSNotification.Name.mxKeyBackupDidStateChange, object: self.keyBackup)
    }

    @objc private func keyBackupDidStateChange() {
        self.checkKeyBackupState()
    }

    func process(viewAction: SettingsKeyBackupViewAction) {
        guard let viewDelegate = self.viewDelegate else {
            return
        }

        switch viewAction {
        case .load:
            viewDelegate.settingsKeyBackupViewModel(self, didUpdateViewState: .checkingBackup)
            self.checkKeyBackupState()
        case .create:
            viewDelegate.settingsKeyBackupViewModelShowKeyBackupSetup(self)
        case .restore(let keyBackupVersion):
            viewDelegate.settingsKeyBackup(self, showKeyBackupRecover: keyBackupVersion)
        case .confirmDelete(let keyBackupVersion):
            viewDelegate.settingsKeyBackup(self, showKeyBackupDeleteConfirm: keyBackupVersion)
        case .delete(let keyBackupVersion):
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

        var viewState: SettingsKeyBackupViewState?
        switch self.keyBackup.state {

        case MXKeyBackupStateUnknown,
             MXKeyBackupStateCheckingBackUpOnHomeserver:
            viewState = .checkingBackup

        case MXKeyBackupStateDisabled, MXKeyBackupStateEnabling:
            viewState = .noBackup

        case MXKeyBackupStateNotTrusted:
            guard let keyBackupVersion = self.keyBackup.keyBackupVersion, let keyBackupVersionTrust = keyBackupVersionTrust else {
                return
            }
            viewState = .backupNotTrusted(keyBackupVersion, keyBackupVersionTrust)

        case MXKeyBackupStateReadyToBackUp:
            guard let keyBackupVersion = self.keyBackup.keyBackupVersion, let keyBackupVersionTrust = keyBackupVersionTrust else {
                return
            }
            viewState = .backup(keyBackupVersion, keyBackupVersionTrust)

        case MXKeyBackupStateWillBackUp, MXKeyBackupStateBackingUp:
            guard let keyBackupVersion = self.keyBackup.keyBackupVersion, let keyBackupVersionTrust = keyBackupVersionTrust else {
                return
            }

            // Get the backup progress before updating the state
            self.keyBackup.backupProgress { [weak self] (progress) in
                guard let sself = self else {
                    return
                }

                sself.viewDelegate?.settingsKeyBackupViewModel(sself, didUpdateViewState: .backupAndRunning(keyBackupVersion, keyBackupVersionTrust, progress))
            }
        default:
            break
        }

        if let vviewState = viewState {
            self.viewDelegate?.settingsKeyBackupViewModel(self, didUpdateViewState: vviewState)
        }
    }

    private func deleteKeyBackupVersion(_ keyBackupVersion: MXKeyBackupVersion) {
        guard let keyBackupVersionVersion = keyBackupVersion.version  else {
            return
        }

        self.viewDelegate?.settingsKeyBackupViewModel(self, didUpdateNetworkRequestViewState: .loading)

        self.keyBackup.deleteVersion(keyBackupVersionVersion, success: { [weak self] () in
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
