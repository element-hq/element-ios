// File created from ScreenTemplate
// $ createScreen.sh SecretsSetupRecoveryKey SecretsSetupRecoveryKey
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

protocol SecretsSetupRecoveryKeyViewModelViewDelegate: AnyObject {
    func secretsSetupRecoveryKeyViewModel(_ viewModel: SecretsSetupRecoveryKeyViewModelType, didUpdateViewState viewSate: SecretsSetupRecoveryKeyViewState)
}

protocol SecretsSetupRecoveryKeyViewModelCoordinatorDelegate: AnyObject {
    func secretsSetupRecoveryKeyViewModelDidComplete(_ viewModel: SecretsSetupRecoveryKeyViewModelType)
    func secretsSetupRecoveryKeyViewModelDidFailed(_ viewModel: SecretsSetupRecoveryKeyViewModelType)
    func secretsSetupRecoveryKeyViewModelDidCancel(_ viewModel: SecretsSetupRecoveryKeyViewModelType)
}

/// Protocol describing the view model used by `SecretsSetupRecoveryKeyViewController`
protocol SecretsSetupRecoveryKeyViewModelType {        
        
    var viewDelegate: SecretsSetupRecoveryKeyViewModelViewDelegate? { get set }
    var coordinatorDelegate: SecretsSetupRecoveryKeyViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: SecretsSetupRecoveryKeyViewAction)
}
