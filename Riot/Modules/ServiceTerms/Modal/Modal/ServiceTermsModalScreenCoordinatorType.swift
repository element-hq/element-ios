// File created from ScreenTemplate
// $ createScreen.sh Modal/Show ServiceTermsModalScreen
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol ServiceTermsModalScreenCoordinatorDelegate: AnyObject {
    func serviceTermsModalScreenCoordinatorDidAccept(_ coordinator: ServiceTermsModalScreenCoordinatorType)
    func serviceTermsModalScreenCoordinator(_ coordinator: ServiceTermsModalScreenCoordinatorType, displayPolicy policy: MXLoginPolicyData)
    func serviceTermsModalScreenCoordinatorDidDecline(_ coordinator: ServiceTermsModalScreenCoordinatorType)
}

/// `ServiceTermsModalScreenCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol ServiceTermsModalScreenCoordinatorType: Coordinator, Presentable {
    var delegate: ServiceTermsModalScreenCoordinatorDelegate? { get }
}
