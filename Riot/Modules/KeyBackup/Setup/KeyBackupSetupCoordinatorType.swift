/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyBackupSetupCoordinatorDelegate: AnyObject {
    func keyBackupSetupCoordinatorDidCancel(_ keyBackupSetupCoordinator: KeyBackupSetupCoordinatorType)
    func keyBackupSetupCoordinatorDidSetupRecoveryKey(_ keyBackupSetupCoordinator: KeyBackupSetupCoordinatorType)
}

/// `KeyBackupSetupCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol KeyBackupSetupCoordinatorType: Coordinator, Presentable {
    var delegate: KeyBackupSetupCoordinatorDelegate? { get }
}
