// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyWait
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol KeyVerificationSelfVerifyWaitCoordinatorDelegate: AnyObject {
    func keyVerificationSelfVerifyWaitCoordinator(_ coordinator: KeyVerificationSelfVerifyWaitCoordinatorType, didAcceptKeyVerificationRequest keyVerificationRequest: MXKeyVerificationRequest)
    func keyVerificationSelfVerifyWaitCoordinator(_ coordinator: KeyVerificationSelfVerifyWaitCoordinatorType, didAcceptIncomingSASTransaction incomingSASTransaction: MXSASTransaction)
    func keyVerificationSelfVerifyWaitCoordinatorDidCancel(_ coordinator: KeyVerificationSelfVerifyWaitCoordinatorType)
    func keyVerificationSelfVerifyWaitCoordinator(_ coordinator: KeyVerificationSelfVerifyWaitCoordinatorType, wantsToRecoverSecretsWith secretsRecoveryMode: SecretsRecoveryMode)
}

/// `KeyVerificationSelfVerifyWaitCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol KeyVerificationSelfVerifyWaitCoordinatorType: Coordinator, Presentable {
    var delegate: KeyVerificationSelfVerifyWaitCoordinatorDelegate? { get }
}
