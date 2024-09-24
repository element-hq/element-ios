// File created from ScreenTemplate
// $ createScreen.sh Test SecretsSetupRecoveryPassphrase
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SecretsSetupRecoveryPassphraseCoordinatorDelegate: AnyObject {
    func secretsSetupRecoveryPassphraseCoordinator(_ coordinator: SecretsSetupRecoveryPassphraseCoordinatorType, didEnterNewPassphrase passphrase: String)
    func secretsSetupRecoveryPassphraseCoordinator(_ coordinator: SecretsSetupRecoveryPassphraseCoordinatorType, didConfirmPassphrase passphrase: String)
    func secretsSetupRecoveryPassphraseCoordinatorDidCancel(_ coordinator: SecretsSetupRecoveryPassphraseCoordinatorType)
}

/// `SecretsSetupRecoveryPassphraseCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol SecretsSetupRecoveryPassphraseCoordinatorType: Coordinator, Presentable {
    var delegate: SecretsSetupRecoveryPassphraseCoordinatorDelegate? { get }
}
