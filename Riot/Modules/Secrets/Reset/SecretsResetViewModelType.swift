// File created from ScreenTemplate
// $ createScreen.sh Secrets/Reset SecretsReset
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
