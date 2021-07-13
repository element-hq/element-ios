// File created from ScreenTemplate
// $ createScreen.sh Secrets/Reset SecretsReset
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

protocol SecretsResetViewModelViewDelegate: AnyObject {
    func secretsResetViewModel(_ viewModel: SecretsResetViewModelType, didUpdateViewState viewState: SecretsResetViewState)
}

protocol SecretsResetViewModelCoordinatorDelegate: AnyObject {
    func secretsResetViewModel(_ viewModel: SecretsResetViewModelType, needsToAuthenticateWith request: AuthenticatedEndpointRequest)
    func secretsResetViewModelDidResetSecrets(_ viewModel: SecretsResetViewModelType)
    func secretsResetViewModelDidCancel(_ viewModel: SecretsResetViewModelType)
}

/// Protocol describing the view model used by `SecretsResetViewController`
protocol SecretsResetViewModelType {        
        
    var viewDelegate: SecretsResetViewModelViewDelegate? { get set }
    var coordinatorDelegate: SecretsResetViewModelCoordinatorDelegate? { get set }
    
    func update(viewState: SecretsResetViewState)    
    func process(viewAction: SecretsResetViewAction)
}
