/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SecretsRecoveryCoordinatorDelegate: AnyObject {
    func secretsRecoveryCoordinatorDidRecover(_ coordinator: SecretsRecoveryCoordinatorType)
    func secretsRecoveryCoordinatorDidCancel(_ coordinator: SecretsRecoveryCoordinatorType)
}

/// `SecretsRecoveryCoordinatorType` is a protocol describing a Coordinator that handle secrets recovery navigation flow.
protocol SecretsRecoveryCoordinatorType: Coordinator, Presentable {
    var delegate: SecretsRecoveryCoordinatorDelegate? { get }
}
