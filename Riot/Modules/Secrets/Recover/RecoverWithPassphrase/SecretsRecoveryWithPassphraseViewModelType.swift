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

protocol SecretsRecoveryWithPassphraseViewModelViewDelegate: AnyObject {
    func secretsRecoveryWithPassphraseViewModel(_ viewModel: SecretsRecoveryWithPassphraseViewModelType, didUpdateViewState viewSate: SecretsRecoveryWithPassphraseViewState)
}

protocol SecretsRecoveryWithPassphraseViewModelCoordinatorDelegate: AnyObject {
    func secretsRecoveryWithPassphraseViewModelDidRecover(_ viewModel: SecretsRecoveryWithPassphraseViewModelType)
    func secretsRecoveryWithPassphraseViewModelDidCancel(_ viewModel: SecretsRecoveryWithPassphraseViewModelType)
    func secretsRecoveryWithPassphraseViewModelWantsToRecoverByKey(_ viewModel: SecretsRecoveryWithPassphraseViewModelType)
    func secretsRecoveryWithPassphraseViewModelWantsToResetSecrets(_ viewModel: SecretsRecoveryWithPassphraseViewModelType)
}

/// Protocol describing the view model used by `SecretsRecoveryWithPassphraseViewController`
protocol SecretsRecoveryWithPassphraseViewModelType {
    
    var passphrase: String? { get set }
    var isFormValid: Bool { get }
    var recoveryGoal: SecretsRecoveryGoal { get }
    
    var viewDelegate: SecretsRecoveryWithPassphraseViewModelViewDelegate? { get set }
    var coordinatorDelegate: SecretsRecoveryWithPassphraseViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: SecretsRecoveryWithPassphraseViewAction)
}
