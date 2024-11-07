/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyBackupRecoverFromRecoveryKeyViewModelViewDelegate: AnyObject {
    func keyBackupRecoverFromPassphraseViewModel(_ viewModel: KeyBackupRecoverFromRecoveryKeyViewModelType, didUpdateViewState viewSate: KeyBackupRecoverFromRecoveryKeyViewState)
}

protocol KeyBackupRecoverFromRecoveryKeyViewModelCoordinatorDelegate: AnyObject {
    func keyBackupRecoverFromRecoveryKeyViewModelDidRecover(_ viewModel: KeyBackupRecoverFromRecoveryKeyViewModelType)
    func keyBackupRecoverFromRecoveryKeyViewModelDidCancel(_ viewModel: KeyBackupRecoverFromRecoveryKeyViewModelType)
}

/// Protocol describing the view model used by `KeyBackupSetupPassphraseViewController`
protocol KeyBackupRecoverFromRecoveryKeyViewModelType {
    
    var recoveryKey: String? { get set }
    var isFormValid: Bool { get }
    
    var viewDelegate: KeyBackupRecoverFromRecoveryKeyViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyBackupRecoverFromRecoveryKeyViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: KeyBackupRecoverFromRecoveryKeyViewAction)
}
