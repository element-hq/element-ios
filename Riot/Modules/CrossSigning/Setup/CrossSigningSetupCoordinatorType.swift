// File created from FlowTemplate
// $ createRootCoordinator.sh CrossSigning CrossSigningSetup
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol CrossSigningSetupCoordinatorDelegate: AnyObject {
    func crossSigningSetupCoordinatorDidComplete(_ coordinator: CrossSigningSetupCoordinatorType)
    func crossSigningSetupCoordinatorDidCancel(_ coordinator: CrossSigningSetupCoordinatorType)
    func crossSigningSetupCoordinator(_ coordinator: CrossSigningSetupCoordinatorType, didFailWithError error: Error)
}

/// `CrossSigningSetupCoordinatorType` is a protocol describing a Coordinator that handles cross signing setup navigation flow.
protocol CrossSigningSetupCoordinatorType: Coordinator, Presentable {
    var delegate: CrossSigningSetupCoordinatorDelegate? { get }
}
