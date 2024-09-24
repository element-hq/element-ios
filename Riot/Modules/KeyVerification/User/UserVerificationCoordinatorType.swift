// File created from FlowTemplate
// $ createRootCoordinator.sh UserVerification UserVerification
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol UserVerificationCoordinatorDelegate: AnyObject {
    func userVerificationCoordinatorDidComplete(_ coordinator: UserVerificationCoordinatorType)
}

/// `UserVerificationCoordinatorType` is a protocol describing a Coordinator that handle user verification navigation flow.
protocol UserVerificationCoordinatorType: Coordinator, Presentable {
    var delegate: UserVerificationCoordinatorDelegate? { get }
}
