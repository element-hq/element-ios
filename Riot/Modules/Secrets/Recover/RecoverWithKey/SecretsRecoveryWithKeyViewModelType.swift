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

protocol SecretsRecoveryWithKeyViewModelViewDelegate: AnyObject {
    func secretsRecoveryWithKeyViewModel(_ viewModel: SecretsRecoveryWithKeyViewModelType, didUpdateViewState viewSate: SecretsRecoveryWithKeyViewState)
}

protocol SecretsRecoveryWithKeyViewModelCoordinatorDelegate: AnyObject {
    func secretsRecoveryWithKeyViewModelDidRecover(_ viewModel: SecretsRecoveryWithKeyViewModelType)
    func secretsRecoveryWithKeyViewModelDidCancel(_ viewModel: SecretsRecoveryWithKeyViewModelType)
    func secretsRecoveryWithKeyViewModelWantsToResetSecrets(_ viewModel: SecretsRecoveryWithKeyViewModelType)
}

/// Protocol describing the view model used by `SecretsRecoveryWithPassphraseViewController`
protocol SecretsRecoveryWithKeyViewModelType {
    
    var recoveryKey: String? { get set }
    var isFormValid: Bool { get }
    var recoveryGoal: SecretsRecoveryGoal { get }
    
    var viewDelegate: SecretsRecoveryWithKeyViewModelViewDelegate? { get set }
    var coordinatorDelegate: SecretsRecoveryWithKeyViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: SecretsRecoveryWithKeyViewAction)
}
