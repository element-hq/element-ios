/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyBackupRecoverFromRecoveryKeyCoordinatorDelegate: AnyObject {
    func keyBackupRecoverFromPassphraseCoordinatorDidRecover(_ keyBackupRecoverFromRecoveryKeyCoordinator: KeyBackupRecoverFromRecoveryKeyCoordinatorType)
    func keyBackupRecoverFromPassphraseCoordinatorDidCancel(_ keyBackupRecoverFromRecoveryKeyCoordinator: KeyBackupRecoverFromRecoveryKeyCoordinatorType)
}

/// `KeyBackupRecoverFromRecoveryKeyCoordinatorType` is a protocol describing a Coordinator that handle key backup recover from recovery key navigation flow.
protocol KeyBackupRecoverFromRecoveryKeyCoordinatorType: Coordinator, Presentable {
    var delegate: KeyBackupRecoverFromRecoveryKeyCoordinatorDelegate? { get }
}
