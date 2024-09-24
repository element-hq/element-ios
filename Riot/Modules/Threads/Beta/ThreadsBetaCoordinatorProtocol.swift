// File created from FlowTemplate
// $ createRootCoordinator.sh Threads ThreadsBeta
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol ThreadsBetaCoordinatorDelegate: AnyObject {
    func threadsBetaCoordinatorDidTapEnable(_ coordinator: ThreadsBetaCoordinatorProtocol)
    func threadsBetaCoordinatorDidTapCancel(_ coordinator: ThreadsBetaCoordinatorProtocol)
}

/// `ThreadsBetaCoordinatorProtocol` is a protocol describing a Coordinator that handle xxxxxxx navigation flow.
protocol ThreadsBetaCoordinatorProtocol: Coordinator, Presentable {
    var delegate: ThreadsBetaCoordinatorDelegate? { get }
}
