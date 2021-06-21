/*
 Copyright 2020 New Vector Ltd
 
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

final class SecretsRecoveryWithPassphraseViewModel: SecretsRecoveryWithPassphraseViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let recoveryService: MXRecoveryService
    
    // MARK: Public
    
    let recoveryGoal: SecretsRecoveryGoal
    
    var passphrase: String?
    
    var isFormValid: Bool {
        return self.passphrase?.isEmpty == false
    }
    
    weak var viewDelegate: SecretsRecoveryWithPassphraseViewModelViewDelegate?
    weak var coordinatorDelegate: SecretsRecoveryWithPassphraseViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(recoveryService: MXRecoveryService, recoveryGoal: SecretsRecoveryGoal) {
        self.recoveryService = recoveryService
        self.recoveryGoal = recoveryGoal
    }
    
    // MARK: - Public
    
    func process(viewAction: SecretsRecoveryWithPassphraseViewAction) {
        switch viewAction {
        case .recover:
            self.recoverWithPassphrase()
        case .cancel:
            self.coordinatorDelegate?.secretsRecoveryWithPassphraseViewModelDidCancel(self)
        case .useRecoveryKey:
            self.coordinatorDelegate?.secretsRecoveryWithPassphraseViewModelWantsToRecoverByKey(self)
        case .resetSecrets:
            self.coordinatorDelegate?.secretsRecoveryWithPassphraseViewModelWantsToResetSecrets(self)
        }
    }
    
    // MARK: - Private
    
    private func recoverWithPassphrase() {
        guard let passphrase = self.passphrase else {
            return
        }
        
        self.update(viewState: .loading)
        
        self.recoveryService.privateKey(fromPassphrase: passphrase, success: { [weak self] privateKey in
            guard let self = self else {
                return
            }
            
            switch self.recoveryGoal {
            case .unlockSecureBackup(let block):
                self.execute(block: block, privateKey: privateKey)
            default:
                self.recoverSecrets(privateKey: privateKey)
            }
            
        }, failure: { [weak self] error in
            guard let self = self else {
                return
            }
            self.update(viewState: .error(error))
        })
    }
    
    private func recoverSecrets(privateKey: Data) {
        let secretIds: [String]?
        
        if case SecretsRecoveryGoal.keyBackup = self.recoveryGoal {
            secretIds = [MXSecretId.keyBackup.takeUnretainedValue() as String]
        } else {
            secretIds = nil
        }
        
        self.recoveryService.recoverSecrets(secretIds, withPrivateKey: privateKey, recoverServices: true, success: { [weak self] _ in
            guard let self = self else {
                return
            }
            self.update(viewState: .loaded)
            self.coordinatorDelegate?.secretsRecoveryWithPassphraseViewModelDidRecover(self)
        }, failure: { [weak self] error in
            guard let self = self else {
                return
            }
            self.update(viewState: .error(error))
        })
    }
    
    private func execute(block: @escaping (_ privateKey: Data, _ completion: @escaping (Result<Void, Error>) -> Void) -> Void, privateKey: Data) {
        // Check the private key is valid before using it
        self.recoveryService.checkPrivateKey(privateKey) { match in
            guard match else {
                // Reuse already managed error
                let error = NSError(domain: MXRecoveryServiceErrorDomain, code: Int(MXRecoveryServiceErrorCode.badRecoveryKeyErrorCode.rawValue), userInfo: nil)
                self.update(viewState: .error(error))
                return
            }
            
            // Run the extenal code while the view state is .loading
            block(privateKey) { result in
                MXLog.debug("[SecretsRecoveryWithPassphraseViewModel] execute: Block returned: \(result)")
                
                switch result {
                case .success:
                    self.update(viewState: .loaded)
                    self.coordinatorDelegate?.secretsRecoveryWithPassphraseViewModelDidRecover(self)
                case .failure(let error):
                    self.update(viewState: .error(error))
                }
            }
        }
    }
    
    private func update(viewState: SecretsRecoveryWithPassphraseViewState) {
        self.viewDelegate?.secretsRecoveryWithPassphraseViewModel(self, didUpdateViewState: viewState)
    }
}
