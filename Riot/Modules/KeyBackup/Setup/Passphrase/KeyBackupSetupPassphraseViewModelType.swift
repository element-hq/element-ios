/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyBackupSetupPassphraseViewModelViewDelegate: AnyObject {
    func keyBackupSetupPassphraseViewModel(_ viewModel: KeyBackupSetupPassphraseViewModelType, didUpdateViewState viewSate: KeyBackupSetupPassphraseViewState)
    func keyBackupSetupPassphraseViewModelShowSkipAlert(_ viewModel: KeyBackupSetupPassphraseViewModelType)
}

protocol KeyBackupSetupPassphraseViewModelCoordinatorDelegate: AnyObject {
    func keyBackupSetupPassphraseViewModel(_ viewModel: KeyBackupSetupPassphraseViewModelType, didCreateBackupFromPassphraseWithResultingRecoveryKey recoveryKey: String)
    func keyBackupSetupPassphraseViewModel(_ viewModel: KeyBackupSetupPassphraseViewModelType, didCreateBackupFromRecoveryKey recoveryKey: String)    
    func keyBackupSetupPassphraseViewModelDidCancel(_ viewModel: KeyBackupSetupPassphraseViewModelType)
}

/// Protocol describing the view model used by `KeyBackupSetupPassphraseViewController`
protocol KeyBackupSetupPassphraseViewModelType {
    
    var passphrase: String? { get set }
    var confirmPassphrase: String? { get set }
    var passphraseStrength: PasswordStrength { get }
    
    var isPassphraseValid: Bool { get }
    var isConfirmPassphraseValid: Bool { get }
    var isFormValid: Bool { get }
        
    var viewDelegate: KeyBackupSetupPassphraseViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyBackupSetupPassphraseViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: KeyBackupSetupPassphraseViewAction)
}
