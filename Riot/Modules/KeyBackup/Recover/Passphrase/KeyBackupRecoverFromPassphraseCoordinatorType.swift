/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyBackupRecoverFromPassphraseCoordinatorDelegate: AnyObject {
    func keyBackupRecoverFromPassphraseCoordinatorDidRecover(_ keyBackupRecoverFromPassphraseCoordinator: KeyBackupRecoverFromPassphraseCoordinatorType)
    func keyBackupRecoverFromPassphraseCoordinatorDoNotKnowPassphrase(_ keyBackupRecoverFromPassphraseCoordinator: KeyBackupRecoverFromPassphraseCoordinatorType)
    func keyBackupRecoverFromPassphraseCoordinatorDidCancel(_ keyBackupRecoverFromPassphraseCoordinator: KeyBackupRecoverFromPassphraseCoordinatorType)
}

/// `KeyBackupRecoverFromPassphraseCoordinatorType` is a protocol describing a Coordinator that handle key backup passphrase recover navigation flow.
protocol KeyBackupRecoverFromPassphraseCoordinatorType: Coordinator, Presentable {
    var delegate: KeyBackupRecoverFromPassphraseCoordinatorDelegate? { get }
}
