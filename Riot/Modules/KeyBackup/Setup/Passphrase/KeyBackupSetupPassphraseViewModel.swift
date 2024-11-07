/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

final class KeyBackupSetupPassphraseViewModel: KeyBackupSetupPassphraseViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private(set) var passphraseStrength: PasswordStrength = .tooGuessable
    private let passwordStrengthManager: PasswordStrengthManager
    private let keyBackup: MXKeyBackup
    private let coordinatorDelegateQueue: OperationQueue
    private var createKeyBackupOperation: MXHTTPOperation?
    
    // MARK: Public
    
    var passphrase: String? {
        didSet {
            self.updatePassphraseStrength()
        }
    }
    
    var confirmPassphrase: String?
    
    var isPassphraseValid: Bool {
        return self.passphraseStrength == .veryUnguessable
    }
    
    var isConfirmPassphraseValid: Bool {
        guard self.isPassphraseValid, let confirmPassphrase = self.confirmPassphrase else {
            return false
        }
        return confirmPassphrase == passphrase
    }
    
    var isFormValid: Bool {
        return self.isPassphraseValid && self.isConfirmPassphraseValid
    }

    weak var viewDelegate: KeyBackupSetupPassphraseViewModelViewDelegate?
    weak var coordinatorDelegate: KeyBackupSetupPassphraseViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(keyBackup: MXKeyBackup) {
        self.passwordStrengthManager = PasswordStrengthManager()
        self.keyBackup = keyBackup
        self.coordinatorDelegateQueue = OperationQueue.vc_createSerialOperationQueue(name: "\(type(of: self)).coordinatorDelegateQueue")
    }
    
    deinit {
        self.createKeyBackupOperation?.cancel()
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyBackupSetupPassphraseViewAction) {
        switch viewAction {
        case .setupPassphrase:
            self.setupPassphrase()
        case .setupRecoveryKey:
            self.setupRecoveryKey()
        case .skip:
            self.coordinatorDelegateQueue.vc_pause()
            self.viewDelegate?.keyBackupSetupPassphraseViewModelShowSkipAlert(self)
        case.skipAlertContinue:            
            self.coordinatorDelegateQueue.vc_resume()
        case.skipAlertSkip:
            self.coordinatorDelegateQueue.cancelAllOperations()
            self.coordinatorDelegate?.keyBackupSetupPassphraseViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func setupPassphrase() {
        guard let passphrase = self.passphrase else {
            return
        }
        
        self.update(viewState: .loading)
        
        self.keyBackup.prepareKeyBackupVersion(withPassword: passphrase, algorithm: nil, success: { [weak self] (megolmBackupCreationInfo) in
            guard let sself = self else {
                return
            }
            
            sself.createKeyBackupOperation = sself.keyBackup.createKeyBackupVersion(megolmBackupCreationInfo, success: { (_) in

                sself.update(viewState: .loaded)
                
                sself.coordinatorDelegateQueue.addOperation {
                    DispatchQueue.main.async {
                        sself.coordinatorDelegate?.keyBackupSetupPassphraseViewModel(sself, didCreateBackupFromPassphraseWithResultingRecoveryKey: megolmBackupCreationInfo.recoveryKey)
                    }
                }

            }, failure: { (error) in
                self?.update(viewState: .error(error))
            })
        }, failure: { [weak self] error in
            self?.update(viewState: .error(error))
        })
    }
    
    private func setupRecoveryKey() {
        self.update(viewState: .loading)
        
        self.keyBackup.prepareKeyBackupVersion(withPassword: nil, algorithm: nil, success: { [weak self] (megolmBackupCreationInfo) in
            guard let sself = self else {
                return
            }
            
            sself.createKeyBackupOperation = sself.keyBackup.createKeyBackupVersion(megolmBackupCreationInfo, success: { (_) in

                sself.update(viewState: .loaded)
                
                sself.coordinatorDelegateQueue.addOperation {
                    DispatchQueue.main.async {
                        sself.coordinatorDelegate?.keyBackupSetupPassphraseViewModel(sself, didCreateBackupFromRecoveryKey: megolmBackupCreationInfo.recoveryKey)
                    }
                }
            }, failure: { (error) in
                self?.update(viewState: .error(error))
            })
        }, failure: { [weak self] error in
            self?.update(viewState: .error(error))
        })
    }
    
    private func updatePassphraseStrength() {
        self.passphraseStrength = self.passwordStrength(for: self.passphrase)
    }
    
    private func passwordStrength(for password: String?) -> PasswordStrength {
        guard let password = password else {
            return .tooGuessable
        }
        return self.passwordStrengthManager.passwordStrength(for: password)
    }
    
    private func update(viewState: KeyBackupSetupPassphraseViewState) {
        self.viewDelegate?.keyBackupSetupPassphraseViewModel(self, didUpdateViewState: viewState)
    }
}
