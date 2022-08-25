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
            updatePassphraseStrength()
        }
    }
    
    var confirmPassphrase: String?
    
    var isPassphraseValid: Bool {
        passphraseStrength == .veryUnguessable
    }
    
    var isConfirmPassphraseValid: Bool {
        guard isPassphraseValid, let confirmPassphrase = confirmPassphrase else {
            return false
        }
        return confirmPassphrase == passphrase
    }
    
    var isFormValid: Bool {
        self.isPassphraseValid && self.isConfirmPassphraseValid
    }

    weak var viewDelegate: KeyBackupSetupPassphraseViewModelViewDelegate?
    weak var coordinatorDelegate: KeyBackupSetupPassphraseViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(keyBackup: MXKeyBackup) {
        passwordStrengthManager = PasswordStrengthManager()
        self.keyBackup = keyBackup
        coordinatorDelegateQueue = OperationQueue.vc_createSerialOperationQueue(name: "\(type(of: self)).coordinatorDelegateQueue")
    }
    
    deinit {
        self.createKeyBackupOperation?.cancel()
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyBackupSetupPassphraseViewAction) {
        switch viewAction {
        case .setupPassphrase:
            setupPassphrase()
        case .setupRecoveryKey:
            setupRecoveryKey()
        case .skip:
            coordinatorDelegateQueue.vc_pause()
            viewDelegate?.keyBackupSetupPassphraseViewModelShowSkipAlert(self)
        case .skipAlertContinue:
            coordinatorDelegateQueue.vc_resume()
        case .skipAlertSkip:
            coordinatorDelegateQueue.cancelAllOperations()
            coordinatorDelegate?.keyBackupSetupPassphraseViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func setupPassphrase() {
        guard let passphrase = passphrase else {
            return
        }
        
        update(viewState: .loading)
        
        keyBackup.prepareKeyBackupVersion(withPassword: passphrase, algorithm: nil, success: { [weak self] megolmBackupCreationInfo in
            guard let sself = self else {
                return
            }
            
            sself.createKeyBackupOperation = sself.keyBackup.createKeyBackupVersion(megolmBackupCreationInfo, success: { _ in

                sself.update(viewState: .loaded)
                
                sself.coordinatorDelegateQueue.addOperation {
                    DispatchQueue.main.async {
                        sself.coordinatorDelegate?.keyBackupSetupPassphraseViewModel(sself, didCreateBackupFromPassphraseWithResultingRecoveryKey: megolmBackupCreationInfo.recoveryKey)
                    }
                }

            }, failure: { error in
                self?.update(viewState: .error(error))
            })
        }, failure: { [weak self] error in
            self?.update(viewState: .error(error))
        })
    }
    
    private func setupRecoveryKey() {
        update(viewState: .loading)
        
        keyBackup.prepareKeyBackupVersion(withPassword: nil, algorithm: nil, success: { [weak self] megolmBackupCreationInfo in
            guard let sself = self else {
                return
            }
            
            sself.createKeyBackupOperation = sself.keyBackup.createKeyBackupVersion(megolmBackupCreationInfo, success: { _ in

                sself.update(viewState: .loaded)
                
                sself.coordinatorDelegateQueue.addOperation {
                    DispatchQueue.main.async {
                        sself.coordinatorDelegate?.keyBackupSetupPassphraseViewModel(sself, didCreateBackupFromRecoveryKey: megolmBackupCreationInfo.recoveryKey)
                    }
                }
            }, failure: { error in
                self?.update(viewState: .error(error))
            })
        }, failure: { [weak self] error in
            self?.update(viewState: .error(error))
        })
    }
    
    private func updatePassphraseStrength() {
        passphraseStrength = passwordStrength(for: passphrase)
    }
    
    private func passwordStrength(for password: String?) -> PasswordStrength {
        guard let password = password else {
            return .tooGuessable
        }
        return passwordStrengthManager.passwordStrength(for: password)
    }
    
    private func update(viewState: KeyBackupSetupPassphraseViewState) {
        viewDelegate?.keyBackupSetupPassphraseViewModel(self, didUpdateViewState: viewState)
    }
}
