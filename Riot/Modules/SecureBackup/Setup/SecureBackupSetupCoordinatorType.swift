// File created from FlowTemplate
// $ createRootCoordinator.sh KeyBackupSetup/SecureSetup SecureKeyBackupSetup
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SecureBackupSetupCoordinatorDelegate: AnyObject {
    func secureBackupSetupCoordinatorDidComplete(_ coordinator: SecureBackupSetupCoordinatorType)
    func secureBackupSetupCoordinatorDidCancel(_ coordinator: SecureBackupSetupCoordinatorType)
}

/// `SecureBackupSetupCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol SecureBackupSetupCoordinatorType: Coordinator, Presentable {
    var delegate: SecureBackupSetupCoordinatorDelegate? { get }
}
