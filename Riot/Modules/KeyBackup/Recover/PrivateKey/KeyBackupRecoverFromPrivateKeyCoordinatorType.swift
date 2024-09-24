// File created from ScreenTemplate
// $ createScreen.sh .KeyBackup/Recover/PrivateKey KeyBackupRecoverFromPrivateKey
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyBackupRecoverFromPrivateKeyCoordinatorDelegate: AnyObject {
    func keyBackupRecoverFromPrivateKeyCoordinatorDidRecover(_ coordinator: KeyBackupRecoverFromPrivateKeyCoordinatorType)
    func keyBackupRecoverFromPrivateKeyCoordinatorDidPrivateKeyFail(_ coordinator: KeyBackupRecoverFromPrivateKeyCoordinatorType)
    func keyBackupRecoverFromPrivateKeyCoordinatorDidCancel(_ coordinator: KeyBackupRecoverFromPrivateKeyCoordinatorType)
}

/// `KeyBackupRecoverFromPrivateKeyCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol KeyBackupRecoverFromPrivateKeyCoordinatorType: Coordinator, Presentable {
    var delegate: KeyBackupRecoverFromPrivateKeyCoordinatorDelegate? { get }
}
