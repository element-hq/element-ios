// File created from ScreenTemplate
// $ createScreen.sh Test SecretsSetupRecoveryPassphrase
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SecretsSetupRecoveryPassphraseViewModelViewDelegate: AnyObject {
    func secretsSetupRecoveryPassphraseViewModel(_ viewModel: SecretsSetupRecoveryPassphraseViewModelType, didUpdateViewState viewSate: SecretsSetupRecoveryPassphraseViewState)
}

protocol SecretsSetupRecoveryPassphraseViewModelCoordinatorDelegate: AnyObject {
    func secretsSetupRecoveryPassphraseViewModel(_ viewModel: SecretsSetupRecoveryPassphraseViewModelType, didEnterNewPassphrase passphrase: String)
    func secretsSetupRecoveryPassphraseViewModel(_ viewModel: SecretsSetupRecoveryPassphraseViewModelType, didConfirmPassphrase passphrase: String)    
    func secretsSetupRecoveryPassphraseViewModelDidCancel(_ viewModel: SecretsSetupRecoveryPassphraseViewModelType)
}

/// Protocol describing the view model used by `SecretsSetupRecoveryPassphraseViewController`
protocol SecretsSetupRecoveryPassphraseViewModelType {
    
    var viewDelegate: SecretsSetupRecoveryPassphraseViewModelViewDelegate? { get set }
    var coordinatorDelegate: SecretsSetupRecoveryPassphraseViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: SecretsSetupRecoveryPassphraseViewAction)
}
