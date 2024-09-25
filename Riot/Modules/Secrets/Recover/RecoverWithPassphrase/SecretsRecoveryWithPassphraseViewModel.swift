/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

final class SecretsRecoveryWithPassphraseViewModel: SecretsRecoveryWithPassphraseViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let recoveryService: MXRecoveryService
    
    private let dehydrationService: DehydrationService?
    
    // MARK: Public
    
    let recoveryGoal: SecretsRecoveryGoal
    
    var passphrase: String?
    
    var isFormValid: Bool {
        return self.passphrase?.isEmpty == false
    }
    
    weak var viewDelegate: SecretsRecoveryWithPassphraseViewModelViewDelegate?
    weak var coordinatorDelegate: SecretsRecoveryWithPassphraseViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(recoveryService: MXRecoveryService, recoveryGoal: SecretsRecoveryGoal, dehydrationService: DehydrationService?) {
        self.recoveryService = recoveryService
        self.dehydrationService = dehydrationService
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
            
            Task {
                await self.dehydrationService?.runDeviceDehydrationFlow(privateKeyData: privateKey)
            }
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
