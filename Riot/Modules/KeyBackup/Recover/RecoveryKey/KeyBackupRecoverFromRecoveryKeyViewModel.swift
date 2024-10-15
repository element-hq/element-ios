/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

final class KeyBackupRecoverFromRecoveryKeyViewModel: KeyBackupRecoverFromRecoveryKeyViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let keyBackup: MXKeyBackup
    private var currentHTTPOperation: MXHTTPOperation?
    private let keyBackupVersion: MXKeyBackupVersion
    
    // MARK: Public
    
    var recoveryKey: String?
    
    var isFormValid: Bool {
        return self.recoveryKey?.isEmpty == false
    }
    
    weak var viewDelegate: KeyBackupRecoverFromRecoveryKeyViewModelViewDelegate?
    weak var coordinatorDelegate: KeyBackupRecoverFromRecoveryKeyViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(keyBackup: MXKeyBackup, keyBackupVersion: MXKeyBackupVersion) {
        self.keyBackup = keyBackup
        self.keyBackupVersion = keyBackupVersion
    }
    
    deinit {
        self.currentHTTPOperation?.cancel()
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyBackupRecoverFromRecoveryKeyViewAction) {
        switch viewAction {
        case .recover:
            self.recover()
        case .cancel:
            self.coordinatorDelegate?.keyBackupRecoverFromRecoveryKeyViewModelDidCancel(self)
        case .unknownRecoveryKey:
            break
        }
    }
    
    // MARK: - Private
    
    private func recover() {
        guard let recoveryKey = self.recoveryKey else {
            return
        }
        
        self.update(viewState: .loading)
        
        self.currentHTTPOperation = self.keyBackup.restore(self.keyBackupVersion, withRecoveryKey: recoveryKey, room: nil, session: nil, success: { [weak self] (_, _) in
            guard let sself = self else {
                return
            }

            // Trust on decrypt
            sself.currentHTTPOperation = sself.keyBackup.trust(sself.keyBackupVersion, trust: true, success: { [weak sself] () in
                guard let ssself = sself else {
                    return
                }

                ssself.update(viewState: .loaded)
                ssself.coordinatorDelegate?.keyBackupRecoverFromRecoveryKeyViewModelDidRecover(ssself)

                }, failure: {[weak sself]  error in
                    sself?.update(viewState: .error(error))
            })

        }, failure: {[weak self]  error in
            self?.update(viewState: .error(error))
        })
    }
    
    private func update(viewState: KeyBackupRecoverFromRecoveryKeyViewState) {        
        self.viewDelegate?.keyBackupRecoverFromPassphraseViewModel(self, didUpdateViewState: viewState)
    }
}
