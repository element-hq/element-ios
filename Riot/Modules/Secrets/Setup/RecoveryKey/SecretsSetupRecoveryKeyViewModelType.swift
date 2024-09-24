// File created from ScreenTemplate
// $ createScreen.sh SecretsSetupRecoveryKey SecretsSetupRecoveryKey
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
