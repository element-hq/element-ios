/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

final class SettingsSecureBackupViewModel: SettingsSecureBackupViewModelType {

    // MARK: - Properties
    weak var viewDelegate: SettingsSecureBackupViewModelViewDelegate?

    // MARK: Private
    private let recoveryService: MXRecoveryService
    private let keyBackup: MXKeyBackup
    private var progressUpdateTimer: Timer?

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
            viewDelegate.settingsSecureBackupViewModel(self, didUpdateViewState: .loading)
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
        
        var viewState: SettingsSecureBackupViewState?
        var keyBackupState: SettingsSecureBackupViewState.KeyBackupState?
        switch self.keyBackup.state {

        case MXKeyBackupStateUnknown,
             MXKeyBackupStateCheckingBackUpOnHomeserver:
            viewState = .loading

        case MXKeyBackupStateDisabled, MXKeyBackupStateEnabling:
            keyBackupState = .noKeyBackup

        case MXKeyBackupStateNotTrusted:
            guard let keyBackupVersion = self.keyBackup.keyBackupVersion, let keyBackupVersionTrust = keyBackupVersionTrust else {
                return
            }
            keyBackupState = .keyBackupNotTrusted(keyBackupVersion, keyBackupVersionTrust)

        case MXKeyBackupStateReadyToBackUp, MXKeyBackupStateWillBackUp, MXKeyBackupStateBackingUp:
            guard let keyBackupVersion = self.keyBackup.keyBackupVersion, let keyBackupVersionTrust = keyBackupVersionTrust else {
                return
            }
            
            let importProgress = keyBackup.importProgress
            let keyBackupState: SettingsSecureBackupViewState.KeyBackupState = .keyBackup(keyBackupVersion, keyBackupVersionTrust, importProgress)
            let viewState: SettingsSecureBackupViewState = self.recoveryService.hasRecovery() ? .secureBackup(keyBackupState) : .noSecureBackup(keyBackupState)
            self.viewDelegate?.settingsSecureBackupViewModel(self, didUpdateViewState: viewState)
            scheduleProgressUpdateIfNecessary(keyBackupVersionTrust: keyBackupVersionTrust, progress: importProgress)
            
        default:
            break
        }
        
        // Turn secure backup and key back states into view state
        if let keyBackupState = keyBackupState {
            viewState = recoveryService.hasRecovery() ? .secureBackup(keyBackupState) : .noSecureBackup(keyBackupState)
        }

        if let viewState = viewState {
            self.viewDelegate?.settingsSecureBackupViewModel(self, didUpdateViewState: viewState)
        }
    }
    
    private func scheduleProgressUpdateIfNecessary(keyBackupVersionTrust: MXKeyBackupVersionTrust, progress: Progress?) {
        if progress != nil {
            progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
                self?.computeState(withBackupVersionTrust: keyBackupVersionTrust)
            }
        } else {
            progressUpdateTimer?.invalidate()
            progressUpdateTimer = nil
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
