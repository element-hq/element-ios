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

final class SecretsRecoveryWithKeyViewModel: SecretsRecoveryWithKeyViewModelType {
    // MARK: - Properties
    
    // MARK: Private
    
    private let recoveryService: MXRecoveryService
    
    // MARK: Public
    
    let recoveryGoal: SecretsRecoveryGoal
    
    var recoveryKey: String?
    
    var isFormValid: Bool {
        self.recoveryKey?.isEmpty == false
    }
    
    weak var viewDelegate: SecretsRecoveryWithKeyViewModelViewDelegate?
    weak var coordinatorDelegate: SecretsRecoveryWithKeyViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(recoveryService: MXRecoveryService, recoveryGoal: SecretsRecoveryGoal) {
        self.recoveryService = recoveryService
        self.recoveryGoal = recoveryGoal
    }

    // MARK: - Public
    
    func process(viewAction: SecretsRecoveryWithKeyViewAction) {
        switch viewAction {
        case .recover:
            recover()
        case .resetSecrets:
            coordinatorDelegate?.secretsRecoveryWithKeyViewModelWantsToResetSecrets(self)
        case .cancel:
            coordinatorDelegate?.secretsRecoveryWithKeyViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func recover() {
        guard let recoveryKey = recoveryKey else {
            return
        }
        
        update(viewState: .loading)
        
        do {
            let secretIds: [String]?
            
            if case SecretsRecoveryGoal.keyBackup = recoveryGoal {
                secretIds = [MXSecretId.keyBackup.takeUnretainedValue() as String]
            } else {
                secretIds = nil
            }
            
            let privateKey = try recoveryService.privateKey(fromRecoveryKey: recoveryKey)
            
            recoveryService.recoverSecrets(secretIds, withPrivateKey: privateKey, recoverServices: true, success: { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.update(viewState: .loaded)
                self.coordinatorDelegate?.secretsRecoveryWithKeyViewModelDidRecover(self)
            }, failure: { [weak self] error in
                guard let self = self else {
                    return
                }
                self.update(viewState: .error(error))
            })
        } catch {
            update(viewState: .error(error))
        }
    }
    
    private func update(viewState: SecretsRecoveryWithKeyViewState) {
        viewDelegate?.secretsRecoveryWithKeyViewModel(self, didUpdateViewState: viewState)
    }
}
