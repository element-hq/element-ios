/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyBackupRecoverFromPassphraseViewModelViewDelegate: AnyObject {
    func keyBackupRecoverFromPassphraseViewModel(_ viewModel: KeyBackupRecoverFromPassphraseViewModelType, didUpdateViewState viewSate: KeyBackupRecoverFromPassphraseViewState)
}

protocol KeyBackupRecoverFromPassphraseViewModelCoordinatorDelegate: AnyObject {
    func keyBackupRecoverFromPassphraseViewModelDidRecover(_ viewModel: KeyBackupRecoverFromPassphraseViewModelType)
    func keyBackupRecoverFromPassphraseViewModelDidCancel(_ viewModel: KeyBackupRecoverFromPassphraseViewModelType)
    func keyBackupRecoverFromPassphraseViewModelDoNotKnowPassphrase(_ viewModel: KeyBackupRecoverFromPassphraseViewModelType)
}

/// Protocol describing the view model used by `KeyBackupRecoverFromPassphraseViewController`
protocol KeyBackupRecoverFromPassphraseViewModelType {
    
    var passphrase: String? { get set }
    var isFormValid: Bool { get }
    
    var viewDelegate: KeyBackupRecoverFromPassphraseViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyBackupRecoverFromPassphraseViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: KeyBackupRecoverFromPassphraseViewAction)
}
