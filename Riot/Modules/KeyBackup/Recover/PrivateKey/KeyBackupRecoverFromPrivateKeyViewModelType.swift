// File created from ScreenTemplate
// $ createScreen.sh .KeyBackup/Recover/PrivateKey KeyBackupRecoverFromPrivateKey
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyBackupRecoverFromPrivateKeyViewModelViewDelegate: AnyObject {
    func keyBackupRecoverFromPrivateKeyViewModel(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType, didUpdateViewState viewSate: KeyBackupRecoverFromPrivateKeyViewState)
}

protocol KeyBackupRecoverFromPrivateKeyViewModelCoordinatorDelegate: AnyObject {
    func keyBackupRecoverFromPrivateKeyViewModelDidRecover(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType)
    func keyBackupRecoverFromPrivateKeyViewModelDidPrivateKeyFail(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType)
    func keyBackupRecoverFromPrivateKeyViewModelDidCancel(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType)
}

/// Protocol describing the view model used by `KeyBackupRecoverFromPrivateKeyViewController`
protocol KeyBackupRecoverFromPrivateKeyViewModelType {

    var viewDelegate: KeyBackupRecoverFromPrivateKeyViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyBackupRecoverFromPrivateKeyViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: KeyBackupRecoverFromPrivateKeyViewAction)
}
