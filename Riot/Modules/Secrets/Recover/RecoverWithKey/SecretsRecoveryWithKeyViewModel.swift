/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

final class SecretsRecoveryWithKeyViewModel: SecretsRecoveryWithKeyViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let recoveryService: MXRecoveryService
    
    private let dehydrationService: DehydrationService?
    
    // MARK: Public
    
    let recoveryGoal: SecretsRecoveryGoal
    
    var recoveryKey: String?
    
    var isFormValid: Bool {
        return self.recoveryKey?.isEmpty == false
    }
    
    weak var viewDelegate: SecretsRecoveryWithKeyViewModelViewDelegate?
    weak var coordinatorDelegate: SecretsRecoveryWithKeyViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(recoveryService: MXRecoveryService, recoveryGoal: SecretsRecoveryGoal, dehydrationService: DehydrationService?) {
        self.recoveryService = recoveryService
        self.dehydrationService = dehydrationService
        self.recoveryGoal = recoveryGoal
    }

    // MARK: - Public
    
    func process(viewAction: SecretsRecoveryWithKeyViewAction) {
        switch viewAction {
        case .recover:
            self.recover()
        case .resetSecrets:
            self.coordinatorDelegate?.secretsRecoveryWithKeyViewModelWantsToResetSecrets(self)
        case .cancel:
            self.coordinatorDelegate?.secretsRecoveryWithKeyViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func recover() {
        guard let recoveryKey = self.recoveryKey else {
            return
        }
        
        self.update(viewState: .loading)
        
        do {
            let secretIds: [String]?
            
            if case SecretsRecoveryGoal.keyBackup = self.recoveryGoal {
                secretIds = [MXSecretId.keyBackup.takeUnretainedValue() as String]
            } else {
                secretIds = nil
            }
            
            let privateKey = try self.recoveryService.privateKey(fromRecoveryKey: recoveryKey)
            
            self.recoveryService.recoverSecrets(secretIds, withPrivateKey: privateKey, recoverServices: true, success: { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.update(viewState: .loaded)
                self.coordinatorDelegate?.secretsRecoveryWithKeyViewModelDidRecover(self)
                
                Task {
                    await self.dehydrationService?.runDeviceDehydrationFlow(privateKeyData: privateKey)
                }
            }, failure: { [weak self] error in
                guard let self = self else {
                    return
                }
                self.update(viewState: .error(error))
            })
        } catch {
            self.update(viewState: .error(error))
        }            
    }
    
    private func update(viewState: SecretsRecoveryWithKeyViewState) {
        self.viewDelegate?.secretsRecoveryWithKeyViewModel(self, didUpdateViewState: viewState)
    }
}
