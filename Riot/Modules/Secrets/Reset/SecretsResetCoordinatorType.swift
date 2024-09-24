// File created from ScreenTemplate
// $ createScreen.sh Secrets/Reset SecretsReset
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SecretsResetCoordinatorDelegate: AnyObject {
    func secretsResetCoordinatorDidResetSecrets(_ coordinator: SecretsResetCoordinatorType)
    func secretsResetCoordinatorDidCancel(_ coordinator: SecretsResetCoordinatorType)
}

/// `SecretsResetCoordinatorType` is a protocol describing a Coordinator that handle keys reset flow.
protocol SecretsResetCoordinatorType: Coordinator, Presentable {
    var delegate: SecretsResetCoordinatorDelegate? { get }
}
