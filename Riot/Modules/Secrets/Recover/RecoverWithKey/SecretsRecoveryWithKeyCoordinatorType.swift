/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SecretsRecoveryWithKeyCoordinatorDelegate: AnyObject {
    func secretsRecoveryWithKeyCoordinatorDidRecover(_ coordinator: SecretsRecoveryWithKeyCoordinatorType)
    func secretsRecoveryWithKeyCoordinatorDidCancel(_ coordinator: SecretsRecoveryWithKeyCoordinatorType)
    func secretsRecoveryWithKeyCoordinatorWantsToResetSecrets(_ viewModel: SecretsRecoveryWithKeyCoordinatorType)
}

/// `SecretsRecoveryWithKeyCoordinatorType` is a protocol describing a Coordinator that handle secrets recovery from recovery key navigation flow.
protocol SecretsRecoveryWithKeyCoordinatorType: Coordinator, Presentable {
    var delegate: SecretsRecoveryWithKeyCoordinatorDelegate? { get }
}
